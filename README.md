# Kallisto · Flutter design system

Repository: [kallistodevlpteam-cloud/kallisto-app](https://github.com/kallistodevlpteam-cloud/kallisto-app).
Use the `development` branch; see [GIT_INSTRUCTIONS.md](GIT_INSTRUCTIONS.md).

An interactive Flutter showcase derived from the existing Kallisto web project. Eight collections, light/dark themes, responsive navigation, bundled images and typography, and a motion playground.

## Run

From this folder in a new terminal:

```powershell
flutter pub get
flutter run -d chrome
```

Or use the launcher, which finds the installed SDK even before your terminal picks up the new PATH:

```powershell
powershell -ExecutionPolicy Bypass -File .\run-showcase.ps1
```

SDK installed on this machine: `C:\Users\User\develop\flutter` (Flutter 3.47.5 / Dart 3.13.4). The official stable archive was SHA-256 verified. Its `bin` directory was added to the user PATH; restart existing terminals to pick it up. A normal user directory avoids packaged-app LocalAppData path virtualization.

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
lib/main.dart                    App and theme/motion preferences
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

Flutter was explicitly requested for this separate catalogue and its Firebase configuration. It makes no framework changes to the Next.js production app. Local ignored credentials and Flutter client configuration are now prepared; see [FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md). The catalogue still has no backend calls, business-record persistence, financial operations, or actual approval actions. This is not a full Flutter port of the production app.

The checkout has no `docs/DESIGN_SYSTEM.md`. Tokens and examples come from existing CSS/components; adaptations and the full inventory are in [DESIGN_SOURCES.md](docs/DESIGN_SOURCES.md). Images follow the parent repository's existing usage permissions. The bundled font includes its license.

Flutter installation reference: https://docs.flutter.dev/install/manual.
