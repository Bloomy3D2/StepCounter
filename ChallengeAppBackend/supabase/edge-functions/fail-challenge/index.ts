// Supabase Edge Function: Fail Challenge
// Deploy: supabase functions deploy fail-challenge

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
  // КРИТИЧНО: Логируем в самом начале, чтобы увидеть, что функция вызывается
  log('🚀 fail-challenge Edge Function STARTED')
  log('📅 Timestamp:', { timestamp: new Date().toISOString() })
  
  try {
    log('🌐 Method:', { method: req.method })
    log('🔗 URL:', { url: req.url })
    
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
    
    const authHeader = req.headers.get('Authorization')
    const authHeaderPreview = authHeader ? `${authHeader.substring(0, 20)}...` : 'MISSING'
    log('🔑 Authorization header:', { 
      preview: authHeaderPreview,
      length: authHeader ? authHeader.length : 0
    })
    
    if (!authHeader) {
      log('❌ No authorization header provided')
      log('❌ Returning 401 - No authorization header')
      const errorResponse = JSON.stringify({ error: 'No authorization header' })
      log('❌ Error response:', { response: errorResponse })
      return new Response(
        errorResponse,
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
    
    if (userError) {
      log('❌ getUser() error:', {
        error: String(userError),
        type: typeof userError,
        keys: Object.keys(userError),
        status: 'status' in userError ? userError.status : undefined,
        message: 'message' in userError ? userError.message : undefined
      })
    }
    
    if (user) {
      log('✅ User found:', { userId: user.id })
    } else {
      log('❌ User is null/undefined')
    }
    
    if (userError || !user) {
      log('❌ Unauthorized - user not found or error occurred', {
        hasUserError: !!userError,
        hasUser: !!user
      })
      const errorDetails = {
        error: 'Unauthorized',
        details: userError?.message || 'User not found',
        hasUserError: !!userError,
        hasUser: !!user
      }
      log('❌ Returning 401 with details:', errorDetails)
      return new Response(
        JSON.stringify(errorDetails),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    log('✅ User authenticated:', { userId: user.id })
    
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
    log('📥 Fail challenge request', { userId: user.id, challengeId })
    
    // Проверяем user_challenge перед вызовом функции (для отладки)
    const { data: userChallengeData, error: ucError } = await supabaseClient
      .from('user_challenges')
      .select('id, user_id, challenge_id, is_active, is_completed, is_failed')
      .eq('user_id', user.id)
      .eq('challenge_id', challengeId)
      .single()
    
    if (ucError || !userChallengeData) {
      log('❌ User challenge not found:', { error: String(ucError) })
      return new Response(
        JSON.stringify({ error: 'User challenge not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    log('📋 User challenge BEFORE fail:', {
      id: userChallengeData.id,
      is_active: userChallengeData.is_active,
      is_completed: userChallengeData.is_completed,
      is_failed: userChallengeData.is_failed
    })

    // Call database function
    const { data, error } = await supabaseClient.rpc('fail_challenge', {
      p_user_id: user.id,
      p_challenge_id: challengeId
    })

    if (error) {
      log('❌ fail_challenge RPC error:', {
        code: error.code,
        message: error.message,
        details: error.details,
        hint: error.hint
      })
      
      return new Response(
        JSON.stringify({ 
          error: error.message || error.details || 'Unknown error',
          code: error.code,
          details: error.details,
          hint: error.hint
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    log('✅ fail_challenge RPC success:', { data })
    
    // Проверяем user_challenge ПОСЛЕ вызова функции (для отладки)
    const { data: userChallengeDataAfter, error: ucErrorAfter } = await supabaseClient
      .from('user_challenges')
      .select('id, user_id, challenge_id, is_active, is_completed, is_failed, failed_at, updated_at')
      .eq('user_id', user.id)
      .eq('challenge_id', challengeId)
      .single()
    
    if (!ucErrorAfter && userChallengeDataAfter) {
      log('📋 User challenge AFTER fail:', {
        id: userChallengeDataAfter.id,
        is_active: userChallengeDataAfter.is_active,
        is_completed: userChallengeDataAfter.is_completed,
        is_failed: userChallengeDataAfter.is_failed,
        failed_at: userChallengeDataAfter.failed_at,
        updated_at: userChallengeDataAfter.updated_at
      })
      
      // Проверяем, что данные действительно обновились
      if (userChallengeDataAfter.is_failed !== true || userChallengeDataAfter.is_active !== false) {
        log('❌ CRITICAL: fail_challenge RPC did not update correctly!', {
          expected: { is_failed: true, is_active: false },
          actual: { 
            is_failed: userChallengeDataAfter.is_failed, 
            is_active: userChallengeDataAfter.is_active 
          }
        })
        
        // FALLBACK: Пытаемся обновить напрямую через Supabase client
        log('🔄 Attempting direct update via Supabase client as fallback...')
        const { data: directUpdateData, error: directUpdateError } = await supabaseClient
          .from('user_challenges')
          .update({
            is_failed: true,
            is_active: false,
            failed_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          })
          .eq('user_id', user.id)
          .eq('challenge_id', challengeId)
          .select()
        
        if (directUpdateError) {
          log('❌ Direct update also failed:', { error: String(directUpdateError) })
        } else {
          log('✅ Direct update succeeded:', { data: directUpdateData })
          
          // Проверяем результат прямого обновления
          const { data: verifyData } = await supabaseClient
            .from('user_challenges')
            .select('id, is_active, is_completed, is_failed')
            .eq('user_id', user.id)
            .eq('challenge_id', challengeId)
            .single()
          
          if (verifyData && verifyData.is_failed === true && verifyData.is_active === false) {
            log('✅ Verified: Direct update worked correctly')
          } else {
            log('❌ CRITICAL: Even direct update did not work!', { verifyData })
          }
        }
      } else {
        log('✅ Verified: Challenge correctly marked as failed')
      }
    } else {
      log('❌ Could not verify user_challenge after fail:', { error: String(ucErrorAfter) })
    }

    log('✅ Returning success response')
    return new Response(
      JSON.stringify({ success: true, data }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    // Внешний catch для перехвата любых ошибок, которые не были обработаны
    log('💥 OUTER CATCH - CRITICAL ERROR in fail-challenge Edge Function:', {
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
      JSON.stringify({ 
        error: error?.message || 'Unknown error',
        type: error?.name || typeof error
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } finally {
    log('🏁 fail-challenge Edge Function FINISHED')
  }
})
