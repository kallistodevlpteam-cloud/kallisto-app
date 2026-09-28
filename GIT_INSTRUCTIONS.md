# Kallisto app version control

- Repository: https://github.com/kallistodevlpteam-cloud/kallisto-app
- Remote: `origin`
- Delivery branch: `development`
- Workspace: this Flutter project, with all server implementation in `backend/`.

This directory is an independent Git repository nested inside the older local
`kallisto-dev` checkout. Run this project's Git commands from this directory.
Do not change the parent checkout's remote or publish its unrelated React code
to this repository. The remote's original `main` history is retained as the
base of `development`. Do not force-push or write to `provider-ui`.

## Routine workflow

```powershell
git status
git fetch origin
git switch development
git pull --ff-only origin development
# Review changes, then stage only the intended files.
git diff --cached --check
git commit -m "Feature: describe the change"
git push origin development
```

Use the existing Git credential manager for GitHub authentication. Do not put
tokens in the remote URL or tracked files. The initial import is committed as
`Codex <codex@local>`; configure your own local Git identity before making your
own commits if needed.

## Private local configuration

Never commit `.env`, `firebase-config.json`, `backend/.env`,
`backend/.private/`, credential exports, or service-account files. Public
`.env.example` templates may be committed. Do not use `git add -f` for ignored
credentials. Flutter build output, dependency caches, and backend dependencies
are excluded by `.gitignore`.

On another machine, clone this repository's `development` branch and provision
the ignored configuration separately using a trusted channel. Follow
`docs/FIREBASE_SETUP.md` and `backend/README.md`; credentials are not in GitHub.
