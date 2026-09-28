import {it,expect} from 'vitest';
import {ClientSharing} from '../src/services/client-sharing.js';
import {ProviderDirectory} from '../src/services/provider-directory.js';
import type {RecordData,RecordStore,StoreQuery} from '../src/repositories/record-store.js';
import {hash} from '../src/services/client-contracts.js';
function fixture(){
  const content={title:'Confirmed home',details:{'brief.project.name':'Confirmed home','brief.project.project_type':'architecture','brief.scope.work_nature':'new_build','brief.site.location.address':'PRIVATE ADDRESS','brief.household.notes':'PRIVATE NOTES'},field_states:{secret:'PRIVATE SOURCE'}};
  const rows=new Map<string,RecordData>([
    ['projects/p',{project_id:'p',owner_uid:'client',requirement_id:'r',confirmed_requirement_version_id:'v',row_version:2}],
    ['requirements/r',{project_id:'p',current_version_id:'v',confirmed_version_id:'v'}],
    ['requirement_versions/v',{project_id:'p',content,content_hash:hash(content)}],
    ['user_access/sp',{active:true,verified:true,role:'provider',organization_id:'org',provider_id:'practice',verification_record_id:'qualification'}],
    ['provider_profiles/practice',{owner_uid:'sp',provider_id:'practice',organization_id:'org'}],
    ['published_profiles/profile',{profile_id:'profile',subject_type:'provider',subject_id:'practice',organization_id:'org',name:'Practice',summary:'Published summary',service_codes:['architectural_design'],coverage_codes:[],publication_status:'published',verification_badge:{state:'approved',category_codes:['architectural_design'],verification_record_id:'qualification'}}],
    ['verification_records/qualification',{subject_type:'provider',subject_id:'practice',outcome:'approved',category_codes:['architectural_design'],coverage:{region_codes:[]}}],
  ]);
  const list=async(query:StoreQuery)=>[...rows].filter(([path,row])=>path.startsWith(query.collection+'/') && (query.filters??[]).every(([key,value])=>row[key]===value)).map(([,row])=>row);
  const store:RecordStore={get:async path=>rows.get(path)??null,list,timestamp:()=> 'test-time',transaction:async action=>{
    const writes=new Map<string,RecordData>();
    const result=await action({get:async path=>rows.get(path)??null,list,create:(path,value)=>{if(rows.has(path)||writes.has(path))throw Error('Duplicate');writes.set(path,value);},set:(path,value)=>{writes.set(path,value);}});
    for(const [path,value] of writes)rows.set(path,value);return result;
  }};
  const authorize=async()=>{};
  return {rows,service:new ClientSharing(store,authorize,new ProviderDirectory(store,authorize)),input:{provider_uid:'sp',requirement_version_id:'v',requirement_content_hash:hash(content)}};
}
async function prepared(){const f=fixture();const preview=await f.service.preview('client','p',f.input);return {...f,send:{...f.input,disclosure_selection:preview.disclosure_selection,disclosure_manifest_hash:preview.disclosure_manifest_hash,disclosure_policy_ref:preview.policy_ref,expected_project_version:preview.expected_project_version,explicit_confirmation:true}};}
it('preview has no writes and excludes private source, address and household',async()=>{
  const f=fixture(),before=f.rows.size;
  const preview=await f.service.preview('client','p',f.input);
  expect(JSON.stringify(preview)).not.toContain('PRIVATE');expect(f.rows.size).toBe(before);
  await expect(f.service.preview('other','p',f.input)).rejects.toMatchObject({code:'NOT_FOUND'});
});
it('frozen sharing creates one enquiry and thread across retries and duplicate intents',async()=>{
  const f=await prepared();
  const first=await f.service.share('client','p',f.send,'share-intent-0001');
  expect(await f.service.share('client','p',f.send,'share-intent-0001')).toEqual(first);
  expect(await f.service.share('client','p',f.send,'share-intent-0002')).toEqual(first);
  expect([...f.rows.keys()].filter(k=>k.startsWith('enquiries/'))).toHaveLength(1);
  expect([...f.rows.keys()].filter(k=>k.startsWith('conversations/'))).toHaveLength(1);
  expect([...f.rows.keys()].filter(k=>k.startsWith('project_members/'))).toHaveLength(0);
  expect(JSON.stringify(f.rows.get(`enquiries/${first.enquiry_id}`))).not.toContain('PRIVATE');
});
it('rejects a changed preview and revoked recipient without sends',async()=>{
  const f=await prepared();
  await expect(f.service.share('client','p',{...f.send,disclosure_manifest_hash:'0'.repeat(64)},'share-intent-0001')).rejects.toMatchObject({code:'STALE_VERSION'});
  f.rows.get('user_access/sp')!.active=false;
  await expect(f.service.share('client','p',f.send,'share-intent-0001')).rejects.toMatchObject({code:'NOT_FOUND'});
  expect([...f.rows.keys()].filter(k=>k.startsWith('enquiries/'))).toHaveLength(0);
});
it('rejects a successor brief and private field injection',async()=>{
  const f=await prepared();
  await expect(f.service.preview('client','p',{...f.input,disclosure_selection:{detail_field_paths:['brief.site.location.address'],attachment_refs:[]}})).rejects.toBeDefined();
  f.rows.get('requirements/r')!.current_version_id='successor';
  await expect(f.service.share('client','p',f.send,'share-intent-0001')).rejects.toMatchObject({code:'STALE_VERSION'});
});
