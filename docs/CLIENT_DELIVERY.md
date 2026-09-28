# Client implementation checkpoint — 29 September 2026

This records executed work, not completion of the master specification.

## Changes

- Copied the Downloads brief to MASTER_SPEC.md; original unchanged. Updated
  client-first sequence, Gemma chat/tools, NVIDIA Nemotron Ultra heavy workflows,
  tool discovery and Cartesia transcription/adoption/speech. Updated both AGENTS.md files.
- Added `lib/client/` shell, Home/Projects/Account pages, Firebase session and
  typed gateway. Sidebar, rail and phone navigation reuse existing tokens.
  Other destinations explicitly report unavailable behavior, not completed
  workflows. Preserved `lib/main_showcase.dart`; added `run-client.ps1`.
- Added Fastify server, validated config, Firebase Admin repository, authorized
  identity/owner-project reads, model/speech adapters and closed tool discovery
  in `backend/src/`. Added backend scripts, dependencies and tests.
- Saved Cartesia credentials only in ignored server files. Updated the safe
  template with API version, STT/TTS models and voice configuration.

## Verification

| Command/check | Result |
| --- | --- |
| Flutter analyze --no-pub | Passed; no issues |
| Flutter test --no-pub | Passed; 30 tests including demo regression tests |
| Flutter build web --release --no-pub --dart-define-from-file=.env | Passed |
| Backend npm run typecheck | Passed |
| Backend npm run lint | Passed |
| Backend npm run test | Passed; 28 tests across four files |
| Backend npm run build | Passed |
| Backend npm audit --omit=dev | Zero vulnerabilities after targeted override |
| Built backend local HTTP smoke | Health 200; anonymous projects 401 using real local configuration, without private database reads |
| Cartesia authenticated voice catalogue | HTTP 200; selected public English stock voice |
| Cartesia synthetic TTS -> STT | Valid 153,678-byte WAV; nonempty 48-character transcript; expected phrase matched |
| Ollama Gemma and Nemotron synthetic requests | Both returned valid visible answers with expected models |
| Gemma tool-search/discovered-tool synthetic sequence | Passed with a test-only read tool; no domain data or writes |

Backend tests cover anonymous/wrong-role/missing-access rejection, revocation,
owner-override rejection, provider transport validation, response limits, voice
cancellation, tool permissions and configuration. Flutter tests cover responsive
layouts, sign-in validation, session changes, private-data clearing, denied
versus empty state and retry.

Manual browser checks used the actual release bundle and signed-out state:
1440x1000 desktop, 768x1024 tablet, 390x844 phone; Home/Projects/Account navigation,
accessible names, form validation and keyboard focus. Browser logs showed no
errors or warnings. Authenticated browser persistence and real Firebase project
reads have not been verified with a provisioned client.

## Remaining work and release boundaries

The full client phase is unfinished: enrolment; manual intake/draft persistence;
protected Turso upload; recording and transcript adoption; consent and atomic
quotas; durable Odin jobs/context/confirmation; provider discovery/enquiries/
selection; project details/documents/messages/reviews/finance/handover. Complete
and verify client workflows before SP and other roles. No domain-write route is
enabled.

Firebase emulator integration, authenticated end-to-end tests, distributed rate
limiting, deployment configuration and native builds remain. Existing backend
records/rules were not migrated. Native Firebase registrations/signing are not
prepared. No Vercel deployment was made. Passing adapter smoke tests is not a
production voice or agent rollout.
