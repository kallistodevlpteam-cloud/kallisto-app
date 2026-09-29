import { createHash } from "node:crypto";
import { z } from "zod";
import { ServiceError } from "./errors.js";

export const id = z.string().regex(/^[a-zA-Z0-9_-]{1,128}$/);
export const projectType = z.enum([
  "architecture",
  "interior",
  "construction",
  "renovation",
  "other",
]);
const text = (max: number) => z.string().trim().min(1).max(max);
const count = z.number().int().min(0).max(1_000_000);
const money = z.number().int().min(0).max(Number.MAX_SAFE_INTEGER);
const list = z.array(text(1000)).max(50);
const services = z
  .array(
    z.enum([
      "architectural_design",
      "interior_design",
      "construction_coordination",
      "construction_execution",
      "renovation",
      "other",
    ]),
  )
  .max(6);
const measurement = z.strictObject({
  value: z.string().regex(/^\d{1,12}(\.\d{1,6})?$/),
  unit: z.enum(["sq_ft", "sq_m", "cent", "acre"]),
  precision: z.enum(["stated_exact", "approximate"]),
});

const calendarDate = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/)
  .refine((v) => {
    const d = new Date(`${v}T00:00:00Z`);
    return !isNaN(d.getTime()) && d.toISOString().slice(0, 10) === v;
  });
const datePreference = z.discriminatedUnion("kind", [
  z.strictObject({
    kind: z.literal("date"),
    value: calendarDate,
    raw_phrase: text(500),
  }),
  z.strictObject({
    kind: z.literal("month"),
    value: z.string().regex(/^\d{4}-(0[1-9]|1[0-2])$/),
    raw_phrase: text(500),
  }),
  z
    .strictObject({
      kind: z.literal("date_range"),
      start: calendarDate,
      end: calendarDate,
      raw_phrase: text(500),
    })
    .refine((v) => v.start <= v.end),
  z.strictObject({
    kind: z.literal("relative_duration"),
    raw_phrase: text(500),
    reference_date: calendarDate,
    timezone: text(80).refine((v) => {
      try {
        new Intl.DateTimeFormat("en", { timeZone: v });
        return true;
      } catch {
        return false;
      }
    }),
  }),
]);

const entries = <T extends z.ZodType>(schema: T) =>
  z
    .array(schema)
    .max(30)
    .refine(
      (rows) =>
        new Set(rows.map((r) => (r as { entry_id: string }).entry_id)).size ===
        rows.length,
    );
const localReference = z.strictObject({
  entry_id: id,
  label: text(240),
  existing_or_proposed: z.enum(["existing", "proposed"]),
  notes: text(1000).optional(),
  source_refs: z.array(z.never()).length(0),
});

/** Closed Appendix E dictionary. No dot-path writes are performed from these names. */
export const intakeFields: Record<string, z.ZodType> = {
  "brief.scope.existing_professional_refs": entries(
    z.strictObject({
      entry_id: id,
      name: text(120),
      role: text(120),
      contact: text(240).optional(),
      notes: text(1000).optional(),
    }),
  ),
  "brief.building.future_expansion": entries(
    z.strictObject({
      entry_id: id,
      description: text(1000),
      timing: text(240).optional(),
    }),
  ),
  "brief.site.reported_conditions": entries(
    z.strictObject({ entry_id: id, observation: text(1000) }),
  ),
  "brief.site.reported_service_availability": z
    .strictObject({
      water: text(500).optional(),
      power: text(500).optional(),
      drainage: text(500).optional(),
      internet: text(500).optional(),
      gas: text(500).optional(),
    })
    .refine((v) => Object.keys(v).length > 0),
  "brief.spaces.additional_spaces": entries(
    z.strictObject({
      entry_id: id,
      label: text(240),
      category: text(120),
      scope: z.enum(["present", "future", "alternative"]),
      count: count.optional(),
      notes: text(1000).optional(),
    }),
  ),
  "brief.design.priorities": entries(
    z.strictObject({
      entry_id: id,
      label: text(240),
      rank: z.number().int().min(1).max(100).optional(),
    }),
  ),
  "brief.design.reference_refs": entries(
    z.strictObject({
      entry_id: id,
      label: text(240),
      url: z
        .url()
        .max(2000)
        .refine((v) => {
          const u = new URL(v);
          return u.protocol === "https:" && !u.username && !u.password;
        }),
    }),
  ),
  // Bytes and ownership are established only by the protected upload service.
  "brief.documents.attachment_refs": z.array(z.never()).length(0),
  "brief.documents.reported_approval_status": entries(
    z.strictObject({
      entry_id: id,
      statement: text(1000),
      reported_by: text(240).optional(),
    }),
  ),
  "brief.renovation.target_areas": entries(localReference),
  "brief.interior.reuse_items": entries(localReference),
  "brief.project.name": text(120),
  "brief.project.project_type": projectType,
  "brief.scope.work_nature": z.enum([
    "new_build",
    "interior_fitout",
    "renovation",
    "extension",
    "maintenance",
    "other",
  ]),
  "brief.scope.requested_services": services,
  "brief.scope.description": text(2000),
  "brief.scope.exclusions": list,
  "brief.scope.reported_current_stage": text(240),
  "brief.building.use": z.enum([
    "residential",
    "commercial",
    "mixed_use",
    "other",
  ]),
  "brief.building.target_built_up_area": measurement,
  "brief.building.floor_count_including_ground": count,
  "brief.building.basement_levels": count,
  "brief.site.tenure_status": z.enum([
    "owned",
    "rented",
    "permission_reported",
    "selecting",
    "other",
  ]),
  "brief.site.client_authority_status": z.enum([
    "reported_authorized",
    "needs_confirmation",
    "unknown",
  ]),
  "brief.site.plot_area": measurement,
  "brief.site.location.locality": text(240),
  "brief.site.location.district": text(120),
  "brief.site.location.state": text(120),
  "brief.site.location.country": z.string().regex(/^[A-Z]{2}$/),
  "brief.site.location.address": text(1000),
  "brief.site.location.site_pin": z.strictObject({
    latitude: z.number().min(-90).max(90),
    longitude: z.number().min(-180).max(180),
    source: z.enum(["user_selected", "user_shared"]),
    accuracy_meters: z.number().nonnegative().optional(),
  }),
  "brief.site.access_constraints": list,
  "brief.spaces.bedrooms.total": count,
  "brief.spaces.bedrooms.ground_floor_count": count,
  "brief.spaces.bathrooms.total": count,
  "brief.spaces.bathrooms.attached_count": count,
  "brief.spaces.kitchen.preferences": list,
  "brief.spaces.utility_area_required": z.boolean(),
  "brief.spaces.parking.vehicle_count": count,
  "brief.spaces.parking.covered_required": z.boolean(),
  "brief.design.style_preferences": list,
  "brief.design.environmental_preferences": list,
  "brief.household.occupant_count": count,
  "brief.household.functional_needs": list,
  "brief.household.accessibility_preferences": list,
  "brief.budget.currency": z.literal("INR"),
  "brief.budget.target_minor": money,
  "brief.budget.minimum_minor": money,
  "brief.budget.maximum_minor": money,
  "brief.budget.hard_cap_minor": money,
  "brief.budget.amount_qualifier": z.enum([
    "approximate",
    "stated_exact",
    "range",
    "undecided",
  ]),
  "brief.budget.scope": text(1000),
  "brief.budget.included_components": z
    .array(
      z.enum([
        "construction",
        "interiors",
        "professional_fees",
        "land",
        "other",
      ]),
    )
    .max(5),
  "brief.budget.excluded_components": z
    .array(
      z.enum([
        "construction",
        "interiors",
        "professional_fees",
        "land",
        "other",
      ]),
    )
    .max(5),
  "brief.budget.flexibility": z.enum([
    "flexible_target",
    "preferred_range",
    "firm_maximum",
    "undecided",
  ]),
  "brief.timing.start_preference": datePreference,
  "brief.timing.completion_preference": datePreference,
  "brief.interior.possession_preference": datePreference,
  "brief.timing.deadline_reason": text(1000),
  "brief.documents.reported_available_types": z
    .array(z.enum(["survey", "drawing", "estimate", "reference", "other"]))
    .max(5),
  "brief.constraints.must_keep": list,
  "brief.constraints.must_avoid": list,
  "brief.constraints.additional_notes": text(8000),
  "brief.existing_building.area": measurement,
  "brief.existing_building.approximate_age_years": z
    .string()
    .regex(/^\d{1,4}(\.\d{1,2})?$/),
  "brief.existing_building.reported_structure": text(1000),
  "brief.renovation.intervention_intent": list,
  "brief.renovation.occupied_during_work": z.boolean(),
  "brief.renovation.work_time_constraints": list,
  "brief.renovation.structural_change_intent": z.enum([
    "proposed",
    "not_proposed",
    "unsure",
  ]),
  "brief.interior.access_constraints": list,
  "brief.interior.fitout_scope": list,
  "brief.commercial.intended_use": text(1000),
  "brief.commercial.expected_occupancy": count,
  "brief.commercial.operational_requirements": list,
  "brief.communication.preferred_language": z.enum(["en", "ml"]),
  "brief.communication.preferred_mode": z.enum(["text", "voice", "manual"]),
};

export const enrollmentInput = z
  .strictObject({
    display_name: text(120),
    client_kind: z.enum(["person", "organization"]),
    organization_display_name: text(120).optional(),
    preferred_language: z.enum(["en", "ml"]),
    preferred_timezone: z
      .string()
      .max(80)
      .refine((value) => {
        try {
          new Intl.DateTimeFormat("en", { timeZone: value });
          return true;
        } catch {
          return false;
        }
      }),
    enrollment_policy_version: text(120),
    explicit_confirmation: z.literal(true),
  })
  .refine(
    (value) =>
      value.client_kind !== "organization" || !!value.organization_display_name,
  );
export const intakeCreateInput = z.strictObject({
  locale: z.enum(["en", "ml"]),
  preferred_mode: z.enum(["text", "voice", "manual"]),
});
export const operationSchema = z.strictObject({
  op: z.enum(["set", "clear", "mark_unknown", "defer", "decline"]),
  field_path: text(120),
  value: z.unknown().optional(),
  expected_field_revision: z.number().int().nonnegative(),
});
export const manualInput = z.strictObject({
  expected_revision: z.number().int().nonnegative(),
  client_input_id: id,
  kind: z.literal("manual"),
  manual_operations: z.array(operationSchema).min(1).max(80),
});
export const sourceRef = z.strictObject({
  input_id: id,
  source_version: z.number().int().positive(),
  source_kind: z.literal("manual"),
  locator: z.literal("whole_input"),
  source_hash: z.string().regex(/^[a-f0-9]{64}$/),
});
export const prepareInput = z.strictObject({
  expected_draft_revision: z.number().int().nonnegative(),
  included_input_refs: z.array(sourceRef).max(250),
  excluded_input_ids: z.array(id).length(0),
  accepted_project_identity: z
    .strictObject({ name: text(120), project_type: projectType })
    .optional(),
});
export const confirmInput = z.strictObject({
  version_id: id,
  content_hash: z.string().regex(/^[a-f0-9]{64}$/),
  expected_requirement_version: z.number().int().positive(),
  explicit_confirmation: z.literal(true),
});
export type ManualInput = z.infer<typeof manualInput>;
export interface Identity {
  uid: string;
  email?: string;
  emailVerified: boolean;
}

export function parse<T>(schema: z.ZodType<T>, input: unknown): T {
  const result = schema.safeParse(input);
  if (!result.success) throw new ServiceError("VALIDATION_ERROR", 422);
  return result.data;
}
export function canonical(value: unknown): string {
  if (Array.isArray(value)) return "[" + value.map(canonical).join(",") + "]";
  if (value !== null && typeof value === "object")
    return (
      "{" +
      Object.entries(value)
        .sort(([a], [b]) => a.localeCompare(b))
        .map(([k, v]) => JSON.stringify(k) + ":" + canonical(v))
        .join(",") +
      "}"
    );
  return JSON.stringify(value);
}
export function hash(value: unknown): string {
  return createHash("sha256").update(canonical(value)).digest("hex");
}
