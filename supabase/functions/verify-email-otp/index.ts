// Supabase Edge Function: verify-email-otp
// Validates 6-digit numeric OTP against SHA-256 hash in email_verification_challenges table,
// tracks 5-attempt rate limit, checks 5-minute expiry, and updates profile verification status.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Helper: SHA-256 hash in hexadecimal string
async function sha256Hex(message: string): Promise<string> {
  const msgBuffer = new TextEncoder().encode(message);
  const hashBuffer = await crypto.subtle.digest("SHA-256", msgBuffer);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const body = await req.json();
    const email = body.email?.trim().toLowerCase();
    const otpCode = body.otp_code?.trim();

    if (!email || !otpCode) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: email and otp_code" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (otpCode.length !== 6 || !/^\d{6}$/.test(otpCode)) {
      return new Response(
        JSON.stringify({ error: "Invalid format. OTP must be a 6-digit numeric code." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Retrieve active challenge
    const { data: challenges, error: fetchError } = await supabaseClient
      .from("email_verification_challenges")
      .select("*")
      .eq("email", email)
      .eq("status", "PENDING")
      .order("created_at", { ascending: false })
      .limit(1);

    if (fetchError || !challenges || challenges.length === 0) {
      return new Response(
        JSON.stringify({ error: "No active verification code found. Please request a new OTP." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const challenge = challenges[0];

    // Check expiration (5 minutes)
    if (new Date(challenge.expires_at).getTime() < Date.now()) {
      await supabaseClient
        .from("email_verification_challenges")
        .update({ status: "EXPIRED", updated_at: new Date().toISOString() })
        .eq("id", challenge.id);

      return new Response(
        JSON.stringify({ error: "Verification code has expired. Please request a new OTP." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Check max attempts (5)
    if (challenge.attempt_count >= challenge.max_attempts) {
      await supabaseClient
        .from("email_verification_challenges")
        .update({ status: "MAX_ATTEMPTS_EXCEEDED", updated_at: new Date().toISOString() })
        .eq("id", challenge.id);

      return new Response(
        JSON.stringify({ error: "Maximum verification attempts exceeded. Please request a new OTP." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Increment attempt count
    const nextAttempts = challenge.attempt_count + 1;
    await supabaseClient
      .from("email_verification_challenges")
      .update({ attempt_count: nextAttempts, updated_at: new Date().toISOString() })
      .eq("id", challenge.id);

    // Compute hash of provided OTP
    const candidateHash = await sha256Hex(otpCode);

    if (candidateHash !== challenge.otp_hash) {
      const remaining = Math.max(0, challenge.max_attempts - nextAttempts);
      if (remaining === 0) {
        await supabaseClient
          .from("email_verification_challenges")
          .update({ status: "MAX_ATTEMPTS_EXCEEDED", updated_at: new Date().toISOString() })
          .eq("id", challenge.id);
      }

      return new Response(
        JSON.stringify({
          error: `Incorrect verification code. ${remaining} attempt(s) remaining.`,
          attempts_remaining: remaining,
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Mark challenge as VERIFIED
    await supabaseClient
      .from("email_verification_challenges")
      .update({ status: "VERIFIED", updated_at: new Date().toISOString() })
      .eq("id", challenge.id);

    // Update profile
    const nowIso = new Date().toISOString();
    await supabaseClient
      .from("profiles")
      .update({
        email_verified_at: nowIso,
        account_status: "PENDING_MOBILE_VERIFICATION",
        updated_at: nowIso,
      })
      .eq("email", email);

    return new Response(
      JSON.stringify({
        success: true,
        message: "Email address verified successfully.",
        verified_at: nowIso,
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
