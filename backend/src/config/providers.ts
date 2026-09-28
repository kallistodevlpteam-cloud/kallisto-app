import { z } from 'zod';
import { CartesiaAdapter } from '../integrations/cartesia.js';
import { OllamaAdapter } from '../integrations/ollama.js';
import { ServiceError } from '../services/errors.js';

/** Explicit allowlist: delivery credentials never enter a provider adapter. */
const schema = z.object({
  OLLAMA_API_KEY: z.string().min(1),
  OLLAMA_BASE_URL: z.literal('https://ollama.com').default('https://ollama.com'),
  OLLAMA_CHAT_MODEL: z.literal('gemma4:31b').default('gemma4:31b'),
  OLLAMA_AGENT_MODEL: z.literal('nemotron-3-ultra').default('nemotron-3-ultra'),
  CARTESIA_API_KEY: z.string().min(1),
  CARTESIA_BASE_URL: z.literal('https://api.cartesia.ai').default('https://api.cartesia.ai'),
  CARTESIA_API_VERSION: z.literal('2026-08-14').default('2026-08-14'),
  CARTESIA_STT_MODEL: z.literal('ink-whisper').default('ink-whisper'),
  CARTESIA_TTS_MODEL: z.literal('sonic-3.6').default('sonic-3.6'),
  CARTESIA_VOICE_ID: z.uuid(),
});

/** Construction is not permission to process data; the job service owns consent and quota. */
export function createProviderAdapters(values: NodeJS.ProcessEnv) {
  const result = schema.safeParse(values);
  if (!result.success) throw new ServiceError('PROVIDERS_NOT_CONFIGURED', 503);
  const config = result.data;
  return {
    ollama: new OllamaAdapter(config.OLLAMA_API_KEY),
    cartesia: new CartesiaAdapter({apiKey: config.CARTESIA_API_KEY,
      apiVersion: config.CARTESIA_API_VERSION, voiceId: config.CARTESIA_VOICE_ID,
      sttModel: config.CARTESIA_STT_MODEL, ttsModel: config.CARTESIA_TTS_MODEL}),
  };
}
