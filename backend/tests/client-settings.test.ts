import { describe, it, expect } from 'vitest';
import { ClientSettingsService, preferenceKey } from '../src/services/client-settings.js';
import type { RecordData, RecordStore } from '../src/repositories/record-store.js';
import { ServiceError } from '../src/services/errors.js';

function fixture() {
  const rows = new Map<string,RecordData>([['users/alice',{uid:'alice',row_version:1,display_name:'Alice'}]]);
  let active = true;
  const store: RecordStore = {
    timestamp: () => 'test-time', get: async path => rows.get(path) ?? null, list: async () => [],
    async transaction(action) {
      const draft = new Map(rows);
      const result = await action({get:async path => draft.get(path) ?? null, list:async()=>[],
        create(path,value) { if (draft.has(path)) throw Error('Already exists'); draft.set(path,value); },
        set(path,value) { draft.set(path,value); }});
      rows.clear(); for (const [key,value] of draft) rows.set(key,value);
      return result;
    },
  };
  return {rows, revoke:()=>{active=false;}, service:new ClientSettingsService(store,async()=>{
    if (!active) throw new ServiceError('FORBIDDEN',403);
  })};
}
const privacy = {optional_analytics_consent:false, marketing_consent:true};
describe('private client settings',()=>{
  it('saves an exact schema and preserves it across service reads',async()=>{
    const {service,rows} = fixture();
    expect((await service.get('alice','privacy')).row_version).toBe(0);
    await service.save('alice','privacy',{expected_version:0,values:privacy},'save-privacy-0001');
    expect(await service.get('alice','privacy')).toEqual({section:'privacy',row_version:1,values:privacy});
    expect((await service.get('bob','privacy')).values.marketing_consent).toBe(false);
    expect(rows.get(`user_preferences/${preferenceKey('alice','privacy')}`)?.uid).toBe('alice');
  });
  it('replays once and rejects changed payloads and stale tabs without overwriting',async()=>{
    const {service,rows} = fixture();
    const input={expected_version:0,values:privacy};
    await service.save('alice','privacy',input,'save-privacy-0001');
    await service.save('alice','privacy',input,'save-privacy-0001');
    expect([...rows.keys()].filter(k=>k.startsWith('audit_events/'))).toHaveLength(1);
    await expect(service.save('alice','privacy',{...input,values:{...privacy,marketing_consent:false}},'save-privacy-0001')).rejects.toMatchObject({code:'IDEMPOTENCY_CONFLICT'});
    await expect(service.save('alice','privacy',input,'save-privacy-0002')).rejects.toMatchObject({code:'STALE_VERSION'});
  });
  it('rechecks access on replay',async()=>{
    const {service,revoke}=fixture();
    const input={expected_version:0,values:privacy};
    await service.save('alice','privacy',input,'save-privacy-0001'); revoke();
    await expect(service.save('alice','privacy',input,'save-privacy-0001')).rejects.toMatchObject({code:'FORBIDDEN'});
  });
  it('rejects role injection and invalid zones with no writes',async()=>{
    const {service,rows}=fixture();
    await expect(service.save('alice','privacy',{expected_version:0,values:{...privacy,role:'internal'}},'save-privacy-0001')).rejects.toBeDefined();
    await expect(service.save('alice','language_region',{expected_version:0,values:{language:'en',timezone:'invented',date_format:'YYYY_MM_DD',unit_preference:'metric'}},'save-language-01')).rejects.toBeDefined();
    expect(rows.size).toBe(1);
  });
  it('synchronizes canonical language and versions conflicting editors',async()=>{
    const {service,rows}=fixture();
    await service.save('alice','communication',{expected_version:0,values:{preferred_language:'ml',preferred_channel:'in_app'}},'save-language-01');
    expect((await service.get('alice','language_region')).values.language).toBe('ml');
    expect(rows.get('users/alice')?.preferred_language).toBe('ml');
    await expect(service.save('alice','language_region',{expected_version:0,values:{language:'en',timezone:'Asia/Kolkata',date_format:'DD_MM_YYYY',unit_preference:'metric'}},'save-language-02')).rejects.toMatchObject({code:'STALE_VERSION'});
  });
});
