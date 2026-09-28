import Fastify from 'fastify';
import cors from '@fastify/cors';
import rateLimit from '@fastify/rate-limit';
import { z } from 'zod';
import type { ClientRepository } from './repositories/client-repository.js';
import { ServiceError } from './services/errors.js';

export async function createApp(repository: ClientRepository, origins: string[]) {
  const app = Fastify({ logger: false, bodyLimit: 32 * 1024 });
  await app.register(cors, { origin: origins, credentials: false, methods: ['GET'],
    allowedHeaders: ['Authorization', 'Content-Type'] });
  await app.register(rateLimit, { max: 60, timeWindow: '1 minute' });
  app.addHook('onSend', async (_request, reply) => {
    reply.header('Cache-Control', 'no-store').header('X-Content-Type-Options', 'nosniff');
  });
  app.setErrorHandler((error, _request, reply) => {
    if (error instanceof ServiceError) return reply.code(error.status).send({ error: { code: error.code } });
    const parsed = z.object({ statusCode: z.literal(429) }).safeParse(error);
    return reply.code(parsed.success ? 429 : 503).send({ error: { code: parsed.success ? 'RATE_LIMITED' : 'SERVICE_UNAVAILABLE' } });
  });
  app.get('/health', async () => ({ status: 'ok', scope: 'client-foundation' }));

  async function client(authorization?: string) {
    const match = authorization?.match(/^Bearer ([^\s]{1,8192})$/);
    if (!match?.[1]) throw new ServiceError('UNAUTHENTICATED', 401);
    const uid = await repository.verifyToken(match[1]);
    if (!uid || uid.includes('/') || uid.length > 128) throw new ServiceError('UNAUTHENTICATED', 401);
    const access = await repository.access(uid);
    if (!access || !access.active || access.role !== 'client' || !access.client_id) {
      throw new ServiceError('CLIENT_ACCESS_REQUIRED', 403);
    }
    return access;
  }

  app.get('/v1/auth/me', async request => {
    const actor = await client(request.headers.authorization);
    const displayName = await repository.displayName(actor.uid);
    const current = await client(request.headers.authorization);
    if (current.access_revision !== actor.access_revision) throw new ServiceError('ACCESS_CHANGED', 403);
    return { data: { uid: actor.uid, display_name: displayName, role: 'client', access_revision: actor.access_revision } };
  });
  app.get('/v1/projects', async request => {
    const actor = await client(request.headers.authorization);
    const parsed = z.strictObject({ cursor: z.string().regex(/^[a-zA-Z0-9_-]{1,128}$/).optional() }).safeParse(request.query);
    if (!parsed.success) throw new ServiceError('INVALID_QUERY');
    const page = await repository.projects(actor.uid, parsed.data.cursor);
    const current = await client(request.headers.authorization);
    if (current.access_revision !== actor.access_revision) throw new ServiceError('ACCESS_CHANGED', 403);
    return { data: page };
  });
  app.get('/v1/odin/capabilities', async request => {
    await client(request.headers.authorization);
    return { data: {
      chat_model: 'gemma4:31b', agent_model: 'nemotron-3-ultra', tool_discovery: 'tool_search',
      speech_provider: 'cartesia', enabled: false,
      reason: 'Durable runs, consent, quota and voice configuration must be completed before live execution.',
    } };
  });
  // No live model/write endpoints until durable jobs, consent and quotas exist.
  return app;
}
