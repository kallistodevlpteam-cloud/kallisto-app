import {describe,it,expect} from 'vitest';
import {ClientWorkflows} from '../src/services/client-workflows.js';
import type {RecordStore,RecordData} from '../src/repositories/record-store.js';
function service(record:RecordData){return new ClientWorkflows({get:async()=>record,list:async()=>[],timestamp:()=>null,transaction:async()=>{throw Error('Not used');}} as RecordStore);}
describe('enrollment notice authorization',()=>{
 const notice={version:'v1',text:'Reviewed workspace notice'};
 it('keeps enrollment unavailable for unapproved text',async()=>{
  expect((await service({values:{client_enrollment_notice:notice}}).capabilities()).client_enrollment).toBe(false);
 });
 it('accepts attributed operator publication without leaking operator identity',async()=>{
  const result=await service({values:{client_enrollment_notice:{...notice,approval:{kind:'operator',principal:'test-operator',authorization_reference:'test-approval'}}}}).capabilities();
  expect(result.client_enrollment).toBe(true);expect(result.enrollment_notice).toEqual(notice);
 });
 it('preserves existing owner-approved notice support',async()=>{
  expect((await service({policy_version:'v1',approved_by_uid:'owner',values:{client_enrollment_notice:notice}}).capabilities()).client_enrollment).toBe(true);
 });
});
