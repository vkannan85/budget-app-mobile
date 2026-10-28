import {createClient} from 'npm:@supabase/supabase-js@2.57.4';
const origin='https://direct-debits-pwa-production.up.railway.app';
const cors={'Access-Control-Allow-Origin':origin,'Access-Control-Allow-Headers':'authorization, apikey, content-type, x-client-info, x-mortgage-access','Access-Control-Allow-Methods':'POST, OPTIONS','Cache-Control':'no-store'};
const json=(data:unknown,status=200)=>new Response(JSON.stringify(data),{status,headers:{...cors,'Content-Type':'application/json'}});
const pick=(source:Record<string,unknown>,keys:string[])=>Object.fromEntries(keys.filter(k=>Object.hasOwn(source,k)).map(k=>[k,source[k]]));
Deno.serve(async(req)=>{
 if(req.method==='OPTIONS')return new Response('ok',{headers:cors});
 if(req.method!=='POST')return json({error:'Method Not Allowed'},405);
 if(req.headers.get('origin')&&req.headers.get('origin')!==origin)return json({error:'Origin Not Allowed'},403);
 const token=req.headers.get('x-mortgage-access')||'';
 if(!/^[A-Za-z0-9_-]{64}$/.test(token))return json({error:'Private Device Access Required'},401);
 const hash=Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(token)))).map(x=>x.toString(16).padStart(2,'0')).join('');
 const db=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,{auth:{persistSession:false,autoRefreshToken:false}});
 const {data:access,error:accessError}=await db.from('mortgage_device_access').select('user_id,expires_at,revoked_at').eq('token_hash',hash).maybeSingle();
 if(accessError||!access||access.revoked_at||new Date(access.expires_at).getTime()<=Date.now())return json({error:'Private Access Has Expired Or Been Revoked'},401);
 let body;try{const raw=await req.text();if(raw.length>16384)return json({error:'Request Too Large'},413);body=JSON.parse(raw);}catch{return json({error:'Invalid Request'},400);}
 const owner=access.user_id;
 try{
  if(body.action==='load'){
   const [deals,lenders]=await Promise.all([db.from('mortgage_deals').select('*').eq('user_id',owner).order('start_month'),db.from('mortgage_lenders').select('*').eq('user_id',owner)]);
   if(deals.error||lenders.error)return json({error:'Could Not Load Mortgage Details'},500);
   return json({deals:deals.data,lenders:lenders.data});
  }
  if(body.action==='history'){const r=await db.from('mortgage_monthly_history').select('*').eq('user_id',owner).order('payment_month');return r.error?json({error:'Could Not Load Payment History'},500):json({data:r.data});}
  if(!['updateDeal','updateProperty','savePayment'].includes(body.action))return json({error:'Unknown Action'},400);
  if(!body.data||typeof body.data!=='object'||Array.isArray(body.data))return json({error:'Invalid Data'},400);
  const id=body.id;if(id!==undefined&&id!==null&&!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id))return json({error:'Invalid Record'},400);
  const table=body.action==='updateDeal'?'mortgage_deals':body.action==='updateProperty'?'mortgage_lenders':'mortgage_monthly_history';
  const fields=body.action==='updateDeal'?['start_month','rate_end_month','borrowing_amount','ltv','term_months','annual_rate','monthly_payment','deposit','reference_number','notes']:body.action==='updateProperty'?['home_address','property_type','property_value']:['payment_month','lender_id','opening_balance','annual_rate','payment','overpayment','lump_sum','actual_interest','notes'];
  const data={...pick(body.data,fields),updated_at:new Date().toISOString()};
  if(body.action!=='savePayment'&&!id)return json({error:'Record Required'},400);
  const result=id?await db.from(table).update(data).eq('id',id).eq('user_id',owner).select('*').single():await db.from(table).insert({...data,user_id:owner}).select('*').single();
  if(result.error)return json({error:result.error.message},400);
  return json({data:result.data});
 }catch{return json({error:'Could Not Complete Mortgage Request'},500);}
});
