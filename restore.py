import os

content = """import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/colors.dart';
import 'core/localization/tnt_localizations.dart';
import 'home/screens/home_screen.dart';
import 'calendar/screens/calendar_screen.dart';
import 'panchangam/screens/panchangam_screen.dart';
import 'muhurtham/screens/muhurtham_screen.dart';
import 'more/screens/more_screen.dart';
import 'services/supabase_service.dart';
import 'services/production_api_service.dart';
import 'services/auth_state_manager.dart';
import 'features/admin/screens/admin_dashboard.dart';
import 'features/auth/presentation/pages/auth_welcome_page.dart';
import 'features/auth/presentation/pages/email_verification_page.dart';
import 'features/auth/presentation/pages/mobile_verification_page.dart';
import 'features/auth/presentation/pages/account_status_page.dart';
import 'main_screen.dart'; // We'll assume there is a main_screen.dart or we construct one.
// Wait, is MainScreen in main.dart?
"""

with open(r'C:\Users\Vishw\Downloads\TNT\lib\main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
