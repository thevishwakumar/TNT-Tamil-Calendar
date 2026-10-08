import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';

import '../../../repositories/panchang_repository.dart';
import '../../../models/tnt_models.dart';
import '../../../core/constants/colors.dart';
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
      int count = 0;

      for (int i = 1; i <= daysInMonth; i++) {
        final d = DateTime(year, month, i);
        try {
          final bundle = await repo.getDailyPanchangam(date: d, location: loc);
          final tithi = bundle.calendarDay.tithiTa;
          final nakshatra = bundle.calendarDay.nakshatraTa;

          String? titleTa;
          String? titleEn;
          String category = 'special_day';
          
          if (tithi.contains('அமாவாசை')) { titleTa = 'அமாவாசை'; titleEn = 'Amavasai'; category = 'amavasai'; }
          else if (tithi.contains('பௌர்ணமி')) { titleTa = 'பௌர்ணமி'; titleEn = 'Pournami'; category = 'pournami'; }
          else if (tithi.contains('ஏகாதசி')) { titleTa = 'ஏகாதசி'; titleEn = 'Ekadashi'; category = 'ekadashi'; }
          else if (tithi.contains('திரயோதசி')) { titleTa = 'பிரதோஷம்'; titleEn = 'Pradosham'; category = 'pradosham'; }
          else if (tithi.contains('சதுர்த்தி')) { titleTa = 'சதுர்த்தி'; titleEn = 'Chaturthi'; category = 'chaturthi'; }
          else if (tithi.contains('சஷ்டி')) { titleTa = 'சஷ்டி'; titleEn = 'Sashti'; category = 'sashti'; }
          else if (nakshatra.contains('கிருத்திகை')) { titleTa = 'கிருத்திகை'; titleEn = 'Krithigai'; category = 'krithigai'; }
          else if (nakshatra.contains('திருவோணம்')) { titleTa = 'திருவோணம்'; titleEn = 'Thiruvonam'; category = 'special_day'; }
          else if (tithi.contains('சதுர்த்தசி') && (bundle.calendarDay.tamilMonth == 'மாசி')) { titleTa = 'மகா சிவராத்திரி'; titleEn = 'Maha Shivaratri'; category = 'shivaratri'; }

          if (titleTa != null) {
            // Check if already exists in local list to avoid duplicates
            final exists = _specialDays.any((s) => s.date.day == d.day && (s.titleTa == titleTa || s.title == titleEn));
            if (!exists) {
              final sp = SpecialDay(
                id: '',
                date: d,
                title: titleEn!,
                titleTa: titleTa,
                category: category,
                categoryTa: titleTa,
                isHoliday: false,
                description: 'Auto-generated $titleEn',
                descriptionTa: '$titleTa தானியங்கி உருவாக்கம்',
              );
              await _repo.saveSpecialDay(sp);
              count++;
            }
          }
        } catch (e) {
          debugPrint('Error generating special day for $d: $e');
        }
      }

      await _loadSpecialDays(forceRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Auto-generation complete! $count special days added.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _downloadCsvTemplate() {
    const templateContent =
        'date,name_tamil,name_english,category,description_tamil,description_english\n'
        '2026-10-14,பிரதோஷம்,Pradosham,pradosham,சிவபெருமான் வழிபாடு,Pradosha pooja window\n'
        '2026-10-28,சர்வ அமாவாசை,Amavasai,amavasai,முன்னோர் வழிபாடு,New Moon Day prayers\n'
        '2026-11-12,சஷ்டி விரதம்,Sashti,sashti,முருகப்பெருமான் வழிபாடு,Lord Murugan worship';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TNTColors.surface,
        title: const Text('Special Days CSV Template', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Required columns:\ndate (YYYY-MM-DD), name_tamil, name_english, category, description_tamil, description_english',
              style: TextStyle(fontSize: 12, color: TNTColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: TNTColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: TNTColors.border),
              ),
              child: const SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  templateContent,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: TNTColors.surface, foregroundColor: TNTColors.primary),
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy Template'),
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: templateContent));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSV Template copied to clipboard!')),
              );
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: TNTColors.primary, foregroundColor: Colors.white),
            icon: const Icon(Icons.share_rounded, size: 16),
            label: const Text('Share / Save'),
            onPressed: () {
              Navigator.of(ctx).pop();
              Share.share(templateContent, subject: 'special_days_template.csv');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _bulkUploadCsv() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TNTColors.surface,
        title: const Text('Bulk Upload Special Days', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('Choose how you want to import Special Days:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: TNTColors.surface, foregroundColor: TNTColors.primary),
            icon: const Icon(Icons.edit_note_rounded, size: 16),
            label: const Text('Paste CSV Text'),
            onPressed: () => Navigator.of(ctx).pop('paste'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: TNTColors.primary, foregroundColor: Colors.white),
            icon: const Icon(Icons.file_upload_rounded, size: 16),
            label: const Text('Select CSV File'),
            onPressed: () => Navigator.of(ctx).pop('file'),
          ),
        ],
      ),
    );

    if (choice == null) return;

    String? csvString;

    if (choice == 'file') {
      try {
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['csv', 'txt', 'xls', 'xlsx'],
        );

        if (result.isEmpty) return;

        final file = result.first;
        csvString = await file.xFile.readAsString();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File read error: $e')));
        }
        return;
      }
    } else if (choice == 'paste') {
      final ctrl = TextEditingController();
      final pasted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: TNTColors.surface,
          title: const Text('Paste CSV Content', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Columns: date, name_tamil, name_english, category, description_tamil, description_english', style: TextStyle(fontSize: 12, color: TNTColors.textSecondary)),
              const SizedBox(height: 10),
              TextField(
                controller: ctrl,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: '2026-10-14,பிரதோஷம்,Pradosham,pradosham,சிவபெருமான் வழிபாடு,Pradosha pooja',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: TNTColors.background,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: TNTColors.primary, foregroundColor: Colors.white),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Import'),
            ),
          ],
        ),
      );
      if (pasted == true && ctrl.text.trim().isNotEmpty) {
        csvString = ctrl.text.trim();
      }
    }

    if (csvString == null || csvString.trim().isEmpty) return;

    await _processAndImportSpecialDaysCsv(csvString);
  }

  Future<void> _processAndImportSpecialDaysCsv(String raw) async {
    setState(() => _isLoading = true);
    int imported = 0;
    int failed = 0;

    try {
      final lines = CsvDecoder().convert(raw);
      if (lines.isEmpty) {
        throw Exception('CSV content is empty');
      }

      final firstRow = lines.first.map((e) => e.toString().trim().toLowerCase()).toList();
      final hasHeader = firstRow.any((col) => col.contains('date') || col.contains('name') || col.contains('title'));
      final dataRows = hasHeader ? lines.sublist(1) : lines;

      int dateIdx = 0;
      int nameTaIdx = 1;
      int nameEnIdx = 2;
      int catIdx = 3;
      int descTaIdx = 4;
      int descEnIdx = 5;

      if (hasHeader) {
        for (int i = 0; i < firstRow.length; i++) {
          final col = firstRow[i];
          if (col.contains('date')) dateIdx = i;
          else if (col.contains('tamil') || col == 'name_ta' || col == 'title_ta') nameTaIdx = i;
          else if (col.contains('english') || col == 'name_en' || col == 'title_en') nameEnIdx = i;
          else if (col.contains('cat')) catIdx = i;
          else if (col.contains('desc') && (col.contains('ta') || col.contains('tamil'))) descTaIdx = i;
          else if (col.contains('desc')) descEnIdx = i;
        }
      }

      for (final row in dataRows) {
        if (row.isEmpty || row.every((c) => c.toString().trim().isEmpty)) continue;
        try {
          final dateStr = row.length > dateIdx ? row[dateIdx].toString().trim() : '';
          final date = DateTime.tryParse(dateStr);
          if (date == null) {
            failed++;
            continue;
          }

          final nameTa = row.length > nameTaIdx ? row[nameTaIdx].toString().trim() : '';
          final nameEn = row.length > nameEnIdx ? row[nameEnIdx].toString().trim() : '';
          final cat = row.length > catIdx ? row[catIdx].toString().trim() : 'special_day';
          final descTa = row.length > descTaIdx ? row[descTaIdx].toString().trim() : '';
          final descEn = row.length > descEnIdx ? row[descEnIdx].toString().trim() : '';

          if (nameTa.isEmpty && nameEn.isEmpty) {
            failed++;
            continue;
          }

          final sp = SpecialDay(
            id: '',
            date: date,
            title: nameEn.isNotEmpty ? nameEn : nameTa,
            titleTa: nameTa.isNotEmpty ? nameTa : nameEn,
            category: cat.isNotEmpty ? cat : 'special_day',
            categoryTa: nameTa,
            isHoliday: false,
            description: descEn,
            descriptionTa: descTa,
          );

          await _repo.saveSpecialDay(sp);
          imported++;
        } catch (e) {
          debugPrint('Row import error: $e');
          failed++;
        }
      }

      await _loadSpecialDays(forceRefresh: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import complete: $imported imported successfully${failed > 0 ? ', $failed failed' : ''}.'),
            backgroundColor: imported > 0 ? Colors.green[700] : Colors.red[700],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to parse CSV: $e'), backgroundColor: Colors.red[700]),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                    id: sp?.id ?? '',
                    titleTa: nameTaCtrl.text.trim(),
                    title: nameEnCtrl.text.trim(),
                    date: selectedDate,
                    descriptionTa: descTaCtrl.text.trim(),
                    description: descEnCtrl.text.trim(),
                    category: category,
                  );

                  try {
                    await _repo.saveSpecialDay(saved);
                    if (!ctx.mounted) return;
                    Navigator.of(ctx).pop();
                    _loadSpecialDays(forceRefresh: true);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Special Day saved successfully!')));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
                    }
                  }
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
            onPressed: _downloadCsvTemplate,
          ),
          IconButton(
            icon: const Icon(Icons.upload_file_rounded, color: TNTColors.primary),
            tooltip: 'Bulk Upload CSV',
            onPressed: _bulkUploadCsv,
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
