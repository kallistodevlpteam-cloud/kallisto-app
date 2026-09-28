# Kallisto backend

This is the designated location for **all backend APIs and server-side code**
for the Flutter application. The folder currently contains credentials and
implementation instructions; an API server has not yet been implemented here.

## Layout

```text
backend/
  .env                              Local server configuration (ignored)
  .env.example                      Safe configuration template
  .private/
    firebase-service-account.json   Firebase Admin SDK credentials (ignored)
    kallisto-credentials-*.md        Original export, including platform tokens (ignored)
  src/
    api/                            API routes
    config/                         Validated server configuration
    services/                       Domain operations
    repositories/                   Database access
    integrations/                   Firebase, Ollama, and other external services
  tests/                            Backend tests
```

The source/test directories are ready for implementation and currently empty.
Read [AGENTS.md](AGENTS.md) before adding backend code.

## Credentials

`.env` contains the existing backend settings, Firebase project/database
selection, Turso connection credentials, local CORS settings, and
`OLLAMA_API_KEY`. It also contains `GITHUB_TOKEN` for operator Git operations,
explicitly stored there at the user's request; the application must not expose
or use this token as runtime business-service configuration.
`GOOGLE_APPLICATION_CREDENTIALS` points to the service-account
file in this folder's `.private/` directory. The local absolute path must be
updated if the workspace moves; production should use its trusted credential
mechanism and deployment environment.

The credential Markdown under `.private/` was initially copied from the original
export and subsequently updated with the user-supplied GitHub token. Its legacy
paths and React/Vercel deployment notes are historical reference, not active
configuration. Platform administration tokens remain in that ignored reference
and are not loaded into application runtime settings.

The Flutter root `.env` and `firebase-config.json` retain only public client
settings. Never pass this backend environment to `--dart-define-from-file` or
include the backend directory in Flutter assets or public hosting output.

The prepared settings target a local backend on port 4000 and allow the local
Flutter web origin `http://localhost:5000`. No backend is started by creating
these files. The existing sibling backend has not been moved or modified.

See [Firebase setup](../docs/FIREBASE_SETUP.md) for current frontend configuration,
validation results, and remaining integration work.
