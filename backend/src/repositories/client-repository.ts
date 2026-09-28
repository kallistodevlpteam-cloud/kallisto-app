import { z } from 'zod';
import type { Identity } from '../services/client-contracts.js';

export const accessSchema = z.object({
  uid: z.string().min(1), role: z.enum(['client', 'provider', 'partner', 'internal']),
  organization_id: z.string().min(1), active: z.boolean(), verified: z.boolean(),
  access_revision: z.number().int().nonnegative(), client_id: z.string().nullable().optional(),
});
export type Access = z.infer<typeof accessSchema>;
export const projectSchema = z.object({
  project_id: z.string().min(1), owner_uid: z.string().min(1),
  name: z.string().min(1).max(120),
  project_type: z.enum(['architecture', 'interior', 'construction', 'renovation', 'other']),
  status: z.enum(['draft', 'active', 'on_hold', 'cancelled', 'completed', 'archived']),
  phase: z.string().max(80), location: z.string().max(240).nullable().optional(),
});
export type Project = z.infer<typeof projectSchema>;
export interface ClientRepository {
  verifyIdentity(token: string): Promise<Identity>;
  verifyToken(token: string): Promise<string>;
  access(uid: string): Promise<Access | null>;
  displayName(uid: string): Promise<string>;
  projects(uid: string, cursor?: string): Promise<{ items: Project[]; next_cursor: string | null }>;
}
