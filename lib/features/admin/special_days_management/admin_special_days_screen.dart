import 'package:flutter/material.dart';
import '../../../repositories/panchang_repository.dart';
import '../../../models/tnt_models.dart';

import '../../../core/constants/colors.dart';
import '../../../models/tnt_models.dart';
import '../repositories/admin_content_repository.dart';
import '../widgets/admin_form_widgets.dart';

/// Admin Special Days Management Screen (Pradosham, Amavasai, Pournami, Ekadasi, etc.)
class AdminSpecialDaysScreen extends StatefulWidget {
  const AdminSpecialDaysScreen({super.key});

  @override
  _AdminSpecialDaysScreenState createState() => _AdminSpecialDaysScreenState();
}

class _AdminSpecialDaysScreenState extends State<AdminSpecialDaysScreen> {
  final AdminContentRepository _repo = AdminContentRepository();

  List<SpecialDay> _specialDays = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSpecialDays();
  }

  
  Future<void> _autoGenerateSpecialDays() async {
    setState(() => _isLoading = true);
    try {
      final repo = PanchangRepository();
      final loc = UserLocationItem(
        id: 'loc-Chennai',
        userId: 'admin',
        name: 'Chennai',
        city: 'Chennai',
        timezone: 'Asia/Kolkata',
        createdAt: DateTime.now(),
      );

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Auto-generating special days for current month...')));

      // Auto generate for current selected month
      final int year = DateTime.now().year;
      final int month = DateTime.now().month;
      final daysInMonth = DateTime(year, month + 1, 0).day;

      for (int i = 1; i <= daysInMonth; i++) {
        final d = DateTime(year, month, i);
        try {
          final bundle = await repo.getDailyPanchangam(date: d, location: loc);
          final tithi = bundle.calendarDay.tithiTa;
          final nakshatra = bundle.calendarDay.nakshatraTa;

          String? titleTa;
          String? titleEn;
          
          if (tithi.contains('அமாவாசை')) { titleTa = 'அமாவாசை'; titleEn = 'Amavasai'; }
          else if (tithi.contains('பௌர்ணமி')) { titleTa = 'பௌர்ணமி'; titleEn = 'Pournami'; }
          else if (tithi.contains('ஏகாதசி')) { titleTa = 'ஏகாதசி'; titleEn = 'Ekadashi'; }
          else if (tithi.contains('திரயோதசி')) { titleTa = 'பிரதோஷம்'; titleEn = 'Pradosham'; }
          else if (tithi.contains('சதுர்த்தி')) { titleTa = 'சதுர்த்தி'; titleEn = 'Chaturthi'; }
          else if (tithi.contains('சஷ்டி')) { titleTa = 'சஷ்டி'; titleEn = 'Sashti'; }
          else if (nakshatra.contains('கிருத்திகை')) { titleTa = 'கிருத்திகை'; titleEn = 'Krithigai'; }
          else if (nakshatra.contains('திருவோணம்')) { titleTa = 'திருவோணம்'; titleEn = 'Thiruvonam'; }

          if (titleTa != null) {
            // Check if already exists in local list to avoid extreme duplicates
            final exists = _specialDays.any((s) => s.date.day == d.day && s.titleTa == titleTa);
            if (!exists) {
              final sp = SpecialDay(
                id: 'sp--',
                date: d,
                title: titleEn!,
                titleTa: titleTa,
                category: 'special_day',
                categoryTa: 'சிறப்பு நாள்',
                isHoliday: false,
                description: 'Auto-generated ',
                descriptionTa: 'தானியங்கி உருவாக்கம்',
              );
              await _repo.saveSpecialDay(sp);
            }
          }
        } catch (e) {
          // ignore error for a single day
        }
      }

      await _loadSpecialDays(forceRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Auto-generation complete!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSpecialDays({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    try {
      final data = await _repo.getAdminSpecialDays(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _specialDays = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDeleteSpecialDay(SpecialDay sp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TNTColors.surface,
        title: const Text('Delete Special Day?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${sp.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: TNTColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _repo.deleteSpecialDay(sp.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Special day deleted successfully'), backgroundColor: Colors.green));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        }
      }
      _loadSpecialDays();
    }
  }



  void _openSpecialDayForm([SpecialDay? sp]) {
    final nameTaCtrl = TextEditingController(text: sp?.titleTa ?? '');
    final nameEnCtrl = TextEditingController(text: sp?.title ?? '');
    final descTaCtrl = TextEditingController(text: sp?.descriptionTa ?? '');
    final descEnCtrl = TextEditingController(text: sp?.description ?? '');
    DateTime selectedDate = sp?.date ?? DateTime.now();
    String category = sp?.category ?? 'Pradosham';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: TNTColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(sp == null ? 'Add Special Observance Day' : 'Edit Special Day', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminTextField(controller: nameTaCtrl, label: 'சிறப்பு நாள் பெயர் (Tamil)', isRequired: true),
                  const SizedBox(height: 12),
                  AdminTextField(controller: nameEnCtrl, label: 'Special Day Name (English)', isRequired: true),
                  const SizedBox(height: 12),
                  AdminDatePicker(
                    label: 'Observance Date',
                    selectedDate: selectedDate,
                    onDateSelected: (d) => setDialogState(() => selectedDate = d),
                  ),
                  const SizedBox(height: 12),
                  AdminDropdown<String>(
                    label: 'Observance Category',
                    value: category,
                    items: {
                      'Amavasai',
                      'Pournami',
                      'Pradosham',
                      'Ekadashi',
                      'Sashti',
                      'Sankatahara Chaturthi',
                      'Krithigai',
                      'Government Holiday',
                      category
                    }.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  AdminTextField(controller: descTaCtrl, label: 'விரத முறை / விளக்கம் (Tamil)', maxLines: 2),
                  const SizedBox(height: 12),
                  AdminTextField(controller: descEnCtrl, label: 'Ritual Notes (English)', maxLines: 2),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel', style: TextStyle(color: TNTColors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: TNTColors.primary, foregroundColor: Colors.white),
                onPressed: () async {
                  if (nameTaCtrl.text.trim().isEmpty || nameEnCtrl.text.trim().isEmpty) return;

                  final saved = SpecialDay(
                    isHoliday: false,
                    id: sp?.id ?? 'sp-${DateTime.now().millisecondsSinceEpoch}',
                    titleTa: nameTaCtrl.text.trim(),
                    title: nameEnCtrl.text.trim(),
                    date: selectedDate,
                    descriptionTa: descTaCtrl.text.trim(),
                    description: descEnCtrl.text.trim(),
                    category: category,
                    // isApproved: true,
                  );

                  await _repo.saveSpecialDay(saved);
                  Navigator.of(ctx).pop();
                  _loadSpecialDays();
                },
                child: const Text('Save Special Day'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: AppBar(
        title: const Text('Special Days Management', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TNTColors.textPrimary)),
        backgroundColor: TNTColors.surface,
        elevation: 0,
                actions: [
          
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: TNTColors.primary),
            tooltip: 'Auto Generate Special Days',
            onPressed: _autoGenerateSpecialDays,
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: TNTColors.primary),
            tooltip: 'Download CSV Template',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSV Format: date (YYYY-MM-DD), name_ta, name_en, category, desc_ta, desc_en')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.upload_file_rounded, color: TNTColors.primary),
            tooltip: 'Bulk Upload CSV',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Use Bulk Import tool in Admin Settings for large uploads.')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: TNTColors.primary),
            onPressed: () => _loadSpecialDays(forceRefresh: true),
            tooltip: 'Refresh',
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: TNTColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add Special Day', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () => _openSpecialDayForm(),
          ),
          const SizedBox(width: 12),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: TNTColors.border, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: TNTColors.primary))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _specialDays.length,
              itemBuilder: (context, index) {
                final sp = _specialDays[index];
                return Card(
                  color: TNTColors.surface,
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: TNTColors.border),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.star_rounded, color: Colors.purple, size: 22),
                    ),
                    title: Text(sp.titleTa, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sp.title, style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${sp.date.day}/${sp.date.month}/${sp.date.year}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: TNTColors.primary),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(color: TNTColors.background, borderRadius: BorderRadius.circular(4)),
                              child: Text(sp.category, style: const TextStyle(fontSize: 10, color: TNTColors.textMuted)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: TNTColors.primary),
                          tooltip: 'Edit',
                          onPressed: () => _openSpecialDayForm(sp),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                          tooltip: 'Delete',
                          onPressed: () => _confirmDeleteSpecialDay(sp),
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
