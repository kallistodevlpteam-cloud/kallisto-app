import { expect, it } from "vitest";
import { isAbsolute } from "node:path";
import { readEnvironment } from "../src/config/environment.js";
import { createProviderAdapters } from "../src/config/providers.js";

const config = {
  FIREBASE_PROJECT_ID: "test-project",
  GOOGLE_APPLICATION_CREDENTIALS: ".private/account.json",
  CORS_ALLOWED_ORIGINS: "http://localhost:5000",
};
it("resolves credentials independently of the invoking working directory", () => {
  const value = readEnvironment(config);
  expect(isAbsolute(value.GOOGLE_APPLICATION_CREDENTIALS)).toBe(true);
  expect(value.GOOGLE_APPLICATION_CREDENTIALS.replaceAll("\\", "/")).toContain(
    "/backend/.private/account.json",
  );
});
it("rejects wildcard, insecure production and malformed origins without echoing config", () => {
  for (const origin of [
    "*",
    "http://untrusted.example",
    "https://user:password@example.test",
  ]) {
    expect(() =>
      readEnvironment({ ...config, CORS_ALLOWED_ORIGINS: origin }),
    ).toThrow("SERVER_CONFIGURATION_INVALID");
  }
  expect(() => readEnvironment({ ...config, NODE_ENV: "production" })).toThrow(
    "SERVER_CONFIGURATION_INVALID",
  );
});
it("keeps operator credentials out of runtime configuration", () => {
  expect(
    JSON.stringify(
      readEnvironment({
        ...config,
        GITHUB_TOKEN: "operator-secret",
        VERCEL_TOKEN: "operator-secret",
      }),
    ),
  ).not.toContain("operator-secret");
});
it("requires explicit demo-only loopback emulator configuration", () => {
  const demo = {
    ...config,
    KALLISTO_EMULATORS: "true",
    FIREBASE_PROJECT_ID: "demo-kallisto",
    FIREBASE_AUTH_EMULATOR_HOST: "127.0.0.1:9099",
    FIRESTORE_EMULATOR_HOST: "127.0.0.1:8088",
  };
  expect(readEnvironment(demo).FIREBASE_PROJECT_ID).toBe("demo-kallisto");
  for (const changed of [
    { NODE_ENV: "production" },
    { FIREBASE_PROJECT_ID: "live-project" },
    { FIRESTORE_EMULATOR_HOST: "remote.example:8088" },
    { KALLISTO_EMULATORS: "false" },
  ])
    expect(() => readEnvironment({ ...demo, ...changed })).toThrow(
      "UNSAFE_EMULATOR_CONFIGURATION",
    );
});
it("rejects provider substitutions, arbitrary endpoints and missing voice configuration", () => {
  const values = {
    OLLAMA_API_KEY: "test",
    CARTESIA_API_KEY: "test",
    CARTESIA_VOICE_ID: "3f41237c-8385-472a-a783-0da9ab58bfc1",
  };
  expect(createProviderAdapters(values)).toHaveProperty("cartesia");
  expect(() =>
    createProviderAdapters({
      ...values,
      CARTESIA_BASE_URL: "https://other.example",
    }),
  ).toThrow("PROVIDERS_NOT_CONFIGURED");
  expect(() =>
    createProviderAdapters({ ...values, CARTESIA_VOICE_ID: "" }),
  ).toThrow("PROVIDERS_NOT_CONFIGURED");
});
