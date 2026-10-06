import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/tnt_localizations.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = TNTLocalizationsProvider.of(context)?.localizations;
    final isTamil = localizations?.language == AppLanguage.tamil;

    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: AppBar(
        title: Text(
          isTamil ? 'விதிமுறைகள் மற்றும் நிபந்தனைகள்' : 'Terms & Conditions',
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
            // Header Card
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
                      color: TNTColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.gavel_rounded, color: TNTColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTamil ? 'TNT பயன்பாட்டு விதிமுறைகள்' : 'TNT Terms of Service',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: TNTColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isTamil ? 'கடைசி புதுப்பிப்பு: செப்டம்பர் 2026' : 'Last Updated: September 2026',
                          style: const TextStyle(fontSize: 11, color: TNTColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSection(
              title: isTamil ? '1. பயன்பாட்டு அங்கீகாரம்' : '1. Acceptance of Terms',
              content: isTamil
                  ? 'TNT தமிழ் காலண்டர் மற்றும் பஞ்சாங்கம் செயலியை பதிவிறக்குதல், நிறுவுதல் அல்லது பயன்படுத்துவதன் மூலம், இந்த விதிமுறைகள் மற்றும் நிபந்தனைகளுக்கு நீங்கள் ஒப்புக்கொள்கிறீர்கள்.'
                  : 'By downloading, installing, or accessing the TNT Tamil Calendar application, you agree to be bound by these Terms and Conditions and applicable laws.',
            ),

            _buildSection(
              title: isTamil ? '2. பஞ்சாங்க கணிப்புகள் மற்றும் ஜோதிட வழிகாட்டுதல்' : '2. Panchangam & Astrological Computations',
              content: isTamil
                  ? 'பஞ்சாங்கம், திதி, நட்சத்திரம், யோகம், கரணம், முகூர்த்த நேரங்கள் ஆகியவை திருக்கணிதம் மற்றும் வாக்கிய பஞ்சாங்க முறைமைகளின்படி உயர் துல்லிய கணித அல்காரிதம்களால் கணக்கிடப்படுகின்றன. எனினும், முக்கியமான நிகழ்வுகளுக்கு உங்கள் குடும்ப ஜோதிடர் அல்லது புரோகிதரிடம் ஆலோசிக்குமாறு கேட்டுக்கொள்ளப்படுகிறது.'
                  : 'Panchangam parameters (Tithi, Nakshatra, Yoga, Karana, Subha Horai, Muhurtham) are calculated using precise astronomical algorithms based on Thirukanitha and traditional ephemeris principles. Users are encouraged to consult personal astrologers for specific familial rituals.',
            ),

            _buildSection(
              title: isTamil ? '3. பயனர் கணக்கு மற்றும் பாதுகாப்பு' : '3. User Accounts & Security',
              content: isTamil
                  ? 'உங்கள் கணக்கின் கடவுச்சொல் மற்றும் உள்நுழைவு விவரங்களை ரகசியமாக வைத்திருப்பது உங்கள் முழுப் பொறுப்பாகும். அங்கீகரிக்கப்படாத பயன்பாடு ஏதேனும் கண்டறியப்பட்டால் உடனடியாக எங்களுக்குத் தெரிவிக்கவும்.'
                  : 'You are responsible for maintaining the confidentiality of your credentials. You agree to notify us immediately of any unauthorized access or breach of security.',
            ),

            _buildSection(
              title: isTamil ? '4. அறிவுசார் சொத்துரிமை' : '4. Intellectual Property',
              content: isTamil
                  ? 'TNT செயலியின் வடிவமைப்பு, கணிப்பீட்டு நிரல்கள், இடைமுகம், தரவுத்தளங்கள் மற்றும் பிராண்ட் முத்திரைகள் அனைத்தும் காப்புரிமை சட்டங்களின் கீழ் பாதுகாக்கப்பட்டுள்ளன.'
                  : 'All visual designs, algorithms, codebases, graphics, trademarks, and curated calendrical databases within TNT are proprietary intellectual property.',
            ),

            _buildSection(
              title: isTamil ? '5. பொறுப்பு வரம்பு' : '5. Limitation of Liability',
              content: isTamil
                  ? 'TNT செயலி எந்தவொரு தற்செயலான, மறைமுக அல்லது விளைவான இழப்புகளுக்கும் பொறுப்பேற்காது. தரவு துல்லியத்தை உறுதிப்படுத்த அனைத்து முயற்சிகளும் எடுக்கப்படுகின்றன.'
                  : 'In no event shall TNT be liable for any direct, indirect, incidental, or consequential damages resulting from the use or inability to use the service.',
            ),

            _buildSection(
              title: isTamil ? '6. தொடர்புக்கு' : '6. Contact & Grievances',
              content: isTamil
                  ? 'விதிமுறைகள் குறித்த சந்தேகங்களுக்கு support@tntcalendar.com என்ற மின்னஞ்சல் மூலம் எங்களை தொடர்பு கொள்ளலாம்.'
                  : 'For questions regarding these Terms & Conditions, please contact us at support@tntcalendar.com.',
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
