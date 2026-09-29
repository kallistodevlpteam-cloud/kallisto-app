import {registerOdinRoutes} from './api/odin-routes.js';
import type {OdinService} from './services/odin.js';
import Fastify from "fastify";
import cors from "@fastify/cors";
import rateLimit from "@fastify/rate-limit";
import { z } from "zod";
import type { ClientRepository } from "./repositories/client-repository.js";
import { ServiceError } from "./services/errors.js";
import { ClientWorkflows } from "./services/client-workflows.js";
import { registerClientRoutes } from "./api/client-routes.js";
import { Timestamp } from "firebase-admin/firestore";

function publicJson(value: unknown): unknown {
  if (value instanceof Timestamp) return value.toDate().toISOString();
  if (Array.isArray(value)) return value.map(publicJson);
  if (value !== null && typeof value === "object")
    return Object.fromEntries(
      Object.entries(value).map(([key, item]) => [key, publicJson(item)]),
    );
  return value;
}

export async function createApp(
  repository: ClientRepository,
  origins: string[],
  workflows?: ClientWorkflows,
  odin?: OdinService,
) {
  const app = Fastify({ logger: false, bodyLimit: 128 * 1024 });
  if(odin)registerOdinRoutes(app,repository,odin);
  await app.register(cors, {
    origin: origins,
    credentials: false,
    methods: ["GET", "POST"],
    allowedHeaders: ["Authorization", "Content-Type", "Idempotency-Key"],
  });
  await app.register(rateLimit, { max: 60, timeWindow: "1 minute" });
  app.addHook("preSerialization", async (_request, _reply, payload) =>
    publicJson(payload),
  );
  app.addHook("onSend", async (_request, reply) => {
    reply
      .header("Cache-Control", "no-store")
      .header("X-Content-Type-Options", "nosniff");
  });
  app.setErrorHandler((error, _request, reply) => {
    if (error instanceof ServiceError)
      return reply.code(error.status).send({ error: { code: error.code } });
    const parsed = z.object({ statusCode: z.number() }).safeParse(error);
    const status =
      parsed.success && [400, 413, 415, 429].includes(parsed.data.statusCode)
        ? parsed.data.statusCode
        : 503;
    return reply
      .code(status)
      .send({
        error: {
          code:
            status === 429
              ? "RATE_LIMITED"
              : status === 503
                ? "SERVICE_UNAVAILABLE"
                : "INVALID_REQUEST",
        },
      });
  });
  app.get("/health", async () => ({
    status: "ok",
    scope: "client-foundation",
  }));

  async function client(authorization?: string) {
    const match = authorization?.match(/^Bearer ([^\s]{1,8192})$/);
    if (!match?.[1]) throw new ServiceError("UNAUTHENTICATED", 401);
    const uid = await repository.verifyToken(match[1]);
    if (!uid || uid.includes("/") || uid.length > 128)
      throw new ServiceError("UNAUTHENTICATED", 401);
    const access = await repository.access(uid);
    if (
      !access ||
      !access.active ||
      access.role !== "client" ||
      !access.client_id
    ) {
      throw new ServiceError("CLIENT_ACCESS_REQUIRED", 403);
    }
    return access;
  }

  app.get("/v1/auth/me", async (request) => {
    if (workflows) {
      const token = request.headers.authorization?.match(
        /^Bearer ([^\s]{1,8192})$/,
      )?.[1];
      if (!token) throw new ServiceError("UNAUTHENTICATED", 401);
      return {
        data: await workflows.actor(await repository.verifyIdentity(token)),
      };
    }
    const actor = await client(request.headers.authorization);
    const displayName = await repository.displayName(actor.uid);
    const current = await client(request.headers.authorization);
    if (current.access_revision !== actor.access_revision)
      throw new ServiceError("ACCESS_CHANGED", 403);
    return {
      data: {
        uid: actor.uid,
        display_name: displayName,
        role: "client",
        access_revision: actor.access_revision,
      },
    };
  });
  if (workflows) registerClientRoutes(app, repository, workflows);
  app.get("/v1/projects", async (request) => {
    const actor = await client(request.headers.authorization);
    const parsed = z
      .strictObject({
        cursor: z
          .string()
          .regex(/^[a-zA-Z0-9_-]{1,128}$/)
          .optional(),
      })
      .safeParse(request.query);
    if (!parsed.success) throw new ServiceError("INVALID_QUERY");
    const page = await repository.projects(actor.uid, parsed.data.cursor);
    const current = await client(request.headers.authorization);
    if (current.access_revision !== actor.access_revision)
      throw new ServiceError("ACCESS_CHANGED", 403);
    return { data: page };
  });
  if(!odin) app.get("/v1/odin/capabilities", async (request) => {
    await client(request.headers.authorization);
    return {
      data: {
        chat_model: "gemma4:31b",
        agent_model: "nemotron-3-ultra",
        tool_discovery: "tool_search",
        speech_provider: "cartesia",
        enabled: false,
        reason:
          "Durable runs, consent, quota and voice configuration must be completed before live execution.",
      },
    };
  });
  // Runtime integration is optional in isolated API tests.
  return app;
}
