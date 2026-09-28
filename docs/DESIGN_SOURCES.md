# Kallisto Flutter design source map

This independent Flutter showcase was explicitly requested by the user. It demonstrates the existing web project's design language; it does not replace the Next.js production app or connect to its business workflows. All interactive records are labeled sample content and live only in widget state. No authentication, Firebase access, approvals, financial writes, uploads, or message sending are implemented here.

## Source hierarchy

The root `AGENTS.md`, `GIT_INSTRUCTIONS.md`, `PRODUCT.md`, and `docs/ARCHITECTURE_v2.md` were inspected. The named `docs/DESIGN_SYSTEM.md`, `docs/PRODUCT.md`, `docs/ARCHITECTURE.md`, `docs/DOMAIN_RULES.md`, `docs/DATA_MODEL.md`, `docs/SECURITY.md`, and `docs/TESTING.md` are absent in this checkout. Existing components and CSS supply the visual reference, with repository rules governing scope. No business rules were changed.

| Source in parent repository | Flutter mapping |
| --- | --- |
| `app/globals.css` root tokens | `lib/design_system/tokens.dart`: surfaces, type, radii, spacing, motion, shell dimensions |
| `app/globals.css` dark theme | Dark theme with slate surfaces and sky accent |
| `components/ui/badge.module.css` | `KBadge`: compact labels, semantic tone, icon, rounded border |
| `components/ui/dialog.tsx` | Native Flutter dialogs with focus containment, Escape/backdrop dismissal |
| `components/layout/app-shell.tsx` and `lib/layout/shell-responsive-contract.ts` | Sidebar, rail, topbar, drawer; miniature source-shell illustration |
| `features/basics/components/provider-card.tsx` and associated CSS | Specialist card, save toggle, metadata, hover and press feedback |
| `features/portfolio/components/portfolio-project-tile.tsx` and associated CSS | Project image card, metadata, image-error fallback, preview |
| Project document, task, and workspace patterns | Document cards, task cards, nested panels, table, board, list/detail compositions |

## Deliberate Flutter adaptations

- Hanken Grotesk is bundled rather than fetched at runtime. Its OFL license is included.
- OKLCH tokens are converted to sRGB: ink `#17130E`, muted `#57524B`, soft `#8A8580`, line `#E6E4E1`, accent `#1175DE`, accent-soft `#E2F0FF`.
- Semantic badge colors use readable light/dark combinations instead of copying the web's dark badge fills into every light surface.
- Material outline icons map the web app's Lucide icons; this is not an exact icon reproduction.
- The source shell defines 1080/1380/1720 breakpoints. The catalogue uses 760/1100 navigation breakpoints so specimens remain browsable on phones, with source dimensions demonstrated on the Layouts page.
- Accessible controls use 44–48 px targets. Cards have intrinsic heights and grids derive column counts from available width.
- Default motion uses the source's 150/200/220/350 ms durations. A playground allows slower inspection. Spring overshoot is spatial; opacity stays bounded.
- System reduced-motion settings and the showcase preference are honored for custom animations.
- Extra card compositions demonstrate how existing primitives combine; they are not claims that every project-specific production workflow has been ported.

## Asset provenance

| Bundled file | Existing project source |
| --- | --- |
| `assets/images/residence.jpg` | `public/assets/nila-thumb1.jpg` |
| `assets/images/floor-plans.jpg` | `public/assets/studio/floor-plans.jpg` |
| `assets/images/visualisations.jpg` | `public/assets/studio/visualisations.jpg` |
| `assets/images/avatar.jpg` | `public/assets/priya-avatar.jpg` |
| `assets/fonts/HankenGrotesk.ttf` | Google Fonts `ofl/hankengrotesk/HankenGrotesk[wght].ttf` |

The image assets are reused under the parent project's existing asset permissions. Font source: https://github.com/google/fonts/tree/main/ofl/hankengrotesk.

## Catalogue inventory

1. Foundations: color swatches, type scale, spacing, corner radii, icon mapping, live theme switch.
2. Buttons: primary, neutral, outline, text, destructive confirmation, loading/success/disabled/toggle, sizes, icon actions, menu, segmented view.
3. Cards: image cover, image overlay, document, horizontal media, specialist, metric, task, selectable, activity, minimal, and nested cards; gallery filters and image previews.
4. Layouts: source shell miniature with inspector toggle, resizable preview, responsive grid, split workspace, board, list/detail, nested image cards.
5. Forms: text, email, dropdown, date picker, multiline, validation, reset, checkbox, switch, slider, filter chips, disabled/error inputs.
6. Data/navigation: semantic statuses, searchable/sortable/selectable table, tabs, breadcrumbs, stepper, activity timeline.
7. Feedback: loading/skeleton, empty, error/retry, success, denied, offline, inline messages, confirmation dialog, side drawer, bottom sheet, toast, tooltip, accordion.
8. Motion: timing tokens, easing/duration controls, fade, slide, scale, rotation, container morph, content switch, hover/focus/press, animated expansion, route transition, reduced motion.
