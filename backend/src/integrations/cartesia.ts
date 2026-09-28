import { z } from 'zod';
import { ServiceError } from '../services/errors.js';
import { boundedBytes, boundedJson, type Fetch } from './provider-http.js';

export interface CartesiaConfig {
  apiKey: string;
  apiVersion: string;
  voiceId: string;
  sttModel: string;
  ttsModel: string;
}
export class CartesiaAdapter {
  constructor(private readonly config: CartesiaConfig, private readonly request: Fetch = fetch) {}

  private headers(): Record<string, string> {
    if (!this.config.apiKey || !this.config.apiVersion) throw new ServiceError('VOICE_NOT_CONFIGURED', 503);
    return { Authorization: `Bearer ${this.config.apiKey}`, 'Cartesia-Version': this.config.apiVersion };
  }

  /** Caller owns authorization, source-file identity, consent, quota and adoption. */
  async transcribe(audio: Uint8Array, mime: string, language: string, signal?: AbortSignal): Promise<string> {
    if (signal?.aborted) throw new ServiceError('VOICE_CANCELLED', 409);
    if (!audio.byteLength || audio.byteLength > 1024 * 1024 ||
        !['audio/wav', 'audio/webm', 'audio/mpeg', 'audio/mp4'].includes(mime) ||
        !/^[a-z]{2}(-[A-Z]{2})?$/.test(language)) throw new ServiceError('INVALID_AUDIO');
    if (!this.config.sttModel) throw new ServiceError('VOICE_NOT_CONFIGURED', 503);
    const form = new FormData();
    form.append('file', new Blob([new Uint8Array(audio)], { type: mime }), 'speech');
    form.append('model', this.config.sttModel);
    form.append('language', language);
    try {
      const response = await this.request('https://api.cartesia.ai/stt', {
        method: 'POST', redirect: 'error', headers: this.headers(), body: form,
        signal: signal ? AbortSignal.any([signal, AbortSignal.timeout(45_000)]) : AbortSignal.timeout(45_000),
      });
      const parsed = z.object({ text: z.string().trim().min(1).max(20_000) }).safeParse(await boundedJson(response));
      if (!parsed.success) throw new ServiceError('INVALID_TRANSCRIPT', 502);
      return parsed.data.text;
    } catch (error) {
      if (signal?.aborted) throw new ServiceError('VOICE_CANCELLED', 409);
      if (error instanceof ServiceError) throw error;
      throw new ServiceError('VOICE_UNAVAILABLE', 503);
    }
  }

  /** Receives only the authorized, persisted, final visible assistant response. */
  async synthesize(text: string, language: string, signal?: AbortSignal): Promise<Uint8Array> {
    if (signal?.aborted) throw new ServiceError('VOICE_CANCELLED', 409);
    if (!text.trim() || text.length > 4000 || !/^[a-z]{2}(-[A-Z]{2})?$/.test(language)) {
      throw new ServiceError('INVALID_SPEECH_TEXT');
    }
    if (!this.config.voiceId || !this.config.ttsModel) throw new ServiceError('VOICE_NOT_CONFIGURED', 503);
    try {
      const response = await this.request('https://api.cartesia.ai/tts/bytes', {
        method: 'POST', redirect: 'error',
        signal: signal ? AbortSignal.any([signal, AbortSignal.timeout(45_000)]) : AbortSignal.timeout(45_000),
        headers: { ...this.headers(), 'Content-Type': 'application/json' },
        body: JSON.stringify({ model_id: this.config.ttsModel, transcript: text,
          voice: this.config.voiceId, language,
          output_format: { container: 'wav', encoding: 'pcm_s16le', sample_rate: 24000 } }),
      });
      const data = await boundedBytes(response, 4 * 1024 * 1024);
      const decoder = new TextDecoder();
      if (decoder.decode(data.slice(0, 4)) !== 'RIFF' || decoder.decode(data.slice(8, 12)) !== 'WAVE') {
        throw new ServiceError('INVALID_SPEECH_AUDIO', 502);
      }
      return data;
    } catch (error) {
      if (signal?.aborted) throw new ServiceError('VOICE_CANCELLED', 409);
      if (error instanceof ServiceError) throw error;
      throw new ServiceError('VOICE_UNAVAILABLE', 503);
    }
  }
}
