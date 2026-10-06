import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = localizations?.language == AppLanguage.tamil;

    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: AppBar(
        title: Text(
          isTamil ? 'தனியுரிமைக் கொள்கை' : 'Privacy Policy',
          style: const TextStyle(fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
        ),
        backgroundColor: TNTColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: TNTColors.textPrimary),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Security Shield Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TNTColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TNTColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.security_rounded, color: Colors.green, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTamil ? 'உங்கள் தரவு பாதுகாப்பு மற்றும் தனியுரிமை' : 'Your Privacy & Data Security',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: TNTColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isTamil ? 'எண்ட்-டு-எண்ட் குறியாக்கம் & RLS பாதுகாப்பு' : 'End-to-end encrypted with PostgreSQL RLS',
                          style: const TextStyle(fontSize: 11, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSection(
              title: isTamil ? '1. சேகரிக்கப்படும் தகவல்கள்' : '1. Information We Collect',
              content: isTamil
                  ? 'நாங்கள் உங்கள் பெயர், மின்னஞ்சல் முகவரி, கைபேசி எண் (விருப்பத்தேர்வு), இருப்பிடம் (நகரம்/அட்சரேகை துல்லிய பஞ்சாங்கத்திற்காக) மற்றும் சேமிக்கப்பட்ட நினைவூட்டல் குறிப்புகளை மட்டுமே சேகரிக்கிறோம்.'
                  : 'We collect your profile details (name, email, optional phone), location preferences (for localized sunrise/sunset/panchangam calculations), notification tokens, and personal calendar bookmarks.',
            ),

            _buildSection(
              title: isTamil ? '2. தகவல்கள் எவ்வாறு பயன்படுத்தப்படுகின்றன' : '2. How We Use Your Information',
              content: isTamil
                  ? 'சூரியோதயம், நல்ல நேரம், எமகண்டம் போன்ற துல்லியமான கணிப்புகளை வழங்கவும், திருவிழா & முகூர்த்த அறிவிப்புகளை அனுப்பவும், உங்கள் தனிப்பட்ட குறிப்புகளை ஒத்திசைக்கவும் தகவல்கள் பயன்படுகின்றன.'
                  : 'Your information is used strictly to calculate location-accurate solar/lunar ephemeris, dispatch targeted festival & muhurtham alerts, and synchronize private notes securely across devices.',
            ),

            _buildSection(
              title: isTamil ? '3. மூன்றாம் தரப்பு தரவு பகிர்வு இல்லை' : '3. No Third-Party Data Selling',
              content: isTamil
                  ? 'TNT உங்கள் தனிப்பட்ட தகவல்களை எந்தவொரு மூன்றாம் தரப்பு விளம்பர நிறுவனங்களுக்கும் விற்காது அல்லது வாடகைக்கு விடாது.'
                  : 'TNT never sells, rents, or monetizes your personal data or browsing activities to third-party ad networks or brokers.',
            ),

            _buildSection(
              title: isTamil ? '4. தரவு பாதுகாப்பு & RLS கொள்கைகள்' : '4. Data Security & PostgreSQL RLS',
              content: isTamil
                  ? 'உங்கள் தரவுத்தளம் Row Level Security (RLS) கொள்கைகளால் பாதுகாக்கப்படுகிறது. உங்கள் தனிப்பட்ட குறிப்புகளை நீங்கள் மட்டுமே பார்க்க முடியும்; நிர்வாகிகளால் கூட நேரடியாக அணுக முடியாது.'
                  : 'All private records are protected by strict PostgreSQL Row-Level Security policies ensuring only authenticated user accounts can access their corresponding user data.',
            ),

            _buildSection(
              title: isTamil ? '5. உங்கள் உரிமைகள் & கணக்கு நீக்குதல்' : '5. User Rights & Account Deletion',
              content: isTamil
                  ? 'உங்கள் சுயவிவரத்தை எப்போது வேண்டுமானாலும் புதுப்பிக்கலாம் அல்லது கணக்கை நிரந்தரமாக நீக்க கோரலாம்.'
                  : 'You maintain full rights to export your bookmarks, update preferences, or permanently delete your account and associated records at any time.',
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TNTColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: TNTColors.border.withValues(alpha: 0.8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: TNTColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(fontSize: 12, height: 1.5, color: TNTColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
