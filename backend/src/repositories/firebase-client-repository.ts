import { readFileSync } from "node:fs";
import { randomUUID } from "node:crypto";
import { cert, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { FieldPath, getFirestore } from "firebase-admin/firestore";
import { z } from "zod";
import type { Environment } from "../config/environment.js";
import { ServiceError } from "../services/errors.js";
import {
  accessSchema,
  projectSchema,
  type ClientRepository,
} from "./client-repository.js";
import { firestoreRecordStore } from "./record-store.js";
import { ClientWorkflows } from "../services/client-workflows.js";

export function firebaseClientRepository(
  config: Environment,
): ClientRepository & { workflows: ClientWorkflows } {
  const credentials =
    config.KALLISTO_EMULATORS === "true"
      ? null
      : z
          .object({
            project_id: z.string(),
            client_email: z.string(),
            private_key: z.string(),
          })
          .safeParse(
            JSON.parse(
              readFileSync(config.GOOGLE_APPLICATION_CREDENTIALS, "utf8"),
            ) as unknown,
          );
  if (
    credentials &&
    (!credentials.success ||
      credentials.data.project_id !== config.FIREBASE_PROJECT_ID)
  ) {
    throw new ServiceError("SERVER_CONFIGURATION_INVALID", 503);
  }
  const app = credentials?.success
    ? initializeApp(
        {
          projectId: config.FIREBASE_PROJECT_ID,
          credential: cert({
            projectId: credentials.data.project_id,
            clientEmail: credentials.data.client_email,
            privateKey: credentials.data.private_key,
          }),
        },
        `kallisto-${randomUUID()}`,
      )
    : initializeApp(
        { projectId: config.FIREBASE_PROJECT_ID },
        `kallisto-${randomUUID()}`,
      );
  const auth = getAuth(app);
  const db = getFirestore(app, config.FIRESTORE_DATABASE_ID);
  return {
    workflows: new ClientWorkflows(firestoreRecordStore(db)),
    async verifyIdentity(token) {
      try {
        const decoded = await auth.verifyIdToken(token, true);
        return {
          uid: decoded.uid,
          email: decoded.email,
          emailVerified: decoded.email_verified === true,
        };
      } catch {
        throw new ServiceError("UNAUTHENTICATED", 401);
      }
    },
    async verifyToken(token) {
      try {
        return (await auth.verifyIdToken(token, true)).uid;
      } catch {
        throw new ServiceError("UNAUTHENTICATED", 401);
      }
    },
    async access(uid) {
      const snapshot = await db.doc(`user_access/${uid}`).get();
      const parsed = accessSchema.safeParse(snapshot.data());
      return parsed.success && parsed.data.uid === uid ? parsed.data : null;
    },
    async displayName(uid) {
      const snapshot = await db.doc(`users/${uid}`).get();
      const parsed = z
        .object({ uid: z.literal(uid), display_name: z.string().max(120) })
        .safeParse(snapshot.data());
      return parsed.success ? parsed.data.display_name : "";
    },
    async projects(uid, cursor) {
      let query = db
        .collection("projects")
        .where("owner_uid", "==", uid)
        .orderBy(FieldPath.documentId())
        .limit(21);
      if (cursor) query = query.startAfter(cursor);
      const snapshot = await query.get();
      const rows = snapshot.docs.slice(0, 20);
      const items = rows.map((doc) => {
        const parsed = projectSchema.safeParse(doc.data());
        if (
          !parsed.success ||
          parsed.data.project_id !== doc.id ||
          parsed.data.owner_uid !== uid
        ) {
          throw new ServiceError("PROJECT_DATA_UNAVAILABLE", 503);
        }
        return parsed.data;
      });
      return {
        items,
        next_cursor: snapshot.size > 20 ? rows.at(-1)!.id : null,
      };
    },
  };
}
