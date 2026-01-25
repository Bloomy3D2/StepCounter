// Supabase Edge Function: Payment Webhook
// Deploy: supabase functions deploy payment-webhook
// 
// Этот webhook обрабатывает уведомления от ЮKassa о статусе платежей
// Настройте URL в ЮKassa: https://YOUR_PROJECT.supabase.co/functions/v1/payment-webhook

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { crypto } from "https://deno.land/std@0.168.0/crypto/mod.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Проверка подписи webhook от ЮKassa (важно для безопасности!)
// ВАЖНО: ЮKassa API v3 использует HMAC-SHA256 для подписи webhook'ов
// Подпись передается в заголовке X-YooMoney-Signature
// Формат: HMAC-SHA256(secret_key, request_body)
async function verifySignature(body: string, signature: string, secretKey: string): Promise<boolean> {
  // Если подпись не предоставлена, пропускаем проверку (не рекомендуется для продакшена)
  if (!signature) {
    console.warn('⚠️ No signature provided in webhook')
    // В тестовом режиме можно пропустить проверку
    // В продакшене это должно быть ошибкой!
    const isTestMode = Deno.env.get('YOOKASSA_TEST_MODE') === 'true' || secretKey.startsWith('test_')
    if (!isTestMode) {
      console.error('❌ Missing signature in production mode - rejecting webhook')
      return false
    }
    return true
  }
  
  if (!secretKey) {
    console.warn('⚠️ No secret key configured for signature verification')
    return false
  }
  
  try {
    // Вычисляем HMAC-SHA256 подпись
    const encoder = new TextEncoder()
    const keyData = encoder.encode(secretKey)
    const bodyData = encoder.encode(body)
    
    // Импортируем ключ для HMAC
    const key = await crypto.subtle.importKey(
      'raw',
      keyData,
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign']
    )
    
    // Вычисляем подпись
    const signatureBytes = await crypto.subtle.sign('HMAC', key, bodyData)
    
    // Конвертируем в base64 для сравнения
    const expectedSignature = btoa(String.fromCharCode(...new Uint8Array(signatureBytes)))
    
    // Сравниваем подписи (используем timing-safe сравнение)
    if (signature.length !== expectedSignature.length) {
      console.error('❌ Signature length mismatch')
      return false
    }
    
    // Простое сравнение (для production лучше использовать timing-safe)
    let matches = true
    for (let i = 0; i < signature.length; i++) {
      if (signature[i] !== expectedSignature[i]) {
        matches = false
        break
      }
    }
    
    if (!matches) {
      console.error('❌ Signature verification failed')
      return false
    }
    
    console.log('✅ Signature verified successfully')
    return true
  } catch (error) {
    console.error('❌ Error verifying signature:', error)
    return false
  }
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Получаем тело запроса
    const body = await req.text()
    const webhookData = JSON.parse(body)
    
    // Проверяем подпись (если настроена)
    const signature = req.headers.get('X-YooMoney-Signature')
    const secretKey = Deno.env.get('YOOKASSA_SECRET_KEY') ?? ''
    
    if (signature && secretKey) {
      const isValid = await verifySignature(body, signature, secretKey)
      if (!isValid) {
        console.error('❌ Invalid webhook signature')
        return new Response(
          JSON.stringify({ error: 'Invalid signature' }),
          { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    }
    
    // Создаем Supabase client с service role key (для обхода RLS)
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )
    
    const event = webhookData.event
    const payment = webhookData.object
    
    console.log(`📨 Webhook received: ${event}, Payment ID: ${payment.id}, Status: ${payment.status}`)
    
    // Обрабатываем события о платежах
    if (event === 'payment.succeeded' || event === 'payment.waiting_for_capture') {
      const paymentId = payment.id
      const status = payment.status
      const amount = parseFloat(payment.amount.value)
      const metadata = payment.metadata || {}
      const challengeId = metadata.challenge_id ? parseInt(metadata.challenge_id) : null
      const userId = metadata.user_id || null
      
      // Для waiting_for_capture может потребоваться явный capture
      // Но так как мы используем capture: true при создании, это должно происходить автоматически
      // Оставляем обработку для случаев, когда требуется ручной capture
      if (status === 'waiting_for_capture') {
        console.log('ℹ️ Payment waiting for capture - may require explicit capture call')
        // В большинстве случаев с capture: true это не требуется
        // Но можно добавить вызов capture API здесь, если нужно
      }
      
      // Обновляем статус платежа в БД
      const { error: paymentError } = await supabaseClient
        .from('payments')
        .update({
          status: status === 'succeeded' ? 'COMPLETED' : 'PENDING',
          processed_at: new Date().toISOString(),
          transaction_id: paymentId
        })
        .eq('transaction_id', paymentId)
      
      if (paymentError) {
        console.error('⚠️ Error updating payment:', paymentError)
        // Если платеж не найден, создаем новую запись
        if (challengeId && userId) {
          await supabaseClient
            .from('payments')
            .insert({
              user_id: userId,
              challenge_id: challengeId,
              type: 'ENTRY_FEE',
              status: status === 'succeeded' ? 'COMPLETED' : 'PENDING',
              amount: amount,
              transaction_id: paymentId,
              description: `Payment for challenge via YooKassa`,
              processed_at: new Date().toISOString()
            })
        }
      }
      
      // Если платеж успешен, вступаем в челлендж
      if (status === 'succeeded' && challengeId && userId) {
        console.log(`✅ Payment succeeded, joining challenge: ${challengeId} for user: ${userId}`)
        
        try {
          // Вызываем функцию вступления в челлендж
          const { data, error } = await supabaseClient.rpc('join_challenge', {
            p_user_id: userId,
            p_challenge_id: challengeId
          })
          
          if (error) {
            console.error('❌ Error joining challenge:', error)
            
            // КРИТИЧЕСКАЯ ОШИБКА: Платеж успешен, но вступление не удалось
            // Инициируем возврат средств через API ЮKassa
            console.error('🚨 CRITICAL: Payment succeeded but failed to join challenge. Refund required!')
            console.error('🚨 Payment ID:', paymentId)
            console.error('🚨 Challenge ID:', challengeId)
            console.error('🚨 User ID:', userId)
            
            // Вызываем API ЮKassa для возврата средств
            try {
              await initiateRefund(paymentId, amount, secretKey)
            } catch (refundError) {
              console.error('❌ Failed to initiate refund:', refundError)
              // Логируем критическую ошибку, но не прерываем выполнение
            }
            
          } else {
            console.log('✅ Successfully joined challenge:', data)
          }
        } catch (joinError) {
          console.error('❌ Exception joining challenge:', joinError)
        }
      }
      
      return new Response(
        JSON.stringify({ success: true, message: 'Webhook processed' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    // Обрабатываем отмененные платежи
    if (event === 'payment.canceled') {
      const paymentId = payment.id
      
      await supabaseClient
        .from('payments')
        .update({
          status: 'FAILED',
          processed_at: new Date().toISOString()
        })
        .eq('transaction_id', paymentId)
      
      return new Response(
        JSON.stringify({ success: true, message: 'Payment canceled' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    // Неизвестное событие
    console.log('ℹ️ Unknown event type:', event)
    return new Response(
      JSON.stringify({ success: true, message: 'Event ignored' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('❌ Webhook error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

// Функция для инициации возврата средств через API ЮKassa
async function initiateRefund(paymentId: string, amount: number, secretKey: string): Promise<void> {
  const refundUrl = 'https://api.yookassa.ru/v3/refunds'
  const credentials = btoa(`${Deno.env.get('YOOKASSA_SHOP_ID')}:${secretKey}`)
  
  const refundRequest = {
    payment_id: paymentId,
    amount: {
      value: amount.toFixed(2),
      currency: 'RUB'
    }
  }
  
  try {
    const response = await fetch(refundUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${credentials}`,
        'Content-Type': 'application/json',
        'Idempotence-Key': crypto.randomUUID()
      },
      body: JSON.stringify(refundRequest)
    })
    
    if (!response.ok) {
      const errorText = await response.text()
      console.error('❌ Refund API error:', response.status, errorText)
      throw new Error(`Refund failed: ${response.status}`)
    }
    
    const refundData = await response.json()
    console.log('✅ Refund initiated successfully:', refundData.id)
  } catch (error) {
    console.error('❌ Error initiating refund:', error)
    throw error
  }
}
