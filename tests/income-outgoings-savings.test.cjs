const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs'),vm=require('node:vm'),path=require('node:path');
const code=fs.readFileSync(path.join(__dirname,'../App.js'),'utf8');
const start=code.indexOf('const monthTx=txRows.filter');
const calculation=code.slice(start,code.indexOf('   const saveManual=',start));
function calculate(savingsRows){
 const context={key:'2026-11',rangeStart:'2026-10-24',rangeEnd:'2026-11-23',
  currentEffective:[{amount:2895.10}],
  txRows:[{date:'2026-10-28',type:'income',amount:4737.01},
   {date:'2026-10-28',type:'expense',account:'Lloyds Debit',amount:1389.93},
   {date:'2026-10-28',type:'expense',account:'Monzo Credit',amount:1.75}],
  savingsRows};
 vm.createContext(context);
 return vm.runInContext(calculation+';({incomeSavingsRows,savingsContributions,outTotal,balance})',context);
}
test('November LISA and Kids appear separately and reduce balance exactly once',()=>{
 const result=calculate([{monthYear:'2026-11',location:'LISA',moneyIn:300},
  {monthYear:'2026-11',location:'Kids Savings',moneyIn:30}]);
 assert.equal(result.incomeSavingsRows.length,2);
 assert.equal(result.savingsContributions,330);
 assert.ok(Math.abs(result.outTotal-4285.03)<0.001);
 assert.ok(Math.abs(result.balance-121.98)<0.001);
});
test('previous months, transfers, pension and withdrawals do not count as cash contributions',()=>{
 const result=calculate([
  {monthYear:'2026-10',location:'LISA',moneyIn:300},
  {monthYear:'2026-11',location:'Pension',moneyIn:643.88},
  {monthYear:'2026-11',location:'LISA',moneyIn:100,transferGroup:'transfer'},
  {monthYear:'2026-11',location:'LISA',moneyIn:0,moneyOut:30}]);
 assert.equal(result.savingsContributions,0);
 assert.equal(result.incomeSavingsRows.length,0);
 assert.ok(Math.abs(result.balance-451.98)<0.001);
});
