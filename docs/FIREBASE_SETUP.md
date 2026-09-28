# Flutter Firebase configuration

Current implementation: the client now initializes Firebase Authentication and
calls the protected backend for identity and owned projects. The original
configuration-only checks below are historical. See [CLIENT_DELIVERY.md](CLIENT_DELIVERY.md)
for current validation, remaining client flows and release limitations. Cartesia
and Ollama keys are in the ignored backend configuration and private reference;
neither is passed to Flutter. No database or security-rule migration is claimed.

Prepared from the supplied credential export on 29 September 2026. The existing
Firebase web registration can be used by Flutter web. Its React/Next.js environment
variable prefixes are not required by Firebase or Flutter.

## Prepared files

| File | Purpose |
| --- | --- |
| `backend/.private/kallisto-credentials-2026-09-28T19-55-16-992Z.md` | Ignored credential reference copied from the export, later updated with the user-supplied GitHub token; never read by Flutter |
| `.env` | Public client settings, with `NEXT_PUBLIC_` removed |
| `firebase-config.json` | Equivalent public configuration in JSON form for `--dart-define-from-file` |
| `.env.example` | Commit-safe empty configuration template |
| `backend/.private/firebase-service-account.json` | Extracted Admin SDK credentials, for trusted server processes only |
| `backend/.env` | Separate server environment with the corrected absolute credential path and an added `http://localhost:5000` CORS origin |
| `.firebaserc` | Existing Firebase project selection |
| `firebase.json` | Local Authentication emulator configuration; no hosting, rules, or Functions deployment configured |
| `lib/config/app_environment.dart` | Typed compile-time client configuration and validation |
| `lib/firebase_options.dart` | Firebase web options adapter using the supplied client settings |

Supporting changes: `.gitignore`, `pubspec.yaml`, `pubspec.lock`,
`run-showcase.ps1`, `validate.ps1`, `README.md`, and
`test/app_environment_test.dart`. Flutter tooling also refreshed generated
plugin registration metadata; it was not edited by hand.

Only `.env.example`, Dart code, and Firebase CLI configuration are intended for
Git. `.gitignore` excludes the export, filled environments, service account,
native credential files, and private directory. None are Flutter assets.
The source export and parent React/backend files were not modified.

The active client environment contains only `BACKEND_URL`, `FIREBASE_API_KEY`,
`FIREBASE_AUTH_DOMAIN`, `FIREBASE_PROJECT_ID`, `FIREBASE_APP_ID`, and
`FIREBASE_MESSAGING_SENDER_ID`. The sender ID is the project number encoded in
the supplied web app ID. No storage bucket was included in the export, so one
has not been invented. Add `FIREBASE_STORAGE_BUCKET` after verifying the actual
bucket if Storage is needed.

Turso credentials remain in the server environment. Vercel tokens, Vercel React
project links, database administration notes, and other operational material
remain only in the ignored original copy; they are not Flutter settings.
All new backend APIs and server-side implementation for this Flutter app belong
in `backend/`, as instructed by the user. See `../backend/AGENTS.md` and
`../backend/README.md`. The existing sibling backend is preserved; no server
implementation has been migrated yet. `OLLAMA_API_KEY` is stored only in
`backend/.env`; no Ollama request integration is implemented.
By explicit user instruction, `GITHUB_TOKEN` is also saved in `backend/.env`
and the private credential Markdown for GitHub operations. `VERCEL_TOKEN`
remains in that private Markdown for Vercel operations. These operator tokens
must not be used as Flutter client settings or returned by backend APIs.

## Run and validate

The launcher loads `.env` and explicitly uses `http://localhost:5000` for web:

```powershell
.\run-showcase.ps1
.\validate.ps1
```

Equivalent direct Flutter commands:

```powershell
flutter run -d chrome --web-hostname=localhost --web-port=5000 --dart-define-from-file=.env
flutter build web --release --no-web-resources-cdn --dart-define-from-file=.env
```

Use either `.env` or `firebase-config.json` as the defines file, not both. Keep
them in sync when values change; `.env` is the launcher default. These settings
are client-visible after compilation. Never pass `backend/.env` to
Flutter or add secrets to client defines.

The export points to the local backend at port 4000. The backend must be running
separately and must load its reviewed server configuration to allow the new
CORS origin; preparing `backend/.env` does not reconfigure a running
server. Production needs an actual HTTPS API URL, an approved exact frontend
origin, and the existing deployment process. No deployment was performed.

On this Windows machine, adding `firebase_core` resolved and downloaded packages
but plugin symlink creation failed because Developer Mode is disabled. Enable
Windows Developer Mode before running `flutter pub get` or native builds. With
the already resolved dependencies, web-only checks and launch can use:

```powershell
.\validate.ps1 -SkipPubGet
.\run-showcase.ps1 -SkipPubGet
```

`-SkipPubGet` is not a substitute for dependency resolution on a fresh checkout.
For web-only development while Developer Mode is unavailable, `dart pub get`
successfully resolves the declared dependencies without the native plugin
symlink step. `flutter_web_plugins` is explicitly declared because Flutter's
generated web registrant imports that SDK package.

## Integration boundary

This change prepares configuration and installs `firebase_core`. It deliberately
does not initialize Firebase inside the UI catalogue or implement authentication,
Firestore access, uploads, or project workflows. When implementing the actual
connected application, initialize Firebase before starting those services:

```dart
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

Import `package:firebase_core/firebase_core.dart` and `firebase_options.dart` at
that entry point, and implement startup loading/error/retry handling as part of
the connected application's bootstrap. No Admin credentials belong in Dart.

Android, iOS, and Windows Firebase apps have not been registered. The supplied
web app ID must not be relabelled as a native ID. Register the intended package
and bundle IDs using FlutterFire before enabling native Firebase. The adapter
currently throws on native platforms. No `google-services.json` or
`GoogleService-Info.plist` has been fabricated.

The seven source-of-truth documents named in AGENTS.md are absent under their
specified names. Existing `docs/ARCHITECTURE_v2.md` in the parent repository and
the backend configuration contract were inspected. No domain behavior, access
rules, data migration, or architecture replacement is part of this preparation.

Reference: [official Firebase Flutter setup](https://firebase.google.com/docs/flutter/setup).

## Validation on 29 September 2026

**Later client implementation:** the running preview now uses real Firebase
`kallisto-db1`, the trusted local API and localhost:8080. Do not use emulators for
the current user workflow. Client Auth uses the stable named app
`kallisto-kallisto-db1-live`, LOCAL browser persistence and waits for the initial
auth-state event before deciding signed-out status. An old emulator session
cannot transfer to this live app. Sign in once with the real account, on the same
hostname/port, to verify reload. Native registrations remain outstanding. See
`CLIENT_DELIVERY.md` for later checks; the preparation-era results below are
historical.

- `flutter pub add firebase_core`: packages resolved, but command failed during
  Windows plugin symlink creation; Developer Mode remains a native setup blocker.
- First web build failed because `flutter_web_plugins` was absent. Added that
  explicit SDK dependency, then `dart pub get` passed.
- `validate.ps1 -SkipPubGet`: passed after that correction. Runs
  `dart format --output=none --set-exit-if-changed lib test` (16 files unchanged),
  `flutter analyze --no-pub` (no issues), `flutter test --no-pub` (22 passed), and
  `flutter build web --release --no-web-resources-cdn --no-pub --dart-define-from-file=.env`
  (release build and Wasm dry run passed).
- Configuration checks passed for JSON parsing, `.env`/JSON equivalence,
  matching Firebase project identifiers, the server credential path, local
  CORS origin, and Git ignore coverage of each sensitive output.
- Client source/assets and release output were checked for the extracted
  private key, private key ID, and database token; none were found.
- Existing responsive and interaction tests passed. Desktop and 390 px mobile
  release rendering were checked in the browser with no warning/error console entries.
- No live Firebase sign-in, backend request, native build, credential validity
  check against cloud services, deployment, commit, or push was performed.
