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
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

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
      const data = await response.json()
      if (data.error) {
        console.error('FCM Error:', data.error)
      }
    }

    // Check for appointments that are strictly 15 minutes away
    // Using PostgreSQL interval checking. We look for appointments where the date_time is between 14 and 15 mins from now.
    // Because cron runs every 1 minute, it will catch the appointment exactly once.
    const { data: upcomingApps, error } = await supabase
      .from('appointments')
      .select('id, customer_id, barber_id, title, status, date_time')
      .eq('status', 'onaylandı')
      .gt('date_time', new Date(Date.now() + 14 * 60 * 1000).toISOString())
      .lte('date_time', new Date(Date.now() + 15 * 60 * 1000).toISOString())

    if (error) throw error

    console.log(`Found ${upcomingApps?.length || 0} appointments 15 mins away.`)

    if (upcomingApps && upcomingApps.length > 0) {
      // Get admin tokens
      const { data: admins } = await supabase.from('admin_device_tokens').select('token')
      
      for (const appt of upcomingApps) {
        // Fetch customer details
        const { data: customer } = await supabase
          .from('customers')
          .select('name, fcm_token')
          .eq('id', appt.customer_id)
          .single()

        // Send to admins
        if (admins) {
          for (const admin of admins) {
            if (admin.token) {
              await sendFcm(
                admin.token, 
                'Yaklaşan Randevu', 
                `Müşteriniz ${customer?.name || 'Bilinmiyor'} ile olan randevunuza 15 dakika kaldı!`
              )
            }
          }
        }

        // Send to customer
        if (customer && customer.fcm_token) {
          await sendFcm(
            customer.fcm_token,
            'Yaklaşan Randevu',
            `Berber randevunuza 15 dakika kaldı!`
          )
        }
      }
    }

    return new Response(JSON.stringify({ success: true, count: upcomingApps?.length || 0 }), {
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
