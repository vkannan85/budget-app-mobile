const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
const source=fs.readFileSync(require('node:path').join(__dirname,'../App.js'),'utf8');
const helpers=source.slice(source.indexOf('const pad='),source.indexOf('const Button='));
const save=source.slice(source.indexOf(' async function save(form)'),source.indexOf(' async function remove(item)'));
const copyStart=source.indexOf('async function copyPrevious(){');
const copy=source.slice(copyStart,source.indexOf("\n if(screen==='home')",copyStart));
const period={start_date:'2026-10-24',end_date:'2026-11-23'};
function setup(overrides={}){
 const writes=[],alerts=[];
 const context={key:'2026-11',period,month:new Date(2026,10,1),rows:[],items:[],
  globalThis:{crypto:{randomUUID:()=> 'new-id'}},
  Alert:{alert:(...args)=>alerts.push(args)},setEdit:()=>{},load:async()=>{},
  supabase:{from:()=>({
   update:record=>({eq:async(_,id)=>{writes.push({id,...record});return{}}}),
   insert:async records=>{writes.push(...(Array.isArray(records)?records:[records]));return{}}
  })},...overrides};
 vm.createContext(context);vm.runInContext(helpers+save+copy,context);
 return {context,writes,alerts};
}
function item(extra={}){return {rowId:'mortgage',id:'mortgage',payee:'Mortgage',month:'2026-11',dueDay:28,
 date:'2026-10-28',amount:1356.82,bank:'Lloyds Debit',status:'pending',tags:['Home'],
 raw:{date:'2026-10-28',vendor:'Bank of Ireland'},...extra};}
test('mark mortgage paid without changing its October date',async()=>{
 const {context,writes}=setup();await context.toggle(item());
 assert.equal(writes.length,1);assert.equal(writes[0].data.date,'2026-10-28');
 assert.equal(writes[0].data.status,'Paid');assert.equal(writes[0].data.month,'2026-11');
 assert.equal(writes[0].data.amount,1356.82);
});
test('mark Apple iPad Care paid and pending without changing its date',async()=>{
 const {context,writes}=setup();
 const apple=item({payee:'Apple iPad Care',amount:7.49,bank:'Monzo Debit'});
 await context.toggle(apple);await context.toggle({...apple,status:'paid'});
 assert.equal(writes[0].data.date,'2026-10-28');assert.equal(writes[0].data.status,'Paid');
 assert.equal(writes[1].data.date,'2026-10-28');assert.equal(writes[1].data.status,'In Due');
});
test('editing amount preserves payment date and account',async()=>{
 const {context,writes}=setup();await context.save(item({amount:1400}));
 assert.equal(writes[0].data.date,'2026-10-28');assert.equal(writes[0].data.amount,1400);
 assert.equal(writes[0].data.bank,'Lloyds Debit');
});
test('new debit day 28 falls in October within November budget',async()=>{
 const {context,writes}=setup();await context.save(item({rowId:undefined,id:undefined,date:undefined}));
 assert.equal(writes[0].data.date,'2026-10-28');
});
test('changing due day resolves to correct calendar month',async()=>{
 const {context,writes}=setup();await context.save(item({dueDay:5}));
 assert.equal(writes[0].data.date,'2026-11-05');
});
test('copy previous month moves day 28 to October, day 5 to November',async()=>{
 const old=[item({month:'2026-10',date:'2026-09-28',status:'paid'}),
 item({id:'car',rowId:'car',payee:'Car Loan',month:'2026-10',date:'2026-10-05',dueDay:5,status:'paid'})];
 const {context,writes}=setup({rows:old});await context.copyPrevious();
 assert.equal(writes.length,2);assert.equal(writes[0].data.date,'2026-10-28');
 assert.equal(writes[1].data.date,'2026-11-05');assert.ok(writes.every(x=>x.data.status==='In Due'));
});
test('calendar months without custom periods retain ordinary dates',()=>{
 const {context}=setup();assert.equal(context.directDebitDate(item(),undefined),'2026-11-28');
});
test('year boundary uses previous December within January budget',()=>{
 const {context}=setup();
 assert.equal(context.directDebitDate(item({month:'2027-01',date:undefined}),{start_date:'2026-12-24',end_date:'2027-01-23'}),'2026-12-28');
});
test('short months clamp day 31 to last available day',()=>{
 const {context}=setup();
 assert.equal(context.directDebitDate(item({month:'2027-02',dueDay:31,date:undefined}),{start_date:'2027-02-01',end_date:'2027-02-28'}),'2027-02-28');
});
test('no occurrence in short custom period prevents saving',async()=>{
 const {context,writes,alerts}=setup({period:{start_date:'2026-11-01',end_date:'2026-11-10'}});
 await context.save(item());assert.equal(writes.length,0);assert.equal(alerts.length,1);
});
test('no occurrence prevents copying entire batch',async()=>{
 const {context,writes,alerts}=setup({period:{start_date:'2026-11-01',end_date:'2026-11-10'},rows:[item({month:'2026-10'})]});
 await context.copyPrevious();assert.equal(writes.length,0);assert.equal(alerts.length,1);
});
test('all payment days resolve within the November custom period',()=>{
 const {context}=setup();
 for(let day=1;day<=31;day++){
  const date=context.directDebitDate(item({dueDay:day,date:undefined}),period);
  assert.ok(date>=period.start_date&&date<=period.end_date,day+': '+date);
  assert.equal(Number(date.slice(8)),day);
 }
});

test('status-only change preserves an adjusted actual payment date',async()=>{
 const {context,writes}=setup();
 await context.toggle(item({date:'2026-10-29',raw:{date:'2026-10-29',dueDay:28}}));
 assert.equal(writes[0].data.date,'2026-10-29');
});
