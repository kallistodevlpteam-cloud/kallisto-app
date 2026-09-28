import { z } from 'zod';
import { ServiceError } from './errors.js';

export type ModelTier = 'routine' | 'heavy';
export type ToolEffect = 'read' | 'draft' | 'confirmation';
export interface ToolContext {
  readonly actorUid: string;
  readonly accessRevision: string;
  readonly projectId?: string;
  readonly runId: string;
}
export interface ToolDefinition {
  readonly name: string;
  readonly description: string;
  readonly keywords: readonly string[];
  readonly tier: ModelTier;
  readonly effect: ToolEffect;
  readonly arguments: z.ZodObject;
  /** Must resolve current trusted access; discovery is not authorization. */
  authorize(context: ToolContext): Promise<boolean>;
  execute(args: Record<string, unknown>, context: ToolContext): Promise<unknown>;
}
export interface NativeTool {
  type: 'function';
  function: { name: string; description: string; parameters: Record<string, unknown> };
}

const searchArguments = z.strictObject({ query: z.string().trim().min(2).max(160) });
export const searchTool: NativeTool = {
  type: 'function',
  function: {
    name: 'tool_search',
    description: 'Find permitted Kallisto tools by purpose keywords. Search before using a tool. Results contain the tools you can request on the next turn.',
    parameters: z.toJSONSchema(searchArguments),
  },
};

function tokens(text: string): string[] {
  return [...new Set((text.normalize('NFKD').toLowerCase().match(/[a-z0-9]+/g) ?? [])
    .filter(word => !['a', 'an', 'the', 'my', 'for', 'to', 'and', 'of', 'me'].includes(word))
    .map(word => word.length > 4 && word.endsWith('s') ? word.slice(0, -1) : word))];
}

/** Per-run discovery state. Persist allowed names with the run when adding jobs. */
export class ToolDiscovery {
  private readonly tools = new Map<string, ToolDefinition>();
  private readonly active = new Set<string>();
  private searchCount = 0;
  private callCount = 0;
  private readonly identity: string;

  constructor(definitions: readonly ToolDefinition[], private readonly context: ToolContext) {
    if (!context.actorUid || !context.accessRevision || !context.runId) {
      throw new ServiceError('AUTHORITY_REQUIRED', 403);
    }
    this.identity = JSON.stringify(context);
    for (const definition of definitions) {
      if (!/^[a-z][a-z0-9_]{1,63}$/.test(definition.name) ||
          definition.name === 'tool_search' || this.tools.has(definition.name)) {
        throw new Error('Invalid or duplicate registered tool name');
      }
      this.tools.set(definition.name, { ...definition, arguments: definition.arguments.strict() });
    }
  }

  private checkContext(): void {
    if (JSON.stringify(this.context) !== this.identity) {
      this.active.clear();
      throw new ServiceError('ACCESS_CONTEXT_CHANGED', 403);
    }
  }

  private definition(tool: ToolDefinition): NativeTool {
    return {
      type: 'function',
      function: {
        name: tool.name,
        description: `${tool.description} Effect: ${tool.effect}. Execution: ${tool.tier}.`,
        parameters: z.toJSONSchema(tool.arguments),
      },
    };
  }

  async schemas(): Promise<NativeTool[]> {
    this.checkContext();
    const result: NativeTool[] = [searchTool];
    for (const name of this.active) {
      const tool = this.tools.get(name)!;
      if (await tool.authorize(this.context)) result.push(this.definition(tool));
      else this.active.delete(name);
    }
    return result;
  }

  async search(input: unknown): Promise<{ tools: NativeTool[] }> {
    this.checkContext();
    if (++this.searchCount > 4) throw new ServiceError('TOOL_SEARCH_LIMIT', 429);
    const parsed = searchArguments.safeParse(input);
    if (!parsed.success) throw new ServiceError('INVALID_TOOL_ARGUMENTS');
    const query = tokens(parsed.data.query);
    const matches: { tool: ToolDefinition; score: number }[] = [];
    for (const tool of this.tools.values()) {
      const vocabulary = tokens(`${tool.name} ${tool.description} ${tool.keywords.join(' ')}`);
      const score = query.filter(word => vocabulary.includes(word)).length;
      if (score > 0 && await tool.authorize(this.context)) matches.push({ tool, score });
    }
    matches.sort((a, b) => b.score - a.score || a.tool.name.localeCompare(b.tool.name));
    const result: NativeTool[] = [];
    for (const { tool } of matches) {
      if (result.length === 5) break;
      if (!this.active.has(tool.name) && this.active.size >= 8) continue;
      this.active.add(tool.name);
      result.push(this.definition(tool));
    }
    return { tools: result };
  }

  async call(name: string, input: unknown, tier: ModelTier): Promise<unknown> {
    this.checkContext();
    if (++this.callCount > 16) throw new ServiceError('TOOL_CALL_LIMIT', 429);
    if (name === 'tool_search') return this.search(input);
    const tool = this.tools.get(name);
    if (!tool || !this.active.has(name) || !await tool.authorize(this.context)) {
      throw new ServiceError('TOOL_NOT_AVAILABLE', 403);
    }
    if (tool.tier === 'heavy' && tier !== 'heavy') {
      return { status: 'heavy_workflow_required', tool: name };
    }
    const parsed = tool.arguments.safeParse(input);
    if (!parsed.success) throw new ServiceError('INVALID_TOOL_ARGUMENTS');
    // Write handlers must implement exact human review + idempotency themselves.
    const result = await tool.execute(parsed.data, this.context);
    this.checkContext();
    if (!await tool.authorize(this.context)) throw new ServiceError('TOOL_NOT_AVAILABLE', 403);
    return result;
  }
}
