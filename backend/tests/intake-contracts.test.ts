import { readFileSync } from "node:fs";
import { describe, it, expect } from "vitest";
import { intakeFields } from "../src/services/client-contracts.js";
describe("complete manual brief field contract", () => {
  it("registers exactly the 77 Appendix E fields", () => {
    const spec = readFileSync(
      new URL("../../docs/MASTER_SPEC.md", import.meta.url),
      "utf8",
    );
    const section = spec.slice(
      spec.indexOf("### E.3"),
      spec.indexOf("### E.4"),
    );
    const fields = [...section.matchAll(/\| (brief\.[a-z_.]+) \|/g)].map(
      (m) => m[1],
    );
    expect(fields).toHaveLength(77);
    expect(Object.keys(intakeFields).sort()).toEqual(fields.sort());
  });
  it("preserves month precision and rejects impossible or reversed dates", () => {
    const schema = intakeFields["brief.timing.start_preference"]!;
    expect(
      schema.parse({
        kind: "month",
        value: "2027-02",
        raw_phrase: "February 2027",
      }),
    ).toEqual({ kind: "month", value: "2027-02", raw_phrase: "February 2027" });
    expect(
      schema.safeParse({
        kind: "date",
        value: "2027-02-30",
        raw_phrase: "30 Feb",
      }).success,
    ).toBe(false);
    expect(
      schema.safeParse({
        kind: "date_range",
        start: "2027-03-01",
        end: "2027-02-01",
        raw_phrase: "range",
      }).success,
    ).toBe(false);
    expect(
      schema.safeParse({
        kind: "relative_duration",
        raw_phrase: "in three months",
        reference_date: "2026-09-29",
        timezone: "invented-zone",
      }).success,
    ).toBe(false);
  });
  it("requires distinct entry IDs and prevents manufactured authority or file access", () => {
    const entry = {
      entry_id: "study",
      label: "Study",
      category: "study",
      scope: "present",
      count: 0,
    };
    const spaces = intakeFields["brief.spaces.additional_spaces"]!;
    expect(spaces.parse([entry])).toEqual([entry]);
    expect(spaces.safeParse([entry, entry]).success).toBe(false);
    expect(spaces.safeParse([{ ...entry, verified: true }]).success).toBe(
      false,
    );
    expect(
      intakeFields["brief.interior.reuse_items"]!.safeParse([
        {
          entry_id: "desk",
          label: "Desk",
          existing_or_proposed: "existing",
          source_refs: [{ resource_id: "foreign" }],
        },
      ]).success,
    ).toBe(false);
    expect(
      intakeFields["brief.documents.attachment_refs"]!.safeParse([
        { file_id: "foreign" },
      ]).success,
    ).toBe(false);
    expect(
      intakeFields["brief.design.reference_refs"]!.safeParse([
        {
          entry_id: "r",
          label: "Reference",
          url: "https://secret:password@example.com",
        },
      ]).success,
    ).toBe(false);
  });
});
