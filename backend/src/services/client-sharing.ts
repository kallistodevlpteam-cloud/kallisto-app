import { z } from 'zod';
import type { RecordData, RecordStore, RecordTransaction } from '../repositories/record-store.js';
import { hash,id,intakeFields,parse } from './client-contracts.js';
import { ServiceError } from './errors.js';
import type { ProviderDirectory } from './provider-directory.js';

// Application disclosure policy: minimal non-household brief facts by default.
// Explicit selection is bounded to these fields until richer disclosure/file UI exists.
export const shareFields=['brief.project.name','brief.project.project_type','brief.scope.work_nature','brief.scope.requested_services','brief.site.location.locality','brief.site.location.district','brief.site.location.state','brief.site.plot_area','brief.design.style_preferences'] as const;
const digest=z.string().regex(/^[a-f0-9]{64}$/);
const selection=z.strictObject({detail_field_paths:z.array(z.enum(shareFields)).max(shareFields.length).refine(v=>new Set(v).size===v.length),attachment_refs:z.array(z.never()).max(0)});
const base={provider_uid:id,requirement_version_id:id,requirement_content_hash:digest};
const previewInput=z.strictObject({...base,disclosure_selection:selection.optional()});
const policy={id:'client-minimal-disclosure',version:'1'};
const shareInput=z.strictObject({...base,disclosure_selection:selection,disclosure_manifest_hash:digest,disclosure_policy_ref:z.strictObject({id:z.literal(policy.id),version:z.literal(policy.version)}),expected_project_version:z.number().int().positive(),explicit_confirmation:z.literal(true)});
export class ClientSharing {
  constructor(private store:RecordStore,private authorize:(tx:RecordTransaction,uid:string)=>Promise<unknown>,private providers:ProviderDirectory){}
  private view(row:RecordData) {
    return {enquiry_id:row.enquiry_id,project_id:row.project_id,requirement_version_id:row.requirement_version_id,
      status:row.status,shared_at:row.shared_at,conversation_id:row.conversation_id,
      disclosure_snapshot:row.disclosure_snapshot,snapshot_hash:row.snapshot_hash};
  }
  async enquiries(uid:string,input:unknown) {
    const query=parse(z.strictObject({cursor:id.optional()}),input);
    return this.store.transaction(async tx=>{
      await this.authorize(tx,uid);
      const rows=await tx.list({collection:'enquiries',filters:[['client_uid',uid]],...(query.cursor?{cursor:query.cursor}:{}),limit:21});
      const page=rows.slice(0,20);
      const items=[];
      for(const row of page){
        if(!id.safeParse(row.project_id).success)continue;
        const project=await tx.get(`projects/${row.project_id}`);
        if(project?.owner_uid===uid)items.push(this.view(row));
      }
      return {items,next_cursor:rows.length>20?page.at(-1)?._id:null,has_more:rows.length>20};
    });
  }
  async enquiry(uid:string,enquiryId:string) {
    return this.store.transaction(async tx=>{
      await this.authorize(tx,uid);
      const row=await tx.get(`enquiries/${parse(id,enquiryId)}`);
      if(!row || row.client_uid!==uid || row.enquiry_id!==enquiryId)throw new ServiceError('NOT_FOUND',404);
      const project=await tx.get(`projects/${parse(id,row.project_id)}`);
      if(!project || project.owner_uid!==uid)throw new ServiceError('NOT_FOUND',404);
      return this.view(row);
    });
  }
  private async snapshot(tx:RecordTransaction,uid:string,projectId:string,data:z.infer<typeof previewInput>) {
    const project=await tx.get(`projects/${parse(id,projectId)}`);
    if(!project || project.owner_uid!==uid || project.project_id!==projectId)throw new ServiceError('NOT_FOUND',404);
    const root=await tx.get(`requirements/${parse(id,project.requirement_id)}`);
    const version=await tx.get(`requirement_versions/${data.requirement_version_id}`);
    if(!root || !version || root.project_id!==projectId || version.project_id!==projectId || root.current_version_id!==data.requirement_version_id || root.confirmed_version_id!==data.requirement_version_id || project.confirmed_requirement_version_id!==data.requirement_version_id || version.content_hash!==data.requirement_content_hash)throw new ServiceError('STALE_VERSION',409);
    const recipient=await this.providers.recipient(tx,data.provider_uid);
    const content=parse(z.object({title:z.string().max(120),details:z.record(z.string(),z.unknown())}),version.content);
    const chosen=data.disclosure_selection ?? {detail_field_paths:shareFields.filter(field=>content.details[field]!==undefined),attachment_refs:[]};
    const details:RecordData={};
    for(const field of chosen.detail_field_paths) {
      const value=content.details[field];
      if(value===undefined)throw new ServiceError('VALIDATION_ERROR',422);
      const schema=intakeFields[field];
      if(!schema)throw new ServiceError('VALIDATION_ERROR',422);
      details[field]=parse(schema,value);
    }
    const disclosure={requirement_version_id:data.requirement_version_id,permitted_details:details,title:content.title,scope_summary:'Client-confirmed details selected for this enquiry.',attachment_refs:[],disclosure_policy_ref:policy};
    const manifest=hash({project_id:projectId,recipient_uid:data.provider_uid,requirement_content_hash:data.requirement_content_hash,disclosure});
    return {project,recipient,selection:chosen,disclosure,manifest};
  }
  async preview(uid:string,projectId:string,input:unknown) {
    const data=parse(previewInput,input);
    return this.store.transaction(async tx=>{
      await this.authorize(tx,uid);
      const snap=await this.snapshot(tx,uid,projectId,data);
      return {...data,disclosure_selection:snap.selection,disclosed_content:snap.disclosure,disclosure_manifest_hash:snap.manifest,policy_ref:policy,expected_project_version:snap.project.row_version};
    });
  }
  async share(uid:string,projectId:string,input:unknown,key:string) {
    const data=parse(shareInput,input);
    parse(z.string().regex(/^[a-zA-Z0-9_-]{16,128}$/),key);
    const command=hash([uid,'ENQUIRY_SHARE',projectId,key]);
    const identity=hash([uid,projectId,data.provider_uid,data.requirement_version_id,data.disclosure_manifest_hash]);
    const enquiryId=`enquiry_${identity.slice(0,32)}`,conversationId=`conversation_${identity.slice(0,32)}`;
    return this.store.transaction(async tx=>{
      await this.authorize(tx,uid);
      const project=await tx.get(`projects/${parse(id,projectId)}`);
      if(!project || project.owner_uid!==uid)throw new ServiceError('NOT_FOUND',404);
      await this.providers.recipient(tx,data.provider_uid);
      const previous=await tx.get(`idempotency_records/${command}`);
      if(previous) {
        if(previous.request_hash!==hash(data))throw new ServiceError('IDEMPOTENCY_CONFLICT',409);
        const enquiry=await tx.get(`enquiries/${enquiryId}`);
        if(!enquiry || enquiry.client_uid!==uid || enquiry.recipient_provider_uid!==data.provider_uid)throw new ServiceError('NOT_FOUND',404);
        return {resource_id:enquiryId,enquiry_id:enquiryId,conversation_id:conversationId};
      }
      const snap=await this.snapshot(tx,uid,projectId,data);
      if(snap.manifest!==data.disclosure_manifest_hash || snap.project.row_version!==data.expected_project_version)throw new ServiceError('STALE_VERSION',409);
      const existing=await tx.get(`enquiries/${enquiryId}`);
      const metadata={schema_version:1,row_version:1,created_at:this.store.timestamp(),created_by_uid:uid,updated_at:this.store.timestamp(),updated_by_uid:uid};
      if (!existing) {
      tx.create(`enquiries/${enquiryId}`,{...metadata,enquiry_id:enquiryId,project_id:projectId,client_uid:uid,recipient_provider_uid:data.provider_uid,requirement_version_id:data.requirement_version_id,disclosure_snapshot:snap.disclosure,snapshot_hash:hash(snap.disclosure),status:'sent',conversation_id:conversationId,shared_at:this.store.timestamp()});
      tx.create(`conversations/${conversationId}`,{...metadata,conversation_id:conversationId,context:{kind:'enquiry',key:enquiryId},project_id:projectId,participant_uids:[uid,data.provider_uid],status:'open',next_sequence:1});
      tx.create(`domain_events/${command}`,{...metadata,event_id:command,event_type:'enquiry.shared',aggregate_type:'enquiry',aggregate_id:enquiryId,aggregate_version:1,project_id:projectId,actor_uid:uid,correlation_id:key,payload:{enquiry_id:enquiryId}});
      tx.create(`audit_events/${command}`,{...metadata,audit_id:command,actor_uid:uid,operation:'ENQUIRY_SHARE',resource_scope:{kind:'enquiry',key:enquiryId},outcome:'allowed',correlation_id:key});
      tx.create(`outbox_events/${identity}`,{...metadata,outbox_id:identity,event_id:command,kind:'notification',recipient_uid:data.provider_uid,channel:'inbox',status:'pending',available_at:this.store.timestamp(),attempt_count:0,payload_ref:{resource_type:'enquiry',resource_id:enquiryId}});
      }
      const result={resource_id:enquiryId,enquiry_id:enquiryId,conversation_id:conversationId};
      tx.create(`idempotency_records/${command}`,{...metadata,command_key:command,actor_uid:uid,operation:'ENQUIRY_SHARE',resource_key:projectId,request_hash:hash(data),status:'committed',result_ref:result,created_resource_ids:existing?[]:[enquiryId,conversationId]});
      return result;
    });
  }
}
