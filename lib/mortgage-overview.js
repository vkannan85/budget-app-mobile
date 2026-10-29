const cents=v=>Math.round(Number(v||0)*100);
function paymentFinance(row){
 const estimated=row.actual_interest===null||row.actual_interest===undefined||row.actual_interest==='';
 const interest=estimated?Math.round(Number(row.opening_balance)*Number(row.annual_rate)/1200*100):cents(row.actual_interest);
 const paid=cents(row.payment)+cents(row.overpayment)+cents(row.lump_sum);
 const principal=paid-interest;
 return {paid:paid/100,interest:interest/100,principal:principal/100,balance:(cents(row.opening_balance)-principal)/100,estimated};
}
function mortgageOverview(history,periods,lenders,today){
 const rows=history.filter(r=>r.payment_month.slice(0,7)<=today&&periods.some(d=>r.payment_month.slice(0,7)>=d.start_month.slice(0,7)&&(!d.lender_end_month||r.payment_month.slice(0,7)<=d.lender_end_month)&&(!r.lender_id||r.lender_id===d.lender_id))).sort((a,b)=>a.payment_month.localeCompare(b.payment_month));
 const totals={paid:0,interest:0,principal:0,regular:0,lumpSum:0,overpayment:0,estimatedMonths:0};
 let gaps=0,balanceDifferences=0;
 rows.forEach((r,i)=>{const f=paymentFinance(r);for(const k of ['paid','interest','principal'])totals[k]+=cents(f[k]);totals.regular+=cents(r.payment);totals.lumpSum+=cents(r.lump_sum);totals.overpayment+=cents(r.overpayment);if(f.estimated)totals.estimatedMonths++;if(i){const p=rows[i-1],a=new Date(p.payment_month),b=new Date(r.payment_month);if((b.getUTCFullYear()-a.getUTCFullYear())*12+b.getUTCMonth()-a.getUTCMonth()!==1)gaps++;if(Math.abs(cents(paymentFinance(p).balance)-cents(r.opening_balance))>100)balanceDifferences++;}});
 for(const k of ['paid','interest','principal','regular','lumpSum','overpayment'])totals[k]/=100;
 const latest=rows[rows.length-1],current=periods.find(d=>d.start_month.slice(0,7)<=today&&(!d.lender_end_month||d.lender_end_month>=today));
 const property=lenders.find(l=>l.id===current?.lender_id),propertyValue=Number(property?.property_value)>0?Number(property.property_value):null;
 const balance=latest?paymentFinance(latest).balance:null;
 let missing=0; if(periods.length){const start=periods.map(d=>d.start_month.slice(0,7)).sort()[0];for(let m=start;m<=today;){if(periods.some(d=>m>=d.start_month.slice(0,7)&&(!d.lender_end_month||m<=d.lender_end_month))&&!rows.some(r=>r.payment_month.slice(0,7)===m))missing++;const [y,n]=m.split('-').map(Number),dt=new Date(Date.UTC(y,n,1));m=dt.toISOString().slice(0,7);}}
 return {...totals,rows,missing,gaps,balanceDifferences,latestMonth:latest?.payment_month.slice(0,7),balance,propertyValue,property,equity:balance!==null&&propertyValue!==null?(cents(propertyValue)-cents(balance))/100:null,ltv:balance!==null&&propertyValue!==null?balance/propertyValue*100:null};
}
module.exports={paymentFinance,mortgageOverview};
