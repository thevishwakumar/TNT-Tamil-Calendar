-- 20261006184000_fix_muhurtham_category.sql

-- Add missing category column to muhurtham_dates
ALTER TABLE public.muhurtham_dates
  ADD COLUMN IF NOT EXISTS category TEXT,
  ADD COLUMN IF NOT EXISTS category_ta TEXT;

-- Index for category searches
CREATE INDEX IF NOT EXISTS idx_muhurtham_category ON public.muhurtham_dates(category);
