# Navamsha Data Fidelity & Mapping Report (Final)

## 1. Navamsha Data Priority 
The Navamsha API (via edge functions) is configured as the undisputed primary source for astrological and chronological calculations.

## 2. Supported Data Fields Preservation
The following mapping verifies that all Navamsha data points are passed fully unadulterated into the UI:

### Panchangam Attributes
- **Tamil Date/Month/Year**: Mapped directly from Navamsha `observances`.
- **Weekday (Vara)**: Mapped and properly translated using `translateWeekdayTa`.
- **Tithi**: Mapped including paksha (Shukla/Krishna -> வளர்பிறை/தேய்பிறை), name, and end time.
- **Nakshatra**: Mapped including name, pada, and end time.
- **Yoga**: Mapped accurately.
- **Karana**: Mapped accurately.

### Sun and Moon Times
- **Sunrise/Sunset**: Inherited straight from the `sun_times` Navamsha endpoint without any local offsetting (except standard timezone formatting).
- **Moonrise/Moonset**: Fully supported via the `moon_times` attribute.

### Inauspicious & Auspicious Periods
- **Rahu Kaal / Yamagandam / Kuligai**: Start and end times preserved exactly as computed by Navamsha.
- **Abhijit / Brahma Muhurta / Amrit Kaal**: Validated and served as high-priority auspicious windows.
- **Horas & Choghadiya**: Direct array passing into `horas` and `choghadiya` nodes.

## 3. Conflict Avoidance & Source Validation
- **No Local Mathematical Interventions**: The `_computeLocalAstronomicalFallback` local computation method has been permanently stripped out of `navamsha_panchang_service.dart`.
- **Strict Error Boundary**: If the Navamsha API fails to fetch, the app will no longer attempt to mask the error with locally inferred math, protecting against incorrect predictions for subha muhurtham or planetary alignments.
- **Source Labeling**: Data objects injected into the Flutter client contain `metadata: { sourceProvider: "navamsha_api_v1" }` to guarantee traceability.
