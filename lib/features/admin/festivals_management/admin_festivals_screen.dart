import 'package:flutter/material.dart';
import '../../repositories/panchang_repository.dart';
import '../../models/tnt_models.dart';

import '../../../core/constants/colors.dart';
import '../../../models/tnt_models.dart';
import '../repositories/admin_content_repository.dart';
import '../widgets/admin_form_widgets.dart';

/// Admin Festivals Management Screen
class AdminFestivalsScreen extends StatefulWidget {
  const AdminFestivalsScreen({super.key});

  @override
  _AdminFestivalsScreenState createState() => _AdminFestivalsScreenState();
}

class _AdminFestivalsScreenState extends State<AdminFestivalsScreen> {
  final AdminContentRepository _repo = AdminContentRepository();

  List<Festival> _festivals = [];
  bool _isLoading = true;
  final String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFestivals();
  }

  
  Future<void> _autoGenerateFestivals() async {
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

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Auto-generating festivals for current month...')));

      // Auto generate for current selected month
      final int year = _selectedYear;
      final int month = _selectedMonth;
      final daysInMonth = DateTime(year, month + 1, 0).day;

      for (int i = 1; i <= daysInMonth; i++) {
        final d = DateTime(year, month, i);
        try {
          final bundle = await repo.getDailyPanchangam(date: d, location: loc);
          
          // Custom heuristic for some major festivals based on tithi/month
          // For a real production app, you might map specific tithi+month to festival names
          // e.g. Chithirai Pournami, Thai Poosam, etc.
          final tithi = bundle.calendarDay.tithiTa;
          final nakshatra = bundle.calendarDay.nakshatraTa;
          final tamilMonth = bundle.calendarDay.tamilMonth;

          String? nameTa;
          String? nameEn;

          if (tamilMonth == 'சித்திரை' && tithi.contains('பௌர்ணமி')) { nameTa = 'சித்ரா பௌர்ணமி'; nameEn = 'Chitra Pournami'; }
          else if (tamilMonth == 'வைகாசி' && nakshatra.contains('விசாகம்')) { nameTa = 'வைகாசி விசாகம்'; nameEn = 'Vaikasi Visakam'; }
          else if (tamilMonth == 'ஆடி' && nakshatra.contains('கிருத்திகை')) { nameTa = 'ஆடிக் கிருத்திகை'; nameEn = 'Aadi Krithigai'; }
          else if (tamilMonth == 'தை' && nakshatra.contains('பூசம்')) { nameTa = 'தைப்பூசம்'; nameEn = 'Thai Poosam'; }
          else if (tamilMonth == 'பங்குனி' && nakshatra.contains('உத்திரம்')) { nameTa = 'பங்குனி உத்திரம்'; nameEn = 'Panguni Uthiram'; }
          else if (tamilMonth == 'மாசி' && tithi.contains('சதுர்த்தசி')) { nameTa = 'மகா சிவராத்திரி'; nameEn = 'Maha Shivaratri'; } // Approximate

          if (nameTa != null) {
            // Check if already exists in local list to avoid duplicates
            final exists = _festivals.any((f) => f.date.day == d.day && f.nameTa == nameTa);
            if (!exists) {
              final fst = Festival(
                id: 'fst--',
                date: d,
                name: nameEn!,
                nameTa: nameTa,
                type: 'hindu',
                typeTa: 'இந்து பண்டிகை',
                category: 'Festivals',
                categoryTa: 'பண்டிகைகள்',
                description: 'Auto-generated ',
                descriptionTa: 'தானியங்கி உருவாக்கம்',
              );
              await _repo.saveFestival(fst);
            }
          }
        } catch (e) {
          // ignore error for a single day
        }
      }

      await _loadFestivals(forceRefresh: true);
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

  Future<void> _loadFestivals({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    try {
      final data = await _repo.getAdminFestivals(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _festivals = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDeleteFestival(Festival fst) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TNTColors.surface,
        title: const Text('Delete Festival?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${fst.title}"?'),
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
        await _repo.deleteFestival(fst.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Festival deleted successfully'), backgroundColor: Colors.green));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        }
      }
      _loadFestivals();
    }
  }

  void _openFestivalForm([Festival? fest]) {
    final nameTaCtrl = TextEditingController(text: fest?.nameTa ?? '');
    final nameEnCtrl = TextEditingController(text: fest?.name ?? '');
    final descTaCtrl = TextEditingController(text: fest?.descriptionTa ?? '');
    final descEnCtrl = TextEditingController(text: fest?.description ?? '');
    DateTime selectedDate = fest?.date ?? DateTime.now();
    String category = fest?.category ?? 'Major Festival';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: TNTColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(fest == null ? 'Add Approved Festival' : 'Edit Festival', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminTextField(controller: nameTaCtrl, label: 'திருவிழா பெயர் (Tamil)', isRequired: true),
                  const SizedBox(height: 12),
                  AdminTextField(controller: nameEnCtrl, label: 'Festival Name (English)', isRequired: true),
                  const SizedBox(height: 12),
                  AdminDatePicker(
                    label: 'Festival Date',
                    selectedDate: selectedDate,
                    onDateSelected: (d) => setDialogState(() => selectedDate = d),
                  ),
                  const SizedBox(height: 12),
                  AdminDropdown<String>(
                    label: 'Category',
                    value: category,
                    items: {
                      'Major Festival',
                      'Temple Festival',
                      'Jayanthi',
                      'Government Holiday',
                      'Festivals',
                      category
                    }.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  AdminTextField(controller: descTaCtrl, label: 'விளக்கம் (Tamil)', maxLines: 2),
                  const SizedBox(height: 12),
                  AdminTextField(controller: descEnCtrl, label: 'Description (English)', maxLines: 2),
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

                  final saved = Festival(
                    id: fest?.id ?? 'fest-${DateTime.now().millisecondsSinceEpoch}',
                    nameTa: nameTaCtrl.text.trim(),
                    name: nameEnCtrl.text.trim(), type: 'hindu',
                    date: selectedDate,
                    descriptionTa: descTaCtrl.text.trim(),
                    description: descEnCtrl.text.trim(),
                    category: category,
                    isPublished: true,

                  );

                  await _repo.saveFestival(saved);
                  Navigator.of(ctx).pop();
                  _loadFestivals();
                },
                child: const Text('Save Festival'),
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
        title: const Text('Festivals Management', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TNTColors.textPrimary)),
        backgroundColor: TNTColors.surface,
        elevation: 0,
                actions: [
          
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: TNTColors.primary),
            tooltip: 'Auto Generate Festivals',
            onPressed: _autoGenerateFestivals,
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
            onPressed: () => _loadFestivals(forceRefresh: true),
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
            label: const Text('Add Festival', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () => _openFestivalForm(),
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
              itemCount: _festivals.length,
              itemBuilder: (context, index) {
                final fest = _festivals[index];
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
                        color: Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.celebration_rounded, color: Colors.orange, size: 22),
                    ),
                    title: Text(fest.nameTa, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fest.name, style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${fest.date.day}/${fest.date.month}/${fest.date.year}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: TNTColors.primary),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(color: TNTColors.background, borderRadius: BorderRadius.circular(4)),
                              child: Text(fest.category, style: const TextStyle(fontSize: 10, color: TNTColors.textMuted)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: TNTColors.primary),
                      onPressed: () => _openFestivalForm(fest),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
