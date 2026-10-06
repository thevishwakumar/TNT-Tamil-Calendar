# NAVAMSHA COMPLETE DATA MAPPING REPORT

## API Connectivity Status
**Status:** 401 Unauthorized / Not Verified
**Reason:** The provided API Key (`vda_live_...`) in `.env.staging` returns a 401 Unauthorized response from `api.navamsha.in`. 
**Impact:** We cannot fetch the live raw JSON to discover additional supported fields. Therefore, any fields not currently referenced in the existing source code (`navamsha_models.dart` and `index.ts`) are marked as UNKNOWN.

## Endpoint Discovery (Based on Edge Function Source)

### 1. Full Panchang
- **Endpoint:** `/api/v1/panchang/full`
- **Method:** POST
- **Request Parameters:** `year`, `month`, `date`, `hours`, `minutes`, `latitude`, `longitude`, `timezone`
- **Known Response Structure:**
  - `tithi` (Object) -> `name`, `number`, `paksha`, `end_time`
  - `nakshatra` (Object) -> `name`, `number`, `pada`, `end_time`
  - `yoga` (Object) -> `name`, `end_time`
  - `karana` (Object) -> `name`
  - `vara` (Object) -> `name`
  - `sun_times` (Object) -> `sunrise`, `sunset`
  - `moon_times` (Object) -> `moonrise`, `moonset`
- **Unknown Fields:** Any other metadata, astrology fields, planetary positions, doshas, etc. (UNKNOWN)

### 2. Sun Times
- **Endpoint:** `/api/v1/panchang/sun-times`
- **Known Response Structure:** `sunrise`, `sunset`, `moonrise`, `moonset`
- **Unknown Fields:** UNKNOWN

### 3. Inauspicious Periods
- **Endpoint:** `/api/v1/panchang/inauspicious-periods`
- **Known Response Structure:** 
  - `rahu_kaal` (Object) -> `start`, `end`
  - `gulika_kaal` (Object) -> `start`, `end`
  - `yamaganda` (Object) -> `start`, `end`
- **Unknown Fields:** durmuhurtham, varjyam, etc. (UNKNOWN)

### 4. Hora
- **Endpoint:** `/api/v1/panchang/hora`
- **Known Response Structure:** Array of objects (specific fields UNKNOWN)

### 5. Choghadiya
- **Endpoint:** `/api/v1/panchang/choghadiya`
- **Known Response Structure:** Array of objects (specific fields UNKNOWN)

### 6. Auspicious Timings (Abhijit, Brahma, Amrit)
- **Endpoints:** 
  - `/api/v1/panchang/abhijit-muhurat`
  - `/api/v1/panchang/brahma-muhurta`
  - `/api/v1/panchang/amrit-kaal`
- **Known Response Structure:** `start`, `end`
- **Unknown Fields:** UNKNOWN

## Field-by-Field Mapping Strategy

Since the API is currently unreachable to get the full schema, the mapping strictly maps what is known from the integration code, preserving the raw nested objects rather than cherry-picking them.

| Navamsha Response (Known) | TNT Model Field (Target) | UI Destination | Source | Transformation / Note |
|---------------------------|--------------------------|----------------|--------|-----------------------|
| `fullPanchang.tithi`      | `NavamshaPanchangBundle.tithi` | Panchangam | Navamsha | Preserved completely |
| `fullPanchang.nakshatra`  | `NavamshaPanchangBundle.nakshatra` | Panchangam | Navamsha | Preserved completely |
| `fullPanchang.yoga`       | `NavamshaPanchangBundle.yoga` | Panchangam | Navamsha | Preserved completely |
| `fullPanchang.karana`     | `NavamshaPanchangBundle.karana` | Panchangam | Navamsha | Preserved completely |
| `sunTimes` / `fullPanchang.sun_times` | `NavamshaPanchangBundle.sunTimes` | Panchangam | Navamsha | Preserved completely |
| `inauspicious.rahu_kaal`  | `NavamshaPanchangBundle.inauspicious.rahuKaal` | Panchangam | Navamsha | Preserved completely |
| `abhijit`, `brahma`, `amrit` | `NavamshaPanchangBundle.auspicious` | Panchangam | Navamsha | Preserved completely |
| `horas` (Array)           | `NavamshaPanchangBundle.horas` | Panchangam | Navamsha | Currently dropped in dart model; must be added. |
| `choghadiya` (Array)      | `NavamshaPanchangBundle.choghadiya` | Panchangam | Navamsha | Currently dropped in dart model; must be added. |

**Important Note:** The Edge function currently computes fallback astronomical data (`computeAstronomicalPanchang`) and manual observances (`isPournami`, etc.). This violates the strict Navamsha fidelity requirement. They will be removed so Navamsha remains the single source of truth, as explicitly requested.
