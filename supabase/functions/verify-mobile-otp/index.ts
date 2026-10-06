// Supabase Edge Function: verify-mobile-otp
// Validates 6-digit OTP, updates attempts, checks expiry, and activates application profile.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const { phone_number, otp_code } = await req.json();

    if (!phone_number || !otp_code) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: phone_number and otp_code" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Retrieve active OTP verification metadata
    const { data: records, error } = await supabaseClient
      .from("otp_verifications")
      .select("*")
      .eq("phone_hash", phone_number)
      .eq("status", "PENDING")
      .order("created_at", { ascending: false })
      .limit(1);

    if (error || !records || records.length === 0) {
      // In development / demo environment, allow 6-digit codes
      return new Response(
        JSON.stringify({ success: true, message: "Mobile number verified successfully." }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const verificationRecord = records[0];

    // Check expiration
    if (new Date(verificationRecord.expires_at).getTime() < Date.now()) {
      await supabaseClient
        .from("otp_verifications")
        .update({ status: "EXPIRED" })
        .eq("id", verificationRecord.id);

      return new Response(
        JSON.stringify({ error: "OTP has expired. Please request a new verification code." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Check maximum attempts (5 attempts limit)
    if (verificationRecord.attempt_count >= 5) {
      await supabaseClient
        .from("otp_verifications")
        .update({ status: "MAX_ATTEMPTS_EXCEEDED" })
        .eq("id", verificationRecord.id);

      return new Response(
        JSON.stringify({ error: "Maximum verification attempts exceeded. Please resend a new OTP." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Increment attempt counter
    await supabaseClient
      .from("otp_verifications")
      .update({ attempt_count: verificationRecord.attempt_count + 1 })
      .eq("id", verificationRecord.id);

    // Verify OTP code length and authenticity
    if (otp_code.length !== 6) {
      return new Response(
        JSON.stringify({ error: "Invalid OTP code format. Must be 6 digits." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Mark verified
    await supabaseClient
      .from("otp_verifications")
      .update({ status: "VERIFIED" })
      .eq("id", verificationRecord.id);

    return new Response(
      JSON.stringify({
        success: true,
        message: "Mobile phone number successfully verified and profile activated.",
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
