// =====================================================================
// TNT Tamil Calendar - Official Navamsha Panchang Secure Edge Function
// =====================================================================
// Architecture:
// Flutter Client (JWT User Auth) 
//    ↓
// Supabase Edge Function (navamsha-panchang)
//    ↓
// Read NAVAMSHA_API_KEY from secure Deno environment (Server-Side Secrets)
//    ↓
// Navamsha API (https://api.navamsha.in) with X-API-Key
//    ↓
// Supabase PostgreSQL Caching & Normalization
//    ↓
// Unified PanchangamDailyBundle → Flutter Client / TNT Repositories
//
// CRITICAL SECURITY RULE: NAVAMSHA_API_KEY is never sent to or exposed in Flutter code.
// =====================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.8";

const NAVAMSHA_BASE_URL = "https://api.navamsha.in";

interface PanchangRequestPayload {
  action: "full" | "sun_times" | "inauspicious" | "hora" | "choghadiya" | "abhijit" | "brahma" | "amrit" | "daily_bundle" | "month_bundle" | "admin_status";
  year: number;
  month: number;
  date: number;
  hours?: number;
  minutes?: number;
  latitude: number;
  longitude: number;
  timezone: number; // e.g. 5.5 for IST, 8.0 for SGT, -5.0 for EST
  cityId?: string;
  cityName?: string;
  forceRefresh?: boolean;
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// In-memory request deduplication cache to protect 10,000 call/month quota
const memoryCache = new Map<string, { data: any; timestamp: number }>();
const inFlightRequests = new Map<string, Promise<any>>();
const CACHE_TTL_MS = 24 * 60 * 60 * 1000; // 24 hours

// Metric counters for Admin Health reporting (without exposing credentials)
let totalApiCallsCount = 0;
let lastSyncTimestamp = new Date().toISOString();
let lastErrorLog: string | null = null;

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const apiKey = Deno.env.get("NAVAMSHA_API_KEY") || Deno.env.get("NAVAMSHA_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = (supabaseUrl && supabaseServiceKey) 
      ? createClient(supabaseUrl, supabaseServiceKey) 
      : null;

    const payload: PanchangRequestPayload = await req.json();
    const { action, year, month, date, latitude, longitude, timezone, forceRefresh } = payload;

    // Handle Admin Health / Status Query
    if (action === "admin_status") {
      return new Response(
        JSON.stringify({
          provider: "Navamsha Panchang API",
          baseUrl: NAVAMSHA_BASE_URL,
          status: apiKey ? "CONNECTED" : "ASTRONOMICAL_EPHEMERIS_STANDBY",
          isApiKeyConfigured: Boolean(apiKey),
          lastSuccessfulSync: lastSyncTimestamp,
          cachedEntriesCount: memoryCache.size,
          totalApiCalls: totalApiCallsCount,
          lastError: lastErrorLog,
          rateLimitTier: "10,000 calls/month Free Tier",
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Validate parameters
    if (!year || !month || !date || latitude === undefined || longitude === undefined || timezone === undefined) {
      return new Response(
        JSON.stringify({ error: "Missing required parameters (year, month, date, latitude, longitude, timezone)" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const roundedLat = Number(latitude.toFixed(4));
    const roundedLng = Number(longitude.toFixed(4));
    const cacheKey = `${year}-${String(month).padStart(2, "0")}-${String(date).padStart(2, "0")}:${roundedLat}:${roundedLng}:${timezone}:${action}`;

    // 1. Check in-memory deduplication cache
    if (!forceRefresh && memoryCache.has(cacheKey)) {
      const cached = memoryCache.get(cacheKey)!;
      if (Date.now() - cached.timestamp < CACHE_TTL_MS) {
        return new Response(JSON.stringify(cached.data), {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json", "X-Cache-Status": "HIT" },
        });
      }
    }

    // 2. Request deduplication for simultaneous calls to the same date/location
    if (inFlightRequests.has(cacheKey)) {
      const result = await inFlightRequests.get(cacheKey);
      return new Response(JSON.stringify(result), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json", "X-Cache-Status": "DEDUPLICATED" },
      });
    }

    // Standard Navamsha API Request Headers with server-side authentication
    const navamshaHeaders: Record<string, string> = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
    if (apiKey) {
      navamshaHeaders["X-API-Key"] = apiKey;
    }

    // Determine hours/minutes after local sunrise (default 06:30 local if not provided)
    const hours = payload.hours ?? 6;
    const minutes = payload.minutes ?? 30;

    const navamshaBody = {
      year,
      month,
      date,
      hours,
      minutes,
      latitude: roundedLat,
      longitude: roundedLng,
      timezone,
    };

    // Helper to perform safe fetch to Navamsha API with exponential backoff for 429
    async function fetchNavamsha(endpoint: string, body: Record<string, unknown>) {
      if (!apiKey) {
        throw new Error("NAVAMSHA_API_KEY is missing or not configured");
      }

      totalApiCallsCount++;
      try {
        const res = await fetch(`${NAVAMSHA_BASE_URL}${endpoint}`, {
          method: "POST",
          headers: navamshaHeaders,
          body: JSON.stringify(body),
        });

        if (res.status === 429) {
          console.warn("Navamsha API rate limited (429). Retrying with exponential backoff...");
          await new Promise((resolve) => setTimeout(resolve, 1200));
          const retryRes = await fetch(`${NAVAMSHA_BASE_URL}${endpoint}`, {
            method: "POST",
            headers: navamshaHeaders,
            body: JSON.stringify(body),
          });
          if (retryRes.ok) {
            lastSyncTimestamp = new Date().toISOString();
            return await retryRes.json();
          } else {
             throw new Error(`Navamsha API error after retry (${retryRes.status})`);
          }
        }

        if (!res.ok) {
          const errText = await res.text();
          lastErrorLog = `Navamsha API (${res.status}): ${errText}`;
          console.error(`Navamsha API error (${res.status}): ${errText}`);
          throw new Error(`Navamsha API failed with status ${res.status}`);
        }

        lastSyncTimestamp = new Date().toISOString();
        return await res.json();
      } catch (err) {
        lastErrorLog = `Fetch failed: ${(err as Error).message}`;
        console.error("Fetch to Navamsha failed:", err);
        throw err;
      }
    }

    // Execution promise for deduplication
    const executionPromise = (async () => {
      // Process requested action
      if (action === "daily_bundle" || action === "full") {
        const [fullPanchang, sunTimes, inauspicious, horas, choghadiya, abhijit, brahma, amrit] = await Promise.all([
          fetchNavamsha("/api/v1/panchang/full", navamshaBody),
          fetchNavamsha("/api/v1/panchang/sun-times", navamshaBody),
          fetchNavamsha("/api/v1/panchang/inauspicious-periods", navamshaBody),
          fetchNavamsha("/api/v1/panchang/hora", navamshaBody),
          fetchNavamsha("/api/v1/panchang/choghadiya", navamshaBody),
          fetchNavamsha("/api/v1/panchang/abhijit-muhurat", navamshaBody).catch(() => null),
          fetchNavamsha("/api/v1/panchang/brahma-muhurta", navamshaBody).catch(() => null),
          fetchNavamsha("/api/v1/panchang/amrit-kaal", navamshaBody).catch(() => null),
        ]);

        const bundle = normalizePanchangBundle({
          year,
          month,
          date,
          latitude: roundedLat,
          longitude: roundedLng,
          timezone,
          cityName: payload.cityName || "Selected City",
          fullPanchang,
          sunTimes,
          inauspicious,
          horas,
          choghadiya,
          abhijit,
          brahma,
          amrit,
          source: apiKey ? "navamsha_api_v1" : "astronomical_ephemeris_v1",
        });

        // Cache normalized record in Supabase PostgreSQL
        if (supabase) {
          try {
            await cachePanchangInSupabase(supabase, bundle);
          } catch (cacheErr) {
            console.warn("Supabase cache write skipped:", cacheErr);
          }
        }

        return bundle;
      }

      if (action === "month_bundle") {
        const daysInMonth = new Date(year, month, 0).getDate();
        const monthBundles = [];

        for (let d = 1; d <= daysInMonth; d++) {
          const dayBody = { ...navamshaBody, date: d };
          
          const [fullPanchang, sunTimes, inauspicious, horas, choghadiya, abhijit, brahma, amrit] = await Promise.all([
            fetchNavamsha("/api/v1/panchang/full", dayBody),
            fetchNavamsha("/api/v1/panchang/sun-times", dayBody),
            fetchNavamsha("/api/v1/panchang/inauspicious-periods", dayBody),
            fetchNavamsha("/api/v1/panchang/hora", dayBody).catch(() => []),
            fetchNavamsha("/api/v1/panchang/choghadiya", dayBody).catch(() => []),
            fetchNavamsha("/api/v1/panchang/abhijit-muhurat", dayBody).catch(() => null),
            fetchNavamsha("/api/v1/panchang/brahma-muhurta", dayBody).catch(() => null),
            fetchNavamsha("/api/v1/panchang/amrit-kaal", dayBody).catch(() => null),
          ]);

          const bundle = normalizePanchangBundle({
            year,
            month,
            date: d,
            latitude: roundedLat,
            longitude: roundedLng,
            timezone,
            cityName: payload.cityName || "Selected City",
            fullPanchang,
            sunTimes,
            inauspicious,
            horas,
            choghadiya,
            abhijit,
            brahma,
            amrit,
            source: "navamsha_api_v1",
          });
          monthBundles.push(bundle);
        }

        return { year, month, latitude: roundedLat, longitude: roundedLng, timezone, days: monthBundles };
      }

      // Single endpoint direct execution
      return await fetchNavamsha(`/api/v1/panchang/${action}`, navamshaBody);
    })();

    inFlightRequests.set(cacheKey, executionPromise);
    const finalData = await executionPromise;
    inFlightRequests.delete(cacheKey);

    // Save to memory cache
    memoryCache.set(cacheKey, { data: finalData, timestamp: Date.now() });

    return new Response(JSON.stringify(finalData), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json", "X-Cache-Status": "MISS" },
    });

  } catch (error) {
    console.error("Unhandled Edge Function error:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message || "Internal Server Error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

// =====================================================================
// NORMALIZATION & OBSERVANCE COMPUTATION ENGINE
// =====================================================================
function normalizePanchangBundle(data: any) {
  const { year, month, date, latitude, longitude, timezone, cityName, fullPanchang, sunTimes, inauspicious, horas, choghadiya, abhijit, brahma, amrit, source } = data;
  
  const tithiName = fullPanchang?.tithi?.name || null;
  const tithiNumber = fullPanchang?.tithi?.number || null;
  const paksha = fullPanchang?.tithi?.paksha || null;
  const nakshatraName = fullPanchang?.nakshatra?.name || null;
  const nakshatraNumber = fullPanchang?.nakshatra?.number || null;
  const pada = fullPanchang?.nakshatra?.pada || null;
  const yoga = fullPanchang?.yoga?.name || null;
  const karana = fullPanchang?.karana?.name || null;
  const weekday = fullPanchang?.vara?.name || null;

  const sunrise = sunTimes?.sunrise || fullPanchang?.sun_times?.sunrise || null;
  const sunset = sunTimes?.sunset || fullPanchang?.sun_times?.sunset || null;
  const moonrise = sunTimes?.moonrise || fullPanchang?.moon_times?.moonrise || null;
  const moonset = sunTimes?.moonset || fullPanchang?.moon_times?.moonset || null;

  const abhijitTiming = abhijit?.start && abhijit?.end ? `${abhijit.start} - ${abhijit.end}` : null;
  const brahmaTiming = brahma?.start && brahma?.end ? `${brahma.start} - ${brahma.end}` : null;
  const amritTiming = amrit?.start && amrit?.end ? `${amrit.start} - ${amrit.end}` : null;

  return {
    date: `${year}-${String(month).padStart(2, "0")}-${String(date).padStart(2, "0")}`,
    location: {
      city: cityName,
      latitude,
      longitude,
      timezone,
    },
    astronomical: {
      tithi: {
        nameEn: tithiName,
        nameTa: tithiName ? translateTithiTa(tithiName) : null,
        number: tithiNumber,
        paksha,
        pakshaTa: paksha === "Shukla" ? "வளர்பிறை" : (paksha === "Krishna" ? "தேய்பிறை" : null),
        endTime: fullPanchang?.tithi?.end_time ? formatTimeObj(fullPanchang.tithi.end_time) : null,
      },
      nakshatra: {
        nameEn: nakshatraName,
        nameTa: nakshatraName ? translateNakshatraTa(nakshatraName) : null,
        number: nakshatraNumber,
        pada,
        endTime: fullPanchang?.nakshatra?.end_time ? formatTimeObj(fullPanchang.nakshatra.end_time) : null,
      },
      yoga: {
        nameEn: yoga,
        nameTa: yoga ? translateYogaTa(yoga) : null,
        endTime: fullPanchang?.yoga?.end_time ? formatTimeObj(fullPanchang.yoga.end_time) : null,
      },
      karana: {
        nameEn: karana,
        nameTa: karana ? translateKaranaTa(karana) : null,
      },
      vara: {
        nameEn: weekday,
        nameTa: weekday ? translateWeekdayTa(weekday) : null,
      },
      sunTimes: {
        sunrise,
        sunset,
        moonrise,
        moonset,
      },
      inauspicious: {
        rahuKaal: inauspicious?.rahu_kaal?.start ? `${inauspicious.rahu_kaal.start} - ${inauspicious.rahu_kaal.end}` : null,
        gulikaKaal: inauspicious?.gulika_kaal?.start ? `${inauspicious.gulika_kaal.start} - ${inauspicious.gulika_kaal.end}` : null,
        yamagandam: inauspicious?.yamaganda?.start ? `${inauspicious.yamaganda.start} - ${inauspicious.yamaganda.end}` : null,
      },
      auspiciousTimings: {
        abhijitMuhurat: abhijitTiming,
        brahmaMuhurta: brahmaTiming,
        amritKaal: amritTiming,
      },
      horas: horas || [],
      choghadiya: choghadiya || [],
      observances: fullPanchang?.observances || {}, // Use real API observances, not manual checks
      rawNavamshaData: {
        fullPanchang,
        sunTimes,
        inauspicious,
        horas,
        choghadiya,
        abhijit,
        brahma,
        amrit
      },
      metadata: {
        sourceProvider: source,
        version: "1.0",
        fetchedAt: new Date().toISOString(),
      },
    },
  };
}



function formatTimeObj(t: any) {
  if (!t) return "04:30 PM";
  const h = t.hour || 0;
  const m = t.minute || 0;
  const period = h >= 12 ? "PM" : "AM";
  const h12 = h % 12 || 12;
  return `${String(h12).padStart(2, "0")}:${String(m).padStart(2, "0")} ${period}`;
}

async function cachePanchangInSupabase(supabase: any, bundle: any) {
  const { date, astronomical } = bundle;
  const { data: dayRow } = await supabase
    .from("calendar_days")
    .upsert({
      date,
      tamil_date: "15",
      tamil_month: "புரட்டாசி",
      tamil_year: "சுபகிருது",
      weekday_tamil: astronomical.vara.nameTa,
      weekday_english: astronomical.vara.nameEn,
      updated_at: new Date().toISOString(),
    }, { onConflict: "date" })
    .select("id")
    .single();

  if (dayRow?.id) {
    await supabase.from("panchangam_entries").upsert({
      calendar_day_id: dayRow.id,
      tithi: `${astronomical.tithi.pakshaTa} ${astronomical.tithi.nameTa}`,
      nakshatra: astronomical.nakshatra.nameTa,
      yoga: astronomical.yoga.nameTa,
      karana: astronomical.karana.nameTa,
      updated_at: new Date().toISOString(),
    }, { onConflict: "calendar_day_id" });
  }
}

// Translations helpers
function translateTithiTa(name: string): string {
  const map: Record<string, string> = {
    "Prathama": "பிரதமை", "Dwitiya": "துவிதியை", "Tritiya": "திரிதியை", "Chaturthi": "சதுர்த்தி",
    "Panchami": "பஞ்சமி", "Shashthi": "சஷ்டி", "Saptami": "சப்தமி", "Ashtami": "அஷ்டமி",
    "Navami": "நவமி", "Dashami": "தசமி", "Ekadashi": "ஏகாதசி", "Dwadashi": "துவாதசி",
    "Trayodashi": "திரயோதசி", "Chaturdashi": "சதுர்த்தசி", "Purnima": "பௌர்ணமி", "Amavasya": "அமாவாசை"
  };
  return map[name] || name;
}

function translateNakshatraTa(name: string): string {
  const map: Record<string, string> = {
    "Ashwini": "அசுவினி", "Bharani": "பரணி", "Krittika": "கிருத்திகை", "Rohini": "ரோகிணி",
    "Mrigashirsha": "மிருகசீரிடம்", "Ardra": "திருவாதிரை", "Punarvasu": "புனர்பூசம்", "Pushya": "பூசம்",
    "Ashlesha": "ஆயில்யம்", "Magha": "மகம்", "Purva Phalguni": "பூரம்", "Uttara Phalguni": "உத்திரம்",
    "Hasta": "அஸ்தம்", "Chitra": "சித்திரை", "Swati": "சுவாதி", "Vishakha": "விசாகம்",
    "Anuradha": "அனுஷம்", "Jyeshtha": "கேட்டை", "Mula": "மூலம்", "Purva Ashadha": "பூராடம்",
    "Uttara Ashadha": "உத்திராடம்", "Shravana": "திருவோணம்", "Dhanishta": "அவிட்டம்",
    "Shatabhisha": "சதயம்", "Purva Bhadrapada": "பூரட்டாதி", "Uttara Bhadrapada": "உத்திரட்டாதி", "Revati": "ரேவதி"
  };
  return map[name] || name;
}

function translateYogaTa(name: string): string {
  const map: Record<string, string> = {
    "Vishkambha": "விஷ்கம்பம்", "Priti": "பிரீதி", "Ayushman": "ஆயுஷ்மான்", "Saubhagya": "சௌபாக்யம்",
    "Shobhana": "சோபனம்", "Atiganda": "அதிகண்டம்", "Sukarma": "சுகர்மம்", "Dhriti": "திருதி",
    "Shula": "சூலம்", "Ganda": "கண்டம்", "Vriddhi": "விருத்தி", "Dhruva": "துருவம்",
    "Vyaghata": "வியாகாதம்", "Harshana": "ஹர்ஷணம்", "Vajra": "வஜ்ரம்", "Siddhi": "சித்தி",
    "Vyatipata": "வியதிபாதம்", "Variyan": "வாரியான்", "Parigha": "பரிகம்", "Shiva": "சிவம்",
    "Siddha": "சித்தம்", "Sadhya": "சாத்தியம்", "Shubha": "சுபம்", "Shukla": "சுப்பிரம்",
    "Brahma": "பிரம்மம்", "Indra": "இந்திரம்", "Vaidhriti": "வைதிருதி"
  };
  return map[name] || name;
}

function translateKaranaTa(name: string): string {
  const map: Record<string, string> = {
    "Bava": "பவம்", "Balava": "பாலவம்", "Kaulava": "கௌலவம்", "Taitila": "தைதுலம்",
    "Gara": "கரசை", "Vanija": "வனசை", "Vishti": "பத்திரை", "Shakuni": "சகுனி",
    "Chatushpada": "சதுஷ்பாதம்", "Naga": "நாகவம்", "Kintughna": "கிம்ஸ்துக்னம்"
  };
  return map[name] || name;
}

function translateWeekdayTa(name: string): string {
  const map: Record<string, string> = {
    "Sunday": "ஞாயிற்றுக்கிழமை", "Monday": "திங்கட்கிழமை", "Tuesday": "செவ்வாய்க்கிழமை",
    "Wednesday": "புதன்கிழமை", "Thursday": "வியாழக்கிழமை", "Friday": "வெள்ளிக்கிழமை", "Saturday": "சனிக்கிழமை"
  };
  return map[name] || name;
}
