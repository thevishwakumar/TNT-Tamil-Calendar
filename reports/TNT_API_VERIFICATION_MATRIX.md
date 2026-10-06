# TNT API Verification Matrix

| Provider | Purpose | Request Endpoint / Table | Auth Method | Expected Response | Status | Verification Evidence |
| -------- | ------- | ------------------------ | ----------- | ----------------- | ------ | --------------------- |
| Supabase Auth | User Authentication | `/auth/v1/otp` | Supabase Anon Key | Auth Session (JWT) | BLOCKED | No Staging Credentials provided in `.env.staging` |
| Supabase DB | Profile Management | `profiles` | RLS (`auth.uid() = id`) | Profile object | BLOCKED | No DB access |
| Supabase DB | Panchangam Fetch | `panchangam_entries` | Public/Anon | Array of entries | BLOCKED | No DB access |
| Supabase DB | Muhurtham Fetch | `muhurtham_dates` | Public/Anon (published=true) | Array of dates | BLOCKED | No DB access |
| Supabase DB | Reminders/Saved | `user_reminders` | RLS (`auth.uid() = user_id`) | Array of user items | BLOCKED | No DB access |
| Supabase DB | Notification Logs | `notification_logs` | RLS (`auth.uid() = user_id`) | Array of logs | BLOCKED | No DB access |
| Supabase DB | Admin Data | All tables | RLS (`is_admin()`) | Full data access | BLOCKED | No DB access |
