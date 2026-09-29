import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {cert,initializeApp,deleteApp} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {getFirestore,FieldValue} from 'firebase-admin/firestore';
import {z} from 'zod';
import {loadEnvironment} from '../config/environment.js';

// Operator-only CLI, never an HTTP route or startup seed. Default mode is validation.
const schema=z.strictObject({version:z.string().regex(/^[a-zA-Z0-9_-]{1,120}$/),text:z.string().trim().min(1).max(8000),approved:z.boolean(),approved_by_uid:z.string().regex(/^[a-zA-Z0-9_-]{1,128}$/).optional(),operator_authorization_reference:z.string().min(1).max(240).optional(),expected_features_version:z.number().int().nonnegative()});
async function main(){
  const [file,mode]=process.argv.slice(2);
  if(!file || (mode && mode!=='--apply'))throw Error('Usage: tsx src/cli/publish-enrollment-notice.ts INPUT.json [--apply]');
  const notice=schema.parse(JSON.parse(readFileSync(file,'utf8')));
  const digest=createHash('sha256').update(JSON.stringify({version:notice.version,text:notice.text})).digest('hex');
  if(mode!=='--apply'){process.stdout.write(JSON.stringify({valid:true,approved:notice.approved,version:notice.version,content_hash:digest,applied:false})+'\n');return;}
  if(!notice.approved || (!notice.operator_authorization_reference && (!notice.approved_by_uid || notice.approved_by_uid.startsWith('REPLACE_'))))throw Error('Actual notice approval and approving owner Firebase UID are required.');
  const config=loadEnvironment();
  if(config.KALLISTO_EMULATORS!=='false')throw Error('This operator command requires the configured real Firebase project.');
  const credentials=JSON.parse(readFileSync(config.GOOGLE_APPLICATION_CREDENTIALS,'utf8'));
  if(credentials.project_id!==config.FIREBASE_PROJECT_ID)throw Error('Firebase project mismatch.');
  const app=initializeApp({credential:cert(credentials),projectId:config.FIREBASE_PROJECT_ID});
  try{
    const owner=notice.operator_authorization_reference ? {uid:String(credentials.client_id),disabled:false} : await getAuth(app).getUser(notice.approved_by_uid!);
    if(owner.disabled || !owner.uid)throw Error('Approving principal is unavailable.');
    const approval=notice.operator_authorization_reference ? {kind:'operator',principal:credentials.client_email,authorization_reference:notice.operator_authorization_reference} : null;
    const db=getFirestore(app,config.FIRESTORE_DATABASE_ID),ref=db.doc('system_settings/features');
    await db.runTransaction(async tx=>{
      const current=(await tx.get(ref)).data();
      if(Number(current?.row_version??0)!==notice.expected_features_version)throw Error('Feature configuration changed; review its current version before applying.');
      const values=current?.values??{};
      if(values.client_enrollment_notice?.version===notice.version && values.client_enrollment_notice?.text!==notice.text)throw Error('Changed notice text requires a new version.');
      tx.set(ref,{...current,schema_version:1,row_version:notice.expected_features_version+1,
        created_at:current?.created_at??FieldValue.serverTimestamp(),created_by_uid:current?.created_by_uid??owner.uid,
        updated_at:FieldValue.serverTimestamp(),updated_by_uid:owner.uid,
        ...(approval ? {} : {policy_version:current?.policy_version??notice.version,approved_by_uid:current?.approved_by_uid??owner.uid}),
        values:{...values,client_enrollment_notice:{version:notice.version,text:notice.text,...(approval ? {approval} : {approved_by_uid:owner.uid}),content_hash:digest}}});
      tx.create(db.doc(`audit_events/enrollment_notice_${digest}`),{schema_version:1,audit_id:`enrollment_notice_${digest}`,actor_uid:owner.uid,...(approval ? {operator_approval:approval} : {}),operation:'ENROLLMENT_NOTICE_PUBLISH',resource_scope:{kind:'system_setting',key:'features'},outcome:'allowed',correlation_id:digest,created_at:FieldValue.serverTimestamp(),created_by_uid:owner.uid,after_ref:{resource_id:'features',revision:notice.expected_features_version+1}});
    });
    process.stdout.write(JSON.stringify({applied:true,project:config.FIREBASE_PROJECT_ID,version:notice.version,content_hash:digest})+'\n');
  }finally{await deleteApp(app);}
}
main().catch(()=>{process.stderr.write('Notice validation/publication failed. Check the input, real owner approval, Firebase account and expected configuration version. No credentials are logged.\n');process.exitCode=1;});
