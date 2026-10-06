-- ==================================================
-- TNT CONTENT MODULES SCHEMA (Phases 8-11)
-- ==================================================

-- 1. Calendar Days Table (Core index for daily panchangam & basic day info)
CREATE TABLE IF NOT EXISTS public.calendar_days (
    id TEXT PRIMARY KEY, -- e.g., '2023-10-12'
    gregorian_date DATE NOT NULL UNIQUE,
    tamil_month TEXT NOT NULL,
    tamil_year TEXT NOT NULL,
    tamil_day INTEGER NOT NULL,
    tamil_date_str TEXT NOT NULL,
    tithi TEXT,
    tithi_ta TEXT,
    nakshatra TEXT,
    nakshatra_ta TEXT,
    is_auspicious BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Muhurtham Dates Table
CREATE TABLE IF NOT EXISTS public.muhurtham_dates (
    id TEXT PRIMARY KEY,
    date DATE NOT NULL,
    tamil_date_str TEXT,
    tamil_month TEXT,
    tamil_year TEXT,
    day_of_week_en TEXT,
    day_of_week_ta TEXT,
    start_time TEXT,
    end_time TEXT,
    duration TEXT,
    is_valarthirai BOOLEAN DEFAULT false,
    category TEXT NOT NULL,
    category_ta TEXT,
    description TEXT,
    description_ta TEXT,
    nakshatra TEXT,
    nakshatra_ta TEXT,
    nakshatra_time TEXT,
    tithi TEXT,
    tithi_ta TEXT,
    yoga TEXT,
    yoga_ta TEXT,
    karana TEXT,
    karana_ta TEXT,
    lagnam TEXT,
    lagnam_ta TEXT,
    subha_horai TEXT,
    subha_horai_ta TEXT,
    rahu_kalam TEXT,
    yamagandam TEXT,
    kuligai TEXT,
    approved_status TEXT DEFAULT 'Draft',
    notes TEXT,
    notes_ta TEXT,
    location TEXT DEFAULT 'Chennai',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Muhurtham Timings Sub-Table (For multiple slots per day)
CREATE TABLE IF NOT EXISTS public.muhurtham_timings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    muhurtham_date_id TEXT NOT NULL REFERENCES public.muhurtham_dates(id) ON DELETE CASCADE,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    duration TEXT,
    lagnam TEXT,
    lagnam_ta TEXT,
    nakshatra TEXT,
    nakshatra_ta TEXT,
    subha_horai TEXT,
    subha_horai_ta TEXT,
    description TEXT,
    description_ta TEXT,
    is_prime BOOLEAN DEFAULT false
);

-- 3. Festivals Table
CREATE TABLE IF NOT EXISTS public.festivals (
    id TEXT PRIMARY KEY,
    date DATE NOT NULL,
    name TEXT NOT NULL,
    name_ta TEXT,
    description TEXT,
    description_ta TEXT,
    category TEXT NOT NULL,
    category_ta TEXT,
    is_public_holiday BOOLEAN DEFAULT false,
    is_bank_holiday BOOLEAN DEFAULT false,
    significance TEXT,
    significance_ta TEXT,
    ritual_time TEXT,
    ritual_time_ta TEXT,
    fasting_rules TEXT,
    fasting_rules_ta TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Special Days Table (Amavasai, Pournami, etc.)
CREATE TABLE IF NOT EXISTS public.special_days (
    id TEXT PRIMARY KEY,
    date DATE NOT NULL,
    name TEXT NOT NULL,
    name_ta TEXT,
    category TEXT NOT NULL,
    category_ta TEXT,
    start_time TEXT,
    end_time TEXT,
    significance TEXT,
    significance_ta TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Important Timings Table (Nalla Neram, Rahu Kalam, etc.)
CREATE TABLE IF NOT EXISTS public.important_timings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    date DATE NOT NULL,
    name TEXT NOT NULL,
    name_ta TEXT,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    is_auspicious BOOLEAN DEFAULT false
);

-- Indexes for fast querying
CREATE INDEX idx_calendar_days_date ON public.calendar_days(gregorian_date);
CREATE INDEX idx_muhurtham_dates_date ON public.muhurtham_dates(date);
CREATE INDEX idx_muhurtham_dates_category ON public.muhurtham_dates(category);
CREATE INDEX idx_festivals_date ON public.festivals(date);
CREATE INDEX idx_special_days_date ON public.special_days(date);
CREATE INDEX idx_important_timings_date ON public.important_timings(date);

-- RLS Policies
ALTER TABLE public.calendar_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.muhurtham_dates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.muhurtham_timings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.festivals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.special_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.important_timings ENABLE ROW LEVEL SECURITY;

-- Public Read Access
CREATE POLICY "Allow public read calendar" ON public.calendar_days FOR SELECT USING (true);
CREATE POLICY "Allow public read muhurthams" ON public.muhurtham_dates FOR SELECT USING (true);
CREATE POLICY "Allow public read muhurtham_timings" ON public.muhurtham_timings FOR SELECT USING (true);
CREATE POLICY "Allow public read festivals" ON public.festivals FOR SELECT USING (true);
CREATE POLICY "Allow public read special_days" ON public.special_days FOR SELECT USING (true);
CREATE POLICY "Allow public read timings" ON public.important_timings FOR SELECT USING (true);
