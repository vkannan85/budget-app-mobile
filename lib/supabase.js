import 'react-native-url-polyfill/auto';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {Platform} from 'react-native';
import {createClient} from '@supabase/supabase-js';
const url=process.env.EXPO_PUBLIC_SUPABASE_URL||'https://osrsbsmbviytpjemwbho.supabase.co';
const key=process.env.EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY||'sb_publishable_Y35kZMZTGbKC3noXyypl8Q_2SalFvSQ';
const webStorage=typeof window!=='undefined'?window.localStorage:AsyncStorage;
export const supabase=createClient(url,key,{auth:{storage:Platform.OS==='web'?webStorage:AsyncStorage,autoRefreshToken:true,persistSession:true,detectSessionInUrl:true,flowType:'implicit'}});
