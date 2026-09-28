import { ServiceError } from '../services/errors.js';

export type Fetch = typeof fetch;

export async function boundedBytes(response: Response, maximum: number): Promise<Uint8Array> {
  if (!response.ok) {
    await response.body?.cancel();
    throw new ServiceError(response.status === 429 ? 'PROVIDER_RATE_LIMITED' : 'PROVIDER_UNAVAILABLE', 503);
  }
  if (Number(response.headers.get('content-length')) > maximum) {
    await response.body?.cancel();
    throw new ServiceError('PROVIDER_RESPONSE_TOO_LARGE', 502);
  }
  const reader = response.body?.getReader();
  if (!reader) throw new ServiceError('EMPTY_PROVIDER_RESPONSE', 502);
  const chunks: Uint8Array[] = [];
  let length = 0;
  try {
    for (;;) {
      const part = await reader.read();
      if (part.done) break;
      length += part.value.byteLength;
      if (length > maximum) {
        await reader.cancel();
        throw new ServiceError('PROVIDER_RESPONSE_TOO_LARGE', 502);
      }
      chunks.push(part.value);
    }
  } finally { reader.releaseLock(); }
  const data = new Uint8Array(length);
  let offset = 0;
  for (const chunk of chunks) { data.set(chunk, offset); offset += chunk.byteLength; }
  return data;
}

export async function boundedJson(response: Response): Promise<unknown> {
  const bytes = await boundedBytes(response, 1024 * 1024);
  try { return JSON.parse(new TextDecoder().decode(bytes)) as unknown; }
  catch { throw new ServiceError('INVALID_PROVIDER_RESPONSE', 502); }
}
