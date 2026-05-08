import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://ocjbpsvpjbnnoytbwaoo.supabase.co'
const supabaseKey = 'sb_publishable_gSK-_e6wONmy_Z5_Q_IIew_EyibrU4m'

export const supabase = createClient(supabaseUrl, supabaseKey)