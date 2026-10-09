import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';
import 'terms_conditions_screen.dart';
import 'privacy_policy_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = localizations?.language == AppLanguage.tamil;

    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: AppBar(
        title: Text(
          isTamil ? 'TNT பற்றி' : 'About TNT',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
        ),
        backgroundColor: TNTColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: TNTColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: TNTColors.border, height: 1),
        ),
      actions: const [TNTBrandHeader()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Logo & Title
            Container(
              width: 240,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: TNTColors.primary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/tnt_logo.jpg',
                  fit: BoxFit.contain,
                  width: 240,
                  height: 180,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isTamil
                  ? 'TNT தமிழ் காலண்டர் & பஞ்சாங்கம்'
                  : 'TNT Tamil Calendar',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: TNTColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              isTamil
                  ? 'பதிப்பு 1.0.0 (உற்பத்தி பதிப்பு)'
                  : 'Version 1.0.0 (Production Release)',
              style: const TextStyle(
                  fontSize: 12,
                  color: TNTColors.textMuted,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),

            // Mission Statement Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TNTColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TNTColors.border),
              ),
              child: Text(
                isTamil
                    ? 'TNT செயலி என்பது துல்லியமான வாக்கிய மற்றும் திருக்கணித பஞ்சாங்கம், சுப முகூர்த்த காலங்கள், பண்டிகைகள், மற்றும் திருமண வழிகாட்டுதலை உலகெங்கிலும் உள்ள தமிழ் மக்களுக்கு நவீன, எளிய வடிவில் வழங்கும் ஒரு முழுமையான தளமாகும்.'
                    : 'TNT is a comprehensive Tamil Calendar and Panchangam platform engineered to deliver accurate ephemeris calculations, auspicious Muhurtham schedules, festival guides, and custom marriage timing consultations with modern mobile elegance.',
                style: const TextStyle(
                    fontSize: 12, height: 1.6, color: TNTColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            // Features Overview
            _buildFeatureTile(
              icon: Icons.auto_awesome_rounded,
              title: isTamil
                  ? 'துல்லிய பஞ்சாங்க கணிப்பு'
                  : 'Astronomical Ephemeris',
              desc: isTamil
                  ? 'திதி, நட்சத்திரம், யோகம், கரணம், சுப ஹோரை துல்லிய கணிப்பு'
                  : 'Tithi, Nakshatra, Yoga, Karana, Subha Horai & Gowri Panchangam',
            ),
            _buildFeatureTile(
              icon: Icons.favorite_rounded,
              title: isTamil
                  ? 'சுப முகூர்த்த வழிகாட்டுதல்'
                  : 'Auspicious Muhurthams',
              desc: isTamil
                  ? 'திருமணம், கிரகப்பிரவேசம், காதணி, பெயர் சூட்டுதல் சுப நேரங்கள்'
                  : 'Weddings, Grihapravesam, Naming, Ear-Piercing & New Business',
            ),
            _buildFeatureTile(
              icon: Icons.verified_user_rounded,
              title: isTamil ? 'பாதுகாப்பான தரவுத்தளம்' : 'PostgreSQL Security',
              desc: isTamil
                  ? 'Row-Level Security மற்றும் பாதுகாப்பான பயனர் நிர்வாகம்'
                  : 'Row-Level Security, private reminders and multi-role admin controls',
            ),

            const SizedBox(height: 16),

            // Quick Links List
            Container(
              decoration: BoxDecoration(
                color: TNTColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TNTColors.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.gavel_rounded,
                        size: 20, color: TNTColors.primary),
                    title: Text(
                      isTamil
                          ? 'விதிமுறைகள் மற்றும் நிபந்தனைகள்'
                          : 'Terms & Conditions',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TNTColors.textPrimary),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: TNTColors.textMuted),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TermsConditionsScreen()));
                    },
                  ),
                  const Divider(height: 1, color: TNTColors.border),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined,
                        size: 20, color: TNTColors.primary),
                    title: Text(
                      isTamil ? 'தனியுரிமைக் கொள்கை' : 'Privacy Policy',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TNTColors.textPrimary),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: TNTColors.textMuted),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyScreen()));
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            Text(
              isTamil
                  ? '© 2026 TNT தமிழ் காலண்டர். அனைத்து உரிமைகளும் பாதுகாக்கப்பட்டவை.'
                  : '© 2026 TNT Tamil Calendar. All rights reserved.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: TNTColors.textMuted),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile(
      {required IconData icon, required String title, required String desc}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TNTColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: TNTColors.border.withValues(alpha: 0.7)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: TNTColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: TNTColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: TNTColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 11, color: TNTColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
