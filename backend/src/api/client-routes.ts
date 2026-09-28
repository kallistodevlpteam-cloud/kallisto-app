import type { FastifyInstance, FastifyRequest } from "fastify";
import { z } from "zod";
import type { ClientRepository } from "../repositories/client-repository.js";
import { ClientWorkflows } from "../services/client-workflows.js";
import { id, parse } from "../services/client-contracts.js";
import { ServiceError } from "../services/errors.js";

export function registerClientRoutes(
  app: FastifyInstance,
  repository: ClientRepository,
  workflows: ClientWorkflows,
) {
  async function identity(request: FastifyRequest) {
    const token = request.headers.authorization?.match(
      /^Bearer ([^\s]{1,8192})$/,
    )?.[1];
    if (!token) throw new ServiceError("UNAUTHENTICATED", 401);
    return repository.verifyIdentity(token);
  }
  const key = (request: FastifyRequest) =>
    parse(id, request.headers["idempotency-key"]);
  const intakeId = (request: FastifyRequest) =>
    parse(z.strictObject({ intakeId: id }), request.params).intakeId;
  const projectId = (request: FastifyRequest) =>
    parse(z.strictObject({ projectId: id }), request.params).projectId;
  const response = (request: FastifyRequest, data: unknown) => ({
    data,
    meta: { correlation_id: request.id, schema_version: "kallisto.api.v1" },
  });
  app.get("/v1/capabilities", async (request) =>
    response(request, await workflows.capabilities()),
  );
  app.post("/v1/provider-applications/client-enrollment", async (request) =>
    response(
      request,
      await workflows.enroll(
        await identity(request),
        request.body,
        key(request),
      ),
    ),
  );
  app.get("/v1/intakes", async (request) => {
    const query = parse(
      z.strictObject({ cursor: id.optional() }),
      request.query,
    );
    return response(
      request,
      await workflows.listIntakes((await identity(request)).uid, query.cursor),
    );
  });
  app.post("/v1/intakes", async (request, reply) =>
    reply
      .code(201)
      .send(
        response(
          request,
          await workflows.createIntake(
            (await identity(request)).uid,
            request.body,
            key(request),
          ),
        ),
      ),
  );
  app.get("/v1/intakes/:intakeId", async (request) =>
    response(
      request,
      await workflows.intake((await identity(request)).uid, intakeId(request)),
    ),
  );
  app.post("/v1/intakes/:intakeId/inputs", async (request) =>
    response(
      request,
      await workflows.input(
        (await identity(request)).uid,
        intakeId(request),
        request.body,
        key(request),
      ),
    ),
  );
  app.post("/v1/intakes/:intakeId/pause", async (request) =>
    response(
      request,
      await workflows.changeIntakeStatus(
        (await identity(request)).uid,
        intakeId(request),
        request.body,
        key(request),
        "paused",
      ),
    ),
  );
  app.post("/v1/intakes/:intakeId/resume", async (request) =>
    response(
      request,
      await workflows.changeIntakeStatus(
        (await identity(request)).uid,
        intakeId(request),
        request.body,
        key(request),
        "active",
      ),
    ),
  );
  app.post("/v1/intakes/:intakeId/prepare-brief", async (request) =>
    response(
      request,
      await workflows.prepare(
        (await identity(request)).uid,
        intakeId(request),
        request.body,
        key(request),
      ),
    ),
  );
  app.get("/v1/projects/:projectId", async (request) =>
    response(
      request,
      await workflows.project(
        (await identity(request)).uid,
        projectId(request),
      ),
    ),
  );
  app.get("/v1/projects/:projectId/requirements", async (request) => {
    const query = parse(
      z.strictObject({ version_id: id.optional() }),
      request.query,
    );
    return response(
      request,
      await workflows.requirements(
        (await identity(request)).uid,
        projectId(request),
        query.version_id,
      ),
    );
  });
  app.post("/v1/projects/:projectId/requirements/confirm", async (request) =>
    response(
      request,
      await workflows.confirm(
        (await identity(request)).uid,
        projectId(request),
        request.body,
        key(request),
      ),
    ),
  );
}
