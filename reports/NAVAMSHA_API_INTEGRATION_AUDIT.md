# NAVAMSHA API INTEGRATION AUDIT

## 1. Existing Configuration
- **Base URL:** `https://api.navamsha.in`
- **Environment Source:** `environment/.env` / `.env.staging` (Key: `NAVAMSHA_API_KEY`)
- **Proxy Architecture:** Secured behind a Supabase Edge Function (`supabase/functions/navamsha-panchang/index.ts`). The Flutter app calls the Edge Function; the Edge Function injects the `X-API-Key` to safely call Navamsha.
- **Authentication Mechanism:** `X-API-Key` sent in HTTP Headers.

## 2. Request Details
- **HTTP Method:** `POST`
- **Existing Headers:** 
  ```json
  {
    "Content-Type": "application/json",
    "Accept": "application/json",
    "X-API-Key": "<SERVER_SIDE_SECRET>"
  }
  ```
- **Request Parameters:**
  ```json
  {
    "year": 2026,
    "month": 10,
    "date": 4,
    "hours": 6,
    "minutes": 30,
    "latitude": 11.0168,
    "longitude": 76.9558,
    "timezone": 5.5
  }
  ```

## 3. Endpoints Discovered
The following endpoints are currently configured in `navamsha-panchang` Edge Function:
1. `/api/v1/panchang/full` (Tithi, Nakshatra, Yoga, Karana, Vara)
2. `/api/v1/panchang/sun-times` (Sunrise, Sunset, Moonrise, Moonset)
3. `/api/v1/panchang/inauspicious-periods` (Rahu Kaal, Gulika Kaal, Yamaganda)
4. `/api/v1/panchang/hora`
5. `/api/v1/panchang/choghadiya`
6. `/api/v1/panchang/abhijit-muhurat`
7. `/api/v1/panchang/brahma-muhurta`
8. `/api/v1/panchang/amrit-kaal`

## 4. Response Format
The Edge Function aggregates the Navamsha responses into a normalized `PanchangamDailyBundle`.

## 5. Current Data Sources vs Navamsha
- **Panchangam Core Data:** Fetched from Navamsha (via Edge Function) and cached in Supabase (`calendar_days`, `panchangam_entries`).
- **Festivals / Special Days:** Missing from Edge Function. Endpoint UNKNOWN.
- **Muhurtham:** Partially fetched (`abhijit-muhurat`, `brahma-muhurta`, `amrit-kaal` endpoints are called), but the Admin Dashboard appears to use hardcoded/local data.

## 6. Write Operations Support (CREATE/UPDATE/DELETE)
- **UNKNOWN:** The current Edge Function only makes read (`POST`) requests to retrieve ephemeris data. Navamsha is typically an ephemeris calculation API, making it inherently READ-ONLY for astronomical data. Admin override logic will be necessary.

## 7. Risks & Missing Elements
- **Missing Endpoints:** The project lacks known endpoints for explicit 'Festivals' and 'Special Days' in the Navamsha API. The API might not provide curated festival calendars, or we might need to deduce festivals astronomically.
- **Admin Overrides:** Since Navamsha is an external third-party API, any corrections to festival dates/muhurtham timings must be stored locally in Supabase and merged with the API response.
