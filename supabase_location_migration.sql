-- ==================================================
-- TNT LOCATION SYSTEM MIGRATION (Phase 2)
-- ==================================================

-- 1. Create Countries Table
CREATE TABLE IF NOT EXISTS public.countries (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    name_ta TEXT,
    iso_code TEXT NOT NULL UNIQUE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create States Table
CREATE TABLE IF NOT EXISTS public.states (
    id TEXT PRIMARY KEY,
    country_id TEXT NOT NULL REFERENCES public.countries(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    name_ta TEXT,
    code TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create Districts Table
CREATE TABLE IF NOT EXISTS public.districts (
    id TEXT PRIMARY KEY,
    state_id TEXT NOT NULL REFERENCES public.states(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    name_ta TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Create Cities Table
CREATE TABLE IF NOT EXISTS public.cities (
    id TEXT PRIMARY KEY,
    district_id TEXT NOT NULL REFERENCES public.districts(id) ON DELETE CASCADE,
    state_id TEXT NOT NULL REFERENCES public.states(id) ON DELETE CASCADE,
    country_id TEXT NOT NULL REFERENCES public.countries(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    name_ta TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    timezone TEXT DEFAULT 'Asia/Kolkata',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Create Indexes
CREATE INDEX IF NOT EXISTS idx_countries_is_active ON public.countries(is_active);
CREATE INDEX IF NOT EXISTS idx_states_country_id ON public.states(country_id);
CREATE INDEX IF NOT EXISTS idx_districts_state_id ON public.districts(state_id);
CREATE INDEX IF NOT EXISTS idx_cities_district_id ON public.cities(district_id);
CREATE INDEX IF NOT EXISTS idx_cities_state_id ON public.cities(state_id);
CREATE INDEX IF NOT EXISTS idx_cities_country_id ON public.cities(country_id);
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS idx_cities_name_trgm ON public.cities USING GIN (name gin_trgm_ops);

-- 6. RLS
ALTER TABLE public.countries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.states ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.districts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cities ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read access to active countries" ON public.countries FOR SELECT USING (is_active = true);
CREATE POLICY "Allow public read access to active states" ON public.states FOR SELECT USING (is_active = true);
CREATE POLICY "Allow public read access to active districts" ON public.districts FOR SELECT USING (is_active = true);
CREATE POLICY "Allow public read access to active cities" ON public.cities FOR SELECT USING (is_active = true);
