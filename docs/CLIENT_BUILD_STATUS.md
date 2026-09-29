# Client implementation matrix

The complete root master (12,460 physical lines, through Appendix Q) was read on
29 September 2026. This matrix covers the requested client phase. The master
remains authoritative; a route or unavailable message does not complete a screen.
Gemma handles routine chat/tools, Nemotron heavy workflows, Cartesia STT/TTS.

Latest instruction: live Firebase for preview; no emulators. Unit/widget test
doubles are isolated checks. Historical emulator evidence is not live evidence.

| Screen | Current widget / adapter / API | Data and outstanding acceptance |
| --- | --- | --- |
| C01 Home | ClientHomePage / ClientGateway / auth/me, projects | Own projects; actions, milestones and notifications remain |
| C02 Projects | ClientProjectsPage, IntakeListPanel / projects, intakes | Bounded lists; full filters/intake pagination remain |
| C03 New project | ClientIntakePage / INTAKE_CREATE | One intake before project preparation; real enrollment policy required |
| C04 Intake | ClientIntakePage / inputs, prepare, pause, resume | Versioned core manual fields; full 77-field editors, voice/text/Odin remain |
| C05 Review | BriefReviewPage / requirements, confirm | Immutable displayed hash; canonical intake review deep link remains |
| C06 Discovery | ClientProvidersPage / providers | Published safe projection, current eligibility, bounded filtering/pagination; comparison remains |
| C07 Profile/share | ClientProvidersPage, ShareBriefPanel / providers/:id, share-preview, share | Exact minimal disclosure and guarded idempotent share; portfolio/expanded disclosure/attachments remain |
| C08 Enquiries | ClientEnquiriesPage / enquiries | Own source-authorized frozen enquiries and paging; status filters remain |
| C09 Enquiry/offers | ClientEnquiriesPage / enquiries/:id | Shared details viewer; exact offer getters/comparison/selection remain; linked conversation implemented |
| C10 Overview | ProjectOverviewPage / project detail | Basic project/brief/policy state; modules remain |
| C11 Documents | Not implemented | Submitted immutable versions, protected bytes, exact decisions |
| C12 BOQ | Not implemented | Baselines, variations, exact review and non-overlapping totals |
| C13 Tasks | Not implemented | Client-visible tasks/comments and filtered dependencies |
| C14 Site | Not implemented | Published daily logs, evidence and acknowledgment |
| C15 Money | Not implemented | Source-separated amounts, claims and settlement evidence |
| C16 Reviews | Not implemented | Typed dispatch, exact source/version decisions and funding |
| C17 Handover | Not implemented | Exact manifest review; separate completion/aftercare |
| C18 Messages | ClientMessagesPage / conversations, messages | Context-authorized inbox/thread, durable text and bounded history; notifications/attachments remain |
| C19 Payments | Not implemented | Cross-project authorized finance projection |
| C20 FTP | Not implemented | Published findings and limitations; no inferred progress |
| CS01 Settings | Account links / settings routes | Seven preference editors connected; complete index remains |
| CS02 Profile | Read-only account name | Profile edit/avatar and verified contact workflows remain |
| CS03 Appearance | Backend closed schema | Theme/density/motion UI and application remain |
| CS04 Communication | ClientSettingsPage / PREFERENCES_GET/SAVE | Channel/language saved; quiet-hours editor remains |
| CS05 Language/region | ClientSettingsPage / PREFERENCES_GET/SAVE | Canonical values saved; full locale/date/unit application remains |
| CS06 Notifications | ClientSettingsPage / PREFERENCES_GET/SAVE | Channel toggles saved; reminder editor/transport remain |
| CS07 Privacy | ClientSettingsPage / PREFERENCES_GET/SAVE | Optional preference toggles; consent/export/deletion workflows remain |
| CS08 Security | Account + ClientSettingsPage | Recovery/signout/security preference; all-session revocation remains |
| CS09 Billing | Backend closed schema | Contact editor remains |
| CS10 Payment methods | Not implemented | Honest processor capability page; no card collection |
| CS11 Project preferences | ClientSettingsPage / PREFERENCES_GET/SAVE | Default view/units saved; application and reminder editor remain |
| CS12 Access | Not implemented | Actual grants, scoped invitation and revocation |
| OD01 Odin | Provider adapters/tool-search foundation | Durable runs, quota, consent, exact intents and UI remain |
| MC01 Messages | ClientMessagesPage / message APIs | Source rechecked, immutable text, retry deduplication, closed state; attachments/unread/filters remain |
| SUP01/SUP02 Support | ClientSupportPage / support APIs | Own case create/list/detail and scoped conversation; evidence, assignment and close actions remain |
| A01 Invitation | Not implemented | Intended recipient verification and scoped acceptance |

## Current verification limits

Settings unit tests cover schema injection, invalid time zones, persistence,
idempotency, stale writes, revoked replay and canonical language synchronization.
Widget tests cover narrow layout, saved reload and uncertain-request retry identity.
Provider tests cover safe field projection, category/coverage filtering, old
eligibility pointers, expiration and invalid queries. Neither test suite creates
production records. Full per-screen success/empty/error/offline/stale/denied and
device acceptance remains required before marking any complete phase.

Sharing tests additionally prove no-write previews, private-address/history
exclusion, changed-version/hash rejection, recipient revocation, duplicate
intent deduplication and no project membership grant. The Flutter test requires
the actual disclosure checkbox before sending. Shared enquiries include a
durable notification intent; notification transport is not yet delivered.

Live preview uses project kallisto-db1, localhost:8080 and API localhost:4000.
With the user's autonomous-testing authorization, a dedicated real Firebase QA
identity passed signup/reload and sign-out/sign-in/reload in the live browser.
See evidence/live-firebase-session-restored.png. The user-approved enrollment notice was published with operator attribution;
real QA enrollment, account reload, support creation and message reload passed.
No business approval or construction policy was fabricated. Native Firebase registration and Vercel
release validation remain outstanding. Do not request the user's login again for
QA work that can use the dedicated test identity.
