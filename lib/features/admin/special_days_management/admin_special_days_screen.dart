import 'package:flutter/material.dart';
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
