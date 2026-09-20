import 'react-native-url-polyfill/auto';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {createClient} from '@supabase/supabase-js';
const url=process.env.EXPO_PUBLIC_SUPABASE_URL||'https://osrsbsmbviytpjemwbho.supabase.co';
const key=process.env.EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY||'sb_publishable_Y35kZMZTGbKC3noXyypl8Q_2SalFvSQ';
export const supabase=createClient(url,key,{auth:{storage:AsyncStorage,autoRefreshToken:true,persistSession:true,detectSessionInUrl:true}});
