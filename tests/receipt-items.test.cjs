const test=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const helpers=import('data:text/javascript;base64,'+Buffer.from(fs.readFileSync(path.join(__dirname,'../lib/receipt-items.js'),'utf8')).toString('base64'));
test('reads items and discounts while excluding receipt totals, payment, dates and weight prices',async()=>{
const {parseReceiptItems,receiptItemsTotal}=await helpers;
const items=parseReceiptItems({text:'TESCO\nMilk 1.50\nRice 8.00 A\nBread 3.00\nTOTAL 12.50\nVISA 12.50\nVAT 0.00\nClubcard saving 0.50\n0.50 kg @ 2.00\nCoupon 0.50-\nChange 0.00\n01/11/2026 13:50'});
assert.deepEqual(items,[{name:'Milk',amount:1.5},{name:'Rice',amount:8},{name:'Bread',amount:3},{name:'Coupon',amount:-.5}]);assert.equal(receiptItemsTotal(items),12);
});
test('reads structured OCR lines, pound symbols and comma decimals',async()=>{const {parseReceiptItems}=await helpers;assert.deepEqual(parseReceiptItems({lines:[{text:'Tea £2.99'},{text:'Coffee 3,50'}]}),[{name:'Tea',amount:2.99},{name:'Coffee',amount:3.5}])});
test('requires names and numeric prices, including legitimate zero and negative prices',async()=>{const {validateReceiptItems}=await helpers;assert.equal(validateReceiptItems([{name:'Milk',amount:''}]),false);assert.equal(validateReceiptItems([{name:'',amount:1}]),false);assert.equal(validateReceiptItems([{name:'Discount',amount:-1},{name:'Free item',amount:0}]),true)});
