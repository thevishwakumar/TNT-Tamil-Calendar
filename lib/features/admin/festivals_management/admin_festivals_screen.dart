import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../models/tnt_models.dart';
import '../repositories/admin_content_repository.dart';
import '../widgets/admin_form_widgets.dart';
import '../services/admin_import_service.dart';

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
                    items: const [
                      DropdownMenuItem(value: 'Major Festival', child: Text('Major Festival')),
                      DropdownMenuItem(value: 'Temple Festival', child: Text('Temple Festival')),
                      DropdownMenuItem(value: 'Jayanthi', child: Text('Jayanthi / Avatar')),
                      DropdownMenuItem(value: 'Government Holiday', child: Text('Government Holiday')),
                    ],
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

                  try {
                    await _repo.saveFestival(saved);
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Festival saved successfully'), backgroundColor: Colors.green),
                    );
                    _loadFestivals(forceRefresh: true);
                  } catch (e) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to save festival: $e'), backgroundColor: Colors.red),
                    );
                  }
                },
                child: const Text('Save Festival'),
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
    final result = await service.pickAndImportFestivals();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.redAccent,
        ),
      );
      if (result.success) {
        _loadFestivals(forceRefresh: true);
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TNTColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: TNTColors.primary,
        onPressed: () => _openFestivalForm(null),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: TNTColors.primary))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Festivals Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TNTColors.textPrimary)),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.file_upload, size: 18),
                        label: const Text('Import'),
                        onPressed: _handleImport,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _festivals.isEmpty
                      ? const Center(
                          child: Text(
                            'No Festivals found.\nTap + to add one.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: TNTColors.textMuted, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
