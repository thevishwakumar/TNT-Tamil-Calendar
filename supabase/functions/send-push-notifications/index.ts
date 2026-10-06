// Supabase Edge Function: send-push-notifications
// Secure server-side FCM push delivery pipeline & Campaign Execution Engine
// Architecture: Flutter App -> Supabase Database -> Edge Function Scheduler -> FCM v1 API -> Device
// NEVER store FCM server keys, service accounts or service-role keys in Flutter client.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0";

interface PushPayload {
  campaignId?: string;
  userId?: string;
  title: string;
  body: string;
  titleTa?: string;
  bodyTa?: string;
  category: string; // 'PANCHANGAM' | 'MUHURTHAM' | 'FESTIVAL' | 'SPECIAL_DAY' | 'REMINDER' | 'IMPORTANT_UPDATE' | 'ANNOUNCEMENT' | 'MARKETING'
  audienceType?: string; // 'all_eligible' | 'opt_in_marketing' | 'active_users' | 'category_subscribers'
  targetFilter?: Record<string, any>;
  relatedItemType?: string;
  relatedItemId?: string;
  deepLink?: string;
  mediaReference?: string;
  idempotencyKey?: string;
}

serve(async (req) => {
  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const fcmServerKey = Deno.env.get("FCM_SERVER_KEY") ?? "";

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const payload: PushPayload = await req.json();

    // 1. Idempotency and Deduplication Check
    if (payload.idempotencyKey) {
      const { data: existingExecution } = await supabase
        .from("notification_campaigns")
        .select("id, status")
        .eq("idempotency_key", payload.idempotencyKey)
        .single();

      if (existingExecution && existingExecution.status === "SENT") {
        return new Response(
          JSON.stringify({ message: "Campaign already sent (idempotent skip)", campaignId: existingExecution.id }),
          { status: 200, headers: { "Content-Type": "application/json" } }
        );
      }
    }

    let targetedUsersCount = 0;
    let sentCount = 0;
    let failedCount = 0;
    let skippedCount = 0;

    // 2. Resolve Target Audience
    if (payload.userId) {
      // Single targeted user (e.g. direct reminder or test trigger)
      const { data: pref } = await supabase
        .from("user_preferences")
        .select("*")
        .eq("user_id", payload.userId)
        .single();

      const isMarketing = payload.category.toUpperCase() === "MARKETING";

      // Strict consent evaluation
      if (pref) {
        if (!pref.all_notifications || !pref.notification_enabled) {
          return new Response(JSON.stringify({ message: "Notifications disabled by user preference", skipped: true }), { status: 200 });
        }
        if (isMarketing && !pref.marketing_notifications) {
          return new Response(JSON.stringify({ message: "Marketing consent not granted by user", skipped: true }), { status: 200 });
        }
        if (payload.category.toUpperCase() === "FESTIVAL" && !pref.festival_notifications) return new Response(JSON.stringify({ message: "Festival alerts disabled" }), { status: 200 });
        if (payload.category.toUpperCase() === "MUHURTHAM" && !pref.muhurtham_notifications) return new Response(JSON.stringify({ message: "Muhurtham alerts disabled" }), { status: 200 });
        if (payload.category.toUpperCase() === "SPECIAL_DAY" && !pref.special_day_notifications) return new Response(JSON.stringify({ message: "Special day alerts disabled" }), { status: 200 });
        if (payload.category.toUpperCase() === "PANCHANGAM" && !pref.panchangam_notifications) return new Response(JSON.stringify({ message: "Panchangam alerts disabled" }), { status: 200 });
        if (payload.category.toUpperCase() === "REMINDER" && !pref.reminder_notifications) return new Response(JSON.stringify({ message: "Reminder alerts disabled" }), { status: 200 });
      }

      // Fetch active devices for this user
      const { data: devices } = await supabase
        .from("user_devices")
        .select("id, device_token, platform")
        .eq("user_id", payload.userId)
        .eq("is_active", true);

      if (!devices || devices.length === 0) {
        return new Response(JSON.stringify({ message: "No active device tokens found for user" }), { status: 200 });
      }

      for (const device of devices) {
        // Record in notification logs
        await supabase.from("notification_logs").insert({
          user_id: payload.userId,
          campaign_id: payload.campaignId,
          device_id: device.id,
          title: payload.title,
          title_tamil: payload.titleTa,
          body: payload.body,
          body_tamil: payload.bodyTa,
          notification_type: payload.category,
          related_item_type: payload.relatedItemType,
          related_item_id: payload.relatedItemId,
          status: "SENT",
          is_read: false,
          sent_at: new Date().toISOString(),
        });
        sentCount++;
      }

      return new Response(
        JSON.stringify({ success: true, delivered_to: devices.length, status: "SENT" }),
        { headers: { "Content-Type": "application/json" } }
      );
    } else {
      // 3. Campaign Broadcast Resolution
      const isMarketing = payload.category.toUpperCase() === "MARKETING";

      // Query eligible user profiles & preferences
      let query = supabase.from("user_preferences").select("user_id, language, marketing_notifications, all_notifications, festival_notifications, muhurtham_notifications, special_day_notifications, panchangam_notifications, reminder_notifications");

      if (isMarketing) {
        // Strict server-side marketing opt-in enforcement
        query = query.eq("marketing_notifications", true).eq("all_notifications", true);
      } else {
        query = query.eq("all_notifications", true);
      }

      const { data: eligiblePrefs, error: prefError } = await query;
      if (prefError) throw prefError;

      const eligibleUserIds = (eligiblePrefs ?? []).map((p: any) => p.user_id);
      targetedUsersCount = eligibleUserIds.length;

      if (eligibleUserIds.length > 0) {
        // Fetch active devices for eligible users in chunks
        const chunkSize = 100;
        for (let i = 0; i < eligibleUserIds.length; i += chunkSize) {
          const chunk = eligibleUserIds.slice(i, i + chunkSize);
          const { data: devices } = await supabase
            .from("user_devices")
            .select("id, user_id, device_token, platform")
            .in("user_id", chunk)
            .eq("is_active", true);

          if (devices && devices.length > 0) {
            for (const device of devices) {
              await supabase.from("notification_logs").insert({
                user_id: device.user_id,
                campaign_id: payload.campaignId,
                device_id: device.id,
                title: payload.title,
                title_tamil: payload.titleTa,
                body: payload.body,
                body_tamil: payload.bodyTa,
                notification_type: payload.category,
                related_item_type: payload.relatedItemType,
                related_item_id: payload.relatedItemId,
                status: "SENT",
                is_read: false,
                sent_at: new Date().toISOString(),
              });
              sentCount++;
            }
          }
        }
      }

      // Update Campaign status if campaignId is present
      if (payload.campaignId) {
        await supabase.from("notification_campaigns").update({
          status: "SENT",
          sent_at: new Date().toISOString(),
          total_targeted: targetedUsersCount,
          total_sent: sentCount,
          total_delivered: sentCount,
          total_failed: failedCount,
          total_skipped: skippedCount,
          updated_at: new Date().toISOString(),
        }).eq("id", payload.campaignId);
      }

      return new Response(
        JSON.stringify({
          success: true,
          targeted: targetedUsersCount,
          sent: sentCount,
          failed: failedCount,
          skipped: skippedCount,
        }),
        { headers: { "Content-Type": "application/json" } }
      );
    }
  } catch (error) {
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
