# Master implementation checklist

Source: docs/MASTER_SPEC.md revision 5.1. Each item remains open until its UI, API, authority checks, persistence, error states and real workflow verification meet the quoted acceptance. Existing partial implementations are not completed modules.

Build order: Odin and client/shared dependencies → complete client acceptance → SP modules and acceptance. Gemma chat; server-routed Nemotron planning; Cartesia voice; Firestore records; Turso bytes.

## Immediate sequence

- [ ] OD01 durable text chat, consent, quota, run history, tool search, cancel/recovery and real-provider verification.
- [ ] Unified intake extraction/corrections and all 77 fields.
- [ ] Protected Turso uploads and Cartesia recording/transcription/adoption/playback.
- [ ] Exact intents/candidates and client module connections below.
- [ ] Finish and verify client phase before SP implementation.

## Verified implementation checkpoint — 29 September 2026

- [x] Odin home composer opens the real assistant and retains submitted text.
- [x] Explicit development processing consent, per-account quota reservations, durable Firestore runs/jobs, bounded history, cancellation and fenced retry.
- [x] Live Gemma response, permission-filtered tool_search then projects_list, and server-selected Nemotron planning verified in the browser with real Firebase.
- [x] Saved run survives full reload; project sources are reauthorized, including inherited conversation sources.
- [x] Registry and UI represent all 77 Appendix E fields. 76 have manual controls; attachments explicitly await protected storage. Typed measurements, date precision, stable record IDs and unknown/deferred/declined states are implemented.
- [x] Profile name, appearance and billing preference adapters/editors added; appearance applies across the client shell.
- [ ] Odin intake extraction/correction/adoption into the same brief; exact reviewable write intents.
- [ ] Full chronological conversation rendering, history pagination, deployed worker scheduling and approved production processing/quota policy.
- [ ] Protected file upload and Cartesia voice. Read-only inspection found legacy Turso tables that differ from G.10; no live schema migration was performed.

These checkpoints do not close OD01, C04 or the overall client/SP phase. The screen acceptance inventory remains the completion contract.

## Screen acceptance inventory

### P01 — Entry and role-resolved landing

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/`.

Load operations: ACTOR_GET, CAPABILITIES_GET. **Mutation operations:** No domain mutation on this screen; navigation only.

Mutation operations: No domain mutation on this screen; navigation only.

Page acceptance: Visitor sees no project names; client/SP/partner/applicant session reaches the correct safe home. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### P02 — Shared application wizard

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/apply`.

Load operations: ACTOR_GET, APPLICATION_GET, CAPABILITIES_GET, HANDLE_CHECK. **Mutation operations:** CLIENT_ENROLL, APPLICATION_SUBMIT, UPLOAD_CREATE, UPLOAD_CHUNK, UPLOAD_FINALIZE, APPLICATION_DRAFT_SAVE.

Mutation operations: CLIENT_ENROLL, APPLICATION_SUBMIT, UPLOAD_CREATE, UPLOAD_CHUNK, UPLOAD_FINALIZE, APPLICATION_DRAFT_SAVE.

Page acceptance: Complete applicant submit-refresh-resume; concurrent handle claim has one winner; no self-verification. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### P03 — Sign in and recovery

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sign-in`.

Load operations: ACTOR_GET, CAPABILITIES_GET. **Mutation operations:** SESSION_CREATE.

Mutation operations: SESSION_CREATE.

Page acceptance: The displayed action calls its exact allowed schema, persists only authorized data, and returns a real saved state after refresh. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### P04 — Application status and corrections

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/application/status`.

Load operations: APPLICATION_GET, ACTOR_GET, HANDLE_CHECK. **Mutation operations:** APPLICATION_SUBMIT, UPLOAD_CREATE, UPLOAD_CHUNK, UPLOAD_FINALIZE, APPLICATION_DRAFT_SAVE.

Mutation operations: APPLICATION_SUBMIT, UPLOAD_CREATE, UPLOAD_CHUNK, UPLOAD_FINALIZE, APPLICATION_DRAFT_SAVE.

Page acceptance: Pending application visible after refresh; rejected state is not active workspace; corrected files retain prior versions. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### C01 — Client home

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/home`.

Load operations: PROJECT_HOME, PROJECTS_LIST, ACTIONS_LIST, CAPABILITIES_GET. **Mutation operations:** No domain mutation on this screen; navigation only.

Mutation operations: No domain mutation on this screen; navigation only.

Page acceptance: No repeated project selection when context exists; cards/counts exclude unrelated/private sources. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### C02 — Client project list

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/projects`.

Load operations: PROJECTS_LIST, INTAKES_LIST. **Mutation operations:** INTAKE_CREATE, INTAKE_RESUME.

Mutation operations: INTAKE_CREATE, INTAKE_RESUME.

Page acceptance: Create one private project; refresh persists; duplicate retry returns same ID. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### C03 — New project intake entry

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/projects/new`.

Load operations: CAPABILITIES_GET, INTAKES_LIST. **Mutation operations:** INTAKE_CREATE, INTAKE_RESUME.

Mutation operations: INTAKE_CREATE, INTAKE_RESUME.

Page acceptance: With AI disabled, manual intake still reaches prepared review; mode switch keeps all fields. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### C04 — Odin intake workspace

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/intakes/:intakeId`.

Load operations: INTAKE_GET, CAPABILITIES_GET, JOB_GET, ODIN_CAPABILITIES, CONSENT_GET. **Mutation operations:** INTAKE_INPUT, INTAKE_CONFLICT, INTAKE_TRANSCRIPT_CORRECT, INTAKE_PAUSE, UPLOAD_CREATE, UPLOAD_CHUNK, UPLOAD_FINALIZE, UPLOAD_CANCEL, INTAKE_RESUME, CONSENT_DECIDE, INTAKE_TRANSCRIBE.

Mutation operations: INTAKE_INPUT, INTAKE_CONFLICT, INTAKE_TRANSCRIPT_CORRECT, INTAKE_PAUSE, UPLOAD_CREATE, UPLOAD_CHUNK, UPLOAD_FINALIZE, UPLOAD_CANCEL, INTAKE_RESUME, CONSENT_DECIDE, INTAKE_TRANSCRIBE.

Page acceptance: Golden paragraph answers ten+ fields without re-asking; out-of-order job and manual edit race tests pass. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### C05 — Prepared brief review and confirmation

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/intakes/:intakeId/review`.

Load operations: INTAKE_GET, REQUIREMENTS_GET. **Mutation operations:** INTAKE_PREPARE, REQUIREMENTS_CONFIRM.

Mutation operations: INTAKE_PREPARE, REQUIREMENTS_CONFIRM.

Page acceptance: Change draft while review open -> stale decision denied, exact new version reviewed. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### C06 — Lead-provider discovery

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/providers`.

Load operations: PROVIDERS_LIST, PROJECTS_LIST. **Mutation operations:** No domain mutation on this screen; navigation only.

Mutation operations: No domain mutation on this screen; navigation only.

Page acceptance: No eligible match returns honest empty state; no private profile contact/evidence leaked. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### C07 — Lead-provider profile and share preview

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/providers/:id`.

Load operations: PROVIDER_DETAIL, PROJECTS_LIST, REQUIREMENTS_GET. **Mutation operations:** ENQUIRY_SHARE, ENQUIRY_SHARE_PREVIEW.

Mutation operations: ENQUIRY_SHARE, ENQUIRY_SHARE_PREVIEW.

Page acceptance: Provider revoked after profile load -> share denied; private intake/source files remain private. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### C08 — Client enquiries

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/enquiries`.

Load operations: CLIENT_ENQUIRIES. **Mutation operations:** No domain mutation on this screen; navigation only.

Mutation operations: No domain mutation on this screen; navigation only.

Page acceptance: Two shared SPs appear independently; messages and offers do not cross recipient scopes. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### C09 — Client enquiry detail and proposal review

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/enquiries/:enquiryId`.

Load operations: ENQUIRY_GET, MAIN_PROPOSALS_GET, MESSAGES_GET, MAIN_PROPOSAL_GET. **Mutation operations:** MESSAGE_SEND, PROVIDER_SELECT.

Mutation operations: MESSAGE_SEND, PROVIDER_SELECT.

Page acceptance: Two browser tabs select competing offers -> one success; loser sees conflict without orphan membership. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### C10 — Client project overview and grouped navigation

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/projects/:projectId`.

Load operations: PROJECT_GET, ACTIONS_LIST, MILESTONES_GET, SITE_GET, FINANCE_GET. **Mutation operations:** No domain mutation on this screen; navigation only.

Mutation operations: No domain mutation on this screen; navigation only.

Page acceptance: Client approves real Hands/Hub request through F10 and FULFILMENT_ACTION in C16; revoked representative immediately loses view. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### C11 — Client drawings, documents and file archive

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/projects/:projectId/documents`.

Load operations: DOCUMENTS_GET, FILE_MANIFEST, FILE_CHUNK, DOCUMENT_GET. **Mutation operations:** DOCUMENT_DECIDE.

Mutation operations: DOCUMENT_DECIDE.

Page acceptance: New private SP draft never appears in client list, version count or preview. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### C12 — Client BOQ and variation review

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/projects/:projectId/boq`.

Load operations: BOQ_GET. **Mutation operations:** BOQ_DECIDE, VARIATION_DECIDE.

Mutation operations: BOQ_DECIDE, VARIATION_DECIDE.

Page acceptance: Pending delta excluded from approved total; stale baseline decision rejected. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### C13 — Client build schedule and tasks

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/projects/:projectId/tasks`.

Load operations: TASKS_GET. **Mutation operations:** TASK_COMMENT.

Mutation operations: TASK_COMMENT.

Page acceptance: Private predecessor does not leak; phone date filtering and refresh persist actual source state. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### C14 — Client site updates

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/projects/:projectId/site`.

Load operations: SITE_GET, FILE_MANIFEST, FILE_CHUNK. **Mutation operations:** SITE_ACK.

Mutation operations: SITE_ACK.

Page acceptance: Acknowledging log does not approve feasibility, milestone or phase. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### C15 — Client project finance

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/projects/:projectId/finance`.

Load operations: FINANCE_GET. **Mutation operations:** No domain mutation on this screen; navigation only.

Mutation operations: No domain mutation on this screen; navigation only.

Page acceptance: Demo payment success cannot change balance or complete project; architect fee not confused with whole build cost. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### C16 — Client review inbox and request decision

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/reviews`.

Load operations: ACTIONS_LIST, DOCUMENT_GET, BOQ_GET, MAIN_PROPOSAL_GET, FULFILMENT_DETAIL, MILESTONE_GET, HANDOVER_GET, BASICS_FUNDING_GET. **Mutation operations:** DOCUMENT_DECIDE, BOQ_DECIDE, VARIATION_DECIDE, PROVIDER_SELECT, FULFILMENT_ACTION, MILESTONE_DECIDE, HANDOVER_DECIDE, BASICS_FUNDING_DECIDE.

Mutation operations: DOCUMENT_DECIDE, BOQ_DECIDE, VARIATION_DECIDE, PROVIDER_SELECT, FULFILMENT_ACTION, MILESTONE_DECIDE, HANDOVER_DECIDE, BASICS_FUNDING_DECIDE.

Page acceptance: Actual client commercial release reaches intended partner only after both approvals; stale cards cannot approve successor. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### C17 — Client handover and aftercare

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/projects/:projectId/handover`; `/client/projects/:projectId/aftercare`.

Load operations: HANDOVER_GET, AFTERCARE_GET, FILE_MANIFEST. **Mutation operations:** HANDOVER_DECIDE, AFTERCARE_SAVE.

Mutation operations: HANDOVER_DECIDE, AFTERCARE_SAVE.

Page acceptance: Missing required file/blocking defect stops completion; new aftercare case preserves original handover. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### C18 — Client messages and notifications

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/messages`; `/client/notifications`.

Load operations: CONVERSATIONS_LIST, MESSAGES_GET, NOTIFICATIONS_LIST. **Mutation operations:** MESSAGE_SEND, NOTIFICATION_READ.

Mutation operations: MESSAGE_SEND, NOTIFICATION_READ.

Page acceptance: Message retry creates one persisted record; read receipt does not count as review decision. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### C19 — Client all-project payment visibility

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/payments`.

Load operations: PROJECTS_LIST, FINANCE_GET. **Mutation operations:** No domain mutation on this screen; navigation only.

Mutation operations: No domain mutation on this screen; navigation only.

Page acceptance: Displayed payment state derives actual evidence, never mocked transaction array. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### S01 — Provider workspace home

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/home`.

Load operations: PROJECT_HOME, SP_OPPORTUNITIES, ACTIONS_LIST, TASKS_GET. **Mutation operations:** No domain mutation on this screen; navigation only.

Mutation operations: No domain mutation on this screen; navigation only.

Page acceptance: Every card deep link opens actual authorized resource; no fabricated KPI counts. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### S02 — Provider enquiry list

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/enquiries`.

Load operations: SP_OPPORTUNITIES. **Mutation operations:** No domain mutation on this screen; navigation only.

Mutation operations: No domain mutation on this screen; navigation only.

Page acceptance: Private client drafts and competing offers cannot be listed. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### S03 — Provider enquiry detail and offer editor

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/enquiries/:enquiryId`.

Load operations: ENQUIRY_GET, MESSAGES_GET. **Mutation operations:** ENQUIRY_ACK, ENQUIRY_RESPOND, MESSAGE_SEND, MAIN_PROPOSAL_SUBMIT.

Mutation operations: ENQUIRY_ACK, ENQUIRY_RESPOND, MESSAGE_SEND, MAIN_PROPOSAL_SUBMIT.

Page acceptance: Reject wrong requirement version; client scope update cannot silently reuse old offer. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### S04 — Provider projects

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/projects`.

Load operations: PROJECTS_LIST. **Mutation operations:** No domain mutation on this screen; navigation only.

Mutation operations: No domain mutation on this screen; navigation only.

Page acceptance: Team member sees only assigned projects, not every organization project. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### S05 — Provider project overview

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/projects/:projectId`.

Load operations: PROJECT_GET, ACTIONS_LIST, TASKS_GET, FULFILMENT_GET. **Mutation operations:** PROJECT_CONTEXT_UPDATE.

Mutation operations: PROJECT_CONTEXT_UPDATE.

Page acceptance: Same project ID across modules, package/task demand links persist after refresh. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### S06 — Provider project activity

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/projects/:projectId/updates`.

Load operations: PROJECT_GET, PROJECT_EVENTS_GET, TASKS_GET, SITE_GET, CONVERSATIONS_LIST. **Mutation operations:** MESSAGE_SEND.

Mutation operations: MESSAGE_SEND.

Page acceptance: Projection replay adds no duplicate business actions or leaked private events. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### S07 — Provider document authoring

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/projects/:projectId/documents`.

Load operations: DOCUMENTS_GET, REQUIREMENTS_GET, FILE_MANIFEST, DOCUMENT_GET. **Mutation operations:** DOCUMENT_UPLOAD, UPLOAD_CHUNK, UPLOAD_FINALIZE, DOCUMENT_SUBMIT, DOCUMENT_VERSION_CREATE, PROJECT_BRIEF_ACK.

Mutation operations: DOCUMENT_UPLOAD, UPLOAD_CHUNK, UPLOAD_FINALIZE, DOCUMENT_SUBMIT, DOCUMENT_VERSION_CREATE, PROJECT_BRIEF_ACK.

Page acceptance: Upload response lost resumes safely; private successor hidden from client until submit. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### S08 — Provider BOQ and variations

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/projects/:projectId/boq`.

Load operations: BOQ_GET, REQUIREMENTS_GET. **Mutation operations:** VARIATION_CREATE, BOQ_VERSION, BOQ_SAVE, BOQ_SUBMIT, VARIATION_SAVE, VARIATION_SUBMIT, PROJECT_BRIEF_ACK, EXPORT_CREATE.

Mutation operations: VARIATION_CREATE, BOQ_VERSION, BOQ_SAVE, BOQ_SUBMIT, VARIATION_SAVE, VARIATION_SUBMIT, PROJECT_BRIEF_ACK, EXPORT_CREATE.

Page acceptance: Zero vs blank and rounding tests; approved values immutable; pending not authorized procurement. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### S09 — Provider tasks and work packages

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/projects/:projectId/tasks`.

Load operations: TASKS_GET, TEAM_GET, TASK_GET. **Mutation operations:** PACKAGE_SAVE, TASK_CREATE, TASK_SAVE, TASK_TRANSITION, TASK_COMMENT, EXPORT_CREATE.

Mutation operations: PACKAGE_SAVE, TASK_CREATE, TASK_SAVE, TASK_TRANSITION, TASK_COMMENT, EXPORT_CREATE.

Page acceptance: Cycle and cross-project dependency denied; all calendar variants reflect same save. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### S10 — Provider timeline and Gantt

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/projects/:projectId/timeline`; `/sp/projects/:projectId/timeline/gantt`.

Load operations: TASKS_GET. **Mutation operations:** TASK_SAVE.

Mutation operations: TASK_SAVE.

Page acceptance: Two concurrent date edits conflict; private predecessors not exposed by dependency arrows. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### S11 — Provider site view

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/projects/:projectId/site`.

Load operations: SITE_GET, FIELD_REPORTS_GET, ISSUES_GET. **Mutation operations:** SITE_ACK, ISSUE_SAVE, SITE_PUBLISH.

Mutation operations: SITE_ACK, ISSUE_SAVE, SITE_PUBLISH.

Page acceptance: SP direct API cannot publish without grant; acknowledged log not phase approval. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### S12 — Provider finance view

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/projects/:projectId/finance`.

Load operations: FINANCE_GET, MILESTONES_GET. **Mutation operations:** FINANCE_EVIDENCE_CREATE, EXPORT_CREATE.

Mutation operations: FINANCE_EVIDENCE_CREATE, EXPORT_CREATE.

Page acceptance: No double counting subcontract in accepted main contract; settlement independent from delivered. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### S13 — Provider project team and invitations

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/projects/:projectId/team`.

Load operations: TEAM_GET, MEMBERSHIPS_GET. **Mutation operations:** INVITE_CREATE, GRANT_REVOKE.

Mutation operations: INVITE_CREATE, GRANT_REVOKE.

Page acceptance: Invite cannot exceed grantor powers; revoked user loses further files and mutations. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### S14 — Provider material planning

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/projects/:projectId/materials`.

Load operations: DEMANDS_GET, BOQ_GET, FULFILMENT_GET, SITE_INVENTORY_GET. **Mutation operations:** DEMAND_SAVE, FULFILMENT_CREATE, SITE_STOCK_MOVE.

Mutation operations: DEMAND_SAVE, FULFILMENT_CREATE, SITE_STOCK_MOVE.

Page acceptance: Pending variation cannot increase purchasing; received versus consumed quantities distinct. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### S15 — Provider milestones and handover

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/projects/:projectId/milestones`; `/sp/projects/:projectId/handover`.

Load operations: MILESTONES_GET, HANDOVER_GET, ISSUES_GET, MILESTONE_GET. **Mutation operations:** MILESTONE_SUBMIT, HANDOVER_SAVE, HANDOVER_SUBMIT, PHASE_TRANSITION, MILESTONE_SAVE.

Mutation operations: MILESTONE_SUBMIT, HANDOVER_SAVE, HANDOVER_SUBMIT, PHASE_TRANSITION, MILESTONE_SAVE.

Page acceptance: Missing gate blocks direct API, not merely disabled button; no dummy completion. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### S16 — Provider global task/calendar/document/site/BOQ wrappers

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/tasks`; `/sp/calendar`; `/sp/documents`; `/sp/site`; `/sp/timeline`; `/sp/boq`; `/sp/finance`.

Load operations: PROJECTS_LIST, TASKS_GET, DOCUMENTS_GET, SITE_GET, BOQ_GET, FINANCE_GET. **Mutation operations:** TASK_SAVE, TASK_TRANSITION, TASK_COMMENT.

Mutation operations: TASK_SAVE, TASK_TRANSITION, TASK_COMMENT.

Page acceptance: Opening global wrapper then project detail yields same record/version and respects same permission. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### S17 — Provider organization team directory

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/team`.

Load operations: ACTOR_GET, TEAM_GET, MEMBERSHIPS_GET. **Mutation operations:** INVITE_CREATE, GRANT_REVOKE.

Mutation operations: INVITE_CREATE, GRANT_REVOKE.

Page acceptance: Cross-organization query denied unless an exact collaborating resource grant exists. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### S18 — Provider analytics

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/analytics`.

Load operations: PROJECTS_LIST, SP_OPPORTUNITIES, FINANCE_GET, TASKS_GET. **Mutation operations:** No domain mutation on this screen; navigation only.

Mutation operations: No domain mutation on this screen; navigation only.

Page acceptance: Empty/new account has empty metrics rather than demo growth. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### SUP01 — Help and support

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/help`.

Load operations: CAPABILITIES_GET, SUPPORT_CASES_LIST. **Mutation operations:** PRIVACY_CREATE, SUPPORT_CASE_CREATE.

Mutation operations: PRIVACY_CREATE, SUPPORT_CASE_CREATE.

Page acceptance: User sees true request-submitted status only after durable record, not unsupported promise of response. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### CS01 — Settings index

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/settings`.

Load operations: PREFERENCES_GET, ACTOR_GET. **Mutation operations:** PREFERENCES_SAVE.

Mutation operations: PREFERENCES_SAVE.

Page acceptance: Save-refresh returns exact allowed preference; unrelated subject IDs and hidden privilege fields denied. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### CS02 — Client profile

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/settings/profile`.

Load operations: PERSON_PROFILE_GET, ACTOR_GET. **Mutation operations:** PERSON_PROFILE_SAVE, UPLOAD_CREATE, UPLOAD_CHUNK, UPLOAD_FINALIZE.

Mutation operations: PERSON_PROFILE_SAVE, UPLOAD_CREATE, UPLOAD_CHUNK, UPLOAD_FINALIZE.

Page acceptance: Save-refresh returns exact allowed preference; unrelated subject IDs and hidden privilege fields denied. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### CS03 — Client appearance

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/settings/appearance`.

Load operations: PREFERENCES_GET, ACTOR_GET. **Mutation operations:** PREFERENCES_SAVE.

Mutation operations: PREFERENCES_SAVE.

Page acceptance: Save-refresh returns exact allowed preference; unrelated subject IDs and hidden privilege fields denied. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### CS04 — Client communication

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/settings/communication`.

Load operations: PREFERENCES_GET, ACTOR_GET. **Mutation operations:** PREFERENCES_SAVE.

Mutation operations: PREFERENCES_SAVE.

Page acceptance: Save-refresh returns exact allowed preference; unrelated subject IDs and hidden privilege fields denied. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### CS05 — Language and region

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/settings/language-region`.

Load operations: PREFERENCES_GET, ACTOR_GET. **Mutation operations:** PREFERENCES_SAVE.

Mutation operations: PREFERENCES_SAVE.

Page acceptance: Save-refresh returns exact allowed preference; unrelated subject IDs and hidden privilege fields denied. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### CS06 — Client notifications

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/settings/notifications`.

Load operations: PREFERENCES_GET, ACTOR_GET. **Mutation operations:** PREFERENCES_SAVE.

Mutation operations: PREFERENCES_SAVE.

Page acceptance: Save-refresh returns exact allowed preference; unrelated subject IDs and hidden privilege fields denied. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### CS07 — Client privacy

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/settings/privacy`.

Load operations: PREFERENCES_GET, ACTOR_GET, PRIVACY_GET, CONSENT_GET. **Mutation operations:** PREFERENCES_SAVE, PRIVACY_CREATE, CONSENT_DECIDE.

Mutation operations: PREFERENCES_SAVE, PRIVACY_CREATE, CONSENT_DECIDE.

Page acceptance: Save-refresh returns exact allowed preference; unrelated subject IDs and hidden privilege fields denied. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### CS08 — Client security

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/settings/security`.

Load operations: PREFERENCES_GET, ACTOR_GET, CAPABILITIES_GET. **Mutation operations:** SESSION_REVOKE.

Mutation operations: SESSION_REVOKE.

Page acceptance: Save-refresh returns exact allowed preference; unrelated subject IDs and hidden privilege fields denied. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### CS09 — Client billing details

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/settings/billing`.

Load operations: PREFERENCES_GET, ACTOR_GET. **Mutation operations:** PREFERENCES_SAVE.

Mutation operations: PREFERENCES_SAVE.

Page acceptance: Save-refresh returns exact allowed preference; unrelated subject IDs and hidden privilege fields denied. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### CS10 — Client payment methods

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/settings/payment-methods`.

Load operations: PREFERENCES_GET, ACTOR_GET, CAPABILITIES_GET. **Mutation operations:** No domain mutation on this screen; navigation only.

Mutation operations: No domain mutation on this screen; navigation only.

Page acceptance: Save-refresh returns exact allowed preference; unrelated subject IDs and hidden privilege fields denied. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### CS11 — Client project preferences

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/settings/project-preferences`.

Load operations: PREFERENCES_GET, ACTOR_GET. **Mutation operations:** PREFERENCES_SAVE.

Mutation operations: PREFERENCES_SAVE.

Page acceptance: Save-refresh returns exact allowed preference; unrelated subject IDs and hidden privilege fields denied. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### CS12 — Client project access

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/settings/project-access`.

Load operations: PREFERENCES_GET, ACTOR_GET, PROJECTS_LIST, TEAM_GET. **Mutation operations:** INVITE_CREATE, GRANT_REVOKE.

Mutation operations: INVITE_CREATE, GRANT_REVOKE.

Page acceptance: Save-refresh returns exact allowed preference; unrelated subject IDs and hidden privilege fields denied. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### SS01 — Account settings

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/settings/account`.

Load operations: PERSON_PROFILE_GET, ACTOR_GET. **Mutation operations:** PERSON_PROFILE_SAVE, UPLOAD_CREATE, UPLOAD_CHUNK, UPLOAD_FINALIZE.

Mutation operations: PERSON_PROFILE_SAVE, UPLOAD_CREATE, UPLOAD_CHUNK, UPLOAD_FINALIZE.

Page acceptance: The displayed action calls its exact allowed schema, persists only authorized data, and returns a real saved state after refresh. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### SS02 — Provider appearance

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/settings/appearance`.

Load operations: PREFERENCES_GET, ACTOR_GET, CAPABILITIES_GET. **Mutation operations:** PREFERENCES_SAVE.

Mutation operations: PREFERENCES_SAVE.

Page acceptance: The displayed action calls its exact allowed schema, persists only authorized data, and returns a real saved state after refresh. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### SS03 — Provider business profile

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/settings/business-profile`.

Load operations: PREFERENCES_GET, ACTOR_GET, CAPABILITIES_GET, BUSINESS_PROFILE_GET. **Mutation operations:** PREFERENCES_SAVE, BUSINESS_PROFILE_SAVE.

Mutation operations: PREFERENCES_SAVE, BUSINESS_PROFILE_SAVE.

Page acceptance: The displayed action calls its exact allowed schema, persists only authorized data, and returns a real saved state after refresh. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### SS04 — Provider billing

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/settings/billing`.

Load operations: PREFERENCES_GET, ACTOR_GET, CAPABILITIES_GET. **Mutation operations:** PREFERENCES_SAVE.

Mutation operations: PREFERENCES_SAVE.

Page acceptance: The displayed action calls its exact allowed schema, persists only authorized data, and returns a real saved state after refresh. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### SS05 — Provider notifications

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/settings/notifications`.

Load operations: PREFERENCES_GET, ACTOR_GET, CAPABILITIES_GET. **Mutation operations:** PREFERENCES_SAVE.

Mutation operations: PREFERENCES_SAVE.

Page acceptance: The displayed action calls its exact allowed schema, persists only authorized data, and returns a real saved state after refresh. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### SS06 — Provider Odin settings

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/settings/odin-ai`.

Load operations: PREFERENCES_GET, ACTOR_GET, CAPABILITIES_GET. **Mutation operations:** PREFERENCES_SAVE.

Mutation operations: PREFERENCES_SAVE.

Page acceptance: The displayed action calls its exact allowed schema, persists only authorized data, and returns a real saved state after refresh. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### SS07 — Provider security

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/settings/security`.

Load operations: PREFERENCES_GET, ACTOR_GET, CAPABILITIES_GET. **Mutation operations:** SESSION_REVOKE.

Mutation operations: SESSION_REVOKE.

Page acceptance: The displayed action calls its exact allowed schema, persists only authorized data, and returns a real saved state after refresh. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### SS08 — Provider services

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/settings/services`.

Load operations: PREFERENCES_GET, ACTOR_GET, CAPABILITIES_GET, OWN_SERVICES_GET. **Mutation operations:** OWN_SERVICES_SAVE.

Mutation operations: OWN_SERVICES_SAVE.

Page acceptance: The displayed action calls its exact allowed schema, persists only authorized data, and returns a real saved state after refresh. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### SS09 — Provider workspace

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/settings/workspace`.

Load operations: BUSINESS_PROFILE_GET, PREFERENCES_GET, ACTOR_GET. **Mutation operations:** BUSINESS_PROFILE_SAVE, PREFERENCES_SAVE.

Mutation operations: BUSINESS_PROFILE_SAVE, PREFERENCES_SAVE.

Page acceptance: The displayed action calls its exact allowed schema, persists only authorized data, and returns a real saved state after refresh. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### A01 — Accept scoped invitation

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/invitations/:invitationId`.

Load operations: ACTOR_GET, INVITE_GET. **Mutation operations:** INVITE_ACCEPT, INVITE_DECLINE.

Mutation operations: INVITE_ACCEPT, INVITE_DECLINE.

Page acceptance: Two accepts idempotent; revoked/expired invitation creates no grants. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### S19 — SP work claims and FTP findings

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/projects/:projectId/verification`.

Load operations: WORK_CLAIMS_LIST, FIELD_REPORTS_GET, ISSUES_GET, FIELD_REPORT_GET, FTP_REINSPECTIONS_LIST. **Mutation operations:** WORK_CLAIM_CREATE, FTP_REINSPECTION_REQUEST, UPLOAD_CREATE, UPLOAD_CHUNK, UPLOAD_FINALIZE.

Mutation operations: WORK_CLAIM_CREATE, FTP_REINSPECTION_REQUEST, UPLOAD_CREATE, UPLOAD_CHUNK, UPLOAD_FINALIZE.

Page acceptance: Claimed and verified work shown separately; no automatic milestone or payment. Also prove J.3 states, persisted refresh and phone/keyboard operation.

### C20 — Client verified site progress

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/client/projects/:projectId/verification`.

Load operations: WORK_CLAIMS_LIST, FIELD_REPORTS_GET, PROJECT_EVENTS_GET, FIELD_REPORT_GET, FTP_REINSPECTIONS_LIST. **Mutation operations:** None; navigation.

Mutation operations: None; navigation.

Page acceptance: Client can understand actual verification without being asked to manage FTP staffing. Also prove J.3 states, persisted refresh and phone/keyboard operation.

### OD01 — Odin assistant workspace

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/odin`; `/odin/runs/:runId`.

Load operations: ODIN_CAPABILITIES, ODIN_RUNS_LIST, ODIN_RUN_GET, ODIN_INTENT_GET, CANDIDATE_GET, PROJECTS_LIST, CONSENT_GET. **Mutation operations:** ODIN_RUN_CREATE, ODIN_RUN_RESUME, ODIN_RUN_CANCEL, ODIN_INTENT_DECIDE, CANDIDATE_APPLY, CONSENT_DECIDE.

Mutation operations: ODIN_RUN_CREATE, ODIN_RUN_RESUME, ODIN_RUN_CANCEL, ODIN_INTENT_DECIDE, CANDIDATE_APPLY, CONSENT_DECIDE.

Page acceptance: Reopen a real run after app restart; every result links to an actual authorized source. Duplicate confirm yields one domain effect, stale source blocks execution, cancellation does not undo committed action. J.3 state and accessibility cases apply.

### MC01 — Context messages

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/messages`; `/messages/:conversationId`.

Load operations: CONVERSATIONS_LIST, CONVERSATION_GET, MESSAGES_GET, FILE_MANIFEST, FILE_CHUNK. **Mutation operations:** MESSAGE_SEND, UPLOAD_CREATE, UPLOAD_CHUNK, UPLOAD_FINALIZE.

Mutation operations: MESSAGE_SEND, UPLOAD_CREATE, UPLOAD_CHUNK, UPLOAD_FINALIZE.

Page acceptance: Each role opens its allowed exact conversation without needing the first list page; revoked context returns no messages, uploads or private counts. J.3 state and accessibility cases apply.

### S20 — SP fulfillment receipt

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/fulfilment/:requestId`.

Load operations: FULFILMENT_DETAIL, SHIPMENTS_GET, SHIPMENT_GET, FILE_MANIFEST. **Mutation operations:** RECEIPT_CREATE, ASSIGNMENT_OPERATIONS_SAVE, UPLOAD_CREATE, UPLOAD_CHUNK, UPLOAD_FINALIZE.

Mutation operations: RECEIPT_CREATE, ASSIGNMENT_OPERATIONS_SAVE, UPLOAD_CREATE, UPLOAD_CHUNK, UPLOAD_FINALIZE.

Page acceptance: Partial delivery, rejection, second shipment, duplicate retry and concurrent receiver tests reconcile quantities correctly and never double-post inventory. J.3 state and accessibility cases apply.

### SUP02 — Support case detail

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/support/cases/:caseId`.

Load operations: SUPPORT_CASE_GET, CONVERSATION_GET, MESSAGES_GET, FILE_MANIFEST. **Mutation operations:** SUPPORT_CASE_ACTION, MESSAGE_SEND, UPLOAD_CREATE, UPLOAD_CHUNK, UPLOAD_FINALIZE.

Mutation operations: SUPPORT_CASE_ACTION, MESSAGE_SEND, UPLOAD_CREATE, UPLOAD_CHUNK, UPLOAD_FINALIZE.

Page acceptance: Case remains accessible to requester after refresh; unauthorized user denied by exact ID. Resolved support does not mark project completed. J.3 state and accessibility cases apply.

### ST01 — Hive Studio workspace

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/studio`.

Load operations: ACTOR_GET, PROJECTS_LIST, CAPABILITIES_GET, STUDIO_JOBS, ODIN_CAPABILITIES, CANDIDATE_GET. **Mutation operations:** STUDIO_CREATE.

Mutation operations: STUDIO_CREATE.

Page acceptance: Selected project reused, no redundant questions; generated content never autoapproved. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### ST02 — Hive active task / output review

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/studio/jobs/:jobId`.

Load operations: JOB_GET, FILE_MANIFEST, FILE_CHUNK, CANDIDATE_GET, ODIN_RUN_GET. **Mutation operations:** JOB_RETRY, CANDIDATE_APPLY, ODIN_RUN_CANCEL.

Mutation operations: JOB_RETRY, CANDIDATE_APPLY, ODIN_RUN_CANCEL.

Page acceptance: Delayed result cannot overwrite newer source revision; retry reconciles external job. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### ST03 — Hive BOQ drafting tool

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/studio/boq`.

Load operations: BOQ_GET, CAPABILITIES_GET, STUDIO_JOBS. **Mutation operations:** STUDIO_CREATE, BOQ_SAVE.

Mutation operations: STUDIO_CREATE, BOQ_SAVE.

Page acceptance: Invalid generated rows fail strict schema; all applied rows retain source attribution. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### ST04 — Hive plan/image generation placeholder with truthful states

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/studio/generation`.

Load operations: CAPABILITIES_GET, STUDIO_JOBS. **Mutation operations:** STUDIO_CREATE.

Mutation operations: STUDIO_CREATE.

Page acceptance: No credential -> no fake output; incompatible job purpose denied. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### PF01 — Portfolio list and editor

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/portfolio`; `/sp/portfolio/new`.

Load operations: PORTFOLIO_GET, PROJECTS_LIST. **Mutation operations:** PORTFOLIO_SAVE, UPLOAD_CREATE, UPLOAD_CHUNK, UPLOAD_FINALIZE.

Mutation operations: PORTFOLIO_SAVE, UPLOAD_CREATE, UPLOAD_CHUNK, UPLOAD_FINALIZE.

Page acceptance: Withdraw removes public projection while preserving private project evidence. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.

### PF02 — Portfolio detail and publication

- [ ] UI, connected data and actions.
- [ ] Authorization, stale/retry/offline and reload verification.

Routes: `/sp/portfolio/:portfolioId`.

Load operations: PORTFOLIO_GET, PUBLIC_PROFILE_GET. **Mutation operations:** PORTFOLIO_SAVE.

Mutation operations: PORTFOLIO_SAVE.

Page acceptance: Anonymous viewer cannot access private draft through guessed projectId. Also prove J.3 loading/empty/validation/permission/offline/conflict states, real persisted refresh and phone/keyboard operation.
