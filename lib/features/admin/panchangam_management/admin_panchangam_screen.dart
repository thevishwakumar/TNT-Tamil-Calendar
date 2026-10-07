import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

/// Admin Panchangam Management Screen
class AdminPanchangamScreen extends StatefulWidget {
  const AdminPanchangamScreen({super.key});

  @override
  _AdminPanchangamScreenState createState() => _AdminPanchangamScreenState();
}

class _AdminPanchangamScreenState extends State<AdminPanchangamScreen> {
  DateTime _selectedDate = DateTime.now();
  final String _selectedLocation = 'Chennai';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: AppBar(
        title: const Text('Panchangam Management', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TNTColors.textPrimary)),
        backgroundColor: TNTColors.surface,
        elevation: 0,
        actions: [ const TNTBrandHeader(), 
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded, color: TNTColors.primary),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: TNTColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected Date Bar
            Card(
              color: TNTColors.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: TNTColors.border)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Viewing Panchangam for:', style: TextStyle(fontSize: 11, color: TNTColors.textMuted)),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} (புரட்டாசி ${_selectedDate.day})',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: TNTColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                      child: Text(_selectedLocation, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: TNTColors.primary)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Panchangam Core Elements Card
            Card(
              color: TNTColors.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: TNTColors.border)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Core Elements (பஞ்சாங்கம்)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary)),
                        Icon(Icons.verified_rounded, size: 16, color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildPanchRow('திதி (Tithi)', 'துவிதியை (Dwitiya) வரை இரவு 08:24'),
                    _buildPanchRow('நட்சத்திரம் (Nakshatra)', 'சித்திரை (Chitra) வரை மாலை 04:10'),
                    _buildPanchRow('யோகம் (Yoga)', 'சுபம் (Subham)'),
                    _buildPanchRow('கரணம் (Karana)', 'பவ (Bhava)'),
                    _buildPanchRow('சூரியோதயம் / மறைவு', '06:04 AM / 06:10 PM'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Timings Management Card
            Card(
              color: TNTColors.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: TNTColors.border)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Approved Timings (சுப நேரங்கள்)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary)),
                    const SizedBox(height: 12),
                    _buildPanchRow('நல்ல நேரம் (Nalla Neram)', 'காலை 09:15 - 10:15, மாலை 04:45 - 05:45', isHighlight: true),
                    _buildPanchRow('கௌரி நல்ல நேரம்', 'காலை 10:45 - 11:45, மாலை 06:30 - 07:30'),
                    _buildPanchRow('ராகு காலம் (Rahu Kalam)', 'காலை 07:30 - 09:00', isCaution: true),
                    _buildPanchRow('எமகண்டம் (Yamagandam)', 'பகல் 01:30 - 03:00', isCaution: true),
                    _buildPanchRow('குளிகை (Kuligai)', 'காலை 06:00 - 07:30'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Edit Approved Values Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: TNTColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('Edit Approved Panchangam Entry'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Panchangam editor locked to validated calculations provider.'), backgroundColor: TNTColors.primary),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanchRow(String label, String value, {bool isHighlight = false, bool isCaution = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isCaution ? Colors.redAccent : (isHighlight ? Colors.green[700] : TNTColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
