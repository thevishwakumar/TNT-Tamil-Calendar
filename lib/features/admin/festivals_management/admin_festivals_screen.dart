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
          final tamilMonth = bundle.calendarDay.tamilMonth;

          String? nameTa;
          String? nameEn;
          String category = 'Festivals';
          String type = 'hindu';

          // Month-specific festivals
          if (tamilMonth == 'சித்திரை' && (tithi.contains('பௌர்ணமி') || nakshatra.contains('சித்திரை'))) {
            nameTa = 'சித்ரா பௌர்ணமி'; nameEn = 'Chitra Pournami';
          } else if (tamilMonth == 'வைகாசி' && nakshatra.contains('விசாகம்')) {
            nameTa = 'வைகாசி விசாகம்'; nameEn = 'Vaikasi Visakam';
          } else if (tamilMonth == 'ஆனி' && nakshatra.contains('உத்திரம்')) {
            nameTa = 'ஆனி திருமஞ்சனம்'; nameEn = 'Aani Thirumanjanam';
          } else if (tamilMonth == 'ஆடி' && nakshatra.contains('கிருத்திகை')) {
            nameTa = 'ஆடிக் கிருத்திகை'; nameEn = 'Aadi Krithigai';
          } else if (tamilMonth == 'ஆடி' && nakshatra.contains('பூரம்')) {
            nameTa = 'ஆடிப் பூரம்'; nameEn = 'Aadi Pooram';
          } else if (tamilMonth == 'ஆவணி' && tithi.contains('சதுர்த்தி')) {
            nameTa = 'விநாயகர் சதுர்த்தி'; nameEn = 'Vinayagar Chaturthi';
          } else if (tamilMonth == 'ஆவணி' && (nakshatra.contains('ரோகிணி') || tithi.contains('அஷ்டமி'))) {
            nameTa = 'ஸ்ரீ கிருஷ்ண ஜெயந்தி'; nameEn = 'Gokulashtami / Krishna Jayanthi';
          } else if (tamilMonth == 'புரட்டாசி' && tithi.contains('நவமி')) {
            nameTa = 'ஆயுத பூஜை / சரஸ்வதி பூஜை'; nameEn = 'Ayudha Pooja / Saraswathi Pooja';
          } else if (tamilMonth == 'புரட்டாசி' && tithi.contains('தசமி')) {
            nameTa = 'விஜயதசமி'; nameEn = 'Vijayadasami';
          } else if (tamilMonth == 'ஐப்பசி' && (tithi.contains('சதுர்த்தசி') || tithi.contains('அமாவாசை'))) {
            nameTa = 'தீபாவளி பண்டிகை'; nameEn = 'Deepavali'; category = 'Major Festival';
          } else if (tamilMonth == 'ஐப்பசி' && tithi.contains('சஷ்டி')) {
            nameTa = 'கந்த சஷ்டி சூரசம்ஹாரம்'; nameEn = 'Skanda Sashti';
          } else if (tamilMonth == 'கார்த்திகை' && (nakshatra.contains('கிருத்திகை') || tithi.contains('பௌர்ணமி'))) {
            nameTa = 'கார்த்திகை தீபம்'; nameEn = 'Karthigai Deepam'; category = 'Major Festival';
          } else if (tamilMonth == 'மார்கழி' && tithi.contains('ஏகாதசி')) {
            nameTa = 'வைகுண்ட ஏகாதசி'; nameEn = 'Vaikunta Ekadashi';
          } else if (tamilMonth == 'மார்கழி' && nakshatra.contains('திருவாதிரை')) {
            nameTa = 'ஆருத்ரா தரிசனம்'; nameEn = 'Arudra Darisanam';
          } else if (tamilMonth == 'தை' && nakshatra.contains('பூசம்')) {
            nameTa = 'தைப்பூசம்'; nameEn = 'Thai Poosam';
          } else if (tamilMonth == 'மாசி' && (tithi.contains('சதுர்த்தசி') || tithi.contains('திரயோதசி'))) {
            nameTa = 'மகா சிவராத்திரி'; nameEn = 'Maha Shivaratri';
          } else if (tamilMonth == 'மாசி' && nakshatra.contains('மகம்')) {
            nameTa = 'மாசி மகம்'; nameEn = 'Masi Magam';
          } else if (tamilMonth == 'பங்குனி' && (nakshatra.contains('உத்திரம்') || tithi.contains('பௌர்ணமி'))) {
            nameTa = 'பங்குனி உத்திரம்'; nameEn = 'Panguni Uthiram';
          }

          // Fixed dates (e.g. New Year, Pongal, Republic Day, Independence Day, Gandhi Jayanthi, Christmas)
          if (nameTa == null) {
            if (d.month == 1 && d.day == 1) { nameTa = 'ஆங்கில புத்தாண்டு'; nameEn = "New Year's Day"; category = 'Government Holiday'; type = 'government'; }
            else if (d.month == 1 && d.day == 14) { nameTa = 'தைப்பொங்கல்'; nameEn = 'Thai Pongal'; category = 'Major Festival'; type = 'government'; }
            else if (d.month == 1 && d.day == 15) { nameTa = 'மாட்டுப் பொங்கல்'; nameEn = 'Mattu Pongal'; category = 'Government Holiday'; type = 'government'; }
            else if (d.month == 1 && d.day == 16) { nameTa = 'காணும் பொங்கல் / உழவர் திருநாள்'; nameEn = 'Kaanum Pongal'; category = 'Government Holiday'; type = 'government'; }
            else if (d.month == 1 && d.day == 26) { nameTa = 'குடியரசு தினம்'; nameEn = 'Republic Day'; category = 'Government Holiday'; type = 'government'; }
            else if (d.month == 4 && d.day == 14) { nameTa = 'தமிழ்ப் புத்தாண்டு'; nameEn = 'Tamil New Year (Puthandu)'; category = 'Major Festival'; type = 'government'; }
            else if (d.month == 5 && d.day == 1) { nameTa = 'மே தினம் / உழைப்பாளர் தினம்'; nameEn = 'May Day'; category = 'Government Holiday'; type = 'government'; }
            else if (d.month == 8 && d.day == 15) { nameTa = 'சுதந்திர தினம்'; nameEn = 'Independence Day'; category = 'Government Holiday'; type = 'government'; }
            else if (d.month == 10 && d.day == 2) { nameTa = 'காந்தி ஜெயந்தி'; nameEn = 'Gandhi Jayanthi'; category = 'Government Holiday'; type = 'government'; }
            else if (d.month == 12 && d.day == 25) { nameTa = 'கிறிஸ்துமஸ் பண்டிகை'; nameEn = 'Christmas'; category = 'Major Festival'; type = 'christian'; }
          }

          if (nameTa != null) {
            final exists = _festivals.any((f) => f.date.day == d.day && (f.nameTa == nameTa || f.name == nameEn));
            if (!exists) {
              final fst = Festival(
                id: '',
                date: d,
                name: nameEn!,
                nameTa: nameTa,
                type: type,
                typeTa: type == 'government' ? 'அரசு விடுமுறை' : 'பண்டிகை',
                category: category,
                categoryTa: 'பண்டிகைகள்',
                description: 'Auto-generated $nameEn',
                descriptionTa: '$nameTa தானியங்கி உருவாக்கம்',
              );
              await _repo.saveFestival(fst);
              count++;
            }
          }
        } catch (e) {
          debugPrint('Error generating festival for $d: $e');
        }
      }

      await _loadFestivals(forceRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Auto-generation complete! $count festivals added.')));
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
        '2026-11-08,தீபாவளி,Deepavali,Festivals,மகிழ்ச்சி தரும் தீப ஒளித்திருநாள்,Festival of lights\n'
        '2026-11-23,கார்த்திகை தீபம்,Karthigai Deepam,Festivals,திருவண்ணாமலை மகா தீப தரிசனம்,Auspicious beacon of light\n'
        '2027-01-14,பொங்கல் திருநாள்,Thai Pongal,Government Holiday,தமிழர் திருநாள்,Harvest festival';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TNTColors.surface,
        title: const Text('Festivals CSV Template', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
              Share.share(templateContent, subject: 'festivals_template.csv');
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
        title: const Text('Bulk Upload Festivals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('Choose how you want to import Festivals:'),
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
                  hintText: '2026-11-08,தீபாவளி,Deepavali,Festivals,தீப ஒளித்திருநாள்,Festival of lights',
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

    await _processAndImportFestivalsCsv(csvString);
  }

  Future<void> _processAndImportFestivalsCsv(String raw) async {
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
          final cat = row.length > catIdx ? row[catIdx].toString().trim() : 'Festivals';
          final descTa = row.length > descTaIdx ? row[descTaIdx].toString().trim() : '';
          final descEn = row.length > descEnIdx ? row[descEnIdx].toString().trim() : '';

          if (nameTa.isEmpty && nameEn.isEmpty) {
            failed++;
            continue;
          }

          final fst = Festival(
            id: '',
            date: date,
            name: nameEn.isNotEmpty ? nameEn : nameTa,
            nameTa: nameTa.isNotEmpty ? nameTa : nameEn,
            category: cat.isNotEmpty ? cat : 'Festivals',
            type: cat.toLowerCase().contains('govt') || cat.toLowerCase().contains('holiday') ? 'government' : 'hindu',
            description: descEn,
            descriptionTa: descTa,
          );

          await _repo.saveFestival(fst);
          imported++;
        } catch (e) {
          debugPrint('Row import error: $e');
          failed++;
        }
      }

      await _loadFestivals(forceRefresh: true);

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
    final displayName = fst.nameTa.isNotEmpty ? fst.nameTa : fst.name;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TNTColors.surface,
        title: const Text('Delete Festival?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "$displayName" (${fst.name})?'),
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
        await _repo.deleteFestival(fst.id, festival: fst);
        if (mounted) {
          setState(() {
            _festivals.removeWhere((item) =>
                (item.id.isNotEmpty && item.id == fst.id) ||
                (item.date.year == fst.date.year &&
                    item.date.month == fst.date.month &&
                    item.date.day == fst.date.day &&
                    (item.nameTa == fst.nameTa || item.name == fst.name)));
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Festival "$displayName" deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        }
      }
      _loadFestivals(forceRefresh: true);
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
              if (fest != null)
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Delete'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _confirmDeleteFestival(fest);
                  },
                ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel', style: TextStyle(color: TNTColors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: TNTColors.primary, foregroundColor: Colors.white),
                onPressed: () async {
                  if (nameTaCtrl.text.trim().isEmpty || nameEnCtrl.text.trim().isEmpty) return;

                  final saved = Festival(
                    id: fest?.id ?? '',
                    nameTa: nameTaCtrl.text.trim(),
                    name: nameEnCtrl.text.trim(),
                    type: category.toLowerCase().contains('govt') || category.toLowerCase().contains('holiday') ? 'government' : 'hindu',
                    date: selectedDate,
                    descriptionTa: descTaCtrl.text.trim(),
                    description: descEnCtrl.text.trim(),
                    category: category,
                    isPublished: true,
                  );

                  try {
                    await _repo.saveFestival(saved);
                    if (!ctx.mounted) return;
                    Navigator.of(ctx).pop();
                    _loadFestivals(forceRefresh: true);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Festival saved successfully!')));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving festival: $e')));
                    }
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
            onPressed: _downloadCsvTemplate,
          ),
          IconButton(
            icon: const Icon(Icons.upload_file_rounded, color: TNTColors.primary),
            tooltip: 'Bulk Upload CSV',
            onPressed: _bulkUploadCsv,
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: TNTColors.primary),
                          tooltip: 'Edit',
                          onPressed: () => _openFestivalForm(fest),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                          tooltip: 'Delete',
                          onPressed: () => _confirmDeleteFestival(fest),
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
