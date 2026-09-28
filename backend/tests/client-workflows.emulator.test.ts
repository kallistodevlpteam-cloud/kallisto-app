import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { randomUUID } from "node:crypto";
import { deleteApp, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { ClientWorkflows } from "../src/services/client-workflows.js";
import { firestoreRecordStore } from "../src/repositories/record-store.js";
import { hash } from "../src/services/client-contracts.js";

// Opt-in test suite: the project and both endpoints are hard-coded to local demo services.
describe.skipIf(process.env.RUN_FIREBASE_EMULATOR_TESTS !== "true")(
  "client workflow transactions (Firestore emulator)",
  () => {
    process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8088";
    process.env.FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099";
    const app = initializeApp(
        { projectId: "demo-kallisto" },
        `test-${randomUUID()}`,
      ),
      db = getFirestore(app);
    const flows = new ClientWorkflows(firestoreRecordStore(db));
    const uid = `test_${randomUUID()}`,
      other = `test_${randomUUID()}`;
    const enrollment = {
      display_name: "Synthetic client",
      client_kind: "person",
      preferred_language: "en",
      preferred_timezone: "Asia/Kolkata",
      enrollment_policy_version: "test-only-v1",
      explicit_confirmation: true,
    };
    let intakeId: string,
      projectId: string,
      versionId: string,
      contentHash: string;
    beforeAll(async () => {
      await db
        .doc("system_settings/features")
        .set({
          policy_version: "test-only-v1",
          approved_by_uid: "local-test-operator",
          values: {
            client_enrollment_notice: {
              version: "test-only-v1",
              text: "LOCAL TEST ONLY: This workspace uses isolated Firebase emulators and synthetic records. Creating a test workspace is not a legal agreement and does not enroll you in the live service.",
            },
          },
        });
      for (const user of [uid, other])
        await flows.enroll(
          { uid: user, email: `${user}@example.test`, emailVerified: false },
          enrollment,
          "enroll",
        );
    });
    afterAll(async () => {
      await db.terminate();
      await deleteApp(app);
    });
    it("enrollment retries keep the same client and do not overwrite another role", async () => {
      const first = await flows.enroll(
        { uid, emailVerified: false },
        enrollment,
        "enroll",
      );
      const again = await flows.enroll(
        { uid, emailVerified: false },
        enrollment,
        "enroll",
      );
      expect(first).toEqual(again);
      await expect(
        flows.enroll(
          { uid, emailVerified: false },
          { ...enrollment, display_name: "Changed" },
          "enroll",
        ),
      ).rejects.toMatchObject({ status: 409 });
      const internal = `test_${randomUUID()}`;
      await db
        .doc(`user_access/${internal}`)
        .set({ role: "internal", active: true });
      await expect(
        flows.enroll(
          { uid: internal, emailVerified: false },
          enrollment,
          "enroll",
        ),
      ).rejects.toMatchObject({ status: 403 });
      expect((await db.doc(`user_access/${internal}`).get()).data()?.role).toBe(
        "internal",
      );
    });
    it("creates one draft for a retried intent and denies another owner", async () => {
      const [a, b] = await Promise.all([
        flows.createIntake(
          uid,
          { locale: "en", preferred_mode: "manual" },
          "create",
        ),
        flows.createIntake(
          uid,
          { locale: "en", preferred_mode: "manual" },
          "create",
        ),
      ]);
      expect(a.intake_id).toBe(b.intake_id);
      intakeId = String(a.intake_id);
      await expect(flows.intake(other, intakeId)).rejects.toMatchObject({
        status: 404,
      });
    });
    it("retains original inputs, validates revision and rejects inconsistent values atomically", async () => {
      const operations = [
        ["brief.project.name", "Emulator courtyard home"],
        ["brief.project.project_type", "architecture"],
        ["brief.spaces.bedrooms.total", 3],
        ["brief.budget.currency", "INR"],
        ["brief.budget.target_minor", 450000000],
      ].map(([field_path, value]) => ({
        op: "set",
        field_path,
        value,
        expected_field_revision: 0,
      }));
      const input = {
        kind: "manual",
        client_input_id: "input-1",
        expected_revision: 0,
        manual_operations: operations,
      };
      const result = await flows.input(uid, intakeId, input, "input-1");
      expect(await flows.input(uid, intakeId, input, "input-1")).toEqual(
        result,
      );
      await expect(
        flows.input(
          uid,
          intakeId,
          { ...input, client_input_id: "input-2" },
          "input-2",
        ),
      ).rejects.toMatchObject({ status: 409 });
      await expect(
        flows.input(
          uid,
          intakeId,
          {
            kind: "manual",
            client_input_id: "invalid",
            expected_revision: 1,
            manual_operations: [
              {
                op: "set",
                field_path: "brief.spaces.bedrooms.ground_floor_count",
                value: 4,
                expected_field_revision: 0,
              },
            ],
          },
          "invalid",
        ),
      ).rejects.toMatchObject({ status: 422 });
      const draft = await flows.intake(uid, intakeId);
      expect(draft.draft_revision).toBe(1);
      expect(draft.question_policy_version).toBe('intake.v1');
      expect(draft.field_schema_version).toBe('intake.v1');
      expect(draft.input_refs).toHaveLength(1);
      expect(
        (await db.collection(`intake_sessions/${intakeId}/revisions`).get())
          .size,
      ).toBe(1);
    });
    it("simultaneous preparation produces one project/version even with different keys", async () => {
      const draft = await flows.intake(uid, intakeId);
      const input = {
        expected_draft_revision: 1,
        included_input_refs: draft.input_refs,
        excluded_input_ids: [],
      };
      await expect(
        flows.prepare(
          uid,
          intakeId,
          { ...input, included_input_refs: [] },
          "missing-sources",
        ),
      ).rejects.toMatchObject({ status: 409 });
      const [a, b] = await Promise.all([
        flows.prepare(uid, intakeId, input, "prepare-a"),
        flows.prepare(uid, intakeId, input, "prepare-b"),
      ]);
      expect(a.project_id).toBe(b.project_id);
      expect(a.version_id).toBe(b.version_id);
      projectId = String(a.project_id);
      versionId = String(a.version_id);
      contentHash = String(a.content_hash);
      expect(
        (await db.collection("projects").where("owner_uid", "==", uid).get())
          .size,
      ).toBe(1);
      expect(
        (
          await db
            .collection("requirement_versions")
            .where("project_id", "==", projectId)
            .get()
        ).size,
      ).toBe(1);
      expect(
        (await db.doc(`project_members/${hash([projectId, uid])}`).get())
          .exists,
      ).toBe(true);
      expect((await flows.project(uid, projectId)).phase).toBe("requirements");
    });
    it("confirmation requires exact current hash/version and keeps immutable evidence", async () => {
      const request = {
        version_id: versionId,
        content_hash: contentHash,
        expected_requirement_version: 1,
        explicit_confirmation: true,
      };
      await expect(
        flows.confirm(other, projectId, request, "confirm"),
      ).rejects.toMatchObject({ status: 404 });
      await expect(
        flows.confirm(
          uid,
          projectId,
          { ...request, content_hash: "0".repeat(64) },
          "bad",
        ),
      ).rejects.toMatchObject({ status: 409 });
      const result = await flows.confirm(uid, projectId, request, "confirm");
      expect(await flows.confirm(uid, projectId, request, "confirm")).toEqual(
        result,
      );
      expect(
        (await flows.requirements(uid, projectId)).confirmation_state,
      ).toBe("confirmed");
      expect(
        (
          await db
            .collection("approvals")
            .where("project_id", "==", projectId)
            .get()
        ).size,
      ).toBe(1);
      expect((await flows.project(uid, projectId)).phase).toBe("requirements");
      expect(
        (await db.doc(`requirement_versions/${versionId}`).get()).data()
          ?.content_hash,
      ).toBe(contentHash);
    });
    it("pause/resume preserves the draft and blocks writes while paused", async () => {
      const draft = await flows.intake(uid, intakeId);
      await flows.changeIntakeStatus(
        uid,
        intakeId,
        { expected_version: draft.row_version },
        "pause",
        "paused",
      );
      await expect(
        flows.input(
          uid,
          intakeId,
          {
            kind: "manual",
            client_input_id: "paused-edit",
            expected_revision: draft.draft_revision,
            manual_operations: [
              {
                op: "mark_unknown",
                field_path: "brief.site.location.district",
                expected_field_revision: 0,
              },
            ],
          },
          "paused-edit",
        ),
      ).rejects.toMatchObject({ status: 409 });
      const paused = await flows.intake(uid, intakeId);
      expect(paused.session_status).toBe("paused");
      await flows.changeIntakeStatus(
        uid,
        intakeId,
        { expected_version: paused.row_version },
        "resume",
        "active",
      );
      expect((await flows.intake(uid, intakeId)).draft_revision).toBe(
        draft.draft_revision,
      );
    });
    it("new drafts produce successor briefs without changing old confirmations", async () => {
      const draft = await flows.intake(uid, intakeId);
      await flows.input(
        uid,
        intakeId,
        {
          kind: "manual",
          client_input_id: "successor-input",
          expected_revision: draft.draft_revision,
          manual_operations: [
            {
              op: "set",
              field_path: "brief.project.name",
              value: "Revised courtyard home",
              expected_field_revision: 1,
            },
          ],
        },
        "successor-input",
      );
      const updated = await flows.intake(uid, intakeId);
      const successor = await flows.prepare(
        uid,
        intakeId,
        {
          expected_draft_revision: updated.draft_revision,
          included_input_refs: updated.input_refs,
          excluded_input_ids: [],
        },
        "successor",
      );
      expect(successor.project_id).toBe(projectId);
      expect(successor.version_number).toBe(2);
      expect(
        (await flows.requirements(uid, projectId)).confirmation_state,
      ).toBe("unconfirmed");
      expect(
        (await flows.requirements(uid, projectId, versionId))
          .confirmation_state,
      ).toBe("confirmed");
      expect(
        (await db.doc(`requirement_versions/${versionId}`).get()).data()
          ?.content.title,
      ).toBe("Emulator courtyard home");
      await expect(
        flows.confirm(
          uid,
          projectId,
          {
            version_id: versionId,
            content_hash: contentHash,
            expected_requirement_version: 3,
            explicit_confirmation: true,
          },
          "stale-confirm",
        ),
      ).rejects.toMatchObject({ status: 409 });
    });
    it("reauthorizes an idempotent replay after access revocation", async () => {
      await db
        .doc(`user_access/${uid}`)
        .update({ active: false, access_revision: 2 });
      await expect(
        flows.createIntake(
          uid,
          { locale: "en", preferred_mode: "manual" },
          "create",
        ),
      ).rejects.toMatchObject({ status: 403 });
      await expect(
        flows.confirm(
          uid,
          projectId,
          {
            version_id: versionId,
            content_hash: contentHash,
            expected_requirement_version: 1,
            explicit_confirmation: true,
          },
          "confirm",
        ),
      ).rejects.toMatchObject({ status: 403 });
    });
  },
);
