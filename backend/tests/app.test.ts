import { afterEach, expect, it, vi } from 'vitest';
import { createApp } from '../src/app.js';
import type { ClientRepository } from '../src/repositories/client-repository.js';

const actor = { uid: 'client-a', role: 'client' as const, organization_id: 'org-a', active: true, verified: false, access_revision: 1, client_id: 'client-record-a' };
const repository = (): ClientRepository => ({
  verifyIdentity:vi.fn(async()=>({uid:'client-a',emailVerified:false})),
  verifyToken: vi.fn(async () => 'client-a'), access: vi.fn(async () => ({ ...actor })),
  displayName: vi.fn(async () => 'Client'), projects: vi.fn(async () => ({ items: [], next_cursor: null })),
});
const apps: Awaited<ReturnType<typeof createApp>>[] = [];
afterEach(async () => { for (const app of apps.splice(0)) await app.close(); });
async function setup(repo = repository()) { const app = await createApp(repo, ['http://localhost:5000']); apps.push(app); return { app, repo }; }
const headers = { authorization: 'Bearer test-id-token' };

it('denies anonymous access before any database read', async () => {
  const { app, repo } = await setup();
  expect((await app.inject('/v1/projects')).statusCode).toBe(401);
  expect(repo.projects).not.toHaveBeenCalled();
});
it('does not grant access based on Firebase identity alone', async () => {
  const repo = repository(); vi.mocked(repo.access).mockResolvedValue(null);
  const { app } = await setup(repo);
  expect((await app.inject({ url: '/v1/projects', headers })).statusCode).toBe(403);
  expect(repo.projects).not.toHaveBeenCalled();
});
it('rejects provider role in this client API slice', async () => {
  const repo = repository(); vi.mocked(repo.access).mockResolvedValue({ ...actor, role: 'provider' });
  const { app } = await setup(repo);
  expect((await app.inject({ url: '/v1/projects', headers })).statusCode).toBe(403);
});
it('uses authenticated owner identity and prevents owner query overrides', async () => {
  const { app, repo } = await setup();
  const result = await app.inject({ url: '/v1/projects', headers });
  expect(result.statusCode).toBe(200);
  expect(repo.projects).toHaveBeenCalledWith('client-a', undefined);
  expect(result.headers['cache-control']).toBe('no-store');
  expect((await app.inject({ url: '/v1/projects?owner_uid=someone-else', headers })).statusCode).toBe(400);
});
it('withholds private results if access changes during the read', async () => {
  const repo = repository(); vi.mocked(repo.access).mockResolvedValueOnce(actor).mockResolvedValueOnce({ ...actor, access_revision: 2 });
  const { app } = await setup(repo);
  expect((await app.inject({ url: '/v1/projects', headers })).statusCode).toBe(403);
});
it('reports truthful AI readiness and does not expose provider keys', async () => {
  const { app } = await setup();
  const result = await app.inject({ url: '/v1/odin/capabilities', headers });
  expect(result.json().data).toMatchObject({ enabled: false, speech_provider: 'cartesia', tool_discovery: 'tool_search' });
  expect(result.body).not.toMatch(/api_key|test-id-token/i);
});
