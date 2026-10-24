import React from 'react';
import {View,Text,Pressable,StyleSheet} from 'react-native';

const dateKey=d=>`${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
const money=n=>new Intl.NumberFormat('en-GB',{style:'currency',currency:'GBP',maximumFractionDigits:2}).format(n);

// Use local calendar dates: UTC conversion can shift dates during British Summer Time.
export function calendarMonths(start,end){
  const months=[];
  for(let cursor=new Date(start+'T12:00:00');dateKey(cursor)<=end;cursor=new Date(cursor.getFullYear(),cursor.getMonth()+1,1,12)){
    const year=cursor.getFullYear(),month=cursor.getMonth();
    const cells=Array((new Date(year,month,1,12).getDay()+6)%7).fill(null);
    for(let day=1;day<=new Date(year,month+1,0,12).getDate();day++){
      const date=dateKey(new Date(year,month,day,12));
      cells.push({date,day,enabled:date>=start&&date<=end});
    }
    while(cells.length%7)cells.push(null);
    months.push({key:`${year}-${month}`,title:cursor.toLocaleDateString('en-GB',{month:'long',year:'numeric'}),cells});
  }
  return months;
}

export default function ExpenseCalendar({start,end,items,selected,onSelect,dark=false}){
  const totals={};
  items.forEach(x=>{const total=totals[x.date]||(totals[x.date]={amount:0,count:0});total.amount+=Number(x.amount||0);total.count++;});
  const today=dateKey(new Date()),text={color:dark?'#edf8f4':'#18342b'},muted={color:dark?'#adc3ba':'#66736f'};
  return <View style={[styles.card,dark&&{backgroundColor:'#172c24',borderColor:'#345247'}]}>
    <View style={styles.heading}><Text style={[styles.title,text]}>Expense calendar</Text><Pressable accessibilityRole="button" onPress={()=>onSelect(null)} style={styles.all}><Text style={{color:'#006a4d',fontWeight:'600'}}>All dates</Text></Pressable></View>
    <Text style={[styles.hint,muted]}>Tap a date to see its expenses. Totals follow your filters.</Text>
    {calendarMonths(start,end).map(month=><View key={month.key}>
      <Text style={[styles.month,text]}>{month.title}</Text>
      <View style={styles.grid}>{['Mon','Tue','Wed','Thu','Fri','Sat','Sun'].map(day=><Text key={day} style={[styles.weekday,muted]}>{day}</Text>)}</View>
      <View style={styles.grid}>{month.cells.map((cell,i)=>{
        if(!cell)return <View key={'blank'+i} style={styles.cell}/>;
        const active=selected===cell.date,total=totals[cell.date],color=active?{color:'#fff'}:text;
        return <Pressable key={cell.date} disabled={!cell.enabled} accessibilityRole="button" accessibilityState={{selected:active,disabled:!cell.enabled}} accessibilityLabel={`${cell.date}, ${total?.count||0} expenses, ${money(total?.amount||0)}`} onPress={()=>onSelect(active?null:cell.date)} style={[styles.cell,!cell.enabled&&{opacity:.25},cell.date===today&&styles.today,active&&styles.active]}>
          <Text style={[styles.day,color]}>{cell.day}</Text>
          {cell.enabled&&total?<><Text numberOfLines={1} adjustsFontSizeToFit minimumFontScale={.65} style={[styles.total,active?{color:'#fff'}:{color:dark?'#9edfc4':'#006a4d'}]}>{money(total.amount)}</Text><View style={[styles.dot,active&&{backgroundColor:'#fff'}]}/></>:<Text style={styles.total}> </Text>}
        </Pressable>;
      })}</View>
    </View>)}
  </View>;
}

const styles=StyleSheet.create({card:{marginHorizontal:16,marginVertical:12,padding:12,borderRadius:18,borderWidth:1,borderColor:'#e0e9e5',backgroundColor:'#fff'},heading:{flexDirection:'row',alignItems:'center',justifyContent:'space-between'},title:{fontSize:18,fontWeight:'600'},all:{padding:12,borderRadius:12,backgroundColor:'#e7f3ef'},hint:{fontSize:12,lineHeight:18,marginTop:5},month:{fontSize:16,fontWeight:'600',marginTop:18,marginBottom:12},grid:{flexDirection:'row',flexWrap:'wrap'},weekday:{width:'14.285714%',textAlign:'center',fontSize:11,paddingBottom:8},cell:{width:'14.285714%',minHeight:68,paddingHorizontal:2,paddingVertical:8,alignItems:'center',borderRadius:12,borderWidth:1,borderColor:'transparent'},today:{borderColor:'#087a57'},active:{backgroundColor:'#006a4d'},day:{fontSize:15,fontWeight:'600'},total:{fontSize:10,marginTop:5},dot:{width:4,height:4,borderRadius:2,backgroundColor:'#087a57',marginTop:4}});
