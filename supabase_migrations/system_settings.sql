-- Migration: System Settings
-- Description: Creates a table to store dynamic app configuration controlled by admins

CREATE TABLE IF NOT EXISTS public.system_settings (
    key VARCHAR(100) PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_by UUID REFERENCES public.profiles(id)
);

-- RLS Policies
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

-- Anyone can read system settings (needed for app config)
CREATE POLICY "Anyone can read system settings"
    ON public.system_settings
    FOR SELECT
    USING (true);

-- Only admins can modify system settings
CREATE POLICY "Admins can update system settings"
    ON public.system_settings
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );

-- Insert default settings
INSERT INTO public.system_settings (key, value, description)
VALUES 
    ('app_maintenance_mode', 'false'::jsonb, 'Toggle to show maintenance screen to users'),
    ('force_update_version', '"1.0.0"'::jsonb, 'Minimum app version required to run'),
    ('enable_catering_module', 'true'::jsonb, 'Toggle visibility of catering services'),
    ('cache_duration_hours', '24'::jsonb, 'How long to cache non-critical data locally')
ON CONFLICT (key) DO NOTHING;
