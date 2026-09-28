import { describe, expect, it, vi } from 'vitest';
import { z } from 'zod';
import { ToolDiscovery, type ToolDefinition } from '../src/services/tool-search.js';

const context = { actorUid: 'client-a', accessRevision: '1', runId: 'run-a' };
function tool(name = 'projects_list', allowed = true): ToolDefinition {
  return { name, description: 'List projects for the current client', keywords: ['project', 'workspace'],
    tier: 'routine', effect: 'read', arguments: z.strictObject({}),
    authorize: vi.fn(async () => allowed), execute: vi.fn(async () => ({ items: [] })) };
}

describe('permission-filtered dynamic tools', () => {
  it('starts with only search, then exposes just matching permitted schemas', async () => {
    const discovery = new ToolDiscovery([tool(), tool('private_projects', false)], context);
    expect((await discovery.schemas()).map(t => t.function.name)).toEqual(['tool_search']);
    const result = await discovery.search({ query: 'my project' });
    expect(result.tools.map(t => t.function.name)).toEqual(['projects_list']);
    expect((await discovery.schemas()).map(t => t.function.name)).toEqual(['tool_search', 'projects_list']);
    expect(JSON.stringify(result)).not.toContain('private_projects');
    expect(result.tools[0]!.function.parameters.additionalProperties).toBe(false);
  });
  it('refuses execution before discovery and never invokes an unknown name', async () => {
    const entry = tool(); const discovery = new ToolDiscovery([entry], context);
    await expect(discovery.call('projects_list', {}, 'routine')).rejects.toMatchObject({ code: 'TOOL_NOT_AVAILABLE' });
    await expect(discovery.call('execute_sql', {}, 'routine')).rejects.toMatchObject({ code: 'TOOL_NOT_AVAILABLE' });
    expect(entry.execute).not.toHaveBeenCalled();
  });
  it('rechecks revocation after discovery', async () => {
    const entry = tool(); const discovery = new ToolDiscovery([entry], context);
    await discovery.search({ query: 'projects' });
    vi.mocked(entry.authorize).mockResolvedValue(false);
    await expect(discovery.call('projects_list', {}, 'routine')).rejects.toMatchObject({ code: 'TOOL_NOT_AVAILABLE' });
    expect(await discovery.schemas()).toHaveLength(1);
    expect(entry.execute).not.toHaveBeenCalled();
  });
  it('rejects actor overrides and returns no fabricated match', async () => {
    const discovery = new ToolDiscovery([tool()], context);
    await expect(discovery.search({ query: 'projects', actorUid: 'admin' })).rejects.toMatchObject({ code: 'INVALID_TOOL_ARGUMENTS' });
    expect(await discovery.search({ query: 'unrelated quantum physics' })).toEqual({ tools: [] });
    await discovery.search({ query: 'projects' });
    await expect(discovery.call('projects_list', { owner_uid: 'someone-else' }, 'routine')).rejects.toMatchObject({ code: 'INVALID_TOOL_ARGUMENTS' });
  });
  it('returns a heavy handoff instead of executing heavy work as Gemma', async () => {
    const entry = { ...tool(), tier: 'heavy' as const };
    const discovery = new ToolDiscovery([entry], context);
    await discovery.search({ query: 'projects' });
    expect(await discovery.call(entry.name, {}, 'routine')).toMatchObject({ status: 'heavy_workflow_required' });
    expect(entry.execute).not.toHaveBeenCalled();
    await discovery.call(entry.name, {}, 'heavy');
    expect(entry.execute).toHaveBeenCalledOnce();
  });
  it('bounds searches and refuses changed run identity', async () => {
    const mutable = { ...context }; const discovery = new ToolDiscovery([tool()], mutable);
    for (let i = 0; i < 4; i++) await discovery.search({ query: 'projects' });
    await expect(discovery.search({ query: 'projects' })).rejects.toMatchObject({ code: 'TOOL_SEARCH_LIMIT' });
    mutable.actorUid = 'client-b';
    await expect(discovery.schemas()).rejects.toMatchObject({ code: 'ACCESS_CONTEXT_CHANGED' });
  });
  it('bounds result and active tool count', async () => {
    const entries = Array.from({ length: 20 }, (_, i) => tool(`projects_${i.toString().padStart(2, '0')}`));
    const discovery = new ToolDiscovery(entries, context);
    expect((await discovery.search({ query: 'projects' })).tools).toHaveLength(5);
    expect((await discovery.schemas()).length).toBeLessThanOrEqual(9);
  });
  it('withholds a result when authority is revoked during the operation', async () => {
    const entry = tool();
    vi.mocked(entry.execute).mockImplementation(async () => {
      vi.mocked(entry.authorize).mockResolvedValue(false);
      return { private_record: 'must not reach model' };
    });
    const discovery = new ToolDiscovery([entry], context);
    await discovery.search({query: 'projects'});
    await expect(discovery.call(entry.name, {}, 'routine')).rejects.toMatchObject({code: 'TOOL_NOT_AVAILABLE'});
  });
  it('closes registered object schemas even when a handler supplied a stripping schema', async () => {
    const entry = {...tool(), arguments: z.object({})};
    const discovery = new ToolDiscovery([entry], context);
    await discovery.search({query: 'projects'});
    await expect(discovery.call(entry.name, {actorUid: 'someone-else'}, 'routine')).rejects.toMatchObject({code: 'INVALID_TOOL_ARGUMENTS'});
    expect(entry.execute).not.toHaveBeenCalled();
  });
});
