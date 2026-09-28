import { z } from 'zod';
import type { RecordData, RecordStore, RecordTransaction } from '../repositories/record-store.js';
import { hash, id, parse } from './client-contracts.js';
import { ServiceError } from './errors.js';

export const providerQuery = z.strictObject({category:z.string().regex(/^[a-z_]{1,80}$/).optional(),coverage:z.string().regex(/^[a-zA-Z0-9_-]{1,80}$/).optional(),cursor:z.string().max(2048).optional(),limit:z.coerce.number().int().min(1).max(25).default(20)});
const profileSchema = z.object({profile_id:id,subject_type:z.literal('provider'),subject_id:id,organization_id:id,name:z.string().max(120),summary:z.string().max(1000),service_codes:z.array(z.string()).max(100),coverage_codes:z.array(z.string()).max(100),publication_status:z.literal('published'),verification_badge:z.object({state:z.literal('approved'),category_codes:z.array(z.string()).max(100),verification_record_id:id})});
export class ProviderDirectory {
  constructor(private store:RecordStore, private authorize:(tx:RecordTransaction,uid:string)=>Promise<unknown>) {}
  private async visible(tx:RecordTransaction, row:RecordData) {
    const parsed=profileSchema.safeParse(row);
    if (!parsed.success) return null;
    const profile=parsed.data;
    const principal=await tx.get(`provider_profiles/${profile.subject_id}`);
    if (!principal || typeof principal.owner_uid !== 'string' || !id.safeParse(principal.owner_uid).success || principal.provider_id !== profile.subject_id || principal.organization_id !== profile.organization_id) return null;
    const access=await tx.get(`user_access/${principal.owner_uid}`);
    const verification=await tx.get(`verification_records/${profile.verification_badge.verification_record_id}`);
    if (!access || access.active !== true || access.verified !== true || access.role !== 'provider' || access.organization_id !== profile.organization_id || access.provider_id !== profile.subject_id || access.verification_record_id !== profile.verification_badge.verification_record_id || !verification || verification.outcome !== 'approved' || verification.subject_type !== 'provider' || verification.subject_id !== profile.subject_id) return null;
    if (verification.valid_until != null) {
      const expiry=verification.valid_until;
      const millis=typeof expiry === 'object' && 'toMillis' in expiry && typeof expiry.toMillis === 'function' ? expiry.toMillis() : typeof expiry === 'string' ? Date.parse(expiry) : NaN;
      if (!Number.isFinite(millis) || millis <= Date.now()) return null;
    }
    const categories=z.array(z.string()).safeParse(verification.category_codes);
    const coverage=z.object({region_codes:z.array(z.string())}).safeParse(verification.coverage);
    if (!categories.success || !coverage.success) return null;
    return {provider_id:profile.profile_id,name:profile.name,summary:profile.summary,
      service_codes:profile.service_codes.filter(code=>categories.data.includes(code)),
      coverage_codes:profile.coverage_codes.filter(code=>coverage.data.region_codes.includes(code)),
      verified_categories:profile.verification_badge.category_codes.filter(code=>categories.data.includes(code)),
      verification_state:'approved'};
  }
  async list(uid:string, input:unknown) {
    const query=parse(providerQuery,input);
    const binding=hash([uid,'providers.v1',query.category??null,query.coverage??null,query.limit]);
    let cursor:string|undefined;
    if (query.cursor) {
      try {
        const decoded=parse(z.strictObject({binding:z.literal(binding),after:id}),JSON.parse(Buffer.from(query.cursor,'base64url').toString('utf8')));
        cursor=decoded.after;
      } catch {throw new ServiceError('INVALID_QUERY',422);}
    }
    return this.store.transaction(async tx=>{
      await this.authorize(tx,uid);
      const rows=await tx.list({collection:'published_profiles',filters:[['subject_type','provider'],['publication_status','published']],...(cursor?{cursor}:{}),limit:query.limit+1});
      const page=rows.slice(0,query.limit), items=[];
      for (const row of page) {
        const safe=await this.visible(tx,row);
        if (safe && (!query.category || safe.service_codes.includes(query.category)) && (!query.coverage || safe.coverage_codes.includes(query.coverage))) items.push(safe);
      }
      const hasMore=rows.length>query.limit;
      const after=page.at(-1)?._id;
      return {items,has_more:hasMore,next_cursor:hasMore && typeof after==='string' ? Buffer.from(JSON.stringify({binding,after})).toString('base64url'):null};
    });
  }
  async detail(uid:string,profileId:string) {
    return this.store.transaction(async tx=>{
      await this.authorize(tx,uid);
      const row=await tx.get(`published_profiles/${parse(id,profileId)}`);
      const visible=row && row.profile_id === profileId ? await this.visible(tx,row):null;
      if (!visible) throw new ServiceError('NOT_FOUND',404);
      return visible;
    });
  }
}
