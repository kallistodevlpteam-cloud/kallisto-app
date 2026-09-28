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

Use the saved `GITHUB_TOKEN` in ignored `backend/.env` for GitHub authentication.
The user explicitly authorized storage there and in the private credential
Markdown; this is a local exception to inherited no-token-in-env guidance.
Do not put
tokens in the remote URL or tracked files. The initial import is committed as
`Codex <codex@local>`; configure your own local Git identity before making your
own commits if needed.

The user requires Git/GitHub for version control and Vercel for deployments.
Use an existing authorized API token or connected account when available rather
than repeatedly opening interactive login prompts. Keep tokens out of terminal
output, Git configuration, command-line arguments, and commits. Load tokens
through trusted credential tooling or directly from a user-designated private
file in memory when invoking the appropriate service.

The user subsequently supplied a GitHub token. `GITHUB_TOKEN` is now saved in
ignored `backend/.env` and the credential Markdown in `backend/.private/`.
Use that credential for GitHub instead of the connected account that previously
reported read-only access. A Vercel token is present as `VERCEL_TOKEN` in the
same private Markdown. Keep service credentials separate.

Vercel is the required hosting provider. Use the token only with Vercel services
when deploying this app. Legacy Vercel project links in the export belong to the
earlier application and must not be assumed to identify this Flutter project.
No Vercel project was linked or deployed during repository setup.

## Private local configuration

Never commit `.env`, `firebase-config.json`, `backend/.env`,
`backend/.private/`, credential exports, or service-account files. Public
`.env.example` templates may be committed. Do not use `git add -f` for ignored
credentials. Flutter build output, dependency caches, and backend dependencies
are excluded by `.gitignore`.

On another machine, clone this repository's `development` branch and provision
the ignored configuration separately using a trusted channel. Follow
`docs/FIREBASE_SETUP.md` and `backend/README.md`; credentials are not in GitHub.
