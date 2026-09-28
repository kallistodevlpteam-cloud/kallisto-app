import { config as dotenv } from "dotenv";
import { fileURLToPath } from "node:url";
import { resolve } from "node:path";
import { z } from "zod";
import { ServiceError } from "../services/errors.js";

const schema = z.object({
  NODE_ENV: z
    .enum(["development", "test", "production"])
    .default("development"),
  HOST: z.string().default("127.0.0.1"),
  PORT: z.coerce.number().int().min(1).max(65535).default(4000),
  FIREBASE_PROJECT_ID: z.string().min(1),
  FIRESTORE_DATABASE_ID: z.string().default("(default)"),
  GOOGLE_APPLICATION_CREDENTIALS: z.string().min(1),
  KALLISTO_EMULATORS: z.enum(["true", "false"]).default("false"),
  CORS_ALLOWED_ORIGINS: z.string().min(1),
  OLLAMA_CHAT_MODEL: z.literal("gemma4:31b").default("gemma4:31b"),
  OLLAMA_AGENT_MODEL: z.literal("nemotron-3-ultra").default("nemotron-3-ultra"),
});
export type Environment = z.infer<typeof schema> & { origins: string[] };

export function readEnvironment(
  values: NodeJS.ProcessEnv = process.env,
): Environment {
  const parsed = schema.safeParse(values);
  if (!parsed.success)
    throw new ServiceError("SERVER_CONFIGURATION_INVALID", 503);
  const emulatorHosts = [
    values.FIREBASE_AUTH_EMULATOR_HOST,
    values.FIRESTORE_EMULATOR_HOST,
  ];
  if (parsed.data.KALLISTO_EMULATORS === "true") {
    if (
      parsed.data.NODE_ENV === "production" ||
      !parsed.data.FIREBASE_PROJECT_ID.startsWith("demo-") ||
      emulatorHosts.some(
        (host) => !host || !/^127\.0\.0\.1:\d{2,5}$/.test(host),
      )
    )
      throw new ServiceError("UNSAFE_EMULATOR_CONFIGURATION", 503);
  } else if (
    emulatorHosts.some(Boolean) ||
    parsed.data.FIREBASE_PROJECT_ID.startsWith("demo-")
  )
    throw new ServiceError("UNSAFE_EMULATOR_CONFIGURATION", 503);
  const origins = parsed.data.CORS_ALLOWED_ORIGINS.split(",").map((value) =>
    value.trim(),
  );
  for (const origin of origins) {
    let url: URL;
    try {
      url = new URL(origin);
    } catch {
      throw new ServiceError("SERVER_CONFIGURATION_INVALID", 503);
    }
    const local = ["localhost", "127.0.0.1", "[::1]"].includes(url.hostname);
    if (
      url.origin !== origin ||
      (url.protocol !== "https:" &&
        !(
          parsed.data.NODE_ENV !== "production" &&
          local &&
          url.protocol === "http:"
        ))
    ) {
      throw new ServiceError("SERVER_CONFIGURATION_INVALID", 503);
    }
  }
  return {
    ...parsed.data,
    origins,
    GOOGLE_APPLICATION_CREDENTIALS: resolve(
      fileURLToPath(new URL("../../", import.meta.url)),
      parsed.data.GOOGLE_APPLICATION_CREDENTIALS,
    ),
  };
}

export function loadEnvironment(): Environment {
  dotenv({
    path: fileURLToPath(new URL("../../.env", import.meta.url)),
    quiet: true,
  });
  return readEnvironment();
}
