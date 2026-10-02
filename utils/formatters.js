export const money=n=>new Intl.NumberFormat('en-GB',{style:'currency',currency:'GBP'}).format(Number(n||0));
export const pad=n=>String(n).padStart(2,'0');
export const monthKey=d=>d.getFullYear()+'-'+pad(d.getMonth()+1);
export const monthName=d=>d.toLocaleDateString('en-GB',{month:'long',year:'numeric'});
export const shiftMonth=(d,n)=>new Date(d.getFullYear(),d.getMonth()+n,1);
export const isoDate=(key,day)=>{const [y,m]=key.split('-').map(Number),last=new Date(y,m,0).getDate();return key+'-'+pad(Math.max(1,Math.min(last,Number(day)||1)))};
export const prettyDate=v=>new Date(v+'T12:00:00').toLocaleDateString('en-GB',{day:'2-digit',month:'short'});
export const canonicalBank=v=>{const s=String(v||'').toLowerCase();if(s.includes('monzo')&&s.includes('credit'))return'Monzo Credit';if(s.includes('monzo'))return'Monzo Debit';if(s.includes('lloyds')&&s.includes('credit'))return'Lloyds Credit';if(s.includes('lloyds'))return'Lloyds Debit';return v||'Not specified'};
export const tagsOf=v=>{if(Array.isArray(v))return v;try{const p=JSON.parse(v);return Array.isArray(p)?p:[]}catch{return String(v||'').split(',').map(x=>x.trim()).filter(Boolean)}};
