# Kallisto backend

All trusted APIs and server integrations live here. Read AGENTS.md and the
workspace amendment in ../docs/MASTER_SPEC.md before making changes.

## Run and validate

Node 22 or later is required. From backend/:

```powershell
npm ci
npm run dev
npm run typecheck
npm run lint
npm run test
npm run build
npm audit --omit=dev
```

The server validates its local .env, resolves service-account paths relative to
this folder, and uses configured HOST/PORT (locally 127.0.0.1:4000). Flutter's
allowed local origin is http://localhost:5000. Production HTTP origins are
rejected. Never serve this directory as static content.

## Implemented HTTP surface

| Route | Behavior |
| --- | --- |
| GET /health | Process health only; not database or AI readiness |
| GET /v1/auth/me | Firebase token plus authoritative active client access |
| GET /v1/projects | Owner-only project projection and bounded pagination |
| GET /v1/odin/capabilities | Reports disabled live Odin execution truthfully |
| GET /v1/capabilities | Actual enrollment notice availability and implemented modes |
| POST /v1/provider-applications/client-enrollment | Explicit client-only enrollment with current notice |
| GET, POST /v1/intakes | Owner-scoped listing and idempotent draft creation |
| GET /v1/intakes/:id | Source-linked working fields and revision |
| POST /v1/intakes/:id/inputs | Closed manual field operations and immutable input/revision |
| POST /v1/intakes/:id/pause, /resume | Version-checked session transition |
| POST /v1/intakes/:id/prepare-brief | Atomic project binding, immutable brief and source manifest |
| GET /v1/projects/:id | Owner project overview |
| GET /v1/projects/:id/requirements | Current or exact historical brief |
| POST /v1/projects/:id/requirements/confirm | Explicit exact-hash/version confirmation |

Reads use user_access/{uid}, users/{uid}, and projects with owner_uid equal to
the authenticated uid. Access revision is rechecked before sending results.
Delegated representatives and other actors are not enabled by this slice.
Browser role/owner overrides are rejected. Firebase Admin stays server-side.
Records must match MASTER_SPEC; this does not silently reinterpret the older
React application's data model.

The rate limiter is process-local. Distributed limiting, App Check,
security-rule rollout, monitoring and deployment configuration
remain release work. No database or rule migration has been applied.

All mutations require an Idempotency-Key. Writes and idempotency records commit
atomically; retries reauthorize the actor/resource. A draft revision binds at most
one prepared manifest. New versions never overwrite prior confirmations. The
initial manual SourceRef uses source_kind=manual, source_version=1 and
locator=whole_input; the input retains the original closed operation list.
Text, voice, file sources and partial source exclusions are not enabled yet.

Enrollment reads the approved `system_settings/features` projection:
`policy_version`, `approved_by_uid`, and
`values.client_enrollment_notice.{version,text}`. This is the implemented policy
adapter; deployment must configure actual approved notice content. Absent or
stale policy blocks enrollment. The emulator runner supplies a nonbinding test
notice only. No arbitrary role selection or live policy seed is available.

Use `../run-local-test.ps1` for local Auth/Firestore emulators, the API, browser
bundle and opt-in integration tests. `firebase.emulators.json` and its deny-all
client rules are emulator configuration, not an authorized production rollout.
See ../docs/CLIENT_DELIVERY.md for coverage and release limitations.

## AI and voice foundation

- Ollama pins gemma4:31b for routine chat/tools and nemotron-3-ultra for heavy
  workflows. Returned models are validated and private thinking is omitted
  from the visible response projection.
- Per-run ToolDiscovery initially supplies only tool_search. Keyword search
  returns up to five permitted closed schemas. Unknown, undiscovered, revoked
  and malformed tool calls fail. Active tools, searches and calls are bounded.
  Heavy tools request a server handoff when called from the routine tier.
- Cartesia supports bounded multipart STT and WAV TTS, timeout/cancellation and
  safe error categories. It requires version/models/voice configuration.
  config/providers.ts excludes GitHub/Vercel operator credentials.

These adapters are not a durable agent runtime. Before exposing live routes,
implement DB86 fenced jobs, DB126/127 runs/steps, current consent, DB129/135 quota
reservations, exact-version input/confirmation and Turso files. Send only schemas
advertised for that provider turn; persist discovery/budgets and reauthorize on
resume. Write tools need transactional domain handlers and idempotency.

Speech flow: authorized audio -> Cartesia transcript -> actual user review and
adoption -> same Odin source sequence -> final visible answer -> Cartesia speech.
Keep original transcripts and corrections. Translation is separate. Never speak
private thinking or tool payloads. Recording and production voice routes are not
enabled yet.

## Credentials and verification

Ignored .env contains Firebase, Turso, Ollama and Cartesia server settings.
Ignored .private/ contains the service account and credential Markdown. GitHub's
token is in both ignored files as requested; Vercel uses its own token in the
private Markdown. Root .env contains Flutter-public settings only. Never pass
backend/.env to Flutter dart-define.

On 29 September 2026, authenticated synthetic tests verified both Ollama models,
Gemma search/discovered-tool calling, and Cartesia TTS->STT. The voice catalogue
returned HTTP 200; an available public English stock voice was selected locally.
No client/project data was sent. Other languages, microphone capture and the
unimplemented job flow are not certified. Application cloud processing remains
disabled.

References: [Cartesia STT](https://docs.cartesia.ai/api-reference/stt/transcribe),
[TTS](https://docs.cartesia.ai/api-reference/tts/bytes),
[version and voices](https://docs.cartesia.ai/api-reference/voices/list).

The targeted gaxios -> uuid 11.1.1+ override addresses
[GHSA-w5hq-g745-h8pq](https://github.com/advisories/GHSA-w5hq-g745-h8pq).
Gaxios uses the compatible CommonJS v4 export. This fixes the optional Google
Storage dependency tree; Firebase Storage is not the app's media store.
