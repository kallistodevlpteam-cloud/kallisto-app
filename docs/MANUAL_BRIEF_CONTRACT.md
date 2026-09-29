# Manual brief contract implementation

Appendix E's 77 semantic paths are registered in `backend/src/services/client-contracts.ts` and represented in `lib/client/intake_fields.dart`. The contract tests compare both registries with the master specification. Fields remain optional at capture; project preparation still requires identity and review prerequisites.

- Measurements preserve a decimal string, original area unit and stated precision. They are never interchanged with plot or existing-building areas.
- Date preferences use a closed tagged union: `date`/`month` with `value` and `raw_phrase`; `date_range` with `start`, `end`, `raw_phrase`; `relative_duration` with `raw_phrase`, `reference_date`, `timezone`. No relative phrase is silently converted to a deadline.
- Structured arrays use stable `entry_id` values. Editing retains the ID; removing an entry changes only the working draft. Original input records and prior requirement versions remain immutable.
- Existing professionals contain supplied name/role and optional contact/notes; future expansion contains description and optional original timing text; site conditions contain user observations. These never establish verification or membership.
- Additional spaces retain category, label, present/future/alternative scope and optional count/notes. Design priorities have optional user-supplied rank. No automatic ordering is manufactured.
- Reported service observations use bounded optional water/power/drainage/internet/gas entries. Missing observations remain absent. Reported approvals contain a statement and optional reported approver; no approval record is created.
- Manually described space/item references contain entry ID, label, existing/proposed, optional notes and an empty nested source-ref list; the trusted intake command attaches actual input provenance. Arbitrary platform record references and fabricated source refs are rejected.
- Design links are labeled HTTPS references with no URL credentials. The service stores the reference metadata and does not fetch or execute the URL.
- Attachment references cannot be supplied through manual patches. The upload service must establish bytes, ownership, hash and ready state. That service remains unfinished; the client clearly exposes its unavailable state.

The main intake command retains allowlisted field paths, expected draft/field revisions, immutable input provenance, retry deduplication, bounded groups and exact requirement confirmation. This implements manual capture; model extraction and transcript adoption still need separate reviewable candidate workflows.
