import type { FastifyInstance, FastifyRequest } from "fastify";
import type { ClientRepository } from "../repositories/client-repository.js";
import { OdinService } from "../services/odin.js";
import { id, parse } from "../services/client-contracts.js";
import { ServiceError } from "../services/errors.js";
import { z } from "zod";
export function registerOdinRoutes(
  app: FastifyInstance,
  repository: ClientRepository,
  odin: OdinService,
) {
  const uid = async (r: FastifyRequest) => {
    const token = r.headers.authorization?.match(
      /^Bearer ([^\s]{1,8192})$/,
    )?.[1];
    if (!token) throw new ServiceError("UNAUTHENTICATED", 401);
    return (await repository.verifyIdentity(token)).uid;
  };
  const key = (r: FastifyRequest) => parse(id, r.headers["idempotency-key"]);
  const run = (r: FastifyRequest) =>
    parse(z.strictObject({ runId: id }), r.params).runId;
  app.get("/v1/odin/capabilities", async (r) => ({
    data: await odin.capabilities(await uid(r)),
  }));
  app.get("/v1/me/consents", async (r) => ({
    data: await odin.consentState(await uid(r)),
  }));
  app.post("/v1/me/consents", async (r) => ({
    data: await odin.consent(await uid(r), r.body, key(r)),
  }));
  app.get("/v1/odin/runs", async (r) => ({
    data: await odin.list(await uid(r)),
  }));
  app.get("/v1/odin/runs/:runId", async (r) => ({
    data: await odin.get(await uid(r), run(r)),
  }));
  app.post("/v1/odin/runs", async (r, reply) =>
    reply
      .code(202)
      .send({ data: await odin.create(await uid(r), r.body, key(r)) }),
  );
  for (const action of ["cancel", "resume"] as const)
    app.post(`/v1/odin/runs/:runId/${action}`, async (r) => ({
      data: await odin.action(await uid(r), run(r), action, r.body, key(r)),
    }));
}
