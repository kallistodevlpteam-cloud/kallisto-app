import { expect, it, vi } from 'vitest';
import { OllamaAdapter } from '../src/integrations/ollama.js';
import { CartesiaAdapter } from '../src/integrations/cartesia.js';
import { boundedBytes } from '../src/integrations/provider-http.js';
import { searchTool } from '../src/services/tool-search.js';

it('uses Gemma or Nemotron according to server tier and strips thinking', async () => {
  const request = vi.fn<typeof fetch>().mockImplementation(async (_url, init) => {
    const body = JSON.parse(String(init?.body)) as { model: string };
    return Response.json({ model: body.model, done: true, message: { role: 'assistant', content: 'Visible answer', thinking: 'Never publish' } });
  });
  const adapter = new OllamaAdapter('test-key', request);
  expect(await adapter.complete('routine', [{ role: 'user', content: 'Hello' }], [searchTool])).toEqual({ role: 'assistant', content: 'Visible answer' });
  await adapter.complete('heavy', [{ role: 'user', content: 'Analyze' }], [searchTool]);
  expect(JSON.parse(String(request.mock.calls[0]![1]!.body)).model).toBe('gemma4:31b');
  expect(JSON.parse(String(request.mock.calls[1]![1]!.body)).model).toBe('nemotron-3-ultra');
});
it('rejects silent model substitution and incomplete responses', async () => {
  const request = vi.fn<typeof fetch>().mockResolvedValue(Response.json({ model: 'different', done: true, message: { role: 'assistant', content: 'Hi' } }));
  await expect(new OllamaAdapter('test', request).complete('routine', [], [searchTool])).rejects.toMatchObject({ code: 'INVALID_PROVIDER_RESPONSE' });
});
it('does not expose provider error bodies', async () => {
  const request = vi.fn<typeof fetch>().mockResolvedValue(new Response('secret diagnostic', { status: 401 }));
  await expect(new OllamaAdapter('test', request).complete('routine', [], [searchTool])).rejects.toMatchObject({ message: 'PROVIDER_UNAVAILABLE' });
});
it('bounds streamed responses even without content length', async () => {
  await expect(boundedBytes(new Response('too large'), 3)).rejects.toMatchObject({ code: 'PROVIDER_RESPONSE_TOO_LARGE' });
});

const config = { apiKey: 'test-key', apiVersion: 'test-version', voiceId: 'configured-voice', sttModel: 'ink-whisper', ttsModel: 'sonic-3.6' };
it('sends actual audio to STT and returns a nonempty transcript', async () => {
  const request = vi.fn<typeof fetch>().mockResolvedValue(Response.json({ text: 'A two-storey home.' }));
  const result = await new CartesiaAdapter(config, request).transcribe(new Uint8Array([1, 2]), 'audio/wav', 'en');
  expect(result).toBe('A two-storey home.');
  expect(request.mock.calls[0]![0]).toBe('https://api.cartesia.ai/stt');
  expect((request.mock.calls[0]![1]!.body as FormData).get('file')).toBeInstanceOf(Blob);
});
it('does not call STT for invalid audio or treat empty transcript as success', async () => {
  const request = vi.fn<typeof fetch>().mockResolvedValue(Response.json({ text: ' ' }));
  const adapter = new CartesiaAdapter(config, request);
  await expect(adapter.transcribe(new Uint8Array(), 'audio/wav', 'en')).rejects.toMatchObject({ code: 'INVALID_AUDIO' });
  expect(request).not.toHaveBeenCalled();
  await expect(adapter.transcribe(new Uint8Array([1]), 'audio/wav', 'en')).rejects.toMatchObject({ code: 'INVALID_TRANSCRIPT' });
});
it('requires a configured voice and validates generated WAV bytes', async () => {
  const request = vi.fn<typeof fetch>().mockResolvedValue(new Response(new TextEncoder().encode('RIFF0000WAVEdata')));
  const adapter = new CartesiaAdapter(config, request);
  expect((await adapter.synthesize('Your brief is ready to review.', 'en')).length).toBeGreaterThan(0);
  const body = JSON.parse(String(request.mock.calls[0]![1]!.body));
  expect(body).toMatchObject({ voice: 'configured-voice', model_id: 'sonic-3.6', transcript: 'Your brief is ready to review.' });
  await expect(new CartesiaAdapter({ ...config, voiceId: '' }, request).synthesize('Hello', 'en')).rejects.toMatchObject({ code: 'VOICE_NOT_CONFIGURED' });
});

it('cancels voice operations without sending audio or text after interruption', async () => {
  const request = vi.fn<typeof fetch>();
  const adapter = new CartesiaAdapter(config, request);
  const controller = new AbortController(); controller.abort();
  await expect(adapter.synthesize('Hello', 'en', controller.signal)).rejects.toMatchObject({code: 'VOICE_CANCELLED'});
  await expect(adapter.transcribe(new Uint8Array([1]), 'audio/wav', 'en', controller.signal)).rejects.toMatchObject({code: 'VOICE_CANCELLED'});
  expect(request).not.toHaveBeenCalled();
});

it('rejects an invalid successful audio response and overlong speech text', async () => {
  const request = vi.fn<typeof fetch>().mockResolvedValue(new Response('not wav'));
  const adapter = new CartesiaAdapter(config, request);
  await expect(adapter.synthesize('Hello', 'en')).rejects.toMatchObject({code: 'INVALID_SPEECH_AUDIO'});
  await expect(adapter.synthesize('x'.repeat(4001), 'en')).rejects.toMatchObject({code: 'INVALID_SPEECH_TEXT'});
  expect(request).toHaveBeenCalledOnce();
});
