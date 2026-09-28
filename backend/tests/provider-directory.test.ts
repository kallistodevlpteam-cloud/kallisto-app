import { it, expect } from 'vitest';
import { ProviderDirectory } from '../src/services/provider-directory.js';
import type { RecordStore, RecordData } from '../src/repositories/record-store.js';
function fixture() {
  const rows = new Map<string,RecordData>([
    ['published_profiles/public-a',{_id:'public-a',profile_id:'public-a',subject_type:'provider',subject_id:'practice',organization_id:'org',name:'Published practice',summary:'Approved summary',service_codes:['architectural_design','private_extra'],coverage_codes:['region','unapproved'],publication_status:'published',verification_badge:{state:'approved',category_codes:['architectural_design'],verification_record_id:'v1'},secret:'must-not-leak'}],
    ['provider_profiles/practice',{provider_id:'practice',organization_id:'org',owner_uid:'principal',private_email:'private@example.test'}],
    ['user_access/principal',{active:true,verified:true,role:'provider',organization_id:'org',provider_id:'practice',verification_record_id:'v1'}],
    ['verification_records/v1',{subject_type:'provider',subject_id:'practice',outcome:'approved',category_codes:['architectural_design'],coverage:{region_codes:['region']}}],
  ]);
  const reader={get:async(path:string)=>rows.get(path)??null,list:async()=>[rows.get('published_profiles/public-a')!]};
  const store:RecordStore={...reader,timestamp:()=>'',transaction:async action=>action({...reader,create:()=>{throw Error('Read only');},set:()=>{throw Error('Read only');}})};
  return {rows,service:new ProviderDirectory(store,async()=>{})};
}
it('projects only currently approved public fields',async()=>{
  const {service}=fixture();
  const result=await service.list('client',{});
  expect(result.items).toHaveLength(1);
  expect(result.items[0]?.service_codes).toEqual(['architectural_design']);
  expect(result.items[0]?.coverage_codes).toEqual(['region']);
  expect(JSON.stringify(result)).not.toContain('private');
  expect(JSON.stringify(result)).not.toContain('must-not-leak');
});
it('withdrawn eligibility and old verification pointers hide discovery and exact details',async()=>{
  const {service,rows}=fixture();
  rows.get('user_access/principal')!.verification_record_id='v2';
  expect((await service.list('client',{})).items).toEqual([]);
  await expect(service.detail('client','public-a')).rejects.toMatchObject({code:'NOT_FOUND'});
});
it('expires qualification and rejects query/cursor injection',async()=>{
  const {service,rows}=fixture();
  rows.get('verification_records/v1')!.valid_until='2020-01-01';
  expect((await service.list('client',{})).items).toEqual([]);
  await expect(service.list('client',{cursor:'not-a-cursor'})).rejects.toMatchObject({code:'INVALID_QUERY'});
  await expect(service.list('client',{role:'internal'})).rejects.toBeDefined();
});
