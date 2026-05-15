import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://idcedhbakykvgfvvqwun.supabase.co'
const supabaseKey = 'sb_publishable_gxlVigh7-NU9TWQ4o0D6DA_FQhkIBaT'

export const supabase = createClient(supabaseUrl, supabaseKey)