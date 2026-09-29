# Enrollment configuration

On 29 September 2026 the user authorized the concrete enrollment notice presented
in this chat. The operator CLI published `client-enrollment-v1` to the real
`kallisto-db1` Firebase project, feature row version 1, with an audit event.
The exact text is in `backend/config/enrollment-notice.draft.json`; that reusable
template deliberately defaults to unapproved. The applied input is ignored under
`backend/.private/`. Its content hash is
`5b4b156db0bfc3c2f9557d4501817158480d0598f5f365d77207027db1fa08de`.

Approval is attributed to the executing service-account operator, with reference
`user-approval-2026-09-29-enrollment-notice`. No human owner UID was invented, no
QA identity was made an administrator, and unrelated settings were preserved.
This notice concerns workspace creation; it does not authorize voice/AI,
payments, provider appointment or construction work. Each client still reviews
and explicitly accepts the current notice when creating their workspace.

Master references: P02, CLIENT_ENROLL and Appendix O.1. The operator-only CLI is
`backend/src/cli/publish-enrollment-notice.ts`. An input requires exact version,
text, approved boolean, expected feature row version and either an existing
Firebase approving owner UID or an operator authorization reference.

From backend/, run `tsx src/cli/publish-enrollment-notice.ts INPUT.json` to
validate. Add `--apply` only for an authorized publication. The command checks
real Firebase/project configuration, preserves unrelated settings, prevents
reusing a version with changed text, and atomically writes configuration plus
audit. There is no public publication API or automatic seed. New notice content
requires renewed review and a new version.
