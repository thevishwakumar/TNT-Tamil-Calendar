import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../models/tnt_models.dart';
import '../../../repositories/tnt_repositories.dart';
import '../repositories/admin_content_repository.dart';
import '../widgets/admin_form_widgets.dart';
import '../services/admin_import_service.dart';

/// Admin Muhurtham Management Screen (Marriage & Auspicious Dates)
class AdminMuhurthamScreen extends StatefulWidget {
  const AdminMuhurthamScreen({super.key});

  @override
  _AdminMuhurthamScreenState createState() => _AdminMuhurthamScreenState();
}

class _AdminMuhurthamScreenState extends State<AdminMuhurthamScreen> {
  final AdminContentRepository _repo = AdminContentRepository();

  List<MuhurthamDate> _muhurthams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMuhurthams();
  }

  Future<void> _loadMuhurthams({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    final now = DateTime.now();
    try {
      _muhurthams = await MuhurthamRepository().fetchMuhurthamDates(year: now.year, month: now.month, forceRefresh: forceRefresh);
    } catch (e) {
      debugPrint('Failed to load Muhurthams: $e');
      _muhurthams = [];
    }
    setState(() => _isLoading = false);
  }

  void _openMuhurthamForm([MuhurthamDate? m]) {
    final timingCtrl = TextEditingController(text: 'காலை 09:00 - 10:30' ?? 'காலை 09:00 - 10:30');
    final lagnamCtrl = TextEditingController(text: m?.lagnam ?? 'துலா லக்னம்');
    final nakshatraCtrl = TextEditingController(text: m?.nakshatra ?? 'ரோகிணி');
    final tithiCtrl = TextEditingController(text: m?.tithi ?? 'வளர்பிறை துவிதியை');
    final descCtrl = TextEditingController(text: m?.description ?? '');
    DateTime selectedDate = m?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: TNTColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(m == null ? 'Add Approved Muhurtham' : 'Edit Muhurtham', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminDatePicker(
                    label: 'Muhurtham Date',
                    selectedDate: selectedDate,
                    onDateSelected: (d) => setDialogState(() => selectedDate = d),
                  ),
                  const SizedBox(height: 12),
                  AdminTextField(controller: timingCtrl, label: 'சுப நேரம் (Timing)', isRequired: true),
                  const SizedBox(height: 12),
                  AdminTextField(controller: lagnamCtrl, label: 'லக்னம் (Lagnam)', isRequired: true),
                  const SizedBox(height: 12),
                  AdminTextField(controller: nakshatraCtrl, label: 'நட்சத்திரம் (Nakshatra)', isRequired: true),
                  const SizedBox(height: 12),
                  AdminTextField(controller: tithiCtrl, label: 'திதி (Tithi)', isRequired: true),
                  const SizedBox(height: 12),
                  AdminTextField(controller: descCtrl, label: 'குறிப்புகள் / Notes', maxLines: 2),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel', style: TextStyle(color: TNTColors.textSecondary))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: TNTColors.primary, foregroundColor: Colors.white),
                onPressed: () async {
                  try {
                    final savedDate = await _repo.saveMuhurthamDate(MuhurthamDate(
                      id: m?.id ?? '',
                      date: selectedDate,
                      tamilDateStr: '', // Not used for insert
                      category: 'Marriage',
                      categoryTa: 'முகூர்த்தம்',
                      description: descCtrl.text.trim(),
                      descriptionTa: descCtrl.text.trim(),
                    ));
                    
                    final timingStr = timingCtrl.text.trim().split('-');
                    final st = timingStr.isNotEmpty ? timingStr[0].trim() : '09:00 AM';
                    final et = timingStr.length > 1 ? timingStr[1].trim() : '10:30 AM';
                    
                    await _repo.saveMuhurthamTiming(
                      savedDate.id,
                      MuhurthamTimingItem(
                        id: (m != null && m.timings.isNotEmpty) ? m.timings.first.id : '',
                        startTime: st,
                        endTime: et,
                        lagnam: lagnamCtrl.text.trim(),
                        nakshatra: nakshatraCtrl.text.trim(),
                      ),
                      isNew: (m == null || m.timings.isEmpty),
                    );

                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved successfully'), backgroundColor: Colors.green),
                    );
                    _loadMuhurthams(forceRefresh: true);
                  } catch (e) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
                    );
                  }
                },
                child: const Text('Save Muhurtham'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleImport() async {
    setState(() => _isLoading = true);
    final service = AdminImportService();
    final result = await service.pickAndImportMuhurtham();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.redAccent,
        ),
      );
      if (result.success) {
        _loadMuhurthams(forceRefresh: true);
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TNTColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: TNTColors.primary))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _muhurthams.length,
              itemBuilder: (context, index) {
                final m = _muhurthams[index];
                return Card(
                  color: TNTColors.surface,
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: TNTColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text('Muhurtham Management', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TNTColors.textPrimary)),
                    ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${m.tamilMonth}  (${m.date.day}/${m.date.month}/${m.date.year})',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: TNTColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                              child: Text(m.category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: TNTColors.primary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text('நேரம்: காலை', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                        Text('லக்னம்: ${m.lagnam} | நட்சத்திரம்: ${m.nakshatra}', style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary)),
                        if (m.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(m.description, style: const TextStyle(fontSize: 11, color: TNTColors.textMuted)),
                        ],
                        const Divider(height: 14, color: TNTColors.border),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.edit_outlined, size: 14),
                              label: const Text('Edit Timing & Lagnam', style: TextStyle(fontSize: 11)),
                              onPressed: () => _openMuhurthamForm(m),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
