import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

import '../config/app_environment.dart';
import '../firebase_options.dart';
import 'client_models.dart';

abstract class ClientGateway {
  Stream<void> get sessionChanges;
  Future<void> initialize();
  Future<ClientSnapshot?> load({String? cursor});
  Future<void> signIn(String email, String password);
  Future<void> recover(String email);
  Future<void> signOut();
  void dispose();
}

class FirebaseClientGateway implements ClientGateway {
  FirebaseClientGateway() : _http = http.Client();
  final http.Client _http;
  final _changes = StreamController<void>.broadcast();
  FirebaseAuth? _auth;
  StreamSubscription<User?>? _subscription;
  bool _closed = false;

  @override
  Stream<void> get sessionChanges => _changes.stream;

  @override
  Future<void> initialize() async {
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      if (Firebase.apps.isEmpty) await Firebase.initializeApp(options: options);
      if (_closed) return;
      _auth = FirebaseAuth.instance;
      _subscription = _auth!.authStateChanges().listen((_) {
        if (!_closed) _changes.add(null);
      });
    } catch (_) {
      throw const ClientFailure(
        ClientConnection.unavailable,
        'Sign-in is unavailable on this device. Please try again later.',
      );
    }
  }

  Future<Object?> _get(String path, {String? cursor}) async {
    final user = _auth?.currentUser;
    if (user == null) {
      throw const ClientFailure(ClientConnection.signedOut, 'Please sign in.');
    }
    try {
      final token = await user.getIdToken();
      if (token == null) {
        throw const ClientFailure(
          ClientConnection.signedOut,
          'Please sign in again.',
        );
      }
      final base = Uri.parse(AppEnvironment.current.backendUrl);
      final uri = base.replace(
        path: '${base.path.replaceFirst(RegExp(r'/$'), '')}$path',
        queryParameters: cursor == null ? null : {'cursor': cursor},
      );
      final response = await _http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 20));
      if (_auth?.currentUser?.uid != user.uid) {
        throw const ClientFailure(
          ClientConnection.signedOut,
          'Session changed.',
        );
      }
      if (response.statusCode == 401) {
        throw const ClientFailure(
          ClientConnection.signedOut,
          'Please sign in again.',
        );
      }
      if (response.statusCode == 403) {
        throw const ClientFailure(
          ClientConnection.denied,
          'Client access is not available for this account.',
        );
      }
      if (response.statusCode != 200) {
        throw const ClientFailure(
          ClientConnection.unavailable,
          'This service is temporarily unavailable. Please retry.',
        );
      }
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic> || !body.containsKey('data')) {
        throw const FormatException();
      }
      return body['data'];
    } on ClientFailure {
      rethrow;
    } on FormatException {
      throw const ClientFailure(
        ClientConnection.unavailable,
        'The service returned an unexpected response.',
      );
    } catch (_) {
      throw const ClientFailure(
        ClientConnection.offline,
        'Could not connect. Check your connection and retry.',
      );
    }
  }

  @override
  Future<ClientSnapshot?> load({String? cursor}) async {
    if (_auth == null) await initialize();
    if (_auth?.currentUser == null) return null;
    final uid = _auth!.currentUser!.uid;
    final actor = await _get('/v1/auth/me');
    final page = await _get('/v1/projects', cursor: cursor);
    if (_auth?.currentUser?.uid != uid) {
      throw const ClientFailure(
        ClientConnection.signedOut,
        'Session changed. Please sign in again.',
      );
    }
    if (actor is! Map<String, dynamic> ||
        actor['uid'] is! String ||
        actor['uid'] != uid ||
        actor['display_name'] is! String ||
        actor['role'] != 'client' ||
        page is! Map<String, dynamic> ||
        page['items'] is! List ||
        (page['next_cursor'] != null && page['next_cursor'] is! String)) {
      throw const ClientFailure(
        ClientConnection.unavailable,
        'The service returned an unexpected response.',
      );
    }
    try {
      return ClientSnapshot(
        uid: actor['uid'] as String,
        name: actor['display_name'] as String,
        projects: (page['items'] as List).map(ClientProject.fromJson).toList(),
        nextCursor: page['next_cursor'] as String?,
      );
    } on FormatException {
      throw const ClientFailure(
        ClientConnection.unavailable,
        'Project information is temporarily unavailable.',
      );
    }
  }

  @override
  Future<void> signIn(String email, String password) async {
    if (_auth == null) await initialize();
    try {
      await _auth!.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException {
      throw const ClientFailure(
        ClientConnection.signedOut,
        'Could not sign in. Check your details and try again.',
      );
    }
  }

  @override
  Future<void> recover(String email) async {
    if (_auth == null) await initialize();
    try {
      await _auth!.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException {
      throw const ClientFailure(
        ClientConnection.unavailable,
        'Recovery is unavailable. Please try again later.',
      );
    }
  }

  @override
  Future<void> signOut() async => _auth?.signOut();

  @override
  void dispose() {
    _closed = true;
    _subscription?.cancel();
    _changes.close();
    _http.close();
  }
}
