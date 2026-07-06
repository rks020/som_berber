import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { JWT } from 'https://esm.sh/google-auth-library@8'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const payload = await req.json()
    console.log('Webhook payload:', payload)

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const record = payload.record
    const old_record = payload.old_record
    const type = payload.type // INSERT, UPDATE, DELETE

    const serviceAccountStr = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
    if (!serviceAccountStr) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT env var is missing')
    }
    const serviceAccount = JSON.parse(serviceAccountStr)

    const getAccessToken = async () => {
      const jwtClient = new JWT({
        email: serviceAccount.client_email,
        key: serviceAccount.private_key,
        scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
      })
      const tokens = await jwtClient.authorize()
      return tokens.access_token
    }

    const sendFcm = async (token: string, title: string, body: string) => {
      const accessToken = await getAccessToken()
      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${accessToken}`,
          },
          body: JSON.stringify({
            message: {
              token: token,
              notification: {
                title,
                body,
              },
            },
          }),
        }
      )
      console.log('FCM response:', await response.json())
    }

    if (type === 'INSERT') {
      // Notify admins
      const { data: admins } = await supabase.from('admin_device_tokens').select('token')
      if (admins) {
        for (const admin of admins) {
          if (admin.token) {
            await sendFcm(admin.token, 'Yeni Randevu Talebi', `Bir müşteri randevu talep etti. Lütfen kontrol edin.`)
          }
        }
      }
    } else if (type === 'UPDATE') {
      const oldStatus = old_record?.status
      const newStatus = record?.status

      if (oldStatus !== newStatus) {
        // Notify admin if customer cancels an appointment
        if (newStatus === 'iptal' && oldStatus !== 'iptal') {
          const { data: admins } = await supabase.from('admin_device_tokens').select('token')
          if (admins) {
            let apptTimeStr = ''
            if (record.date_time) {
              const dt = new Date(record.date_time)
              // Adjust for local time display if needed. Assuming TR time is +03:00.
              const trTime = new Date(dt.getTime())
              const hours = trTime.getHours().toString().padStart(2, '0')
              const minutes = trTime.getMinutes().toString().padStart(2, '0')
              const day = trTime.getDate().toString().padStart(2, '0')
              const month = (trTime.getMonth() + 1).toString().padStart(2, '0')
              apptTimeStr = `${day}.${month}.${dt.getFullYear()} ${hours}:${minutes} `
            }
            for (const admin of admins) {
              if (admin.token) {
                await sendFcm(admin.token, 'Randevu İptali', `Müşteriniz ${apptTimeStr}tarihindeki randevusunu iptal etti.`)
              }
            }
          }
        }

        // Fetch customer token for customer notifications
        const { data: customer } = await supabase
          .from('customers')
          .select('fcm_token')
          .eq('id', record.customer_id)
          .single()

        if (customer && customer.fcm_token) {
          let title = ''
          let body = ''

          if (newStatus === 'onaylandı') {
            title = 'Randevunuz Onaylandı!'
            body = 'Berber randevunuz onaylanmıştır. Bizi tercih ettiğiniz için teşekkürler!'
          } else if (newStatus === 'reddedildi') {
            title = 'Randevu Talebiniz Reddedildi'
            body = 'Saat uygunluğu olmadığından iptal edildi'
          } else if (newStatus === 'saat_onerildi') {
            title = 'Yeni Saat Önerisi'
            body = 'Berberiniz randevu için yeni bir saat önerdi. Lütfen kontrol edin.'
          }

          if (title) {
            await sendFcm(customer.fcm_token, title, body)
          }
        }
      }
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('Error:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
