# Kallisto Flutter workspace

These instructions supplement the repository guidelines preserved in
`docs/REPOSITORY_GUIDELINES.md`. Read that document before implementation.

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
