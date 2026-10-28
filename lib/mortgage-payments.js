const monthOk=/^\d{4}-(0[1-9]|1[0-2])$/;
const cents=value=>Math.round(Number(value||0)*100);
function nextMonth(value){const [y,m]=value.split('-').map(Number),d=new Date(y,m,1);return d.getFullYear()+'-'+String(d.getMonth()+1).padStart(2,'0');}
function paymentBreakdown(history,deal,endMonth,today){
 const start=deal.start_month.slice(0,7);
 const records=history.filter(row=>{const m=row.payment_month.slice(0,7);return m>=start&&(!endMonth||m<=endMonth)&&(!row.lender_id||row.lender_id===deal.lender_id);});
 const last=endMonth||[start,today,...records.map(row=>row.payment_month.slice(0,7))].sort().pop();
 const byMonth=new Map(records.map(row=>[row.payment_month.slice(0,7),row]));
 const months=[];for(let m=start;m<=last;m=nextMonth(m)){const record=byMonth.get(m);months.push({month:m,record,future:m>today,rateDiffers:!!record&&Math.abs(Number(record.annual_rate)-Number(deal.annual_rate))>.00001,assignedByMonth:!!record&&!record.lender_id});}
 const regular=months.filter(x=>x.record&&!x.future).reduce((n,x)=>n+cents(x.record.payment),0),overpayment=months.filter(x=>x.record&&!x.future).reduce((n,x)=>n+cents(x.record.overpayment),0),lumpSum=months.filter(x=>x.record&&!x.future).reduce((n,x)=>n+cents(x.record.lump_sum),0);
 return {months,regular:regular/100,overpayment:overpayment/100,lumpSum:lumpSum/100,total:(regular+overpayment+lumpSum)/100,missing:months.filter(x=>!x.record&&!x.future).length,recorded:months.filter(x=>x.record&&!x.future).length};
}
function paymentPayload(form,deal,endMonth){
 const errors=[],m=String(form.payment_month||'').slice(0,7),start=deal.start_month.slice(0,7);
 if(!monthOk.test(m)||m<start||(endMonth&&m>endMonth))errors.push('Payment Month Must Be Within This Lender Period');
 const money=(key,label,optional=false)=>{const raw=String(form[key]??'').trim();if(!raw&&optional)return null;if(!/^\d+(\.\d{1,2})?$/.test(raw)){errors.push(label+' Must Be A Non-Negative Amount With Up To Two Decimal Places');return null;}return Number(raw);};
 const opening=money('opening_balance','Opening Balance'),payment=money('payment','Monthly Payment'),overpayment=money('overpayment','Overpayment'),lump=money('lump_sum','Lump Sum'),interest=money('actual_interest','Actual Interest',true),rawRate=String(form.annual_rate??'').trim(),rate=Number(rawRate);
 if(!rawRate||!Number.isFinite(rate)||rate<0||rate>100)errors.push('Enter A Valid Interest Rate');
 if(cents(payment)+cents(overpayment)+cents(lump)<=0)errors.push('Enter At Least One Payment Amount');
 if(opening!==null&&payment!==null&&overpayment!==null&&lump!==null&&Number.isFinite(rate)){const allowed=cents(opening)+(interest===null?Math.round(opening*rate/1200*100):cents(interest));if(cents(payment)+cents(overpayment)+cents(lump)>allowed)errors.push('Payments Exceed The Opening Balance Plus Interest');}
 const notes=String(form.notes||'').trim();if(notes.length>1000)errors.push('Notes Must Be 1000 Characters Or Fewer');
 return {errors,data:{payment_month:m+'-01',lender_id:deal.lender_id,opening_balance:opening,annual_rate:rate,payment,overpayment,lump_sum:lump,actual_interest:interest,notes}};
}
module.exports={paymentBreakdown,paymentPayload};
