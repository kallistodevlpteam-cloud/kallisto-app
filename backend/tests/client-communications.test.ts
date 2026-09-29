import {describe,it,expect} from 'vitest';
import {ClientCommunications} from '../src/services/client-communications.js';
import type {RecordData,RecordStore,StoreQuery} from '../src/repositories/record-store.js';

function fixture(){
  const rows=new Map<string,RecordData>();
  const query=(input:StoreQuery)=>[...rows].filter(([path,row])=>path.startsWith(input.collection+'/') && path.slice(input.collection.length+1).indexOf('/')===-1 && (input.filters??[]).every(([key,value])=>row[key]===value) && (!input.arrayContains || Array.isArray(row[input.arrayContains[0]]) && (row[input.arrayContains[0]] as unknown[]).includes(input.arrayContains[1])))
    .map(([path,row])=>({...row,_id:path.split('/').at(-1)!})).sort((a,b)=>input.order?(input.order[1]==='desc'?-1:1)*(Number(a[input.order[0] as keyof typeof a])-Number(b[input.order[0] as keyof typeof b]))||a._id.localeCompare(b._id):a._id.localeCompare(b._id))
    .filter(row=>!input.cursor || (input.order?(input.order[1]==='desc'?Number(row[input.order[0] as keyof typeof row])<input.cursorValue!:Number(row[input.order[0] as keyof typeof row])>input.cursorValue!):row._id>input.cursor)).slice(0,input.limit??21);
  const store:RecordStore={timestamp:()=> '2026-09-29T00:00:00Z',get:async path=>rows.get(path)??null,list:async input=>query(input),transaction:async action=>{
    const pending=new Map<string,RecordData>();
    const read=()=>{if(pending.size)throw Error('Read after write');};
    const result=await action({get:async path=>{read();return rows.get(path)??null;},list:async input=>{read();return query(input);},create:(path,value)=>{if(rows.has(path))throw Error('Duplicate');pending.set(path,value);},set:(path,value)=>{pending.set(path,value);}});
    for(const [path,value] of pending)rows.set(path,value);return result;
  }};
  return {rows,service:new ClientCommunications(store)};
}
const input={category:'account',subject:'Enrollment question',description:'Cannot finish account setup',evidence_refs:[]};
describe('client support and context messages',()=>{
  it('allows own support before enrollment without granting a client role',async()=>{
    const {service,rows}=fixture();
    const created=await service.createCase('alice',input,'support-intent-0001');
    expect(await service.createCase('alice',input,'support-intent-0001')).toEqual(created);
    expect(rows.has('user_access/alice')).toBe(false);
    expect((await service.cases('alice',{})).items).toHaveLength(1);
    expect((await service.conversations('alice',{})).items).toHaveLength(1);
    await expect(service.supportCase('bob',created.case_id)).rejects.toMatchObject({code:'NOT_FOUND'});
    await expect(service.conversation('bob',created.conversation_id)).rejects.toMatchObject({code:'NOT_FOUND'});
  });
  it('deduplicates message retry and rejects changed payload or unrelated reply',async()=>{
    const {service}=fixture(),created=await service.createCase('alice',input,'support-intent-0001');
    const message={text:'More detail',client_message_id:'message-0001',attachment_refs:[]};
    const first=await service.send('alice',created.conversation_id,message,'message-intent-001');
    expect(await service.send('alice',created.conversation_id,message,'message-intent-002')).toEqual(first);
    expect((await service.messages('alice',created.conversation_id,{})).items).toHaveLength(1);
    await expect(service.send('alice',created.conversation_id,{...message,text:'Changed'},'message-intent-001')).rejects.toMatchObject({code:'IDEMPOTENCY_CONFLICT'});
    await expect(service.send('alice',created.conversation_id,{...message,client_message_id:'message-0002',reply_to_id:'unrelated'},'message-intent-003')).rejects.toMatchObject({code:'NOT_FOUND'});
  });
  it('rechecks domain source and revocation rather than trusting participant arrays',async()=>{
    const {service,rows}=fixture(),created=await service.createCase('alice',input,'support-intent-0001');
    rows.get(`conversations/${created.conversation_id}`)!.participant_uids=['alice','bob'];
    await expect(service.messages('bob',created.conversation_id,{})).rejects.toMatchObject({code:'NOT_FOUND'});
    rows.set('user_access/alice',{uid:'alice',active:false});
    await expect(service.createCase('alice',input,'support-intent-0001')).rejects.toMatchObject({code:'FORBIDDEN'});
    await expect(service.messages('alice',created.conversation_id,{})).rejects.toMatchObject({code:'FORBIDDEN'});
  });
  it('returns ordered pages with cursors bound to user and conversation',async()=>{
    const {service}=fixture(),created=await service.createCase('alice',input,'support-intent-0001');
    for(let i=0;i<3;i++)await service.send('alice',created.conversation_id,{text:`Message ${i}`,client_message_id:`message-${i}`},`message-intent-000${i}`);
    const first=await service.messages('alice',created.conversation_id,{limit:2});
    expect(first.items).toHaveLength(2);expect(first.has_more).toBe(true);
    const next=await service.messages('alice',created.conversation_id,{limit:2,cursor:first.next_cursor});
    expect(next.items).toMatchObject([{text:'Message 0',sequence:1}]);
    await expect(service.messages('bob',created.conversation_id,{limit:2,cursor:first.next_cursor})).rejects.toMatchObject({code:'INVALID_QUERY'});
  });
  it('rejects private attachment injection and read-only sends',async()=>{
    const {service,rows}=fixture(),created=await service.createCase('alice',input,'support-intent-0001');
    await expect(service.createCase('alice',{...input,evidence_refs:[{file_id:'private'}]},'support-intent-0002')).rejects.toBeDefined();
    rows.get(`conversations/${created.conversation_id}`)!.status='closed';
    await expect(service.send('alice',created.conversation_id,{text:'Hello',client_message_id:'m'},'message-intent-001')).rejects.toMatchObject({code:'INVALID_TRANSITION'});
  });
});
