import {
  FieldPath,
  FieldValue,
  type Firestore,
  type Query,
  type Transaction,
} from "firebase-admin/firestore";

export type RecordData = Record<string, unknown>;
export interface StoreQuery {
  collection: string;
  filters?: readonly [string, unknown][];
  cursor?: string;
  limit?: number;
}
export interface RecordReader {
  get(path: string): Promise<RecordData | null>;
  list(query: StoreQuery): Promise<RecordData[]>;
}
export interface RecordTransaction extends RecordReader {
  create(path: string, value: RecordData): void;
  set(path: string, value: RecordData): void;
}
export interface RecordStore extends RecordReader {
  transaction<T>(action: (tx: RecordTransaction) => Promise<T>): Promise<T>;
  timestamp(): unknown;
}

export function firestoreRecordStore(db: Firestore): RecordStore {
  function query(input: StoreQuery): Query {
    let result: Query = db.collection(input.collection);
    for (const [field, value] of input.filters ?? [])
      result = result.where(field, "==", value);
    result = result.orderBy(FieldPath.documentId()).limit(input.limit ?? 21);
    return input.cursor ? result.startAfter(input.cursor) : result;
  }
  const reader = (tx?: Transaction): RecordReader => ({
    async get(path) {
      const ref = db.doc(path);
      return (tx ? await tx.get(ref) : await ref.get()).data() ?? null;
    },
    async list(input) {
      const ref = query(input);
      return (tx ? await tx.get(ref) : await ref.get()).docs.map((doc) => ({
        ...doc.data(),
        _id: doc.id,
      }));
    },
  });
  return {
    ...reader(),
    timestamp: () => FieldValue.serverTimestamp(),
    transaction: (action) =>
      db.runTransaction((tx) =>
        action({
          ...reader(tx),
          create: (path, value) => {
            tx.create(db.doc(path), value);
          },
          set: (path, value) => {
            tx.set(db.doc(path), value);
          },
        }),
      ),
  };
}
