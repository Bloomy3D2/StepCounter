// Supabase Edge Function: Complete Day
// Deploy: supabase functions deploy complete-day

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'No authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: authHeader },
        },
      }
    )

    const { data: { user }, error: userError } = await supabaseClient.auth.getUser()
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const { challengeId } = await req.json()
    if (!challengeId) {
      return new Response(
        JSON.stringify({ error: 'challengeId is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Log request details
    console.log(`📥 Complete day request: userId=${user.id}, challengeId=${challengeId}`)
    
    // Проверяем user_challenge перед вызовом функции (для отладки)
    const { data: userChallengeData, error: ucError } = await supabaseClient
      .from('user_challenges')
      .select('id, user_id, challenge_id, is_active, entry_date, is_completed, is_failed')
      .eq('user_id', user.id)
      .eq('challenge_id', challengeId)
      .single()
    
    if (ucError || !userChallengeData) {
      console.error(`❌ User challenge not found:`, ucError)
      return new Response(
        JSON.stringify({ error: 'User challenge not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    console.log(`📋 User challenge info:`, {
      id: userChallengeData.id,
      is_active: userChallengeData.is_active,
      is_completed: userChallengeData.is_completed,
      is_failed: userChallengeData.is_failed,
      entry_date: userChallengeData.entry_date,
      now: new Date().toISOString()
    })
    
    // Проверяем, выполнен ли уже сегодня
    const { data: completedToday, error: completedError } = await supabaseClient
      .from('completed_days')
      .select('id')
      .eq('user_challenge_id', userChallengeData.id)
      .eq('completed_date', new Date().toISOString().split('T')[0])
      .single()
    
    if (completedToday) {
      console.log(`⚠️ Day already completed today`)
      return new Response(
        JSON.stringify({ error: 'Day already completed' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Call database function
    const { data, error } = await supabaseClient.rpc('complete_day', {
      p_user_id: user.id,
      p_challenge_id: challengeId
    })

    if (error) {
      console.error(`❌ complete_day RPC error:`, error)
      console.error(`   Code: ${error.code}`)
      console.error(`   Message: ${error.message}`)
      console.error(`   Details: ${error.details}`)
      console.error(`   Hint: ${error.hint}`)
      
      // Return detailed error message
      const errorMessage = error.message || error.details || 'Unknown error'
      return new Response(
        JSON.stringify({ 
          error: errorMessage,
          code: error.code,
          details: error.details,
          hint: error.hint
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    console.log(`✅ complete_day RPC success:`, data)

    return new Response(
      JSON.stringify({ success: true, data }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
