ALTER TABLE public.muhurtham_dates
  ADD COLUMN IF NOT EXISTS tamil_date_str TEXT,
  ADD COLUMN IF NOT EXISTS tamil_month TEXT,
  ADD COLUMN IF NOT EXISTS tamil_year TEXT,
  ADD COLUMN IF NOT EXISTS day_of_week_en TEXT,
  ADD COLUMN IF NOT EXISTS day_of_week_ta TEXT,
  ADD COLUMN IF NOT EXISTS start_time TEXT,
  ADD COLUMN IF NOT EXISTS end_time TEXT,
  ADD COLUMN IF NOT EXISTS duration TEXT,
  ADD COLUMN IF NOT EXISTS is_valarthirai BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS category TEXT,
  ADD COLUMN IF NOT EXISTS category_ta TEXT,
  ADD COLUMN IF NOT EXISTS nakshatra TEXT,
  ADD COLUMN IF NOT EXISTS nakshatra_ta TEXT,
  ADD COLUMN IF NOT EXISTS nakshatra_time TEXT,
  ADD COLUMN IF NOT EXISTS tithi TEXT,
  ADD COLUMN IF NOT EXISTS tithi_ta TEXT,
  ADD COLUMN IF NOT EXISTS yoga TEXT,
  ADD COLUMN IF NOT EXISTS yoga_ta TEXT,
  ADD COLUMN IF NOT EXISTS karana TEXT,
  ADD COLUMN IF NOT EXISTS karana_ta TEXT,
  ADD COLUMN IF NOT EXISTS lagnam TEXT,
  ADD COLUMN IF NOT EXISTS lagnam_ta TEXT,
  ADD COLUMN IF NOT EXISTS subha_horai TEXT,
  ADD COLUMN IF NOT EXISTS subha_horai_ta TEXT,
  ADD COLUMN IF NOT EXISTS rahu_kalam TEXT,
  ADD COLUMN IF NOT EXISTS yamagandam TEXT,
  ADD COLUMN IF NOT EXISTS kuligai TEXT,
  ADD COLUMN IF NOT EXISTS approved_status TEXT,
  ADD COLUMN IF NOT EXISTS notes TEXT,
  ADD COLUMN IF NOT EXISTS notes_ta TEXT;

CREATE INDEX IF NOT EXISTS idx_muhurtham_category ON public.muhurtham_dates(category);

ALTER TABLE public.muhurtham_timings
  ADD COLUMN IF NOT EXISTS duration TEXT,
  ADD COLUMN IF NOT EXISTS lagnam TEXT,
  ADD COLUMN IF NOT EXISTS lagnam_ta TEXT,
  ADD COLUMN IF NOT EXISTS nakshatra TEXT,
  ADD COLUMN IF NOT EXISTS nakshatra_ta TEXT,
  ADD COLUMN IF NOT EXISTS subha_horai TEXT,
  ADD COLUMN IF NOT EXISTS subha_horai_ta TEXT,
  ADD COLUMN IF NOT EXISTS description TEXT,
  ADD COLUMN IF NOT EXISTS description_ta TEXT,
  ADD COLUMN IF NOT EXISTS is_prime BOOLEAN DEFAULT true;

-- Ensure countries exist for location picker
CREATE TABLE IF NOT EXISTS public.countries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    name_ta TEXT NOT NULL,
    iso_code TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS public.states (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    country_id UUID NOT NULL REFERENCES public.countries(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    name_ta TEXT NOT NULL,
    code TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS public.districts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    state_id UUID NOT NULL REFERENCES public.states(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    name_ta TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS public.cities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    district_id UUID REFERENCES public.districts(id) ON DELETE CASCADE,
    state_id UUID NOT NULL REFERENCES public.states(id) ON DELETE CASCADE,
    country_id UUID NOT NULL REFERENCES public.countries(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    name_ta TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    timezone TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Location indexes
CREATE INDEX IF NOT EXISTS idx_states_country ON public.states(country_id);
CREATE INDEX IF NOT EXISTS idx_districts_state ON public.districts(state_id);
CREATE INDEX IF NOT EXISTS idx_cities_district ON public.cities(district_id);
CREATE INDEX IF NOT EXISTS idx_cities_name ON public.cities(name);

ALTER TABLE public.countries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.states ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.districts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cities ENABLE ROW LEVEL SECURITY;

DO \
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'countries' AND policyname = 'Allow public read access on countries'
    ) THEN
        CREATE POLICY "Allow public read access on countries" ON public.countries FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'states' AND policyname = 'Allow public read access on states'
    ) THEN
        CREATE POLICY "Allow public read access on states" ON public.states FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'districts' AND policyname = 'Allow public read access on districts'
    ) THEN
        CREATE POLICY "Allow public read access on districts" ON public.districts FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'cities' AND policyname = 'Allow public read access on cities'
    ) THEN
        CREATE POLICY "Allow public read access on cities" ON public.cities FOR SELECT USING (true);
    END IF;
END
\;

DO \
DECLARE
    india_id UUID := gen_random_uuid();
    tn_id UUID := gen_random_uuid();
    ka_id UUID := gen_random_uuid();
    chennai_dist_id UUID := gen_random_uuid();
    cbe_dist_id UUID := gen_random_uuid();
    mdu_dist_id UUID := gen_random_uuid();
    blr_dist_id UUID := gen_random_uuid();
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.countries WHERE name = 'India') THEN
        INSERT INTO public.countries (id, name, name_ta, iso_code)
        VALUES (india_id, 'India', '???????', 'IN');

        INSERT INTO public.states (id, country_id, name, name_ta, code)
        VALUES 
            (tn_id, india_id, 'Tamil Nadu', '?????????', 'TN'),
            (ka_id, india_id, 'Karnataka', '????????', 'KA');

        INSERT INTO public.districts (id, state_id, name, name_ta)
        VALUES
            (chennai_dist_id, tn_id, 'Chennai', '??????'),
            (cbe_dist_id, tn_id, 'Coimbatore', '?????????????'),
            (mdu_dist_id, tn_id, 'Madurai', '?????'),
            (blr_dist_id, ka_id, 'Bengaluru Urban', '?????????');

        INSERT INTO public.cities (district_id, state_id, country_id, name, name_ta, latitude, longitude, timezone)
        VALUES
            (chennai_dist_id, tn_id, india_id, 'Chennai', '??????', 13.0827, 80.2707, 'Asia/Kolkata'),
            (cbe_dist_id, tn_id, india_id, 'Coimbatore', '?????????????', 11.0168, 76.9558, 'Asia/Kolkata'),
            (mdu_dist_id, tn_id, india_id, 'Madurai', '?????', 9.9252, 78.1198, 'Asia/Kolkata'),
            (blr_dist_id, ka_id, india_id, 'Bengaluru', '?????????', 12.9716, 77.5946, 'Asia/Kolkata');
    END IF;
END \;
-- Add missing columns to festivals
ALTER TABLE public.festivals
  ADD COLUMN IF NOT EXISTS tamil_date_str TEXT,
  ADD COLUMN IF NOT EXISTS tamil_month TEXT,
  ADD COLUMN IF NOT EXISTS tamil_year TEXT,
  ADD COLUMN IF NOT EXISTS day_of_week_en TEXT,
  ADD COLUMN IF NOT EXISTS day_of_week_ta TEXT,
  ADD COLUMN IF NOT EXISTS type TEXT,
  ADD COLUMN IF NOT EXISTS type_ta TEXT,
  ADD COLUMN IF NOT EXISTS category TEXT,
  ADD COLUMN IF NOT EXISTS category_ta TEXT,
  ADD COLUMN IF NOT EXISTS rituals TEXT,
  ADD COLUMN IF NOT EXISTS rituals_ta TEXT,
  ADD COLUMN IF NOT EXISTS deity TEXT,
  ADD COLUMN IF NOT EXISTS deity_ta TEXT,
  ADD COLUMN IF NOT EXISTS significance TEXT,
  ADD COLUMN IF NOT EXISTS significance_ta TEXT,
  ADD COLUMN IF NOT EXISTS is_holiday BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS image_url TEXT,
  ADD COLUMN IF NOT EXISTS location TEXT;

-- Add missing columns to special_days
ALTER TABLE public.special_days
  ADD COLUMN IF NOT EXISTS tamil_date_str TEXT,
  ADD COLUMN IF NOT EXISTS tamil_month TEXT,
  ADD COLUMN IF NOT EXISTS tamil_year TEXT,
  ADD COLUMN IF NOT EXISTS day_of_week_en TEXT,
  ADD COLUMN IF NOT EXISTS day_of_week_ta TEXT,
  ADD COLUMN IF NOT EXISTS category_ta TEXT,
  ADD COLUMN IF NOT EXISTS image_url TEXT,
  ADD COLUMN IF NOT EXISTS is_auspicious BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS location TEXT;
