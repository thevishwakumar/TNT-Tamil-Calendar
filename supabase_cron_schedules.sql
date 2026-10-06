-- ==========================================
-- TNT MODULE 6: SERVER-SIDE SCHEDULER & CRON
-- ==========================================
-- Execute this file in your Supabase SQL Editor.
-- It enables pg_cron and pg_net to allow your database
-- to automatically trigger Edge Functions and RPCs.

-- 1. Enable Required Extensions
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 2. Define Cron Job: Notification Dispatcher
SELECT cron.schedule(
    'job_notification_dispatcher',
    '*/5 * * * *',
    \$\$ 
    SELECT net.http_post(
        url := current_setting('app.settings.supabase_url') || '/functions/v1/send-push-notifications',
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || current_setting('app.settings.supabase_anon_key')
        )
    );
    \$\$
);

-- 3. Define Cron Job: Content Publisher
SELECT cron.schedule(
    'job_publish_scheduled_content',
    '1 0 * * *',
    \$\$ SELECT public.publish_scheduled_content(); \$\$
);

-- 4. Create an Admin View to monitor Cron Execution Logs
CREATE OR REPLACE VIEW public.admin_cron_logs AS
SELECT jobid, runid, job_pid, database, username, command, status, return_message, start_time, end_time
FROM cron.job_run_details
ORDER BY start_time DESC;

GRANT SELECT ON public.admin_cron_logs TO authenticated;
