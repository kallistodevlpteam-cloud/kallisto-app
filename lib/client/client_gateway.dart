import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

import '../config/app_environment.dart';
import '../firebase_options.dart';
import 'client_models.dart';
import 'workflow_models.dart';

String clientIntentId() => List.generate(
  16,
  (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
).join();

abstract class ClientGateway {
  Stream<void> get sessionChanges;
  Future<void> initialize();
  Future<ClientSnapshot?> load({String? cursor});
  Future<void> signIn(String email, String password);
  Future<void> recover(String email);
  Future<void> signOut();
  Future<void> signUp(String email, String password) =>
      throw UnimplementedError();
  Future<EnrollmentNotice?> enrollmentNotice() => throw UnimplementedError();
  Future<void> enroll(String name, EnrollmentNotice notice, String key) =>
      throw UnimplementedError();
  Future<List<IntakeSummary>> intakes() => throw UnimplementedError();
  Future<ProjectDetail> project(String id) => throw UnimplementedError();
  Future<void> setIntakePaused(IntakeDraft draft, bool paused, String key) =>
      throw UnimplementedError();
  Future<String> createIntake(String key) => throw UnimplementedError();
  Future<IntakeDraft> intake(String id) => throw UnimplementedError();
  Future<void> saveIntake(
    IntakeDraft draft,
    List<Map<String, Object?>> operations,
    String key,
  ) => throw UnimplementedError();
  Future<PreparedBrief> prepare(IntakeDraft draft, String key) =>
      throw UnimplementedError();
  Future<RequirementView> requirements(String projectId, {String? versionId}) =>
      throw UnimplementedError();
  Future<void> confirm(String projectId, RequirementView brief, String key) =>
      throw UnimplementedError();
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
      if (const bool.fromEnvironment('KALLISTO_EMULATORS')) {
        if (!AppEnvironment.current.projectId.startsWith('demo-') ||
            !['localhost', '127.0.0.1'].contains(Uri.base.host)) {
          throw StateError('Emulators require a local demo project.');
        }
        await _auth!.useAuthEmulator('127.0.0.1', 9099);
      } else if (AppEnvironment.current.projectId.startsWith('demo-')) {
        throw StateError('Demo project requires emulators.');
      }
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

  Future<Object?> _get(
    String path, {
    String? cursor,
    String method = 'GET',
    Object? payload,
    String? commandKey,
    bool authenticated = true,
  }) async {
    final user = _auth?.currentUser;
    if (authenticated && user == null) {
      throw const ClientFailure(ClientConnection.signedOut, 'Please sign in.');
    }
    try {
      final token = authenticated ? await user!.getIdToken() : null;
      if (authenticated && token == null) {
        throw const ClientFailure(
          ClientConnection.signedOut,
          'Please sign in again.',
        );
      }
      final base = Uri.parse(AppEnvironment.current.backendUrl);
      final target = Uri.parse(path);
      final uri = base.replace(
        path: '${base.path.replaceFirst(RegExp(r'/$'), '')}${target.path}',
        queryParameters: cursor == null
            ? target.queryParameters
            : {'cursor': cursor},
      );
      final headers = <String, String>{
        if (token != null) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Idempotency-Key': ?commandKey,
      };
      final response =
          await (method == 'POST'
                  ? _http.post(uri, headers: headers, body: jsonEncode(payload))
                  : _http.get(uri, headers: headers))
              .timeout(const Duration(seconds: 20));
      if (authenticated && _auth?.currentUser?.uid != user?.uid) {
        throw const ClientFailure(
          ClientConnection.signedOut,
          'Session changed.',
        );
      }
      if (response.statusCode == 401) {
        if (path != '/v1/auth/me' && path != '/v1/projects' && !_closed) {
          _changes.add(null);
        }
        throw const ClientFailure(
          ClientConnection.signedOut,
          'Please sign in again.',
        );
      }
      if (response.statusCode == 403) {
        if (path != '/v1/auth/me' && path != '/v1/projects' && !_closed) {
          _changes.add(null);
        }
        throw const ClientFailure(
          ClientConnection.denied,
          'Client access is not available for this account.',
        );
      }
      if (response.statusCode == 409) {
        throw const ClientFailure(
          ClientConnection.ready,
          'This record changed. Reload it before trying again. Your unsaved fields are still shown.',
        );
      }
      if (response.statusCode == 404) {
        throw const ClientFailure(
          ClientConnection.ready,
          'This record is unavailable or you no longer have access to it.',
        );
      }
      if (response.statusCode == 429) {
        throw const ClientFailure(
          ClientConnection.ready,
          'Too many requests. Wait a moment before retrying.',
        );
      }
      if (response.statusCode == 422) {
        throw const ClientFailure(
          ClientConnection.ready,
          'Check the entered details. Counts, field values and budgets must be consistent.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
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
    if (actor is Map<String, dynamic> &&
        actor['application_state'] == 'enrollment_required') {
      return ClientSnapshot(
        uid: uid,
        name: '',
        projects: const [],
        nextCursor: null,
        enrollmentRequired: true,
      );
    }
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
  Future<void> signUp(String email, String password) async {
    if (_auth == null) await initialize();
    try {
      await _auth!.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException {
      throw const ClientFailure(
        ClientConnection.signedOut,
        'Could not create this account. Use a valid email and a stronger password, or sign in if you already registered.',
      );
    }
  }

  @override
  Future<EnrollmentNotice?> enrollmentNotice() async {
    final data = objectValue(
      await _get('/v1/capabilities', authenticated: false),
    );
    return data['enrollment_notice'] == null
        ? null
        : EnrollmentNotice.fromJson(data['enrollment_notice']);
  }

  @override
  Future<void> enroll(String name, EnrollmentNotice notice, String key) async {
    await _get(
      '/v1/provider-applications/client-enrollment',
      method: 'POST',
      commandKey: key,
      payload: {
        'display_name': name,
        'client_kind': 'person',
        'preferred_language': 'en',
        'preferred_timezone': 'Asia/Kolkata',
        'enrollment_policy_version': notice.version,
        'explicit_confirmation': true,
      },
    );
  }

  @override
  Future<List<IntakeSummary>> intakes() async {
    final data = objectValue(await _get('/v1/intakes'));
    if (data['items'] is! List) throw const FormatException();
    return (data['items'] as List).map(IntakeSummary.fromJson).toList();
  }

  @override
  Future<ProjectDetail> project(String id) async => ProjectDetail.fromJson(
    await _get('/v1/projects/${Uri.encodeComponent(id)}'),
  );
  @override
  Future<void> setIntakePaused(
    IntakeDraft draft,
    bool paused,
    String key,
  ) async {
    await _get(
      '/v1/intakes/${Uri.encodeComponent(draft.id)}/${paused ? 'pause' : 'resume'}',
      method: 'POST',
      commandKey: key,
      payload: {'expected_version': draft.rowVersion},
    );
  }

  @override
  Future<String> createIntake(String key) async => stringValue(
    objectValue(
      await _get(
        '/v1/intakes',
        method: 'POST',
        commandKey: key,
        payload: {'locale': 'en', 'preferred_mode': 'manual'},
      ),
    ),
    'intake_id',
  );
  @override
  Future<IntakeDraft> intake(String id) async => IntakeDraft.fromJson(
    await _get('/v1/intakes/${Uri.encodeComponent(id)}'),
  );
  @override
  Future<void> saveIntake(
    IntakeDraft draft,
    List<Map<String, Object?>> operations,
    String key,
  ) async {
    await _get(
      '/v1/intakes/${Uri.encodeComponent(draft.id)}/inputs',
      method: 'POST',
      commandKey: key,
      payload: {
        'expected_revision': draft.revision,
        'client_input_id': key,
        'kind': 'manual',
        'manual_operations': operations,
      },
    );
  }

  @override
  Future<PreparedBrief> prepare(IntakeDraft draft, String key) async =>
      PreparedBrief.fromJson(
        await _get(
          '/v1/intakes/${Uri.encodeComponent(draft.id)}/prepare-brief',
          method: 'POST',
          commandKey: key,
          payload: {
            'expected_draft_revision': draft.revision,
            'included_input_refs': draft.inputRefs,
            'excluded_input_ids': <String>[],
          },
        ),
      );
  @override
  Future<RequirementView> requirements(
    String projectId, {
    String? versionId,
  }) async => RequirementView.fromJson(
    await _get(
      '/v1/projects/${Uri.encodeComponent(projectId)}/requirements${versionId == null ? '' : '?version_id=${Uri.encodeComponent(versionId)}'}',
    ),
  );
  @override
  Future<void> confirm(
    String projectId,
    RequirementView brief,
    String key,
  ) async {
    await _get(
      '/v1/projects/${Uri.encodeComponent(projectId)}/requirements/confirm',
      method: 'POST',
      commandKey: key,
      payload: {
        'version_id': brief.versionId,
        'content_hash': brief.hash,
        'expected_requirement_version': brief.expectedVersion,
        'explicit_confirmation': true,
      },
    );
  }

  @override
  void dispose() {
    _closed = true;
    _subscription?.cancel();
    _changes.close();
    _http.close();
  }
}
