import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/localization/tnt_localizations.dart';
import '../../../../services/auth_state_manager.dart';

class AccountStatusPage extends StatelessWidget {
  final AuthStateManager authStateManager;

  const AccountStatusPage({
    super.key,
    required this.authStateManager,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = Localizations.localeOf(context).languageCode == 'ta';
    final userEmail = authStateManager.currentProfile?.email ?? 'User';

    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: AppBar(
        backgroundColor: TNTColors.surface,
        elevation: 0,
        title: Text(
          isTamil ? 'கணக்கு நிலை' : 'Account Status',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
        ),
        actions: [ const TNTBrandHeader(), 
          IconButton(
            tooltip: isTamil ? 'வெளியேறு' : 'Sign Out',
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            onPressed: () => authStateManager.signOut(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: TNTColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.block_rounded, color: Colors.red, size: 40),
              ),
              const SizedBox(height: 24),

              Text(
                isTamil ? 'கணக்கு இடைநிறுத்தப்பட்டுள்ளது' : 'Account Suspended',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                isTamil
                    ? 'உங்கள் கணக்கு ($userEmail) தற்காலிகமாக இடைநிறுத்தப்பட்டுள்ளது. மேலும் விவரங்களுக்கு எங்கள் ஆதரவுக் குழுவை அணுகவும்.'
                    : 'Your account ($userEmail) has been suspended. For assistance or appeal, please contact TNT Support.',
                style: const TextStyle(fontSize: 13, color: TNTColors.textSecondary, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: TNTColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: TNTColors.border),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TNT Support Helpdesk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.email_outlined, size: 14, color: TNTColors.primary),
                        SizedBox(width: 6),
                        Text('support@tntcalendar.in', style: TextStyle(fontSize: 12, color: TNTColors.primary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TNTColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => authStateManager.signOut(),
                  child: Text(
                    isTamil ? 'வெளியேறு' : 'Sign Out',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
