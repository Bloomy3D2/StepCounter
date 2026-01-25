// Supabase Edge Function: Join Challenge
// Deploy: supabase functions deploy join-challenge

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Helper для гарантированного логирования
function log(message: string, data?: any) {
  const timestamp = new Date().toISOString()
  const logMessage = `[${timestamp}] ${message}${data ? ' ' + JSON.stringify(data) : ''}`
  
  // Используем несколько методов для гарантированного логирования
  console.error(logMessage)
  console.log(logMessage) // На случай, если console.error не работает
  
  // Пытаемся записать напрямую в stderr (для Deno)
  try {
    const encoder = new TextEncoder()
    Deno.stderr.writeSync(encoder.encode(logMessage + '\n'))
  } catch (e) {
    // Игнорируем ошибки записи
  }
}

serve(async (req) => {
  // КРИТИЧНО: Логируем в самом начале
  log('🚀 join-challenge Edge Function STARTED')
  log('📅 Timestamp:', { timestamp: new Date().toISOString() })
  
  try {
    log('🌐 Method:', { method: req.method })
    log('🔗 URL:', { url: req.url })
    
    // Handle CORS
    if (req.method === 'OPTIONS') {
      log('✅ OPTIONS request - returning CORS headers')
      return new Response('ok', { headers: corsHeaders })
    }

    // Проверяем переменные окружения
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')
    log('🔍 Environment check:', {
      hasSupabaseUrl: !!supabaseUrl,
      hasSupabaseAnonKey: !!supabaseAnonKey
    })
    
    if (!supabaseUrl || !supabaseAnonKey) {
      log('❌ CRITICAL: Missing environment variables!')
      return new Response(
        JSON.stringify({ error: 'Server configuration error' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Логируем все заголовки для диагностики
    try {
      const headersObj = Object.fromEntries(req.headers.entries())
      log('📋 Request headers:', headersObj)
    } catch (headerError) {
      log('❌ Error logging headers:', { error: String(headerError) })
    }
    
    // Get authorization header
    const authHeader = req.headers.get('Authorization')
    const authHeaderPreview = authHeader ? `${authHeader.substring(0, 20)}...` : 'MISSING'
    log('🔑 Authorization header:', { 
      preview: authHeaderPreview,
      length: authHeader ? authHeader.length : 0
    })
    
    if (!authHeader) {
      log('❌ No authorization header provided')
      return new Response(
        JSON.stringify({ error: 'No authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    log('🔧 Creating Supabase client...')
    const supabaseClient = createClient(
      supabaseUrl,
      supabaseAnonKey,
      {
        global: {
          headers: { Authorization: authHeader },
        },
      }
    )
    log('✅ Supabase client created')

    // Get user
    log('🔍 Calling supabaseClient.auth.getUser()...')
    let user, userError
    try {
      const result = await supabaseClient.auth.getUser()
      user = result.data?.user
      userError = result.error
      log('🔍 getUser() completed', { hasUser: !!user, hasError: !!userError })
    } catch (getUserError) {
      log('❌ Exception in getUser():', { error: String(getUserError) })
      userError = getUserError
      user = null
    }
    
    if (userError || !user) {
      log('❌ Unauthorized - user not found or error occurred', {
        hasUserError: !!userError,
        hasUser: !!user,
        errorMessage: userError?.message
      })
      return new Response(
        JSON.stringify({ error: 'Unauthorized', details: userError?.message || 'User not found' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    log('✅ User authenticated:', { userId: user.id })

    // Parse request body
    log('📥 Parsing request body...')
    let challengeId
    try {
      const body = await req.json()
      challengeId = body.challengeId
      log('📥 Request body parsed', { challengeId })
    } catch (parseError) {
      log('❌ Error parsing request body:', { error: String(parseError) })
      return new Response(
        JSON.stringify({ error: 'Invalid request body', details: parseError?.message }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    if (!challengeId) {
      log('❌ challengeId is missing from request body')
      return new Response(
        JSON.stringify({ error: 'challengeId is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Log request details
    log('📥 Join challenge request', { userId: user.id, challengeId })
    
    // Проверяем статус челленджа перед вызовом функции (для отладки)
    log('🔍 Checking challenge existence...')
    const { data: challengeData, error: challengeError } = await supabaseClient
      .from('challenges')
      .select('id, title, start_date, end_date, is_active, entry_fee')
      .eq('id', challengeId)
      .single()
    
    if (challengeError || !challengeData) {
      log('❌ Challenge not found:', { error: String(challengeError), challengeId })
      return new Response(
        JSON.stringify({ error: 'Challenge not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    log('📋 Challenge info:', {
      id: challengeData.id,
      title: challengeData.title,
      start_date: challengeData.start_date,
      end_date: challengeData.end_date,
      is_active: challengeData.is_active,
      entry_fee: challengeData.entry_fee,
      now: new Date().toISOString()
    })
    
    // Проверяем, участвует ли пользователь уже
    log('🔍 Checking if user already joined...')
    const { data: existingJoin, error: joinCheckError } = await supabaseClient
      .from('user_challenges')
      .select('id, is_active, is_completed, is_failed')
      .eq('user_id', user.id)
      .eq('challenge_id', challengeId)
      .maybeSingle()
    
    if (joinCheckError && joinCheckError.code !== 'PGRST116') {
      // PGRST116 = no rows returned, это нормально
      log('⚠️ Error checking existing join:', { error: String(joinCheckError) })
    }
    
    if (existingJoin) {
      log('⚠️ User already joined this challenge:', {
        userChallengeId: existingJoin.id,
        is_active: existingJoin.is_active,
        is_completed: existingJoin.is_completed,
        is_failed: existingJoin.is_failed
      })
      return new Response(
        JSON.stringify({ error: 'User already joined this challenge' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    log('✅ User not yet joined, proceeding with join_challenge RPC...')
    
    // Call database function
    const { data, error } = await supabaseClient.rpc('join_challenge', {
      p_user_id: user.id,
      p_challenge_id: challengeId
    })

    if (error) {
      log('❌ join_challenge RPC error:', {
        code: error.code,
        message: error.message,
        details: error.details,
        hint: error.hint
      })
      
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
    
    log('✅ join_challenge RPC success:', { data })

    // Get updated user challenge
    log('🔍 Fetching created user challenge...')
    const { data: userChallenge, error: ucError } = await supabaseClient
      .from('user_challenges')
      .select(`
        *,
        challenge:challenges(*)
      `)
      .eq('id', data.user_challenge_id)
      .single()

    if (ucError) {
      log('❌ Failed to fetch user challenge:', { error: String(ucError), userChallengeId: data.user_challenge_id })
      return new Response(
        JSON.stringify({ error: 'Failed to fetch user challenge' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    log('✅ User challenge fetched successfully:', {
      id: userChallenge.id,
      challengeId: userChallenge.challenge_id,
      is_active: userChallenge.is_active
    })
    
    log('✅ Returning success response')
    return new Response(
      JSON.stringify({ success: true, data: userChallenge }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    // Внешний catch для перехвата любых ошибок
    log('💥 OUTER CATCH - CRITICAL ERROR in join-challenge Edge Function:', {
      type: typeof error,
      name: error?.name,
      message: error?.message,
      stack: error?.stack
    })
    
    try {
      log('   Full error:', JSON.parse(JSON.stringify(error, Object.getOwnPropertyNames(error))))
    } catch (stringifyError) {
      log('   Could not stringify error:', { error: String(stringifyError) })
    }
    
    return new Response(
      JSON.stringify({ error: error?.message || 'Unknown error', type: error?.name || typeof error }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } finally {
    log('🏁 join-challenge Edge Function FINISHED')
  }
})
