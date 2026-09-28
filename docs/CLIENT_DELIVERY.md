# Client delivery status — 29 September 2026

This records executed implementation and checks. **The full client phase in MASTER_SPEC is still unfinished.** SP work has not started.

## Latest live-Firebase checkpoint

The complete master, including O/P/Q, has now been read. See
[CLIENT_BUILD_STATUS.md](CLIENT_BUILD_STATUS.md) for each client screen and its
remaining implementation. This section supersedes the older emulator workflow
below for current use; do not run emulators for the user's preview.

- Auth initialization now waits for the first restored Firebase session, uses
  explicit web LOCAL persistence, and isolates live/test app namespaces. Auth
  actions await the same initialization. One controlled token refresh retries an
  expired-token API request with the original idempotency key.
- `run-client.ps1` explicitly selects live Firebase at stable localhost:8080.
  The real API runs at localhost:4000; Auth/Firestore emulators are stopped.
- Added seven client preference editors backed by closed Firestore schemas,
  version checks and replay protection. Language changes synchronize the canonical
  language/region preference and user projection. Appearance/billing schemas are
  implemented server-side but their full UI is not yet wired.
- Added provider directory/profile reads with current eligibility and expiry
  checks, safe field projection, category/coverage filters and bounded pagination.
  Portfolio, comparison and appointment remain unfinished. Minimal exact brief
  disclosure preview/share and source-authorized enquiry list/detail are now
  connected. Sharing creates one frozen enquiry/thread even across duplicate
  intent keys, and queues an inbox notification intent without claiming delivery.
- Current checks: Flutter analyzer passed; 38 Flutter tests passed; backend
  typecheck/lint/build passed; 41 backend tests passed, 8 emulator tests skipped.
  Live-config Flutter release build passed.
- Following the user's explicit autonomous-testing authorization, a dedicated
  `kallisto-qa-…@example.test` identity was created through the real Firebase signup
  UI. Signup → full reload preserved authentication; explicit sign-out → normal
  email/password sign-in → another full reload also preserved authentication.
  The first rapid automated sign-in submission failed; refilling each field and
  allowing the Flutter form to settle before submission succeeded. No credential
  value was written to logs, evidence or tracked files.
- Evidence: [restored live session](evidence/live-firebase-session-restored.png).
  This proves Auth persistence, not completed workspace enrollment. The missing
  approved live enrollment notice still blocks enrollment and downstream live
  client-workspace testing. No business role, approved notice or policy was seeded.
  The QA identity remains signed in for continued testing; real Firebase is used,
  and ports 8088/9099 have no emulator listeners.


## Working now

- Firebase email/password signup, sign-in, password recovery request, sign-out and session restoration. New identities reach client enrollment instead of receiving arbitrary roles. Enrollment requires the current configured notice and an explicit checkbox.
- Adaptive Flutter Home, Account, Projects, private manual intake, exact brief review and project overview. The existing design system and showcase are preserved.
- Manual input saves through trusted backend transactions with original inputs, field revisions, provenance and unknown/deferred/declined states. Empty values do not become zero or false. Entered INR amounts become integer paise.
- Draft reload and resume, pause/resume commands, version checks, bounded reads and an unsaved-navigation guard. Project list refreshes after returning from creation.
- Preparing a brief atomically binds one project and creates an immutable requirement version, source manifest and owner membership. Concurrent prepare requests return the same project/version. It does not confirm, share, select a provider or advance construction.
- Explicit confirmation binds the displayed version and hash. Successor briefs preserve previous versions and decisions. Access is rechecked before idempotency replay.
- Root `KALLISTO_MASTER_FLUTTER_ODIN_OLLAMA_KIMI_K3_AUDITED.md` now matches the amended `docs/MASTER_SPEC.md`: Gemma chat/routine tools, NVIDIA Nemotron heavy workflows, Cartesia STT/TTS. The Downloads original was not changed.

## Executed verification

| Check | Result |
| --- | --- |
| Flutter analyze --no-pub | Passed, no issues |
| Flutter test --no-pub | 34 passed, including original showcase tests |
| Backend typecheck, ESLint, build | Passed |
| Backend tests with Firestore emulator | 37 passed |
| Backend npm audit (full tree and production-only) | Zero vulnerabilities |
| Flutter web debug emulator build | Passed |
| Flutter web release build with public root configuration | Passed; output build/client-release |
| Browser signup and client enrollment | Passed with synthetic account and nonbinding local-test notice |
| Browser sign-in, session reload and saved draft reload | Passed using debug emulator build |
| Browser prepare project and confirm exact brief | Passed; confirmed state persisted across page reload |
| Browser pause/resume draft, unsaved-navigation guard, sign-out privacy | Passed |
| Layouts | Desktop 1440x1000, tablet 768x1024, phone 390x844 inspected; widget coverage includes width 320 |

The emulator suite checks conflicting enrollment roles, idempotency, atomic inconsistent-field rejection, cross-client access denial, simultaneous prepares, immutable confirmations, successor versions, pause/resume and revoked-access replay. Emulator data is isolated under `demo-kallisto`; no production domain records, rules, indexes or storage were migrated.

Browser testing found that FlutterFire restores Auth emulator configuration before initialization only in debug mode. The local-test runner therefore deliberately builds debug web; the release artifact is compiled separately. An earlier synthetic draft lost two internal schema tags before the write-preservation fix; only that known emulator fixture was repaired. Subsequent full transaction tests exercise the corrected writes. Production data was untouched.

Evidence: [phone brief](evidence/client-brief-phone.png), [tablet intake](evidence/client-intake-tablet.png), [desktop projects](evidence/client-projects-desktop.png). Screenshots show synthetic test content only. Browser logs include a Noto fallback-font coverage warning; no JavaScript errors were reported. Full locale/font coverage remains to be validated.

## Reproduce the local browser test

Install backend dependencies with `npm ci` in `backend/`, and resolve Flutter packages. Java 21+ is required for the Firestore emulator. Run three PowerShell terminals from this workspace:

```powershell
.\run-local-test.ps1 -Part emulators
.\run-local-test.ps1 -Part api
.\run-local-test.ps1 -Part web
```

Open http://localhost:8080. Create a synthetic account, review the clearly marked local-test notice, enroll, start a brief, save it, prepare it and confirm the displayed version. The API runner seeds only the emulator notice. It does not load backend/.env or real credentials. To run integration checks while the emulators are running:

```powershell
.\run-local-test.ps1 -Part tests
```

Emulator records are temporary. Keep real personal/project data out of this test workspace. The local server binds loopback; no deployment is implied.

## Remaining client implementation and release work

- The manual UI covers core scalar/list fields, not all 77 Appendix E fields. Structured wishes, measurements, date precision, authorized references/attachments and other complex editors remain. Current intake listing is bounded to the first 20 drafts; full filter/pagination UI and representative access remain.
- Organization enrollment UI, profile/preferences editing, email-verification UX, canonical C05 route binding and the complete action-descriptor DTO contract remain.
- Protected Turso binary transfer, recording, transcript adoption/translation, durable Odin runs/jobs, consent and quota reservations remain. Provider adapters were previously smoke-tested, but live text/voice routes remain disabled. This is an implementation gap, not a claim of unavailable credentials.
- Provider discovery, exact-version share previews/enquiries/offers/selection, messaging/notifications, document/review workflows, BOQ/variations, tasks/site/FTP progress, finance and handover/aftercare remain unimplemented. Their unavailable screens do not count as complete workflows.
- Production enrollment needs an actual approved notice configured in `system_settings/features`. Lifecycle transitions need a valid approved published policy. No fabricated terms or approval were installed in production.
- Distributed rate limits, full Firestore indexes/rules review and rollout, deployment configuration, native Firebase registrations/builds/signing and Vercel delivery remain. No Vercel deployment was made.

The account/project-brief slice has local end-to-end evidence. It is not certification of a finished client product or production rollout.
