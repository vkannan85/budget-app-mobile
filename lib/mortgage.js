const monthPattern=/^\d{4}-(0[1-9]|1[0-2])$/;
function monthBefore(value){const [y,m]=value.slice(0,7).split('-').map(Number);const date=new Date(y,m-2,1);return date.getFullYear()+'-'+String(date.getMonth()+1).padStart(2,'0');}
function mortgagePeriods(deals,today){return [...deals].sort((a,b)=>a.start_month.localeCompare(b.start_month)).map((deal,i,all)=>{const end=all[i+1]?monthBefore(all[i+1].start_month):null;return {...deal,lender_end_month:end,status:deal.start_month.slice(0,7)>today?'Upcoming':end&&end<today?'Previous':'Current'};});}
function mortgagePayload(form){
 const errors=[];
 const number=(key,label,min,max,integer=false,optional=false)=>{const raw=String(form[key]??'').trim();if(!raw&&optional)return null;const value=Number(raw);if(!raw||!Number.isFinite(value)||value<min||(max!==null&&value>max)||(integer&&!Number.isInteger(value))){errors.push(label+' Is Invalid');return null;}return value;};
 const start=String(form.start_month||'').slice(0,7),end=String(form.rate_end_month||'').slice(0,7);
 if(!monthPattern.test(start))errors.push('Enter A Valid Start Month');
 if(!monthPattern.test(end)||end<start)errors.push('Rate End Month Must Be On Or After Start Month');
 const data={start_month:start+'-01',rate_end_month:end+'-01',borrowing_amount:number('borrowing_amount','Borrowing Amount',0.01,null),ltv:number('ltv','LTV',0.01,100,false,true),term_months:number('term_months','Term',1,600,true),annual_rate:number('annual_rate','Rate',0,100),monthly_payment:number('monthly_payment','Monthly Payment',0.01,null),deposit:number('deposit','Deposit',0,null,false,true),reference_number:String(form.reference_number||'').trim(),notes:String(form.notes||'').trim()};
 if(data.reference_number.length>120)errors.push('Reference Must Be 120 Characters Or Fewer');
 return {data,errors};
}
module.exports={mortgagePeriods,mortgagePayload};
