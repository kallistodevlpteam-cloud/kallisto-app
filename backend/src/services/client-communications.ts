import {z} from 'zod';
import type {RecordData,RecordStore,RecordTransaction} from '../repositories/record-store.js';
import {id,hash,parse} from './client-contracts.js';
import {ServiceError} from './errors.js';

const pageInput=z.strictObject({cursor:z.string().max(2048).optional(),limit:z.coerce.number().int().min(1).max(50).default(25)});
const caseInput=z.strictObject({project_id:id.optional(),category:z.enum(['account','technical','project','upload','privacy','other']),subject:z.string().trim().min(1).max(240),description:z.string().trim().min(1).max(8000),evidence_refs:z.array(z.never()).max(0)});
const sendInput=z.strictObject({text:z.string().trim().min(1).max(8000),attachment_refs:z.array(z.never()).max(0).default([]),reply_to_id:id.optional(),client_message_id:id});
export class ClientCommunications {
  constructor(private store:RecordStore){}
  private metadata(uid:string){return {schema_version:1,row_version:1,created_at:this.store.timestamp(),created_by_uid:uid,updated_at:this.store.timestamp(),updated_by_uid:uid};}
  private async subject(tx:RecordTransaction,uid:string){
    parse(id,uid);
    const access=await tx.get(`user_access/${uid}`);
    if(access && (access.uid!==uid || access.active!==true))throw new ServiceError('FORBIDDEN',403);
    return access;
  }
  private async ownedProject(tx:RecordTransaction,uid:string,projectId:unknown){
    const project=await tx.get(`projects/${parse(id,projectId)}`);
    if(!project || project.owner_uid!==uid)throw new ServiceError('NOT_FOUND',404);
    return project;
  }
  private paging(uid:string,scope:string,input:unknown){
    const query=parse(pageInput,input),binding=hash([uid,scope,query.limit]);
    let after:string|undefined,sequence:number|undefined;
    if(query.cursor){try{const cursor=parse(z.strictObject({binding:z.literal(binding),after:id,sequence:z.number().int().positive().optional()}),JSON.parse(Buffer.from(query.cursor,'base64url').toString('utf8')));after=cursor.after;sequence=cursor.sequence;}catch{throw new ServiceError('INVALID_QUERY',422);}}
    return {...query,binding,after,sequence};
  }
  private page(query:ReturnType<ClientCommunications['paging']>,rows:RecordData[],items:unknown[],ordered=false){
    const last=rows.slice(0,query.limit).at(-1),hasMore=rows.length>query.limit;
    return {items,has_more:hasMore,next_cursor:hasMore&&last?Buffer.from(JSON.stringify({binding:query.binding,after:last._id,...(ordered?{sequence:last.sequence}:{})})).toString('base64url'):null};
  }
  private async thread(tx:RecordTransaction,uid:string,threadId:string){
    const access=await this.subject(tx,uid);
    const row=await tx.get(`conversations/${parse(id,threadId)}`);
    if(!row || row.conversation_id!==threadId || !Array.isArray(row.participant_uids) || !row.participant_uids.includes(uid))throw new ServiceError('NOT_FOUND',404);
    const parsedContext=z.object({kind:z.enum(['project','enquiry','support']),key:id}).safeParse(row.context);
    if(!parsedContext.success)throw new ServiceError('NOT_FOUND',404);
    const context=parsedContext.data;
    let title:string;
    if(context.kind==='support'){
      const support=await tx.get(`support_cases/${context.key}`);
      if(!support || support.requester_uid!==uid || support.conversation_id!==threadId)throw new ServiceError('NOT_FOUND',404);
      title=parse(z.string().min(1).max(240),support.subject);
    }else{
      if(!access || access.role!=='client')throw new ServiceError('NOT_FOUND',404);
      if(context.kind==='project'){
        const project=await this.ownedProject(tx,uid,context.key);title=parse(z.string().min(1).max(120),project.name);
      }else{
        const enquiry=await tx.get(`enquiries/${context.key}`);
        if(!enquiry || enquiry.client_uid!==uid || enquiry.conversation_id!==threadId)throw new ServiceError('NOT_FOUND',404);
        await this.ownedProject(tx,uid,enquiry.project_id);
        title=parse(z.object({title:z.string().min(1).max(120)}),enquiry.disclosure_snapshot).title;
      }
    }
    return {row,view:{conversation_id:threadId,context,title,status:parse(z.enum(['open','read_only','closed']),row.status)}};
  }
  async conversations(uid:string,input:unknown){
    const query=this.paging(uid,'conversations',input);
    return this.store.transaction(async tx=>{
      await this.subject(tx,uid);
      const rows=await tx.list({collection:'conversations',arrayContains:['participant_uids',uid],...(query.after?{cursor:query.after}:{}),limit:query.limit+1});
      const items=[];
      for(const row of rows.slice(0,query.limit)){
        try{items.push((await this.thread(tx,uid,parse(id,row.conversation_id))).view);}catch(error){if(!(error instanceof ServiceError && error.status===404))throw error;}
      }
      return this.page(query,rows,items);
    });
  }
  async conversation(uid:string,threadId:string){return this.store.transaction(async tx=>(await this.thread(tx,uid,threadId)).view);}
  async messages(uid:string,threadId:string,input:unknown){
    const query=this.paging(uid,`messages:${threadId}`,input);
    if(query.after && !query.sequence)throw new ServiceError('INVALID_QUERY',422);
    return this.store.transaction(async tx=>{
      await this.thread(tx,uid,threadId);
      const rows=await tx.list({collection:`conversations/${threadId}/messages`,order:['sequence','desc'],...(query.after?{cursor:query.after,cursorValue:query.sequence!}:{}),limit:query.limit+1});
      const items=[];
      for(const row of rows.slice(0,query.limit)){
        const authorId=parse(id,row.author_uid),author=await tx.get(`users/${authorId}`);
        items.push({message_id:row.message_id,sequence:row.sequence,text:row.text,created_at:row.created_at,author_summary:{display_name:typeof author?.display_name==='string' && author.display_name?author.display_name:'Account holder'},attachment_refs:[],...(row.reply_to_id?{reply_to_id:row.reply_to_id}:{})});
      }
      return this.page(query,rows,items,true);
    });
  }
  async send(uid:string,threadId:string,input:unknown,key:string){
    const data=parse(sendInput,input);parse(z.string().regex(/^[a-zA-Z0-9_-]{16,128}$/),key);
    const messageId=hash([uid,threadId,data.client_message_id]),command=hash([uid,'MESSAGE_SEND',threadId,key]);
    return this.store.transaction(async tx=>{
      const thread=await this.thread(tx,uid,threadId);
      const previous=await tx.get(`idempotency_records/${command}`),existing=await tx.get(`conversations/${threadId}/messages/${messageId}`);
      if(previous && previous.request_hash!==hash(data))throw new ServiceError('IDEMPOTENCY_CONFLICT',409);
      if(existing){if(existing.request_hash!==hash(data) || existing.author_uid!==uid)throw new ServiceError('IDEMPOTENCY_CONFLICT',409);return {message_id:messageId,sequence:existing.sequence};}
      if(thread.view.status!=='open')throw new ServiceError('INVALID_TRANSITION',409);
      if(data.reply_to_id && !await tx.get(`conversations/${threadId}/messages/${data.reply_to_id}`))throw new ServiceError('NOT_FOUND',404);
      const sequence=parse(z.number().int().positive(),thread.row.next_sequence),metadata=this.metadata(uid);
      tx.create(`conversations/${threadId}/messages/${messageId}`,{...metadata,message_id:messageId,sequence,author_uid:uid,text:data.text,attachment_refs:[],...(data.reply_to_id?{reply_to_id:data.reply_to_id}:{}),request_hash:hash(data)});
      tx.set(`conversations/${threadId}`,{...thread.row,row_version:Number(thread.row.row_version)+1,next_sequence:sequence+1,last_message_at:this.store.timestamp(),updated_at:this.store.timestamp(),updated_by_uid:uid});
      const result={message_id:messageId,sequence};
      tx.create(`idempotency_records/${command}`,{...metadata,command_key:command,actor_uid:uid,operation:'MESSAGE_SEND',resource_key:threadId,request_hash:hash(data),status:'committed',result_ref:result,created_resource_ids:[messageId]});
      // Delivery is queued, not represented as sent email/push.
      for(const recipient of parse(z.array(id).max(100),thread.row.participant_uids).filter(v=>v!==uid)){
        const outbox=hash([messageId,recipient]);
        tx.create(`outbox_events/${outbox}`,{...metadata,outbox_id:outbox,event_id:messageId,kind:'notification',recipient_uid:recipient,channel:'inbox',status:'pending',available_at:this.store.timestamp(),attempt_count:0,payload_ref:{resource_type:'conversation',resource_id:threadId,message_id:messageId}});
      }
      return result;
    });
  }
  private caseView(row:RecordData){return {case_id:row.case_id,category:row.category,subject:row.subject,description:row.description,status:row.status,conversation_id:row.conversation_id,row_version:row.row_version};}
  async cases(uid:string,input:unknown){const query=this.paging(uid,'support',input);return this.store.transaction(async tx=>{
    await this.subject(tx,uid);const rows=await tx.list({collection:'support_cases',filters:[['requester_uid',uid]],...(query.after?{cursor:query.after}:{}),limit:query.limit+1});return this.page(query,rows,rows.slice(0,query.limit).map(row=>this.caseView(row)));
  });}
  async supportCase(uid:string,caseId:string){return this.store.transaction(async tx=>{await this.subject(tx,uid);const row=await tx.get(`support_cases/${parse(id,caseId)}`);if(!row || row.requester_uid!==uid || row.case_id!==caseId)throw new ServiceError('NOT_FOUND',404);return this.caseView(row);});}
  async createCase(uid:string,input:unknown,key:string){
    const data=parse(caseInput,input);parse(z.string().regex(/^[a-zA-Z0-9_-]{16,128}$/),key);
    const command=hash([uid,'SUPPORT_CASE_CREATE',key]),caseId=`case_${command.slice(0,32)}`,conversationId=`support_${command.slice(0,32)}`;
    return this.store.transaction(async tx=>{
      await this.subject(tx,uid);if(data.project_id)await this.ownedProject(tx,uid,data.project_id);
      const previous=await tx.get(`idempotency_records/${command}`);
      if(previous){if(previous.request_hash!==hash(data))throw new ServiceError('IDEMPOTENCY_CONFLICT',409);const row=await tx.get(`support_cases/${caseId}`);if(!row||row.requester_uid!==uid)throw new ServiceError('NOT_FOUND',404);return {case_id:caseId,conversation_id:conversationId};}
      const metadata=this.metadata(uid);
      tx.create(`support_cases/${caseId}`,{...metadata,...data,case_id:caseId,requester_uid:uid,status:'open',conversation_id:conversationId});
      tx.create(`conversations/${conversationId}`,{...metadata,conversation_id:conversationId,context:{kind:'support',key:caseId},participant_uids:[uid],status:'open',next_sequence:1});
      tx.create(`outbox_events/${command}`,{...metadata,outbox_id:command,event_id:command,kind:'projection',channel:'internal',status:'pending',available_at:this.store.timestamp(),attempt_count:0,payload_ref:{resource_type:'support_case',resource_id:caseId}});
      tx.create(`audit_events/${command}`,{...metadata,audit_id:command,actor_uid:uid,operation:'SUPPORT_CASE_CREATE',resource_scope:{kind:'support',key:caseId},outcome:'allowed',correlation_id:key});
      const result={case_id:caseId,conversation_id:conversationId};
      tx.create(`idempotency_records/${command}`,{...metadata,command_key:command,actor_uid:uid,operation:'SUPPORT_CASE_CREATE',resource_key:caseId,request_hash:hash(data),status:'committed',result_ref:result,created_resource_ids:[caseId,conversationId]});
      return result;
    });
  }
}
