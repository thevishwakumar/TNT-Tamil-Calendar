--- Table: profiles ---
id | uuid | Nullable: NO | Default: null
full_name | text | Nullable: NO | Default: null
email | text | Nullable: NO | Default: null
phone | text | Nullable: YES | Default: null
mobile | text | Nullable: YES | Default: null
role | text | Nullable: NO | Default: 'USER'::text
account_status | text | Nullable: NO | Default: 'PENDING_EMAIL_VERIFICATION'::text
language | text | Nullable: NO | Default: 'ta'::text
city | text | Nullable: YES | Default: null
state | text | Nullable: YES | Default: null
country | text | Nullable: YES | Default: null
avatar_url | text | Nullable: YES | Default: null
is_active | boolean | Nullable: NO | Default: true
email_verified_at | timestamp with time zone | Nullable: YES | Default: null
phone_verified_at | timestamp with time zone | Nullable: YES | Default: null
created_at | timestamp with time zone | Nullable: NO | Default: now()
updated_at | timestamp with time zone | Nullable: NO | Default: now()
Constraint: FOREIGN KEY (profiles_id_fkey) on id -> null(null)
Constraint: PRIMARY KEY (profiles_pkey) on id -> profiles(id)

--- Table: analytics_events ---
id | uuid | Nullable: NO | Default: gen_random_uuid()
user_id | uuid | Nullable: YES | Default: null
event_name | text | Nullable: NO | Default: null
content_id | uuid | Nullable: YES | Default: null
metadata | jsonb | Nullable: YES | Default: null
created_at | timestamp with time zone | Nullable: NO | Default: now()
Constraint: PRIMARY KEY (analytics_events_pkey) on id -> analytics_events(id)
Constraint: FOREIGN KEY (analytics_events_user_id_fkey) on user_id -> profiles(id)

--- Table: calendar_days ---
id | uuid | Nullable: NO | Default: gen_random_uuid()
date | date | Nullable: NO | Default: null
tamil_date | text | Nullable: NO | Default: null
tamil_month | text | Nullable: NO | Default: null
tamil_year | text | Nullable: NO | Default: null
weekday_tamil | text | Nullable: NO | Default: null
weekday_english | text | Nullable: NO | Default: null
created_at | timestamp with time zone | Nullable: NO | Default: now()
updated_at | timestamp with time zone | Nullable: NO | Default: now()
Constraint: UNIQUE (calendar_days_date_key) on date -> calendar_days(date)
Constraint: PRIMARY KEY (calendar_days_pkey) on id -> calendar_days(id)

--- Table: muhurtham_dates ---
id | uuid | Nullable: NO | Default: gen_random_uuid()
date | date | Nullable: NO | Default: null
title_tamil | text | Nullable: NO | Default: null
title_english | text | Nullable: NO | Default: null
description_tamil | text | Nullable: YES | Default: null
description_english | text | Nullable: YES | Default: null
is_published | boolean | Nullable: NO | Default: false
source_name | text | Nullable: YES | Default: null
source_reference | text | Nullable: YES | Default: null
created_at | timestamp with time zone | Nullable: NO | Default: now()
updated_at | timestamp with time zone | Nullable: NO | Default: now()
category | text | Nullable: YES | Default: null
category_ta | text | Nullable: YES | Default: null
Constraint: UNIQUE (muhurtham_dates_date_key) on date -> muhurtham_dates(date)
Constraint: PRIMARY KEY (muhurtham_dates_pkey) on id -> muhurtham_dates(id)

--- Table: muhurtham_timings ---
id | uuid | Nullable: NO | Default: gen_random_uuid()
muhurtham_date_id | uuid | Nullable: NO | Default: null
start_time | text | Nullable: NO | Default: null
end_time | text | Nullable: NO | Default: null
nakshatra | text | Nullable: YES | Default: null
nakshatra_start | text | Nullable: YES | Default: null
nakshatra_end | text | Nullable: YES | Default: null
nalla_neram_start | text | Nullable: YES | Default: null
nalla_neram_end | text | Nullable: YES | Default: null
rahu_start | text | Nullable: YES | Default: null
rahu_end | text | Nullable: YES | Default: null
yamagandam_start | text | Nullable: YES | Default: null
yamagandam_end | text | Nullable: YES | Default: null
kuligai_start | text | Nullable: YES | Default: null
kuligai_end | text | Nullable: YES | Default: null
created_at | timestamp with time zone | Nullable: NO | Default: now()
updated_at | timestamp with time zone | Nullable: NO | Default: now()
Constraint: FOREIGN KEY (muhurtham_timings_muhurtham_date_id_fkey) on muhurtham_date_id -> muhurtham_dates(id)
Constraint: PRIMARY KEY (muhurtham_timings_pkey) on id -> muhurtham_timings(id)

--- Table: festivals ---
id | uuid | Nullable: NO | Default: gen_random_uuid()
date | date | Nullable: NO | Default: null
name_tamil | text | Nullable: NO | Default: null
name_english | text | Nullable: NO | Default: null
description_tamil | text | Nullable: YES | Default: null
description_english | text | Nullable: YES | Default: null
is_published | boolean | Nullable: NO | Default: true
created_at | timestamp with time zone | Nullable: NO | Default: now()
updated_at | timestamp with time zone | Nullable: NO | Default: now()
Constraint: PRIMARY KEY (festivals_pkey) on id -> festivals(id)

--- Table: special_days ---
id | uuid | Nullable: NO | Default: gen_random_uuid()
date | date | Nullable: NO | Default: null
name_tamil | text | Nullable: NO | Default: null
name_english | text | Nullable: NO | Default: null
category | text | Nullable: NO | Default: null
description_tamil | text | Nullable: YES | Default: null
description_english | text | Nullable: YES | Default: null
is_published | boolean | Nullable: NO | Default: true
created_at | timestamp with time zone | Nullable: NO | Default: now()
updated_at | timestamp with time zone | Nullable: NO | Default: now()
Constraint: PRIMARY KEY (special_days_pkey) on id -> special_days(id)

--- Table: important_timings ---
Table does not exist.
--- Table: locations ---
Table does not exist.
--- Table: countries ---
id | text | Nullable: NO | Default: null
name | text | Nullable: NO | Default: null
name_ta | text | Nullable: YES | Default: null
iso_code | text | Nullable: NO | Default: null
is_active | boolean | Nullable: YES | Default: true
created_at | timestamp with time zone | Nullable: YES | Default: now()
Constraint: UNIQUE (countries_iso_code_key) on iso_code -> countries(iso_code)
Constraint: PRIMARY KEY (countries_pkey) on id -> countries(id)

--- Table: states ---
id | text | Nullable: NO | Default: null
country_id | text | Nullable: NO | Default: null
name | text | Nullable: NO | Default: null
name_ta | text | Nullable: YES | Default: null
code | text | Nullable: YES | Default: null
is_active | boolean | Nullable: YES | Default: true
created_at | timestamp with time zone | Nullable: YES | Default: now()
Constraint: FOREIGN KEY (states_country_id_fkey) on country_id -> countries(id)
Constraint: PRIMARY KEY (states_pkey) on id -> states(id)

--- Table: districts ---
id | text | Nullable: NO | Default: null
state_id | text | Nullable: NO | Default: null
name | text | Nullable: NO | Default: null
name_ta | text | Nullable: YES | Default: null
is_active | boolean | Nullable: YES | Default: true
created_at | timestamp with time zone | Nullable: YES | Default: now()
Constraint: PRIMARY KEY (districts_pkey) on id -> districts(id)
Constraint: FOREIGN KEY (districts_state_id_fkey) on state_id -> states(id)

--- Table: cities ---
id | text | Nullable: NO | Default: null
district_id | text | Nullable: NO | Default: null
state_id | text | Nullable: NO | Default: null
country_id | text | Nullable: NO | Default: null
name | text | Nullable: NO | Default: null
name_ta | text | Nullable: YES | Default: null
latitude | double precision | Nullable: YES | Default: null
longitude | double precision | Nullable: YES | Default: null
timezone | text | Nullable: YES | Default: 'Asia/Kolkata'::text
is_active | boolean | Nullable: YES | Default: true
created_at | timestamp with time zone | Nullable: YES | Default: now()
Constraint: FOREIGN KEY (cities_country_id_fkey) on country_id -> countries(id)
Constraint: FOREIGN KEY (cities_district_id_fkey) on district_id -> districts(id)
Constraint: PRIMARY KEY (cities_pkey) on id -> cities(id)
Constraint: FOREIGN KEY (cities_state_id_fkey) on state_id -> states(id)

--- Table: user_preferences ---
id | uuid | Nullable: NO | Default: gen_random_uuid()
user_id | uuid | Nullable: NO | Default: null
language | text | Nullable: NO | Default: 'ta'::text
notification_enabled | boolean | Nullable: NO | Default: true
all_notifications | boolean | Nullable: NO | Default: true
panchangam_notifications | boolean | Nullable: NO | Default: true
muhurtham_notifications | boolean | Nullable: NO | Default: true
festival_notifications | boolean | Nullable: NO | Default: true
special_day_notifications | boolean | Nullable: NO | Default: true
reminder_notifications | boolean | Nullable: NO | Default: true
important_updates | boolean | Nullable: NO | Default: true
marketing_notifications | boolean | Nullable: NO | Default: false
location_permission_enabled | boolean | Nullable: NO | Default: false
created_at | timestamp with time zone | Nullable: NO | Default: now()
updated_at | timestamp with time zone | Nullable: NO | Default: now()
Constraint: PRIMARY KEY (user_preferences_pkey) on id -> user_preferences(id)
Constraint: FOREIGN KEY (user_preferences_user_id_fkey) on user_id -> profiles(id)
Constraint: UNIQUE (user_preferences_user_id_key) on user_id -> user_preferences(user_id)

--- Table: user_saved_items ---
id | uuid | Nullable: NO | Default: gen_random_uuid()
user_id | uuid | Nullable: NO | Default: null
item_type | text | Nullable: NO | Default: null
item_id | uuid | Nullable: NO | Default: null
created_at | timestamp with time zone | Nullable: NO | Default: now()
Constraint: PRIMARY KEY (user_saved_items_pkey) on id -> user_saved_items(id)
Constraint: FOREIGN KEY (user_saved_items_user_id_fkey) on user_id -> profiles(id)
Constraint: UNIQUE (user_saved_items_user_id_item_type_item_id_key) on user_id -> user_saved_items(item_id)
Constraint: UNIQUE (user_saved_items_user_id_item_type_item_id_key) on user_id -> user_saved_items(item_type)
Constraint: UNIQUE (user_saved_items_user_id_item_type_item_id_key) on user_id -> user_saved_items(user_id)
Constraint: UNIQUE (user_saved_items_user_id_item_type_item_id_key) on item_type -> user_saved_items(item_id)
Constraint: UNIQUE (user_saved_items_user_id_item_type_item_id_key) on item_type -> user_saved_items(item_type)
Constraint: UNIQUE (user_saved_items_user_id_item_type_item_id_key) on item_type -> user_saved_items(user_id)
Constraint: UNIQUE (user_saved_items_user_id_item_type_item_id_key) on item_id -> user_saved_items(item_id)
Constraint: UNIQUE (user_saved_items_user_id_item_type_item_id_key) on item_id -> user_saved_items(item_type)
Constraint: UNIQUE (user_saved_items_user_id_item_type_item_id_key) on item_id -> user_saved_items(user_id)

--- Table: user_reminders ---
id | uuid | Nullable: NO | Default: gen_random_uuid()
user_id | uuid | Nullable: NO | Default: null
item_type | text | Nullable: NO | Default: null
item_id | uuid | Nullable: NO | Default: null
reminder_time | timestamp with time zone | Nullable: NO | Default: null
is_enabled | boolean | Nullable: NO | Default: true
created_at | timestamp with time zone | Nullable: NO | Default: now()
updated_at | timestamp with time zone | Nullable: NO | Default: now()
Constraint: PRIMARY KEY (user_reminders_pkey) on id -> user_reminders(id)
Constraint: FOREIGN KEY (user_reminders_user_id_fkey) on user_id -> profiles(id)

--- Table: personal_events ---
Table does not exist.
--- Table: notification_logs ---
id | uuid | Nullable: NO | Default: gen_random_uuid()
user_id | uuid | Nullable: NO | Default: null
campaign_id | uuid | Nullable: YES | Default: null
device_id | uuid | Nullable: YES | Default: null
title | text | Nullable: NO | Default: null
title_tamil | text | Nullable: YES | Default: null
body | text | Nullable: NO | Default: null
body_tamil | text | Nullable: YES | Default: null
notification_type | text | Nullable: NO | Default: null
related_item_type | text | Nullable: YES | Default: null
related_item_id | text | Nullable: YES | Default: null
status | text | Nullable: NO | Default: 'SENT'::text
error_message | text | Nullable: YES | Default: null
is_read | boolean | Nullable: NO | Default: false
sent_at | timestamp with time zone | Nullable: NO | Default: now()
delivered_at | timestamp with time zone | Nullable: YES | Default: null
opened_at | timestamp with time zone | Nullable: YES | Default: null
created_at | timestamp with time zone | Nullable: NO | Default: now()
Constraint: FOREIGN KEY (notification_logs_campaign_id_fkey) on campaign_id -> notification_campaigns(id)
Constraint: FOREIGN KEY (notification_logs_device_id_fkey) on device_id -> user_devices(id)
Constraint: PRIMARY KEY (notification_logs_pkey) on id -> notification_logs(id)
Constraint: FOREIGN KEY (notification_logs_user_id_fkey) on user_id -> profiles(id)

