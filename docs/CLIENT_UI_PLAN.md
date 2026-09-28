# Client delivery: UI first

Authority: MASTER_SPEC.md, especially A, J, K, O and the workspace amendment.
Reuse Hanken Grotesk, KTokens, KPanel, KBadge and the current design system.
Keep the existing component demo available independently.

## Navigation and layout

Desktop uses a persistent sidebar and a bounded central workspace. Tablets use
a compact navigation rail. Phones use five bottom destinations and full-screen
details. Destinations: Home / Ask Odin, Projects, Providers, Messages, Account.
Use content-driven layouts and accessible controls; do not require hover.

Home leads with a conversational project brief composer and a compact explanation
of the process. Projects distinguish private intake from an active project.
Provider discovery includes only published verified providers. Messages belong
to an authorized conversation. Account resolves the actual Firebase identity.

Odin provides Type, Speak and Manual modes in one intake context. Its desktop
brief panel moves to a separate tab on phones. Speech states: permission,
recording, uploading, transcribing, transcript review, processing, playback,
interrupted and unavailable. The visible transcript and text response remain
available when a speech service fails. Heavy workflow progress shows actual
steps and decisions, never internal model reasoning.

Project details group Overview, Design, Build, Money and Files. Review panels
bind exact source/version/evidence and use domain-specific confirmation. Money
separates budget, estimates, commitments and verified payments. Empty financial
fields remain unknown rather than zero.

## Ordered implementation checklist

1. Copy/adapt master brief and agent instructions; preserve credentials privately.
2. Implement adaptive client shell and data/loading/denied/unavailable states.
3. Implement Firebase session/bootstrap and typed authenticated API transport.
4. Complete client intake, transcript adoption and exact brief review.
5. Complete provider disclosure, enquiry, offer review and selection.
6. Complete project groups, documents, reviews, messages, account and handover.
7. Verify the full client phase, then build SP workflows against the same contracts.

Each completed slice requires actual persistence and success/denied/stale/retry
tests. A designed screen, prepared adapter or unit-tested tool registry is not
evidence that an end-to-end workflow is live. Track actual results in the delivery
report; do not claim the whole master specification is implemented at a checkpoint.
