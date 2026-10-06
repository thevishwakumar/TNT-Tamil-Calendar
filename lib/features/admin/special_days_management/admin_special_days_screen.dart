import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../models/tnt_models.dart';
import '../repositories/admin_content_repository.dart';
import '../widgets/admin_form_widgets.dart';
import '../services/admin_import_service.dart';

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
                    items: const [
                      DropdownMenuItem(value: 'Amavasai', child: Text('Amavasai (அமாவாசை)')),
                      DropdownMenuItem(value: 'Pournami', child: Text('Pournami (பௌர்ணமி)')),
                      DropdownMenuItem(value: 'Pradosham', child: Text('Pradosham (பிரதோஷம்)')),
                      DropdownMenuItem(value: 'Ekadashi', child: Text('Ekadashi (ஏகாதசி)')),
                      DropdownMenuItem(value: 'Sashti', child: Text('Sashti (சஷ்டி)')),
                      DropdownMenuItem(value: 'Sankatahara Chaturthi', child: Text('Sankatahara Chaturthi (சங்கடஹர சதுர்த்தி)')),
                      DropdownMenuItem(value: 'Krithigai', child: Text('Krithigai (கிருத்திகை)')),
                      DropdownMenuItem(value: 'Government Holiday', child: Text('Government Holiday (அரசு விடுமுறை)')),
                    ],
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

  Future<void> _handleImport() async {
    setState(() => _isLoading = true);
    final service = AdminImportService();
    final result = await service.pickAndImportSpecialDays();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.redAccent,
        ),
      );
      if (result.success) {
        _loadSpecialDays(forceRefresh: true);
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
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text('Special Days Management', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TNTColors.textPrimary)),
                    ),
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
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: TNTColors.primary),
                      onPressed: () => _openSpecialDayForm(sp),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
