import { z } from 'zod';
import type { RecordData, RecordStore, RecordTransaction } from '../repositories/record-store.js';
import { hash, parse } from './client-contracts.js';
import { ServiceError } from './errors.js';

const language = z.enum(['en', 'ml']);
const units = z.enum(['metric', 'imperial', 'mixed']);
const kinds = z.enum(['review_due', 'task_due', 'visit_due']);
const timezone = z.string().max(100).refine(value => {
  try { new Intl.DateTimeFormat('en', { timeZone: value }); return true; } catch { return false; }
});
const time = z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/);
export const preferenceSchemas = {
  appearance: z.strictObject({theme: z.enum(['light', 'dark', 'system']), density: z.enum(['comfortable', 'compact']), reduce_motion: z.boolean()}),
  notifications: z.strictObject({in_app: z.boolean(), email: z.boolean(), push: z.boolean(), reminder_preferences: z.array(z.strictObject({kind: kinds, enabled: z.boolean(), lead_minutes: z.number().int().min(0).max(10080)})).max(3).refine(rows => new Set(rows.map(r => r.kind)).size === rows.length)}),
  communication: z.strictObject({preferred_language: language, preferred_channel: z.enum(['in_app', 'email', 'push']), quiet_hours: z.strictObject({weekday_codes: z.array(z.enum(['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'])).max(7), start_local: time.optional(), end_local: time.optional(), timezone, notes: z.string().max(1000).optional()}).optional()}),
  language_region: z.strictObject({language, timezone, date_format: z.enum(['DD_MM_YYYY', 'YYYY_MM_DD']), unit_preference: units}),
  project_preferences: z.strictObject({default_view: z.enum(['overview', 'design', 'build', 'money', 'files']), default_units: units, notification_preferences: z.array(kinds).max(3)}),
  privacy: z.strictObject({optional_analytics_consent: z.boolean(), marketing_consent: z.boolean()}),
  security: z.strictObject({security_notification_enabled: z.boolean()}),
  odin: z.strictObject({preferred_mode: z.enum(['text', 'voice', 'manual']), spoken_replies_enabled: z.boolean(), preferred_language: language}),
  billing: z.strictObject({billing_contact: z.strictObject({name: z.string().max(120).optional(), email: z.email().max(254).optional(), phone_e164: z.string().regex(/^\+[1-9]\d{1,14}$/).optional(), address: z.string().max(2000).optional()}), invoice_delivery_email: z.email().max(254).optional()}),
};
export type PreferenceSection = keyof typeof preferenceSchemas;
export const preferenceSection = z.enum(Object.keys(preferenceSchemas) as [PreferenceSection, ...PreferenceSection[]]);
export const preferenceKey = (uid: string, section: string) => hash([uid, section]);
const defaults: Record<PreferenceSection, RecordData> = {
  appearance: {theme:'system', density:'comfortable', reduce_motion:false},
  notifications: {in_app:true, email:false, push:false, reminder_preferences:[]},
  communication: {preferred_language:'en', preferred_channel:'in_app'},
  language_region: {language:'en', timezone:'Asia/Kolkata', date_format:'DD_MM_YYYY', unit_preference:'metric'},
  project_preferences: {default_view:'overview', default_units:'metric', notification_preferences:[]},
  privacy: {optional_analytics_consent:false, marketing_consent:false},
  security: {security_notification_enabled:true},
  odin: {preferred_mode:'manual', spoken_replies_enabled:false, preferred_language:'en'},
  billing: {billing_contact:{}},
};

export class ClientSettingsService {
  constructor(private store: RecordStore, private authorize: (tx: RecordTransaction, uid: string) => Promise<unknown>) {}
  private async read(tx: RecordTransaction, uid: string, section: PreferenceSection) {
    const row = await tx.get(`user_preferences/${preferenceKey(uid, section)}`);
    if (row && (row.uid !== uid || row.section !== section)) throw new ServiceError('NOT_FOUND', 404);
    const user = !row && section === 'language_region' ? await tx.get(`users/${uid}`) : null;
    const initial = user ? {...defaults.language_region,
      language:language.safeParse(user.preferred_language).success ? user.preferred_language : 'en',
      timezone:timezone.safeParse(user.preferred_timezone).success ? user.preferred_timezone : 'Asia/Kolkata'} : defaults[section];
    return {section, row_version: row ? parse(z.number().int().positive(), row.row_version) : 0,
      values: parse(preferenceSchemas[section] as z.ZodType<RecordData>, row?.values ?? initial), row};
  }
  async get(uid: string, section: PreferenceSection) {
    return this.store.transaction(async tx => {
      await this.authorize(tx, uid);
      const value = await this.read(tx, uid, section);
      if (section === 'communication') {
        const region = await this.read(tx, uid, 'language_region');
        (value.values as RecordData).preferred_language = (region.values as RecordData).language;
      }
      return {section, row_version:value.row_version, values:value.values};
    });
  }
  async save(uid: string, section: PreferenceSection, input: unknown, key: string) {
    parse(z.string().regex(/^[a-zA-Z0-9_-]{16,128}$/), key);
    const data = parse(z.strictObject({expected_version:z.number().int().nonnegative(), values:preferenceSchemas[section]}), input);
    const command = hash([uid, 'PREFERENCES_SAVE', section, key]);
    await this.store.transaction(async tx => {
      await this.authorize(tx, uid);
      const current = await this.read(tx, uid, section);
      const previous = await tx.get(`idempotency_records/${command}`);
      if (previous) {
        if (previous.request_hash !== hash(data)) throw new ServiceError('IDEMPOTENCY_CONFLICT',409);
        return;
      }
      if (current.row_version !== data.expected_version) throw new ServiceError('STALE_VERSION',409);
      const region = section === 'communication' ? await this.read(tx, uid, 'language_region') : null;
      const user = (section === 'communication' || section === 'language_region') ? await tx.get(`users/${uid}`) : null;
      const communication = section === 'language_region' ? await this.read(tx, uid, 'communication') : null;
      const metadata = {schema_version:1, created_at:this.store.timestamp(), created_by_uid:uid, updated_at:this.store.timestamp(), updated_by_uid:uid};
      const write = (target: PreferenceSection, prior: {row:RecordData|null;row_version:number}, values: unknown) => {
        tx.set(`user_preferences/${preferenceKey(uid,target)}`, {...metadata, ...prior.row,
          preference_key:preferenceKey(uid,target), uid, section:target, values,
          row_version:prior.row_version+1, updated_at:this.store.timestamp(), updated_by_uid:uid});
      };
      write(section,current,data.values);
      const values = data.values as RecordData;
      if (region) write('language_region',region,{...region.values,language:values.preferred_language});
      if (communication) write('communication',communication,{...communication.values,preferred_language:values.language});
      if (user) tx.set(`users/${uid}`, {...user, preferred_language:values.language ?? values.preferred_language,
        ...(section === 'language_region' ? {preferred_timezone:values.timezone} : {}),
        row_version:Number(user.row_version ?? 0)+1, updated_at:this.store.timestamp(), updated_by_uid:uid});
      tx.create(`audit_events/${command}`, {...metadata,event_id:command,actor_uid:uid,operation:'PREFERENCES_SAVE',resource_type:'user_preferences',resource_id:preferenceKey(uid,section),result:'committed'});
      tx.create(`idempotency_records/${command}`, {...metadata,command_key:command,actor_uid:uid,operation:'PREFERENCES_SAVE',resource_key:preferenceKey(uid,section),request_hash:hash(data),status:'committed',result_ref:{section,row_version:current.row_version+1}});
    });
    // Reauthorize and return current preferences rather than an old cached private DTO.
    return this.get(uid,section);
  }
}
