# Kallisto Flutter workspace

Read `docs/MASTER_SPEC.md` before implementation. It is the user's supplied
complete product brief, adapted with the latest instructions in this chat.
It controls product behavior over conflicting older guidance in
`docs/REPOSITORY_GUIDELINES.md`; retain the older security and quality rules
where compatible. Do not ask for another product brief.

## Required build order and AI/voice architecture

- Preserve and reuse the existing Flutter design system and demo. Design the
  client-facing UI first for desktop web, phone and tablet, then connect its
  backend and verify its workflows. Complete the client phase before SP work;
  other actor work follows. Keep phase progress and limitations documented.
- Build all trusted server code in `backend/`. The master spec authorizes
  TypeScript/Fastify, Firebase Auth, Firestore business records, and Turso actual
  media bytes. Do not substitute Firebase Storage for the required binary store.
- Odin uses Ollama: Gemma (`gemma4:31b`) for chat and routine authorized tool
  calls; NVIDIA Nemotron Ultra (`nemotron-3-ultra`) for heavy agent workflows.
  Exact tags are verified engineering defaults, not a claim of live integration.
- Initially expose only `tool_search`. It accepts purpose keywords and returns
  permission-filtered matching function schemas. Activate only discovered tools
  for that run; reauthorize execution and bound search/results/calls. The server
  routes heavy work; neither model controls its own permissions or model choice.
- Cartesia is the selected STT/TTS provider. User audio is transcribed, reviewed
  or adopted into the same Odin conversation/intake, and sent to the chosen
  model. Convert the final visible Gemma response to speech. Never speak hidden
  reasoning or tool payloads. Keep text/manual modes usable if voice is unavailable.
- Keep CARTESIA_API_KEY, OLLAMA_API_KEY and other secrets in ignored backend
  configuration. Respect recording/processing consent and exact-version review;
  spoken answers are not approval of contracts, spending, or project completion.
- Transcription and speech synthesis do not imply translation between languages.
  Preserve original speech/transcript; label any requested translation separately
  and verify actual model/language support before enabling it.

## Version control

- This workspace is an independent repository connected to
  `https://github.com/kallistodevlpteam-cloud/kallisto-app` as `origin`.
- Commit and push this app's work to `development`. Follow `GIT_INSTRUCTIONS.md`.
- Do not change the parent React checkout's remote or include its unrelated work.
- The repository URL and workflow in this workspace override the older parent
  repository identity in inherited references.
- User rule: use Git/GitHub for version control and Vercel for deployment.
  Prefer the user's existing authorized credentials or connected accounts;
  do not create replacement repositories, hosting projects, or tokens merely
  because an interactive login was cancelled. Verify actual write access.
- User instruction: use `GITHUB_TOKEN` from ignored `backend/.env` for authorized
  GitHub operations. The user explicitly requested storing it there and in the
  private credential Markdown, overriding the earlier generic no-token-in-env
  guidance for this local file only. Never copy its value into tracked files.
- Use `VERCEL_TOKEN` from the ignored credential Markdown under
  `backend/.private/` for authorized Vercel operations. Use each service's own
  token; do not substitute tokens or repeatedly open login prompts when saved
  credentials are available.
- Load tokens privately into process memory for the relevant operation. Never
  put token values in remote URLs, persisted Git configuration, command-line
  arguments, logs, Flutter configuration, assets, or commits. Verify write access
  and report actual authentication failures without displaying credentials.

## Frontend and backend locations

- The user explicitly selected Flutter for this application's frontend.
- The user designated `backend/` in this workspace as the home for all backend
  APIs and server-side implementation. Build new server routes, authentication
  and authorization, domain services, integrations, database access, jobs,
  server configuration, and backend tests there.
- Keep Flutter UI and client adapters in `lib/`. Client adapters call the backend;
  privileged logic and server credentials must never be bundled into Flutter.
- Do not create parallel backend implementations elsewhere or add this app's
  new APIs to the parent React application. Existing parent backend code may be
  inspected for contracts and reused through a deliberate migration into
  `backend/`; preserve existing systems and business rules.
- Backend secrets belong in ignored `backend/.env` and `backend/.private/`.
  Root `.env` and `firebase-config.json` contain client-visible settings only.
- Follow `backend/AGENTS.md` for backend work and `docs/FIREBASE_SETUP.md` for
  current configuration and integration limitations.

All parent security, domain, validation, and delivery-branch requirements remain
in force. This folder decision does not authorize database migrations, changing
business rules, deploying services, or weakening access controls.

## Client workflow implementation checkpoint

Signup/enrollment, persisted manual intake, exact-version brief preparation and
confirmation, project overview, and pause/resume are implemented in this slice.
Read docs/CLIENT_DELIVERY.md for executed emulator/browser evidence and unfinished
client features. Do not describe the client phase as complete or start SP work.
The latest user instruction requires real Firebase for the preview and workflow
verification. Do not start emulators. `run-client.ps1` uses the public live
configuration and stable localhost:8080 origin. Production policies and records
must never be replaced with synthetic fixtures. Unit/widget test doubles are
isolated tests, not the running application's data source.

The user explicitly authorized autonomous testing, including performing login
tests without asking them to sign in. Use dedicated clearly identified QA
identities and normal application flows on real Firebase. Do not repeatedly ask
for permission already granted. This does not fabricate an approved enrollment
notice, verified business, payment or another participant's consent.
