# Backend implementation rules

All backend APIs and server-side code for this Flutter application belong in
this directory, as explicitly instructed by the user.

Use `../docs/MASTER_SPEC.md` as the product and contract authority, including its
workspace amendment. Implement client workflows first, then SP. Use Gemma for
routine chat/tools, Nemotron Ultra for heavy workflows, and permission-filtered
`tool_search` as the only initial model tool. Cartesia supplies STT/TTS via trusted
server adapters; no provider credentials may reach Flutter.

- Use `src/api/` for API routing, `src/config/` for validated configuration,
  `src/services/` for domain operations, `src/repositories/` for persistence,
  `src/integrations/` for external service clients, and `tests/` for backend tests.
  Extend this structure only when required by real features.
- Use trusted TypeScript server code consistent with the existing backend and
  the parent approved architecture. Do not choose a new database, auth provider,
  or server framework without documenting the requirement and impact.
- Load and validate server configuration from `backend/.env` for local work or
  trusted deployment environment variables. Resolve paths explicitly; do not
  depend on Flutter's working directory or implicitly read the root client env.
- Keep Firebase Admin SDK usage, service-account credentials, database tokens,
  and Ollama API calls server-side. Never expose secrets in API responses, logs,
  fixtures, client defines, assets, or committed files.
- Verify Firebase identity and authoritative permissions for protected APIs.
  Preserve requirement versions, immutable approvals, audit history, idempotency,
  and transaction boundaries required by the parent domain rules.
- Use exact approved CORS origins. CORS alone is not authorization.
- Keep `.env.example` free of values copied from private credentials. Never commit
  `.env` or `.private/`, including the original credential export.
- Per explicit user instruction, GitHub authentication uses `GITHUB_TOKEN` saved
  in this folder's ignored `.env`; Vercel deployment uses `VERCEL_TOKEN` in the
  private credential Markdown. These are operator credentials, not API runtime
  configuration: never forward them to clients or load them into integrations
  unrelated to GitHub/Vercel delivery. Follow the root `AGENTS.md` token rules.
- Add relevant tests and real lint, typecheck, test, and build commands when the
  backend implementation is introduced. Do not claim an API exists merely because
  credentials or directories have been prepared.
