import { describe, it, expect } from "vitest";
import { OdinService, odinNotice } from "../src/services/odin.js";
import type {
  RecordData,
  RecordStore,
} from "../src/repositories/record-store.js";
import type { OllamaMessage } from "../src/integrations/ollama.js";
import type { NativeTool } from "../src/services/tool-search.js";
function fixture(
  answer?: (
    messages: readonly OllamaMessage[],
    tools: NativeTool[],
  ) => Promise<OllamaMessage>,
) {
  const rows = new Map<string, RecordData>([
    [
      "user_access/alice",
      {
        uid: "alice",
        role: "client",
        active: true,
        client_id: "client",
        organization_id: "org",
        access_revision: 1,
      },
    ],
  ]);
  let calls = 0,
    now = 1000000;
  const store: RecordStore = {
    get: async (p) => rows.get(p) ?? null,
    list: async (q) =>
      [...rows]
        .filter(
          ([p, r]) =>
            p.startsWith(q.collection + "/") &&
            !p.slice(q.collection.length + 1).includes("/") &&
            (q.filters ?? []).every(([k, v]) => r[k] === v),
        )
        .map(([p, r]) => ({ ...r, _id: p.split("/").at(-1)! }))
        .sort((a, b) =>
          q.order
            ? Number(b.sequence ?? 0) - Number(a.sequence ?? 0)
            : a._id.localeCompare(b._id),
        )
        .slice(0, q.limit ?? 20),
    timestamp: () => new Date(now).toISOString(),
    transaction: async (work) => {
      const pending = new Map<string, RecordData>();
      const read = () => {
        if (pending.size) throw Error("Read after write");
      };
      const result = await work({
        get: async (p) => {
          read();
          return rows.get(p) ?? null;
        },
        list: async (q) => {
          read();
          return store.list(q);
        },
        create: (p, r) => {
          if (rows.has(p)) throw Error("Duplicate");
          pending.set(p, r);
        },
        set: (p, r) => pending.set(p, r),
      });
      for (const [p, r] of pending) rows.set(p, r);
      return result;
    },
  };
  const service = new OdinService(
    store,
    {
      complete: async (_tier, m, t) => {
        calls++;
        return answer
          ? answer(m, t)
          : { role: "assistant", content: "A real test adapter response" };
      },
    },
    { enabled: true, dailyCalls: 16, production: false },
    () => now,
  );
  return {
    service,
    rows,
    calls: () => calls,
    advance: () => {
      now += 100000;
    },
  };
}
const consent = {
  purpose: "external_ai_processing",
  resource_scope: { kind: "account" },
  policy_version: odinNotice.version,
  decision: "granted",
  explicit_confirmation: true,
};
const input = (c: string, msg = "message1") => ({
  mode: "assist",
  consent_record_id: c,
  message: { client_message_id: msg, text: "Hello Odin", attachment_refs: [] },
});
describe("durable Odin execution", () => {
  it("requires explicit current consent and rejects arbitrary model overrides", async () => {
    const f = fixture();
    await expect(
      f.service.create("alice", input("absent"), "key"),
    ).rejects.toMatchObject({ code: "AI_CONSENT_REQUIRED" });
    const c = await f.service.consent("alice", consent, "consent1");
    await expect(
      f.service.create(
        "alice",
        { ...input(c.consent_id), model: "unsafe" },
        "key",
      ),
    ).rejects.toBeDefined();
    expect(f.calls()).toBe(0);
  });
  it("persists one original input, response and exact replay with protected run reads", async () => {
    const f = fixture(),
      c = await f.service.consent("alice", consent, "consent1"),
      r = await f.service.create("alice", input(c.consent_id), "key");
    expect(
      await f.service.create("alice", input(c.consent_id), "another"),
    ).toEqual(r);
    await f.service.execute(r.run_id);
    const result = await f.service.get("alice", r.run_id);
    expect(result.status).toBe("succeeded");
    expect(result.answer).toBe("A real test adapter response");
    expect(f.calls()).toBe(1);
    await f.service.execute(r.run_id);
    expect(f.calls()).toBe(1);
    f.rows.set("user_access/bob", {
      uid: "bob",
      role: "client",
      active: true,
      client_id: "other",
    });
    await expect(f.service.get("bob", r.run_id)).rejects.toMatchObject({
      code: "NOT_FOUND",
    });
  });
  it("exposes only search initially and activates discovered read tools on subsequent turns", async () => {
    let turn = 0;
    const f = fixture(async (_messages, tools) => {
      turn++;
      if (turn === 1) {
        expect(tools.map((t) => t.function.name)).toEqual(["tool_search"]);
        return {
          role: "assistant",
          content: "",
          tool_calls: [
            {
              function: {
                name: "tool_search",
                arguments: { query: "projects list" },
              },
            },
          ],
        };
      }
      if (turn === 2) {
        expect(tools.some((t) => t.function.name === "projects_list")).toBe(
          true,
        );
        return {
          role: "assistant",
          content: "",
          tool_calls: [{ function: { name: "projects_list", arguments: {} } }],
        };
      }
      return { role: "assistant", content: "There are no saved projects." };
    });
    const c = await f.service.consent("alice", consent, "consent1"),
      r = await f.service.create("alice", input(c.consent_id), "key");
    await f.service.execute(r.run_id);
    expect((await f.service.get("alice", r.run_id)).status).toBe("succeeded");
    expect(f.calls()).toBe(3);
  });
  it("fences a cancelled external result and preserves the original input", async () => {
    let release!: (v: OllamaMessage) => void;
    const f = fixture(
        () =>
          new Promise((resolve) => {
            release = resolve;
          }),
      ),
      c = await f.service.consent("alice", consent, "consent1"),
      r = await f.service.create("alice", input(c.consent_id), "key");
    const execution = f.service.execute(r.run_id);
    while (!release) await new Promise((resolve) => setTimeout(resolve, 0));
    const running = await f.service.get("alice", r.run_id);
    await f.service.action(
      "alice",
      r.run_id,
      "cancel",
      { expected_version: running.row_version },
      "cancel1",
    );
    release({ role: "assistant", content: "Late answer" });
    await execution;
    const result = await f.service.get("alice", r.run_id);
    expect(result.status).toBe("cancelled");
    expect(result.answer).toBeNull();
  });
  it("blocks withdrawn consent before outbound processing and releases active slot", async () => {
    const f = fixture(),
      c = await f.service.consent("alice", consent, "consent1"),
      r = await f.service.create("alice", input(c.consent_id), "key");
    await f.service.consent(
      "alice",
      { ...consent, decision: "withdrawn" },
      "withdraw",
    );
    await f.service.execute(r.run_id);
    expect(f.calls()).toBe(0);
    expect((await f.service.get("alice", r.run_id)).status).toBe("failed");
    expect(f.rows.get("odin_active/alice")?.count).toBe(0);
  });
  it("reserves worst-case quota before any external call", async () => {
    const f = fixture(),
      c = await f.service.consent("alice", consent, "consent1");
    for (let i = 0; i < 2; i++) {
      const r = await f.service.create(
        "alice",
        input(c.consent_id, `msg${i}`),
        "key",
      );
      await f.service.execute(r.run_id);
    }
    await expect(
      f.service.create("alice", input(c.consent_id, "msg3"), "key"),
    ).rejects.toMatchObject({ code: "ODIN_QUOTA_EXHAUSTED" });
  });
  it("fails stale project context before the provider is called", async () => {
    const f = fixture();
    f.rows.set("projects/p1", {
      project_id: "p1",
      owner_uid: "alice",
      row_version: 1,
      name: "Project",
    });
    const c = await f.service.consent("alice", consent, "consent1"),
      r = await f.service.create(
        "alice",
        { ...input(c.consent_id), project_id: "p1" },
        "key",
      );
    f.rows.get("projects/p1")!.row_version = 2;
    await f.service.execute(r.run_id);
    expect(f.calls()).toBe(0);
    expect(f.rows.get(`odin_runs/${r.run_id}`)?.status).toBe("failed");
  });
  it("recovers a committed final response without a second provider call", async () => {
    const f = fixture(),
      c = await f.service.consent("alice", consent, "consent1"),
      r = await f.service.create("alice", input(c.consent_id), "key");
    const job = f.rows.get(`jobs/${r.run_id}`)!;
    job.status = "running";
    job.lease_generation = 1;
    job.lease_until_ms = 0;
    job.checkpoint = {
      messages: [{ role: "assistant", content: "Committed reply" }],
      completed_calls: 1,
    };
    f.rows.get(`odin_runs/${r.run_id}`)!.status = "running";
    f.rows.get(`odin_runs/${r.run_id}`)!.step_count = 1;
    await f.service.pump();
    const failed = await f.service.get("alice", r.run_id);
    expect(failed.status).toBe("failed");
    await f.service.action(
      "alice",
      r.run_id,
      "resume",
      { expected_version: failed.row_version },
      "resume1",
    );
    await f.service.execute(r.run_id);
    expect((await f.service.get("alice", r.run_id)).answer).toBe(
      "Committed reply",
    );
    expect(f.calls()).toBe(0);
  });
  it("rejects a guessed tool bundled with discovery in the same provider turn", async () => {
    const f = fixture(async () => ({
      role: "assistant",
      content: "",
      tool_calls: [
        {
          function: {
            name: "tool_search",
            arguments: { keywords: "projects" },
          },
        },
        { function: { name: "projects_list", arguments: {} } },
      ],
    }));
    const c = await f.service.consent("alice", consent, "c"),
      r = await f.service.create("alice", input(c.consent_id), "key");
    await f.service.execute(r.run_id);
    expect((await f.service.get("alice", r.run_id)).error_code).toBe(
      "TOOL_NOT_AVAILABLE",
    );
    expect(f.rows.get(`odin_runs/${r.run_id}`)?.tool_call_count).toBe(0);
  });
  it("retains source authority across follow-up answers", async () => {
    const f = fixture();
    f.rows.set("projects/p1", {
      project_id: "p1",
      owner_uid: "alice",
      row_version: 1,
      name: "Private project",
    });
    const c = await f.service.consent("alice", consent, "c"),
      first = await f.service.create("alice", input(c.consent_id), "key");
    await f.service.execute(first.run_id);
    f.rows.get(`odin_runs/${first.run_id}`)!.sources = [
      { resource_type: "project", resource_id: "p1", version_id: "1" },
    ];
    const second = await f.service.create(
      "alice",
      {
        ...input(c.consent_id, "followup"),
        conversation_id: first.conversation_id,
      },
      "key2",
    );
    await f.service.execute(second.run_id);
    expect((await f.service.get("alice", second.run_id)).sources).toHaveLength(
      1,
    );
    f.rows.get("projects/p1")!.owner_uid = "someone_else";
    await expect(f.service.get("alice", second.run_id)).rejects.toBeDefined();
  });
});
