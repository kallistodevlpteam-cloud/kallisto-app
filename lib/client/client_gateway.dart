import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_environment.dart';
import '../firebase_options.dart';
import 'client_models.dart';
import 'workflow_models.dart';
import 'settings_models.dart';
import 'provider_models.dart';
import 'sharing_models.dart';
import 'message_models.dart';

String clientIntentId() => List.generate(
  16,
  (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
).join();

abstract class ClientGateway {
  Future<ClientSettings> profile() => throw UnimplementedError();
  Future<ClientSettings> saveProfile(
    ClientSettings previous,
    String name,
    String key,
  ) => throw UnimplementedError();
  Future<Map<String, dynamic>> odinCapabilities() => throw UnimplementedError();
  Future<List<dynamic>> odinRuns() => throw UnimplementedError();
  Future<Map<String, dynamic>> odinRun(String id) => throw UnimplementedError();
  Future<void> withdrawOdinConsent(String version, String key) =>
      throw UnimplementedError();
  Future<String> odinConsent(String version, String key) =>
      throw UnimplementedError();
  Future<Map<String, dynamic>> odinSend(
    String text,
    String key,
    String consent, {
    String? conversation,
    String? project,
    bool planning = false,
  }) => throw UnimplementedError();
  Future<void> odinAction(String id, String action, int version, String key) =>
      throw UnimplementedError();
  Future<ClientPage<ClientThread>> conversations({String? cursor}) =>
      throw UnimplementedError();
  Future<ClientThread> conversation(String id) => throw UnimplementedError();
  Future<ClientPage<ThreadMessage>> messages(String id, {String? cursor}) =>
      throw UnimplementedError();
  Future<void> sendMessage(String id, String text, String key) =>
      throw UnimplementedError();
  Future<ClientPage<SupportCase>> supportCases({String? cursor}) =>
      throw UnimplementedError();
  Future<SupportCase> supportCase(String id) => throw UnimplementedError();
  Future<String> createSupportCase(
    String category,
    String subject,
    String description,
    String key,
  ) => throw UnimplementedError();
  Future<EnquiryPage> enquiries({String? cursor}) => throw UnimplementedError();
  Future<ClientEnquiry> enquiry(String id) => throw UnimplementedError();
  Future<BriefDisclosure> previewShare(
    String projectId,
    String recipient,
    RequirementView brief,
  ) => throw UnimplementedError();
  Future<String> shareBrief(BriefDisclosure preview, String key) =>
      throw UnimplementedError();
  Future<ProviderPage> providers({
    String? category,
    String? coverage,
    String? cursor,
  }) => throw UnimplementedError();
  Future<LeadProvider> provider(String id) => throw UnimplementedError();
  Future<ClientSettings> settings(String section) => throw UnimplementedError();
  Future<ClientSettings> saveSettings(
    ClientSettings previous,
    Map<String, dynamic> values,
    String key,
  ) => throw UnimplementedError();
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
  ClientSettings _profileSettings(Object? value) {
    final data = objectValue(value);
    return ClientSettings(
      'profile',
      integerValue(data, 'row_version'),
      objectValue(data['profile']),
    );
  }

  @override
  Future<ClientSettings> profile() async =>
      _profileSettings(await _get('/v1/me/profile'));
  @override
  Future<ClientSettings> saveProfile(
    ClientSettings previous,
    String name,
    String key,
  ) async => _profileSettings(
    await _get(
      '/v1/me/profile',
      method: 'POST',
      commandKey: key,
      payload: {'expected_version': previous.version, 'display_name': name},
    ),
  );
  @override
  Future<void> withdrawOdinConsent(String version, String key) async {
    await _get(
      '/v1/me/consents',
      method: 'POST',
      commandKey: key,
      payload: {
        'purpose': 'external_ai_processing',
        'resource_scope': {'kind': 'account'},
        'policy_version': version,
        'decision': 'withdrawn',
        'explicit_confirmation': true,
      },
    );
  }

  @override
  Future<Map<String, dynamic>> odinCapabilities() async =>
      objectValue(await _get('/v1/odin/capabilities'));
  @override
  Future<List<dynamic>> odinRuns() async =>
      objectValue(await _get('/v1/odin/runs'))['items'] as List;
  @override
  Future<Map<String, dynamic>> odinRun(String id) async =>
      objectValue(await _get('/v1/odin/runs/${Uri.encodeComponent(id)}'));
  @override
  Future<String> odinConsent(String version, String key) async =>
      objectValue(
            await _get(
              '/v1/me/consents',
              method: 'POST',
              commandKey: key,
              payload: {
                'purpose': 'external_ai_processing',
                'resource_scope': {'kind': 'account'},
                'policy_version': version,
                'decision': 'granted',
                'explicit_confirmation': true,
              },
            ),
          )['consent_id']
          as String;
  @override
  Future<Map<String, dynamic>> odinSend(
    String text,
    String key,
    String consent, {
    String? conversation,
    String? project,
    bool planning = false,
  }) async => objectValue(
    await _get(
      '/v1/odin/runs',
      method: 'POST',
      commandKey: key,
      payload: {
        'mode': 'assist',
        'requested_output_kind': planning ? 'project_plan' : 'answer',
        'consent_record_id': consent,
        'conversation_id': ?conversation,
        'project_id': ?project,
        'message': {
          'client_message_id': key,
          'text': text,
          'attachment_refs': <Object>[],
        },
      },
    ),
  );
  @override
  Future<void> odinAction(
    String id,
    String action,
    int version,
    String key,
  ) async {
    await _get(
      '/v1/odin/runs/${Uri.encodeComponent(id)}/$action',
      method: 'POST',
      commandKey: key,
      payload: {'expected_version': version},
    );
  }

  @override
  Future<ClientPage<ClientThread>> conversations({String? cursor}) async =>
      ClientPage.parse(
        await _get('/v1/conversations', cursor: cursor),
        ClientThread.fromJson,
      );
  @override
  Future<ClientThread> conversation(String id) async => ClientThread.fromJson(
    await _get('/v1/conversations/${Uri.encodeComponent(id)}'),
  );
  @override
  Future<ClientPage<ThreadMessage>> messages(
    String id, {
    String? cursor,
  }) async => ClientPage.parse(
    await _get(
      '/v1/conversations/${Uri.encodeComponent(id)}/messages',
      cursor: cursor,
    ),
    ThreadMessage.fromJson,
  );
  @override
  Future<void> sendMessage(String id, String text, String key) async {
    await _get(
      '/v1/conversations/${Uri.encodeComponent(id)}/messages',
      method: 'POST',
      commandKey: key,
      payload: {
        'text': text,
        'attachment_refs': <Object>[],
        'client_message_id': key,
      },
    );
  }

  @override
  Future<ClientPage<SupportCase>> supportCases({String? cursor}) async =>
      ClientPage.parse(
        await _get('/v1/support/cases', cursor: cursor),
        SupportCase.fromJson,
      );
  @override
  Future<SupportCase> supportCase(String id) async => SupportCase.fromJson(
    await _get('/v1/support/cases/${Uri.encodeComponent(id)}'),
  );
  @override
  Future<String> createSupportCase(
    String category,
    String subject,
    String description,
    String key,
  ) async => stringValue(
    objectValue(
      await _get(
        '/v1/support/cases',
        method: 'POST',
        commandKey: key,
        payload: {
          'category': category,
          'subject': subject,
          'description': description,
          'evidence_refs': <Object>[],
        },
      ),
    ),
    'case_id',
  );
  @override
  Future<EnquiryPage> enquiries({String? cursor}) async =>
      EnquiryPage.fromJson(await _get('/v1/enquiries', cursor: cursor));
  @override
  Future<ClientEnquiry> enquiry(String id) async => ClientEnquiry.fromJson(
    await _get('/v1/enquiries/${Uri.encodeComponent(id)}'),
  );
  @override
  Future<BriefDisclosure> previewShare(
    String projectId,
    String recipient,
    RequirementView brief,
  ) async => BriefDisclosure.fromJson(
    projectId,
    await _get(
      '/v1/projects/${Uri.encodeComponent(projectId)}/share-preview',
      method: 'POST',
      payload: {
        'provider_uid': recipient,
        'requirement_version_id': brief.versionId,
        'requirement_content_hash': brief.hash,
      },
    ),
  );
  @override
  Future<String> shareBrief(BriefDisclosure preview, String key) async =>
      stringValue(
        objectValue(
          await _get(
            '/v1/projects/${Uri.encodeComponent(preview.projectId)}/share',
            method: 'POST',
            commandKey: key,
            payload: {
              'provider_uid': preview.recipient,
              'requirement_version_id': preview.versionId,
              'requirement_content_hash': preview.briefHash,
              'disclosure_selection': preview.selection,
              'disclosure_manifest_hash': preview.manifestHash,
              'disclosure_policy_ref': preview.policy,
              'expected_project_version': preview.projectVersion,
              'explicit_confirmation': true,
            },
          ),
        ),
        'enquiry_id',
      );
  @override
  Future<ProviderPage> providers({
    String? category,
    String? coverage,
    String? cursor,
  }) async => ProviderPage.fromJson(
    await _get(
      Uri(
        path: '/v1/providers',
        queryParameters: {
          'category': ?category,
          'coverage': ?coverage,
          'cursor': ?cursor,
        },
      ).toString(),
    ),
  );
  @override
  Future<LeadProvider> provider(String id) async => LeadProvider.fromJson(
    await _get('/v1/providers/${Uri.encodeComponent(id)}'),
  );
  @override
  Future<ClientSettings> settings(String section) async =>
      ClientSettings.fromJson(
        await _get('/v1/workspace-settings/${Uri.encodeComponent(section)}'),
      );
  @override
  Future<ClientSettings> saveSettings(
    ClientSettings previous,
    Map<String, dynamic> values,
    String key,
  ) async => ClientSettings.fromJson(
    await _get(
      '/v1/workspace-settings/${Uri.encodeComponent(previous.section)}',
      method: 'POST',
      commandKey: key,
      payload: {'expected_version': previous.version, 'values': values},
    ),
  );
  FirebaseClientGateway() : _http = http.Client();
  final http.Client _http;
  final _changes = StreamController<void>.broadcast();
  FirebaseAuth? _auth;
  StreamSubscription<User?>? _subscription;
  bool _closed = false;
  Future<void>? _initialization;
  Future<String?>? _tokenRefresh;
  String? _refreshUid;

  Future<String?> _refreshToken(User user) async {
    if (_tokenRefresh != null && _refreshUid == user.uid) return _tokenRefresh!;
    _refreshUid = user.uid;
    final future = user.getIdToken(true);
    _tokenRefresh = future;
    try {
      return await future;
    } finally {
      if (identical(_tokenRefresh, future)) {
        _tokenRefresh = null;
        _refreshUid = null;
      }
    }
  }

  @override
  Stream<void> get sessionChanges => _changes.stream;

  @override
  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      const emulator = bool.fromEnvironment('KALLISTO_EMULATORS');
      // Separate Auth persistence namespaces prevent an old emulator session
      // from being restored into the real Firebase app on the same localhost.
      final appName =
          'kallisto-${options.projectId}-${emulator ? 'test' : 'live'}';
      final matches = Firebase.apps.where((app) => app.name == appName);
      final app = matches.isEmpty
          ? await Firebase.initializeApp(name: appName, options: options)
          : matches.single;
      if (_closed) return;
      _auth = FirebaseAuth.instanceFor(app: app);
      if (emulator) {
        if (!AppEnvironment.current.projectId.startsWith('demo-') ||
            !['localhost', '127.0.0.1'].contains(Uri.base.host)) {
          throw StateError('Emulators require a local demo project.');
        }
        await _auth!.useAuthEmulator('127.0.0.1', 9099);
      } else if (AppEnvironment.current.projectId.startsWith('demo-')) {
        throw StateError('Demo project requires emulators.');
      }
      if (kIsWeb) await _auth!.setPersistence(Persistence.LOCAL);
      if (_closed) return;
      final restored = Completer<void>();
      _subscription = _auth!.authStateChanges().listen(
        (_) {
          if (!restored.isCompleted) {
            restored.complete();
          } else if (!_closed) {
            _changes.add(null);
          }
        },
        onError: (Object error, StackTrace stack) {
          if (!restored.isCompleted) restored.completeError(error, stack);
        },
      );
      await restored.future;
    } catch (_) {
      await _subscription?.cancel();
      _subscription = null;
      _initialization = null;
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
    if (authenticated) await initialize();
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
      Future<http.Response> send() =>
          (method == 'POST'
                  ? _http.post(uri, headers: headers, body: jsonEncode(payload))
                  : _http.get(uri, headers: headers))
              .timeout(const Duration(seconds: 20));
      var response = await send();
      if (authenticated &&
          response.statusCode == 401 &&
          _auth?.currentUser?.uid == user!.uid) {
        final freshToken = await _refreshToken(user);
        if (freshToken != null && _auth?.currentUser?.uid == user.uid) {
          headers['Authorization'] = 'Bearer $freshToken';
          response = await send();
        }
      }
      if (authenticated && _auth?.currentUser?.uid != user?.uid) {
        throw const ClientFailure(
          ClientConnection.signedOut,
          'Session changed.',
        );
      }
      if (response.statusCode >= 400 && path.startsWith('/v1/odin')) {
        String? code;
        try {
          code =
              (jsonDecode(response.body)
                      as Map<String, dynamic>)['error']?['code']
                  as String?;
        } catch (_) {}
        final message = <String, String>{
          'ODIN_QUOTA_EXHAUSTED':
              'The daily Odin development allowance is used. Saved answers remain available; try again after the UTC day resets.',
          'ODIN_ACTIVE_LIMIT':
              'Two Odin runs are already active. Wait for one or stop it before starting another.',
          'ODIN_CONVERSATION_BUSY':
              'This conversation already has a run in progress. Open it from saved runs.',
          'ODIN_SOURCE_CHANGED':
              'The project changed since this run. Its previous response is withheld; start a new conversation with the current project.',
          'AI_CONSENT_REQUIRED':
              'Review and grant the current AI processing notice before starting a new run.',
          'ODIN_RETRY_UNAVAILABLE':
              'This run cannot be retried further. Its original input is saved; start a new run if needed.',
        }[code];
        if (message != null) {
          throw ClientFailure(ClientConnection.ready, message);
        }
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
    await initialize();
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
    await initialize();
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
    await initialize();
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
  Future<void> signOut() async {
    await initialize();
    await _auth?.signOut();
  }

  @override
  Future<void> signUp(String email, String password) async {
    await initialize();
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
