# Validation · 28 September 2026

## Automated checks

| Command | Result |
| --- | --- |
| `flutter --version` | Flutter 3.47.5 stable; Dart 3.13.4 |
| `flutter pub get` | Passed; dependency lockfile generated |
| `dart format --output=none --set-exit-if-changed lib test` | Passed; 13 Dart files, zero formatting changes |
| `flutter analyze` | Passed; no issues found |
| `flutter test --reporter expanded` | Passed; 18 tests |
| `flutter build web --release --no-web-resources-cdn` | Passed; `build/web` generated; Wasm compatibility dry run also passed |
| `flutter doctor -v` | Web target available. Android JDK and Windows Visual Studio C++ tooling are missing. |

Initial checks found a non-const constructor, layout overflow, hidden ListTile ink feedback, and a zero-duration AnimatedSize issue. These were repaired and the checks rerun. The final checks above passed; errors were not suppressed. The first release build's missing Cupertino font warning was resolved by bundling `cupertino_icons` for Flutter's adaptive platform widgets.

## Automated coverage

- Desktop navigation across all eight collections and theme switching.
- Mobile navigation drawer opens, navigates, and closes.
- Tablet rail omits expansion when the viewport cannot accommodate a sidebar.
- All component sections at 320, 768, and 1440 px widths.
- Representative sections at 150% text size on a 390 px phone viewport.
- Save button disables during a simulated operation and resolves to success.
- Required field/email validation, valid submission, notes reset, validation reset.
- Card category filtering, project image preview, Escape dismissal.
- Error retry to success; no-results table search.
- Reduced-motion zero-duration custom transition behavior.
- Every layout pattern inside a 320 px preview.
- Dialog, side drawer, and bottom sheet dismissal via Escape.
- Spring motion sampled during forward and reverse animation.
- Route transition and return navigation.

## Browser verification

The release build was served on loopback and inspected in the Codex browser. Desktop (1440 × 1000), tablet (768 × 1024), and phone (390 × 844) rendering, image assets, navigation, project preview, Escape dismissal, theme switching, and the live motion playground were checked. Browser console error/warning inspection returned no entries during these checks. Screenshots are saved in this directory.

The specimens reset after reload by design. There is no business-data persistence to verify. Authentication, server permissions, uploads, financial settlement, and real project transitions are out of scope for this separate component library; their appearances here are explicitly labeled samples.

## Limitations

- Native Android, iOS, and Windows binaries have not been built. Android requires JDK configuration, Windows requires Visual Studio C++ tooling, and iOS requires macOS/Xcode.
- Accessibility was checked through Flutter semantics, keyboard interaction, responsive tests, and larger text; this is not a comprehensive screen-reader audit.
- This ports the shared design vocabulary and representative compositions, not every production route or project-specific widget.
- No root Next.js/backend tests were run because no existing application source was changed. Flutter analysis provides the scoped lint/type checks and Flutter web compilation supplies the release-build check.
- No deployment, commit, or push was performed. All additions are contained in `kallisto flutter/`; existing working-tree changes were preserved.
