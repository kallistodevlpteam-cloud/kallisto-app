import { z } from 'zod';
import { ServiceError } from '../services/errors.js';
import type { ModelTier, NativeTool } from '../services/tool-search.js';
import { boundedJson, type Fetch } from './provider-http.js';

export interface OllamaMessage {
  role: 'system' | 'user' | 'assistant' | 'tool';
  content: string;
  tool_name?: string;
  tool_calls?: { function: { name: string; arguments: Record<string, unknown> } }[];
}
const replySchema = z.object({
  model: z.string(),
  message: z.object({
    role: z.literal('assistant'), content: z.string().max(100_000),
    tool_calls: z.array(z.object({ function: z.object({
      name: z.string().max(64), arguments: z.record(z.string(), z.unknown()),
    }) })).max(16).optional(),
  }),
  done: z.literal(true),
});

export class OllamaAdapter {
  constructor(private readonly apiKey: string, private readonly request: Fetch = fetch) {}

  async complete(tier: ModelTier, messages: readonly OllamaMessage[], tools: NativeTool[]): Promise<OllamaMessage> {
    if (!this.apiKey) throw new ServiceError('OLLAMA_NOT_CONFIGURED', 503);
    const model = tier === 'heavy' ? 'nemotron-3-ultra' : 'gemma4:31b';
    try {
      const response = await this.request('https://ollama.com/api/chat', {
        method: 'POST', redirect: 'error', signal: AbortSignal.timeout(60_000),
        headers: { Authorization: `Bearer ${this.apiKey}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ model, messages, tools, stream: false }),
      });
      const parsed = replySchema.safeParse(await boundedJson(response));
      if (!parsed.success || parsed.data.model !== model) throw new ServiceError('INVALID_PROVIDER_RESPONSE', 502);
      // Never return provider thinking, credentials, or arbitrary envelope fields.
      return parsed.data.message;
    } catch (error) {
      if (error instanceof ServiceError) throw error;
      throw new ServiceError('PROVIDER_UNAVAILABLE', 503);
    }
  }
}
