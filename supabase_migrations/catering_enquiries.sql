-- Migration: Add catering enquiries table

CREATE TABLE IF NOT EXISTS public.catering_enquiries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    reference_code TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    mobile_number TEXT NOT NULL,
    event_type TEXT NOT NULL,
    other_event_type TEXT,
    event_date DATE NOT NULL,
    guest_count INTEGER,
    event_location TEXT,
    message TEXT,
    status TEXT NOT NULL DEFAULT 'new',
    source TEXT NOT NULL DEFAULT 'tnt_app',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    contacted_at TIMESTAMPTZ,
    notes TEXT,
    assigned_to UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

-- RLS
ALTER TABLE public.catering_enquiries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert their own enquiries" 
    ON public.catering_enquiries FOR INSERT 
    WITH CHECK (auth.uid() = user_id OR auth.uid() IS NULL);

CREATE POLICY "Users can view their own enquiries" 
    ON public.catering_enquiries FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "Admins can do everything on enquiries" 
    ON public.catering_enquiries FOR ALL 
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE user_profiles.id = auth.uid() AND user_profiles.role = 'admin'
        )
    );
