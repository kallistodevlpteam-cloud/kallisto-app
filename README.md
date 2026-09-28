# Kallisto · Flutter client and backend

Repository: [kallistodevlpteam-cloud/kallisto-app](https://github.com/kallistodevlpteam-cloud/kallisto-app).
Use the `development` branch; see [GIT_INSTRUCTIONS.md](GIT_INSTRUCTIONS.md).

The complete product brief is [MASTER_SPEC.md](docs/MASTER_SPEC.md). Its workspace
amendment preserves this design system and requires client UI/backend delivery
first, then service-provider workflows. Odin uses Gemma for chat/routine tools,
Nemotron Ultra for heavy workflows, and Cartesia for speech input/output.

The default entry is the adaptive client workspace. Firebase sign-in and the
owner-project read API are implemented. Intake, messaging and live Odin/voice
are still being connected; unavailable screens do not simulate success. See
[delivery status](docs/CLIENT_DELIVERY.md) for implemented scope and validation.
The original eight-collection design-system demo remains available separately.

## Run

From this folder in a new terminal:

```powershell
flutter pub get
flutter run -d chrome --dart-define-from-file=.env --web-port=5000
```

Or use the launcher, which finds the installed SDK even before your terminal picks up the new PATH:

```powershell
powershell -ExecutionPolicy Bypass -File .\run-client.ps1
```

SDK installed on this machine: `C:\Users\User\develop\flutter` (Flutter 3.47.5 / Dart 3.13.4). The official stable archive was SHA-256 verified. Its `bin` directory was added to the user PATH; restart existing terminals to pick it up. A normal user directory avoids packaged-app LocalAppData path virtualization.

Run the original demo with `run-showcase.ps1` or
`flutter run -t lib/main_showcase.dart -d chrome`. If Windows plugin symlink
support is unavailable, use `dart pub get` and then the launcher with
`-SkipPubGet` for web. Start the API separately with `npm run dev` in `backend/`.

## Collections

| Collection | Examples |
| --- | --- |
| Foundations | Colors, Hanken Grotesk type scale, spacing, radii, icons |
| Buttons & actions | Primary, neutral, outline, text, destructive, disabled, loading, success, toggle, menus, segmented view |
| Cards & media | Project cover, overlay, document, horizontal, specialist, metric, task, selectable, activity, minimal, nested |
| Layouts | Shell, grid, split pane, board, list/detail, resizable preview, cards inside layouts |
| Forms & controls | Text, email, dropdown, date picker, textarea, validation, reset, switch, checkbox, slider, chips |
| Data & navigation | Status badges, searchable/sortable/selectable table, tabs, breadcrumbs, stepper, timeline |
| Feedback & overlays | Loading/skeleton, empty, error/retry, success, denied, offline, dialog, drawer, bottom sheet, toast, tooltip, accordion |
| Motion | Fade, slide, scale, rotation, morph, content switch, hover/press/focus, expansion, route transition; easing and duration controls |

Use the moon/sun control to change theme. The preferences menu includes **Reduce motion**; system preferences are also respected by custom transitions. Example state resets when its collection is recreated or the app restarts.

## Structure

```text
lib/main.dart                    Client app entry; preserved showcase class
lib/main_showcase.dart           Separate design-system demo entry
lib/client/                     Adaptive UI, session and backend gateway
lib/design_system/tokens.dart    Shared tokens and Flutter themes
lib/design_system/components.dart Panel, badge, grid, image, interactive card
lib/showcase/showcase_shell.dart Responsive navigation
lib/showcase/sections/           Eight independent collections
assets/fonts/                   Hanken Grotesk and OFL license
assets/images/                  Existing project images
test/showcase_test.dart          Interaction and responsive tests
docs/DESIGN_SOURCES.md           Source mapping and adaptations
docs/VALIDATION.md               Verification and limitations
```

## Validate and build

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn
```

`validate.ps1` runs these checks in sequence and stops on failure. Serve `build/web` over HTTP; do not open its `index.html` as a local file. The no-CDN build bundles rendering resources as well as the images and font.

Web, Android, iOS, and Windows scaffolds are included. Web is the verified target. Android needs a configured JDK; Windows needs Visual Studio C++ tools; iOS needs macOS/Xcode. These additional toolchains were not installed and native binaries are not claimed as verified.

## Scope

All backend APIs and server-side code for this Flutter app must be built in
[`backend/`](backend/README.md). Server credentials live in its ignored `.env`
and `.private/` directory. Root environment files contain public client settings
only. See [AGENTS.md](AGENTS.md) for this workspace's implementation boundary.

Flutter was explicitly requested for this separate application. It makes no
framework changes to the older Next.js checkout. Local credentials remain
ignored; see [FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md). The catalogue remains a
demo; the new client uses a separate authenticated backend adapter. This is an
initial implementation checkpoint, not the completed master specification or a
production release. No domain writes, financial operations or approval actions
have been enabled.

The checkout has no `docs/DESIGN_SYSTEM.md`. Tokens and examples come from existing CSS/components; adaptations and the full inventory are in [DESIGN_SOURCES.md](docs/DESIGN_SOURCES.md). Images follow the parent repository's existing usage permissions. The bundled font includes its license.

Flutter installation reference: https://docs.flutter.dev/install/manual.
