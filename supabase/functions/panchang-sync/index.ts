import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.8";

const SHASTRA_BASE_URL = "https://shastrapanchangam.com/api/v1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    // 1. Authenticate Request
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing Authorization header" }), { status: 401, headers: corsHeaders });
    }

    const authClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    
    const { data: { user }, error: userError } = await authClient.auth.getUser();
    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Invalid token" }), { status: 401, headers: corsHeaders });
    }

    // Initialize Service Role client to bypass RLS and perform sync
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 2. Verify Admin Role
    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single();

    if (profile?.role !== 'ADMIN') {
      return new Response(JSON.stringify({ error: "Forbidden: Admin privileges required" }), { status: 403, headers: corsHeaders });
    }

    const payload = await req.json();
    const { action, year, cityCode, preview_only } = payload;

    if (!action) {
      return new Response(JSON.stringify({ error: "Missing 'action' parameter" }), { status: 400, headers: corsHeaders });
    }

    // =========================================================================
    // SYNC FESTIVALS (Shastra)
    // =========================================================================
    if (action === 'sync_festivals') {
      const fetchYear = year || new Date().getFullYear();
      const code = cityCode || 'chennai';

      // Fetch from Shastra
      const res = await fetch(`${SHASTRA_BASE_URL}/festivals.json`);
      if (!res.ok) throw new Error("Failed to fetch Shastra festivals");
      
      const shastraData = await res.json();
      const festivalsMap = shastraData.festivals || {};
      
      let newCount = 0;
      let updateCount = 0;

      for (const [key, value] of Object.entries(festivalsMap)) {
        const fest = value as any;
        const nameEn = fest.en || key;
        const rule = fest.rule || "";
        const dates: string[] = (fest.local_dates && fest.local_dates[code]) ? fest.local_dates[code] : (fest.dates || []);
        
        for (const date of dates) {
          if (date.startsWith(fetchYear.toString())) {
            // Check if exists
            const { data: existing } = await supabase
              .from('festivals')
              .select('id, description_english')
              .eq('date', date)
              .eq('name_english', nameEn)
              .maybeSingle();

            if (existing) {
              if (existing.description_english !== rule && rule !== "") {
                if (!preview_only) {
                  await supabase
                    .from('festivals')
                    .update({ description_english: rule, updated_at: new Date().toISOString() })
                    .eq('id', existing.id);
                }
                updateCount++;
              }
            } else {
              if (!preview_only) {
                await supabase
                  .from('festivals')
                  .insert({
                    date,
                    name_tamil: nameEn,
                    name_english: nameEn,
                    description_english: rule,
                    is_published: true
                  });
              }
              newCount++;
            }
          }
        }
      }

      // Log sync action if not preview
      if (!preview_only) {
        try {
          await supabase.rpc('log_admin_audit', {
            p_action: 'SYNC',
            p_module: 'FESTIVALS',
            p_record_id: 'shastra-api',
            p_new_state: { source: 'shastra', year: fetchYear, city: code, inserted: newCount, updated: updateCount }
          });
        } catch (e) {
           console.warn("Audit log skipped", e);
        }
      }

      return new Response(JSON.stringify({ 
        success: true, 
        newRecords: newCount, 
        updatedRecords: updateCount,
        fetched: Object.keys(festivalsMap).length,
        is_preview: !!preview_only
      }), { status: 200, headers: corsHeaders });
    }

    return new Response(JSON.stringify({ error: "Unknown action" }), { status: 400, headers: corsHeaders });

  } catch (error) {
    console.error("Sync Error:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message || "Internal Server Error" }),
      { status: 500, headers: corsHeaders }
    );
  }
});
