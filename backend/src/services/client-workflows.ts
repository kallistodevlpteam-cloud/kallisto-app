import { z } from "zod";
import { randomUUID } from "node:crypto";
import type {
  RecordData,
  RecordReader,
  RecordStore,
  RecordTransaction,
} from "../repositories/record-store.js";
import {
  accessSchema,
  projectSchema,
  type Access,
} from "../repositories/client-repository.js";
import { ServiceError } from "./errors.js";
import { ClientSettingsService } from './client-settings.js';
import { ProviderDirectory } from './provider-directory.js';
import { ClientSharing } from './client-sharing.js';
import {
  canonical,
  confirmInput,
  enrollmentInput,
  hash,
  id,
  intakeCreateInput,
  intakeFields,
  manualInput,
  parse,
  prepareInput,
  type Identity,
} from "./client-contracts.js";

const positive = z.number().int().nonnegative();
const sessionSchema = z.object({
  intake_id: id,
  owner_uid: id,
  organization_id: id,
  project_id: id.optional(),
  session_status: z.enum(["active", "paused", "closed", "abandoned"]),
  preferred_mode: z.enum(["text", "voice", "manual"]),
  locale: z.enum(["en", "ml"]),
  draft_revision: positive,
  row_version: positive,
  latest_input_sequence: positive,
  processed_through_sequence: positive,
  pending_input_count: positive,
  prepared_manifest_id: id.optional(),
  question_policy_version: z.string(),
  field_schema_version: z.string(),
  schema_version: z.number(),
  created_at: z.unknown(),
  created_by_uid: z.string(),
  updated_at: z.unknown(),
  updated_by_uid: z.string(),
});
const fieldStateSchema = z.object({
  field_path: z.string(),
  answer_state: z.enum([
    "missing",
    "provided",
    "explicit_unknown",
    "deferred",
    "declined",
  ]),
  value: z.unknown(),
  field_revision: positive,
  source_refs: z.array(z.record(z.string(), z.unknown())),
  evidence_class: z.literal("user_reported"),
});
type FieldState = z.infer<typeof fieldStateSchema>;
const groupsSchema = z.object({
  group_id: z.string(),
  group_revision: positive,
  values: z.record(z.string(), z.unknown()),
  field_states: z.record(z.string(), fieldStateSchema),
  last_input_sequence: positive,
  created_at: z.unknown(),
  created_by_uid: z.string(),
  row_version: positive,
});
type Session = z.infer<typeof sessionSchema>;
type Result = Record<string, string | number | boolean | null>;
const noticeSchema = z.object({
  policy_version: z.string(),
  approved_by_uid: z.string().min(1),
  values: z.object({
    client_enrollment_notice: z.object({
      version: z.string(),
      text: z.string().min(1).max(8000),
    }),
  }),
});

export class ClientWorkflows {
  get sharing() { return new ClientSharing(this.store, (tx,uid)=>this.access(tx,uid),this.providers); }
  get providers() { return new ProviderDirectory(this.store, (tx, uid) => this.access(tx, uid)); }
  get settings() { return new ClientSettingsService(this.store, (tx, uid) => this.access(tx, uid)); }
  constructor(private readonly store: RecordStore) {}
  private envelope(actor: string, row = 1): RecordData {
    return {
      schema_version: 1,
      row_version: row,
      created_at: this.store.timestamp(),
      updated_at: this.store.timestamp(),
      created_by_uid: actor,
      updated_by_uid: actor,
    };
  }
  async access(reader: RecordReader, uid: string): Promise<Access> {
    const record = await reader.get(`user_access/${uid}`);
    const parsed = accessSchema.safeParse(record);
    if (
      !parsed.success ||
      parsed.data.uid !== uid ||
      !parsed.data.active ||
      parsed.data.role !== "client" ||
      !parsed.data.client_id
    )
      throw new ServiceError("CLIENT_ACCESS_REQUIRED", 403);
    return parsed.data;
  }
  private async ownedIntake(
    reader: RecordReader,
    uid: string,
    intakeId: string,
  ): Promise<Session> {
    const record = sessionSchema.safeParse(
      await reader.get(`intake_sessions/${intakeId}`),
    );
    if (
      !record.success ||
      record.data.intake_id !== intakeId ||
      record.data.owner_uid !== uid
    )
      throw new ServiceError("NOT_FOUND", 404);
    return record.data;
  }
  private async ownedProject(
    reader: RecordReader,
    uid: string,
    projectId: string,
  ): Promise<RecordData> {
    const record = await reader.get(`projects/${projectId}`);
    if (!record || record.owner_uid !== uid || record.project_id !== projectId)
      throw new ServiceError("NOT_FOUND", 404);
    return record;
  }
  private async fields(reader: RecordReader, intakeId: string) {
    const groups = (
      await reader.list({
        collection: `intake_sessions/${intakeId}/draft_groups`,
        limit: 20,
      })
    ).map((row) => parse(groupsSchema, row));
    const states: Record<string, FieldState> = {};
    for (const group of groups) Object.assign(states, group.field_states);
    return { groups, states };
  }
  async capabilities() {
    const notice = noticeSchema.safeParse(
      await this.store.get("system_settings/features"),
    );
    return {
      client_enrollment: notice.success,
      enrollment_notice: notice.success
        ? notice.data.values.client_enrollment_notice
        : null,
      manual_intake: true,
      odin_text: false,
      voice: false,
      chat_model: "gemma4:31b",
      agent_model: "nemotron-3-ultra",
    };
  }
  async actor(identity: Identity) {
    return this.store.transaction(async (tx) => {
      const record = await tx.get(`user_access/${identity.uid}`);
      if (!record)
        return {
          uid: identity.uid,
          display_name: "",
          primary_role: null,
          role: null,
          active: true,
          eligible_workspaces: [],
          access_revision: 0,
          allowed_landing_route: "/client/account",
          application_state: "enrollment_required",
          capability_codes: [],
        };
      const access = await this.access(tx, identity.uid);
      const user = await tx.get(`users/${identity.uid}`);
      return {
        uid: identity.uid,
        display_name:
          typeof user?.display_name === "string" ? user.display_name : "",
        primary_role: "client",
        role: "client",
        active: true,
        eligible_workspaces: ["client"],
        acting_organization_id: access.organization_id,
        access_revision: access.access_revision,
        allowed_landing_route: "/client/home",
        capability_codes: ["INTAKE_CREATE", "PROJECTS_LIST"],
      };
    });
  }
  async enroll(
    identity: Identity,
    input: unknown,
    key: string,
  ): Promise<Result> {
    const data = parse(enrollmentInput, input);
    parse(id, key);
    const commandKey = hash([identity.uid, "CLIENT_ENROLL", key]),
      fingerprint = hash(data);
    const clientId = `client_${hash(identity.uid).slice(0, 32)}`,
      organizationId = `org_${hash(identity.uid).slice(0, 32)}`,
      consentId = `consent_${commandKey.slice(0, 32)}`;
    return this.store.transaction(async (tx) => {
      const [existing, previous, policy, user] = await Promise.all([
        tx.get(`user_access/${identity.uid}`),
        tx.get(`idempotency_records/${commandKey}`),
        tx.get("system_settings/features"),
        tx.get(`users/${identity.uid}`),
      ]);
      if (existing && (existing.role !== "client" || existing.active !== true))
        throw new ServiceError("ROLE_CONFLICT", 403);
      if (previous) {
        if (previous.request_hash !== fingerprint)
          throw new ServiceError("IDEMPOTENCY_CONFLICT", 409);
        return parse(
          z.record(
            z.string(),
            z.union([z.string(), z.number(), z.boolean(), z.null()]),
          ),
          previous.result_ref,
        );
      }
      if (existing)
        return {
          client_id: parse(id, existing.client_id),
          resource_id: parse(id, existing.client_id),
        };
      const notice = noticeSchema.safeParse(policy);
      if (
        !notice.success ||
        notice.data.values.client_enrollment_notice.version !==
          data.enrollment_policy_version
      )
        throw new ServiceError("POLICY_UNAVAILABLE", 503);
      const metadata = this.envelope(identity.uid);
      tx.set(`users/${identity.uid}`, {
        ...metadata,
        ...user,
        updated_at: this.store.timestamp(),
        updated_by_uid: identity.uid,
        row_version:
          typeof user?.row_version === "number" ? user.row_version + 1 : 1,
        uid: identity.uid,
        display_name: data.display_name,
        ...(identity.email ? { email: identity.email } : {}),
        preferred_language: data.preferred_language,
        preferred_timezone: data.preferred_timezone,
        profile_status: "active",
      });
      tx.create(`organizations/${organizationId}`, {
        ...metadata,
        organization_id: organizationId,
        organization_kind: "client",
        legal_name: data.organization_display_name ?? data.display_name,
        display_name: data.organization_display_name ?? data.display_name,
        contact: {},
        status: "active",
      });
      tx.create(`clients/${clientId}`, {
        ...metadata,
        client_id: clientId,
        owner_uid: identity.uid,
        organization_id: organizationId,
        client_kind: data.client_kind,
        contact: {},
        consent_record_id: consentId,
      });
      tx.create(`user_access/${identity.uid}`, {
        ...metadata,
        uid: identity.uid,
        role: "client",
        client_id: clientId,
        organization_id: organizationId,
        active: true,
        verified: false,
        access_revision: 1,
      });
      tx.create(`consent_records/${consentId}`, {
        ...metadata,
        consent_id: consentId,
        subject_uid: identity.uid,
        purpose: "enrollment",
        resource_scope: { kind: "user", key: identity.uid },
        policy_version: data.enrollment_policy_version,
        decision: "granted",
        source_interaction_id: key,
      });
      const result = { resource_id: clientId, client_id: clientId };
      tx.create(`idempotency_records/${commandKey}`, {
        ...metadata,
        command_key: commandKey,
        actor_uid: identity.uid,
        operation: "CLIENT_ENROLL",
        resource_key: identity.uid,
        request_hash: fingerprint,
        status: "committed",
        result_ref: result,
        created_resource_ids: [clientId, organizationId],
      });
      return result;
    });
  }
  private async command(
    uid: string,
    operation: string,
    resource: string,
    key: string,
    payload: unknown,
    authorize: (tx: RecordTransaction) => Promise<void>,
    work: (tx: RecordTransaction, actor: Access) => Promise<Result>,
  ): Promise<Result> {
    parse(id, key);
    const commandKey = hash([uid, operation, resource, key]),
      requestHash = hash(payload);
    return this.store.transaction(async (tx) => {
      const actor = await this.access(tx, uid);
      await authorize(tx);
      const prior = await tx.get(`idempotency_records/${commandKey}`);
      if (prior) {
        if (prior.request_hash !== requestHash)
          throw new ServiceError("IDEMPOTENCY_CONFLICT", 409);
        return parse(
          z.record(
            z.string(),
            z.union([z.string(), z.number(), z.boolean(), z.null()]),
          ),
          prior.result_ref,
        );
      }
      const result = await work(tx, actor);
      tx.create(`idempotency_records/${commandKey}`, {
        ...this.envelope(uid),
        command_key: commandKey,
        actor_uid: uid,
        operation,
        resource_key: resource,
        request_hash: requestHash,
        status: "committed",
        result_ref: result,
        created_resource_ids: [],
      });
      return result;
    });
  }
  async createIntake(uid: string, input: unknown, key: string) {
    const data = parse(intakeCreateInput, input);
    const intakeId = randomUUID();
    return this.command(
      uid,
      "INTAKE_CREATE",
      "new",
      key,
      data,
      async () => {},
      async (tx, actor) => {
        tx.create(`intake_sessions/${intakeId}`, {
          ...this.envelope(uid),
          intake_id: intakeId,
          owner_uid: uid,
          organization_id: actor.organization_id,
          ...data,
          session_status: "active",
          draft_revision: 0,
          latest_input_sequence: 0,
          processed_through_sequence: 0,
          pending_input_count: 0,
          question_policy_version: "intake.v1",
          field_schema_version: "intake.v1",
        });
        return {
          resource_id: intakeId,
          intake_id: intakeId,
          row_version: 1,
          draft_revision: 0,
        };
      },
    );
  }
  async listIntakes(uid: string, cursor?: string) {
    return this.store.transaction(async (tx) => {
      await this.access(tx, uid);
      const rows = await tx.list({
        collection: "intake_sessions",
        filters: [["owner_uid", uid]],
        cursor,
        limit: 21,
      });
      const items = rows.slice(0, 20).map((row) => parse(sessionSchema, row));
      return {
        items,
        next_cursor: rows.length > 20 ? items.at(-1)!.intake_id : null,
        has_more: rows.length > 20,
      };
    });
  }
  async intake(uid: string, intakeId: string) {
    return this.store.transaction(async (tx) => {
      await this.access(tx, uid);
      const session = await this.ownedIntake(tx, uid, intakeId);
      const { states } = await this.fields(tx, intakeId);
      const inputs = await tx.list({
        collection: `intake_sessions/${intakeId}/inputs`,
        limit: 251,
      });
      const refs = inputs.map((row) => ({
        input_id: row.input_id,
        source_version: 1,
        source_kind: row.kind,
        locator: "whole_input",
        source_hash: row.source_hash,
      }));
      const values = Object.fromEntries(
        Object.entries(states)
          .filter(([, s]) => s.answer_state === "provided")
          .map(([path, s]) => [path, s.value]),
      );
      return {
        ...session,
        groups: values,
        field_states: states,
        conflicts: [],
        readiness: {
          ready:
            !!values["brief.project.name"] &&
            !!values["brief.project.project_type"],
          missing_fields: [
            "brief.project.name",
            "brief.project.project_type",
          ].filter((p) => !values[p]),
        },
        input_refs: refs,
        jobs: [],
        allowed_actions:
          session.session_status === "active"
            ? ["INTAKE_INPUT", "INTAKE_PREPARE", "INTAKE_PAUSE"]
            : session.session_status === "paused"
              ? ["INTAKE_RESUME"]
              : [],
      };
    });
  }
  async changeIntakeStatus(
    uid: string,
    intakeId: string,
    input: unknown,
    key: string,
    next: "active" | "paused",
  ) {
    const data = parse(
      z.strictObject({
        expected_version: z.number().int().positive(),
        pause_reason:
          next === "paused"
            ? z.string().trim().max(1000).optional()
            : z.never().optional(),
      }),
      input,
    );
    return this.command(
      uid,
      next === "paused" ? "INTAKE_PAUSE" : "INTAKE_RESUME",
      intakeId,
      key,
      data,
      async (tx) => {
        await this.ownedIntake(tx, uid, intakeId);
      },
      async (tx) => {
        const session = await this.ownedIntake(tx, uid, intakeId);
        if (session.row_version !== data.expected_version)
          throw new ServiceError("STALE_VERSION", 409);
        if (
          session.session_status !== (next === "paused" ? "active" : "paused")
        )
          throw new ServiceError("INVALID_TRANSITION", 409);
        tx.set(`intake_sessions/${intakeId}`, {
          ...session,
          session_status: next,
          row_version: session.row_version + 1,
          updated_by_uid: uid,
          updated_at: this.store.timestamp(),
          ...(next === "paused" && data.pause_reason
            ? { pause_reason: data.pause_reason }
            : {}),
        });
        return {
          resource_id: intakeId,
          intake_id: intakeId,
          row_version: session.row_version + 1,
        };
      },
    );
  }
  async input(uid: string, intakeId: string, input: unknown, key: string) {
    const data = parse(manualInput, input);
    const seen = new Set<string>();
    for (const op of data.manual_operations) {
      const schema = intakeFields[op.field_path];
      if (
        !Object.hasOwn(intakeFields, op.field_path) ||
        !schema ||
        seen.has(op.field_path) ||
        (op.op !== "set" && op.value !== undefined)
      )
        throw new ServiceError("VALIDATION_ERROR", 422);
      seen.add(op.field_path);
      if (op.op === "set") parse(schema, op.value);
    }
    return this.command(
      uid,
      "INTAKE_INPUT",
      intakeId,
      key,
      data,
      async (tx) => {
        await this.ownedIntake(tx, uid, intakeId);
      },
      async (tx) => {
        const session = await this.ownedIntake(tx, uid, intakeId);
        const inputId = hash([intakeId, data.client_input_id]).slice(0, 40),
          inputPath = `intake_sessions/${intakeId}/inputs/${inputId}`;
        const prior = await tx.get(inputPath);
        if (prior) {
          if (prior.source_hash !== hash(data))
            throw new ServiceError("IDEMPOTENCY_CONFLICT", 409);
          return {
            resource_id: intakeId,
            intake_id: intakeId,
            input_id: inputId,
            draft_revision: session.draft_revision,
          };
        }
        if (session.session_status !== "active")
          throw new ServiceError("INVALID_TRANSITION", 409);
        if (session.draft_revision !== data.expected_revision)
          throw new ServiceError("STALE_VERSION", 409);
        if (session.latest_input_sequence >= 250)
          throw new ServiceError("INTAKE_INPUT_LIMIT", 429);
        const { groups, states } = await this.fields(tx, intakeId),
          sequence = session.latest_input_sequence + 1;
        const source = {
          input_id: inputId,
          source_version: 1,
          source_kind: "manual",
          locator: "whole_input",
          source_hash: hash(data),
        };
        for (const op of data.manual_operations) {
          const previous = states[op.field_path];
          if ((previous?.field_revision ?? 0) !== op.expected_field_revision)
            throw new ServiceError("STALE_VERSION", 409);
          const answerState = (
            {
              set: "provided",
              clear: "missing",
              mark_unknown: "explicit_unknown",
              defer: "deferred",
              decline: "declined",
            } as const
          )[op.op];
          states[op.field_path] = {
            field_path: op.field_path,
            answer_state: answerState,
            value:
              op.op === "set"
                ? parse(intakeFields[op.field_path]!, op.value)
                : null,
            field_revision: op.expected_field_revision + 1,
            source_refs: [source],
            evidence_class: "user_reported",
          };
        }
        this.checkConsistency(states);
        if (Buffer.byteLength(canonical(states), "utf8") > 128 * 1024)
          throw new ServiceError("BRIEF_SIZE_LIMIT", 422);
        const metadata = this.envelope(uid);
        tx.create(inputPath, {
          ...metadata,
          input_id: inputId,
          actor_uid: uid,
          client_input_id: data.client_input_id,
          sequence,
          kind: "manual",
          manual_operations: data.manual_operations,
          source_hash: hash(data),
        });
        for (const groupId of new Set(
          data.manual_operations.map((op) => op.field_path.split(".")[1]!),
        )) {
          const previous = groups.find((g) => g.group_id === groupId);
          const fields = Object.fromEntries(
            Object.entries(states).filter(
              ([path]) => path.split(".")[1] === groupId,
            ),
          );
          tx.set(`intake_sessions/${intakeId}/draft_groups/${groupId}`, {
            ...metadata,
            ...(previous
              ? {
                  created_at: previous.created_at,
                  created_by_uid: previous.created_by_uid,
                }
              : {}),
            row_version: (previous?.row_version ?? 0) + 1,
            group_id: groupId,
            group_revision: (previous?.group_revision ?? 0) + 1,
            values: Object.fromEntries(
              Object.entries(fields)
                .filter(([, s]) => s.answer_state === "provided")
                .map(([path, s]) => [path, s.value]),
            ),
            field_states: fields,
            last_input_sequence: sequence,
          });
        }
        tx.create(`intake_sessions/${intakeId}/revisions/${inputId}`, {
          ...metadata,
          revision_id: inputId,
          input_id: inputId,
          draft_revision: session.draft_revision + 1,
          accepted_operations: data.manual_operations,
        });
        tx.set(`intake_sessions/${intakeId}`, {
          ...session,
          updated_at: this.store.timestamp(),
          updated_by_uid: uid,
          row_version: session.row_version + 1,
          draft_revision: session.draft_revision + 1,
          latest_input_sequence: sequence,
          processed_through_sequence: sequence,
        });
        return {
          resource_id: intakeId,
          intake_id: intakeId,
          input_id: inputId,
          draft_revision: session.draft_revision + 1,
        };
      },
    );
  }
  private checkConsistency(states: Record<string, FieldState>) {
    const value = (key: string) =>
      states[key]?.answer_state === "provided" ? states[key]?.value : undefined;
    for (const [subset, total] of [
      [
        "brief.spaces.bedrooms.ground_floor_count",
        "brief.spaces.bedrooms.total",
      ],
      ["brief.spaces.bathrooms.attached_count", "brief.spaces.bathrooms.total"],
      ["brief.budget.minimum_minor", "brief.budget.maximum_minor"],
    ]) {
      const a = value(subset!),
        b = value(total!);
      if (typeof a === "number" && typeof b === "number" && a > b)
        throw new ServiceError("INCONSISTENT_FIELDS", 422);
    }
    for (const path of [
      "target_minor",
      "minimum_minor",
      "maximum_minor",
      "hard_cap_minor",
    ])
      if (
        value(`brief.budget.${path}`) !== undefined &&
        value("brief.budget.currency") !== "INR"
      )
        throw new ServiceError("BUDGET_CURRENCY_REQUIRED", 422);
  }
  async prepare(uid: string, intakeId: string, input: unknown, key: string) {
    const data = parse(prepareInput, input);
    return this.command(
      uid,
      "INTAKE_PREPARE",
      intakeId,
      key,
      data,
      async (tx) => {
        await this.ownedIntake(tx, uid, intakeId);
      },
      async (tx, actor): Promise<Result> => {
        const session = await this.ownedIntake(tx, uid, intakeId);
        if (session.session_status !== "active")
          throw new ServiceError("INVALID_TRANSITION", 409);
        if (
          session.draft_revision !== data.expected_draft_revision ||
          session.pending_input_count !== 0
        )
          throw new ServiceError("STALE_VERSION", 409);
        const manifestId = hash([intakeId, session.draft_revision]).slice(
          0,
          40,
        );
        const [previous, fields, inputs] = await Promise.all([
          tx.get(`prepared_briefs/${manifestId}`),
          this.fields(tx, intakeId),
          tx.list({
            collection: `intake_sessions/${intakeId}/inputs`,
            limit: 251,
          }),
        ]);
        const refs = inputs
          .map((row) => ({
            input_id: row.input_id,
            source_version: 1,
            source_kind: row.kind,
            locator: "whole_input",
            source_hash: row.source_hash,
          }))
          .sort((a, b) => String(a.input_id).localeCompare(String(b.input_id)));
        const actualRefs = [...data.included_input_refs].sort((a, b) =>
          a.input_id.localeCompare(b.input_id),
        );
        if (hash(refs) !== hash(actualRefs))
          throw new ServiceError("SOURCE_MANIFEST_MISMATCH", 409);
        if (previous)
          return {
            resource_id: parse(id, previous.project_id),
            project_id: parse(id, previous.project_id),
            version_id: parse(id, previous.requirement_version_id),
            content_hash: parse(z.string(), previous.requirement_content_hash),
          };
        const values = Object.fromEntries(
          Object.entries(fields.states)
            .filter(([, s]) => s.answer_state === "provided")
            .map(([path, s]) => [path, s.value]),
        );
        const accepted = parse(
          z.object({
            name: z.string().min(1).max(120),
            project_type: z.enum([
              "architecture",
              "interior",
              "construction",
              "renovation",
              "other",
            ]),
          }),
          data.accepted_project_identity ?? {
            name: values["brief.project.name"],
            project_type: values["brief.project.project_type"],
          },
        );
        if (
          accepted.name !== values["brief.project.name"] ||
          accepted.project_type !== values["brief.project.project_type"]
        )
          throw new ServiceError("IDENTITY_REVIEW_REQUIRED", 409);
        const projectId =
            session.project_id ?? `project_${hash(intakeId).slice(0, 32)}`,
          requirementId = `requirement_${hash(projectId).slice(0, 32)}`;
        const [project, root, policies] = await Promise.all([
          tx.get(`projects/${projectId}`),
          tx.get(`requirements/${requirementId}`),
          tx.list({
            collection: "lifecycle_policies",
            filters: [
              ["project_type", accepted.project_type],
              ["status", "published"],
            ],
            limit: 2,
          }),
        ]);
        if (project && project.owner_uid !== uid)
          throw new ServiceError("NOT_FOUND", 404);
        const number =
          typeof root?.latest_version_number === "number"
            ? root.latest_version_number + 1
            : 1;
        const versionId = `brief_${manifestId}`,
          metadata = this.envelope(uid);
        const content = {
          title: accepted.name,
          original_text: "",
          priorities: [],
          services: values["brief.scope.requested_services"] ?? [],
          details: values,
          field_states: fields.states,
        };
        const contentHash = hash(content);
        // A policy is usable only when one explicit approved published version exists.
        // Ambiguous or absent policy leaves the project in requirements with a blocked gate.
        const policy =
          policies.length === 1 && policies[0]?.approval_ref
            ? policies[0]
            : null;
        const policyRef =
          project?.lifecycle_policy_ref ??
          (policy ? { id: policy._id, version: policy._id } : null);
        tx.create(`requirement_versions/${versionId}`, {
          ...metadata,
          version_id: versionId,
          requirement_id: requirementId,
          project_id: projectId,
          version_number: number,
          ...(root?.current_version_id
            ? { previous_version_id: root.current_version_id }
            : {}),
          content,
          source: "intake_v1",
          source_manifest_ref: manifestId,
          content_hash: contentHash,
          intake_schema_version: "intake.v1",
          requirement_policy_version: "intake.v1",
        });
        tx.set(`requirements/${requirementId}`, {
          ...metadata,
          ...root,
          updated_at: this.store.timestamp(),
          updated_by_uid: uid,
          row_version:
            typeof root?.row_version === "number" ? root.row_version + 1 : 1,
          requirement_id: requirementId,
          project_id: projectId,
          owner_uid: uid,
          current_version_id: versionId,
          latest_version_number: number,
        });
        tx.set(`projects/${projectId}`, {
          ...metadata,
          ...project,
          updated_at: this.store.timestamp(),
          updated_by_uid: uid,
          row_version:
            typeof project?.row_version === "number"
              ? project.row_version + 1
              : 1,
          project_id: projectId,
          owner_uid: uid,
          client_id: actor.client_id,
          organization_id: actor.organization_id,
          ...accepted,
          currency: "INR",
          status: project?.status ?? "draft",
          phase: project?.phase ?? "requirements",
          requirement_id: requirementId,
          current_requirement_version_id: versionId,
          active_intake_session_id: intakeId,
          location: values["brief.site.location.locality"] ?? null,
          lifecycle_policy_ref: policyRef,
          lifecycle_gate: policyRef ? null : "POLICY_UNAVAILABLE",
        });
        if (!project) {
          const memberId = hash([projectId, uid]);
          tx.create(`project_members/${memberId}`, {
            ...metadata,
            project_member_id: memberId,
            project_id: projectId,
            uid,
            role: "client_owner",
            active_roles: ["client_owner"],
            active: true,
            module_grants: ["overview", "requirements"],
            capability_grant_ids: [],
            source_deal_ids: [],
            source_ftp_assignment_ids: [],
            retained_read_source_ids: [],
            access_revision: 1,
          });
        }
        tx.create(`prepared_briefs/${manifestId}`, {
          ...metadata,
          manifest_id: manifestId,
          intake_id: intakeId,
          owner_uid: uid,
          project_id: projectId,
          requirement_version_id: versionId,
          source_draft_revision: session.draft_revision,
          included_input_refs: refs,
          field_snapshot_hash: hash(fields.states),
          requirement_content_hash: contentHash,
          policy_refs: [],
        });
        tx.set(`intake_sessions/${intakeId}`, {
          ...session,
          updated_at: this.store.timestamp(),
          updated_by_uid: uid,
          row_version: session.row_version + 1,
          project_id: projectId,
          prepared_manifest_id: manifestId,
        });
        tx.create(`domain_events/${manifestId}`, {
          ...metadata,
          event_id: manifestId,
          event_type: "requirements.prepared",
          aggregate_type: "requirements",
          aggregate_id: requirementId,
          aggregate_version: number,
          project_id: projectId,
          actor_uid: uid,
          correlation_id: key,
          payload: { version_id: versionId },
        });
        return {
          resource_id: projectId,
          project_id: projectId,
          requirement_id: requirementId,
          version_id: versionId,
          content_hash: contentHash,
          version_number: number,
        };
      },
    );
  }
  async project(uid: string, projectId: string) {
    return this.store.transaction(async (tx) => {
      await this.access(tx, uid);
      const data = await this.ownedProject(tx, uid, projectId);
      return {
        ...parse(projectSchema, data),
        row_version: data.row_version,
        requirement_id: data.requirement_id,
        current_requirement_version_id: data.current_requirement_version_id,
        confirmed_requirement_version_id:
          data.confirmed_requirement_version_id ?? null,
        active_intake_session_id: data.active_intake_session_id ?? null,
        visible_modules: ["overview", "requirements"],
        allowed_actions: [],
        lifecycle_gate: data.lifecycle_gate ?? null,
      };
    });
  }
  async requirements(uid: string, projectId: string, versionId?: string) {
    return this.store.transaction(async (tx) => {
      await this.access(tx, uid);
      const project = await this.ownedProject(tx, uid, projectId);
      const root = await tx.get(
        `requirements/${parse(id, project.requirement_id)}`,
      );
      const version = await tx.get(
        `requirement_versions/${versionId ?? parse(id, root?.current_version_id)}`,
      );
      if (!root || !version || version.project_id !== projectId)
        throw new ServiceError("NOT_FOUND", 404);
      return {
        requirement_id: root.requirement_id,
        version_id: version.version_id,
        content_hash: version.content_hash,
        version_number: version.version_number,
        content: version.content,
        confirmation_state:
          root.confirmed_version_id === version.version_id
            ? "confirmed"
            : "unconfirmed",
        expected_requirement_version: root.row_version,
        allowed_actions:
          root.current_version_id === version.version_id &&
          root.confirmed_version_id !== version.version_id
            ? ["REQUIREMENTS_CONFIRM"]
            : [],
      };
    });
  }
  async confirm(uid: string, projectId: string, input: unknown, key: string) {
    const data = parse(confirmInput, input);
    return this.command(
      uid,
      "REQUIREMENTS_CONFIRM",
      projectId,
      key,
      data,
      async (tx) => {
        await this.ownedProject(tx, uid, projectId);
      },
      async (tx) => {
        const project = await this.ownedProject(tx, uid, projectId),
          requirementId = parse(id, project.requirement_id);
        const [root, version] = await Promise.all([
          tx.get(`requirements/${requirementId}`),
          tx.get(`requirement_versions/${data.version_id}`),
        ]);
        if (
          !root ||
          !version ||
          version.project_id !== projectId ||
          version.content_hash !== data.content_hash ||
          root.current_version_id !== data.version_id
        )
          throw new ServiceError("STALE_VERSION", 409);
        if (root.confirmed_version_id === data.version_id)
          return {
            resource_id: projectId,
            project_id: projectId,
            version_id: data.version_id,
            confirmation_id: parse(id, root.confirmation_id),
          };
        if (root.row_version !== data.expected_requirement_version)
          throw new ServiceError("STALE_VERSION", 409);
        const confirmationId = `confirm_${hash([projectId, data.version_id]).slice(0, 32)}`,
          metadata = this.envelope(uid);
        tx.create(`approvals/${confirmationId}`, {
          ...metadata,
          approval_id: confirmationId,
          project_id: projectId,
          resource: {
            resource_type: "requirements",
            resource_id: requirementId,
            version_id: data.version_id,
            content_hash: data.content_hash,
          },
          actor_uid: uid,
          acting_capability: "requirements.confirm",
          decision: "confirmed",
          evidence_refs: [],
          policy_ref: { id: "intake", version: "intake.v1" },
          explicit_confirmation: true,
        });
        tx.set(`requirements/${requirementId}`, {
          ...root,
          row_version: data.expected_requirement_version + 1,
          updated_at: this.store.timestamp(),
          confirmed_version_id: data.version_id,
          confirmation_id: confirmationId,
        });
        tx.set(`projects/${projectId}`, {
          ...project,
          row_version: Number(project.row_version) + 1,
          updated_at: this.store.timestamp(),
          confirmed_requirement_version_id: data.version_id,
        });
        tx.create(`domain_events/${confirmationId}`, {
          ...metadata,
          event_id: confirmationId,
          event_type: "requirements.confirmed",
          aggregate_type: "requirements",
          aggregate_id: requirementId,
          aggregate_version: data.expected_requirement_version + 1,
          project_id: projectId,
          actor_uid: uid,
          correlation_id: key,
          payload: { version_id: data.version_id },
        });
        return {
          resource_id: projectId,
          project_id: projectId,
          version_id: data.version_id,
          confirmation_id: confirmationId,
        };
      },
    );
  }
}
