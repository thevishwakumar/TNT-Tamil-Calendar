# Navamsha Fallback Source Research

## 1. Official API Status
**Status:** Navamsha API is configured correctly via Supabase Edge Functions. It is the primary, authoritative source of truth. The `NAVAMSHA_API_KEY` is securely injected into the edge function environments and is no longer exposed in the Flutter client or `.env.staging`.

## 2. Structured Fallback Investigation
If Navamsha API is genuinely unavailable or fails to provide specific fields, the following sources were evaluated as production-grade alternatives:

### A. Drik Panchang API / Dataset
- **Data Categories:** Panchangam, Muhurtham, Festivals, Planetary Positions.
- **API Availability:** Commercial API available.
- **Reliability:** High (Widely recognized in India).
- **Licensing:** Requires commercial license for production.

### B. ProKerala Astrology API
- **Data Categories:** Panchangam, Josiam, Rasi, Lagna, Dasha/Bhukti, Nakshatra.
- **API Availability:** Yes.
- **Reliability:** High.
- **Licensing:** Paid tiers available.

### C. Government/Observatory Data (e.g., Positional Astronomy Centre, India)
- **Data Categories:** Sunrise/Sunset, Moonrise/Moonset, Eclipses, Indian National Calendar.
- **API Availability:** No direct REST API, typically published as PDF/Ephemeris books.
- **Reliability:** Highest (Official government source).
- **Licensing:** Public domain / Government data.

### D. Swiss Ephemeris (Open Source Astronomical Data)
- **Data Categories:** High-precision planetary positions, Rasi, Lagna.
- **API Availability:** via C/Python/Dart wrappers (e.g., `sweph` libraries).
- **Reliability:** Extremely high.
- **Licensing:** GPL (Requires open-source or commercial license).

## 3. Fallback Priority Registration

For each category of data, if Navamsha is completely down, the system should strictly fallback to:
1. **Navamsha API (Primary)**
2. **Authorized Commercial API (ProKerala/DrikPanchang)**
3. **Unavailable State** - If no verified source is accessible, show "Data Unavailable".

*Note:* We have completely removed silent local mathematical fallback generators (`_computeLocalAstronomicalFallback`) to ensure no fake/simulated data is accidentally presented as Navamsha API data.
