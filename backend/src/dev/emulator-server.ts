/** Local-only fixture and runner. Never imports live .env or service credentials. */
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { readEnvironment } from "../config/environment.js";
import { firebaseClientRepository } from "../repositories/firebase-client-repository.js";
import { createApp } from "../app.js";

process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8088";
process.env.FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099";
const config = readEnvironment({
  NODE_ENV: "test",
  FIREBASE_PROJECT_ID: "demo-kallisto",
  FIRESTORE_DATABASE_ID: "(default)",
  GOOGLE_APPLICATION_CREDENTIALS: "unused",
  KALLISTO_EMULATORS: "true",
  FIRESTORE_EMULATOR_HOST: process.env.FIRESTORE_EMULATOR_HOST,
  FIREBASE_AUTH_EMULATOR_HOST: process.env.FIREBASE_AUTH_EMULATOR_HOST,
  CORS_ALLOWED_ORIGINS: "http://localhost:8080,http://127.0.0.1:8080",
  PORT: "4000",
});
const fixtureApp = initializeApp(
  { projectId: "demo-kallisto" },
  "emulator-fixtures",
);
const db = getFirestore(fixtureApp);
await db
  .doc("system_settings/features")
  .set({
    policy_version: "test-only-v1",
    approved_by_uid: "local-test-operator",
    values: {
      client_enrollment_notice: {
        version: "test-only-v1",
        text: "LOCAL TEST ONLY: This workspace uses isolated Firebase emulators and synthetic records. Creating a test workspace is not a legal agreement and does not enroll you in the live service.",
      },
    },
  });
const repository = firebaseClientRepository(config);
const app = await createApp(repository, config.origins, repository.workflows);
await app.listen({ host: "127.0.0.1", port: 4000 });
process.stdout.write(
  "Local test API: http://127.0.0.1:4000 (demo-kallisto emulators only)\n",
);
