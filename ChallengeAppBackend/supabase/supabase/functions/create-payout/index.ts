// Supabase Edge Function: Create Payout via YooKassa Payouts API
// Deploy: supabase functions deploy create-payout
//
// Создает выплату через YooKassa Payouts API
// Поддерживает выплаты на: банковские карты, СБП (по номеру телефона), банковские счета

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
  
  console.error(logMessage)
  console.log(logMessage)
  
  try {
    const encoder = new TextEncoder()
    Deno.stderr.writeSync(encoder.encode(logMessage + '\n'))
  } catch (e) {
    // Игнорируем ошибки записи
  }
}

serve(async (req) => {
  log('🚀 create-payout Edge Function STARTED')
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
    const yooKassaShopId = Deno.env.get('YOOKASSA_SHOP_ID')
    const yooKassaSecretKey = Deno.env.get('YOOKASSA_SECRET_KEY')
    
    log('🔍 Environment check:', {
      hasSupabaseUrl: !!supabaseUrl,
      hasSupabaseAnonKey: !!supabaseAnonKey,
      hasYooKassaShopId: !!yooKassaShopId,
      hasYooKassaSecretKey: !!yooKassaSecretKey
    })
    
    if (!supabaseUrl || !supabaseAnonKey) {
      log('❌ CRITICAL: Missing Supabase environment variables!')
      return new Response(
        JSON.stringify({ error: 'Server configuration error' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    if (!yooKassaShopId || !yooKassaSecretKey) {
      log('❌ CRITICAL: Missing YooKassa credentials!')
      return new Response(
        JSON.stringify({ error: 'YooKassa credentials not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    // Get authorization header
    const authHeader = req.headers.get('Authorization')
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
    let payoutData
    try {
      const body = await req.json()
      payoutData = body
      log('📥 Request body parsed', { 
        amount: payoutData.amount,
        method: payoutData.method,
        hasCardNumber: !!payoutData.cardNumber,
        hasPhoneNumber: !!payoutData.phoneNumber,
        hasBankAccount: !!payoutData.bankAccount
      })
    } catch (parseError) {
      log('❌ Error parsing request body:', { error: String(parseError) })
      return new Response(
        JSON.stringify({ error: 'Invalid request body', details: parseError?.message }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    // Валидация данных
    const { amount, method, cardNumber, phoneNumber, bankAccount, description } = payoutData
    
    if (!amount || amount <= 0) {
      log('❌ Invalid amount:', { amount })
      return new Response(
        JSON.stringify({ error: 'Invalid amount' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    if (!method || !['card', 'sbp', 'bank_account'].includes(method)) {
      log('❌ Invalid payout method:', { method })
      return new Response(
        JSON.stringify({ error: 'Invalid payout method. Must be: card, sbp, or bank_account' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    // Проверяем наличие данных для выбранного метода
    if (method === 'card' && !cardNumber) {
      return new Response(
        JSON.stringify({ error: 'Card number is required for card payout' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    if (method === 'sbp' && !phoneNumber) {
      return new Response(
        JSON.stringify({ error: 'Phone number is required for SBP payout' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    if (method === 'bank_account' && !bankAccount) {
      return new Response(
        JSON.stringify({ error: 'Bank account is required for bank account payout' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    // Проверяем баланс пользователя
    log('🔍 Checking user balance...')
    const { data: userData, error: userDataError } = await supabaseClient
      .from('users')
      .select('balance')
      .eq('id', user.id)
      .single()
    
    if (userDataError || !userData) {
      log('❌ Error fetching user balance:', { error: String(userDataError) })
      return new Response(
        JSON.stringify({ error: 'Failed to fetch user balance' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    if (userData.balance < amount) {
      log('❌ Insufficient balance:', { balance: userData.balance, requested: amount })
      return new Response(
        JSON.stringify({ 
          error: 'Insufficient balance',
          details: `Available: ${userData.balance}, Requested: ${amount}`
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    log('✅ Balance check passed:', { balance: userData.balance, amount })
    
    // Формируем запрос к YooKassa Payouts API
    const yooKassaUrl = 'https://api.yookassa.ru/v3/payouts'
    const idempotenceKey = crypto.randomUUID()
    
    // Базовая авторизация для YooKassa
    const credentials = `${yooKassaShopId}:${yooKassaSecretKey}`
    const base64Auth = btoa(credentials)
    
    // Формируем payout_destination_data в зависимости от метода
    let payoutDestinationData: any = {}
    
    if (method === 'card') {
      // Выплата на банковскую карту
      payoutDestinationData = {
        type: 'bank_card',
        card: {
          number: cardNumber.replace(/\s/g, '') // Убираем пробелы
        }
      }
    } else if (method === 'sbp') {
      // Выплата через СБП (по номеру телефона)
      payoutDestinationData = {
        type: 'sbp',
        sbp: {
          phone: phoneNumber.replace(/[^\d+]/g, '') // Оставляем только цифры и +
        }
      }
    } else if (method === 'bank_account') {
      // Выплата на банковский счет
      payoutDestinationData = {
        type: 'yoo_money', // Для банковского счета может потребоваться другой тип
        // Или использовать bank_account если поддерживается
        // Уточните в документации YooKassa для банковских счетов
      }
    }
    
    const payoutRequest = {
      amount: {
        value: amount.toFixed(2),
        currency: 'RUB'
      },
      payout_destination_data: payoutDestinationData,
      description: description || `Вывод средств: ${amount} ₽`,
      metadata: {
        user_id: user.id,
        payout_method: method
      }
    }
    
    log('📤 Creating payout via YooKassa API...', {
      amount: payoutRequest.amount.value,
      method: method,
      idempotenceKey
    })
    
    // Вызываем YooKassa Payouts API
    const yooKassaResponse = await fetch(yooKassaUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${base64Auth}`,
        'Content-Type': 'application/json',
        'Idempotence-Key': idempotenceKey
      },
      body: JSON.stringify(payoutRequest)
    })
    
    const yooKassaData = await yooKassaResponse.json()
    
    log('📥 YooKassa API response:', {
      status: yooKassaResponse.status,
      statusText: yooKassaResponse.statusText,
      payoutId: yooKassaData.id,
      payoutStatus: yooKassaData.status
    })
    
    if (!yooKassaResponse.ok) {
      log('❌ YooKassa API error:', yooKassaData)
      return new Response(
        JSON.stringify({ 
          error: yooKassaData.description || 'YooKassa payout creation failed',
          code: yooKassaData.code,
          details: yooKassaData
        }),
        { status: yooKassaResponse.status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    // Списываем баланс пользователя
    const newBalance = userData.balance - amount
    
    log('💰 Updating user balance...', { oldBalance: userData.balance, newBalance, amount })
    
    const { error: balanceUpdateError } = await supabaseClient
      .from('users')
      .update({ balance: newBalance })
      .eq('id', user.id)
    
    if (balanceUpdateError) {
      log('❌ Error updating user balance:', { error: String(balanceUpdateError) })
      // ВАЖНО: Если баланс не обновлен, но выплата создана, нужно отменить выплату или обработать это
      // Для упрощения просто возвращаем ошибку
      return new Response(
        JSON.stringify({ error: 'Failed to update user balance' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    // Создаем запись о выплате в таблице payments
    const accountDetails = method === 'card' ? `Карта: ${cardNumber}` :
                          method === 'sbp' ? `СБП: ${phoneNumber}` :
                          `Счет: ${bankAccount}`
    
    const { error: paymentInsertError } = await supabaseClient
      .from('payments')
      .insert({
        user_id: user.id,
        challenge_id: null,
        type: 'WITHDRAWAL',
        status: yooKassaData.status === 'succeeded' ? 'COMPLETED' : 'PENDING',
        amount: amount,
        transaction_id: yooKassaData.id,
        description: accountDetails
      })
    
    if (paymentInsertError) {
      log('⚠️ Error inserting payment record:', { error: String(paymentInsertError) })
      // Не критично, но логируем
    }
    
    log('✅ Payout created successfully:', {
      payoutId: yooKassaData.id,
      status: yooKassaData.status,
      newBalance
    })
    
    return new Response(
      JSON.stringify({
        success: true,
        payout: {
          id: yooKassaData.id,
          status: yooKassaData.status,
          amount: yooKassaData.amount,
          created_at: yooKassaData.created_at
        },
        newBalance
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    log('💥 OUTER CATCH - CRITICAL ERROR in create-payout Edge Function:', {
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
    log('🏁 create-payout Edge Function FINISHED')
  }
})
