
export function parseReceiptItems(result) {
 const lines=Array.isArray(result?.lines)&&result.lines.length?result.lines.map(x=>x.text):String(result?.text||'').split(/\r?\n/);
 const summary=/^(?:sub\s*total|total|grand total|balance|amount due|amount paid|cash|change|card|visa|mastercard|amex|payment|tender|vat|tax|receipt|transaction|terminal|auth|approval|merchant|store|tel|phone|www|https|thank|clubcard|nectar|points|savings|you saved|items? sold|number of items)\b/i;
 const items=[];
 for(const line of lines){
  const text=String(line||'').trim();
  if(!text||summary.test(text)||/\b(?:\d{1,2}[/:]\d{1,2}[/:]\d{2,4}|\d{1,2}:\d{2})\b/.test(text))continue;
  const match=text.match(/^(.*?)\s+([−-]?\s*£?\s*\d+(?:[.,]\d{2}))\s*([−-]?)\s*(?:[A-Z*])?\s*$/);
  if(!match)continue;
  const name=match[1].replace(/\s+/g,' ').trim();
  if(!/[a-z]/i.test(name)||summary.test(name)||/^(?:\d+[.,]?\d*\s*(?:kg|g|lb)?\s*[@x×]|@)/i.test(name))continue;
  let amount=Number(match[2].replace(/[£\s]/g,'').replace('−','-').replace(',','.'));
  if(match[3])amount=-Math.abs(amount);
  if(Number.isFinite(amount))items.push({name,amount});
 }
 return items;
}
export function receiptItemsTotal(items) {
 return (items||[]).reduce((sum,item)=>sum+Math.round(Number(item.amount||0)*100),0)/100;
}
export function validateReceiptItems(items) {
 return Array.isArray(items)&&items.every(item=>String(item.name||'').trim()&&String(item.amount).trim()!==''&&Number.isFinite(Number(item.amount)));
}
