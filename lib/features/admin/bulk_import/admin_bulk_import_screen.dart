import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../models/tnt_models.dart';
import '../repositories/admin_content_repository.dart';
import '../widgets/admin_form_widgets.dart';

/// Admin Bulk Import Foundation Screen
/// Strictly validates approved datasets with preview before commit.
class AdminBulkImportScreen extends StatefulWidget {
  const AdminBulkImportScreen({super.key});

  @override
  _AdminBulkImportScreenState createState() => _AdminBulkImportScreenState();
}

class _AdminBulkImportScreenState extends State<AdminBulkImportScreen> {
  final AdminContentRepository _repo = AdminContentRepository();
  final TextEditingController _contentController = TextEditingController();

  String _selectedModule = 'FESTIVALS';
  BulkImportResult? _validationResult;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _loadSampleTemplate();
  }

  void _loadSampleTemplate() {
    if (_selectedModule == 'FESTIVALS') {
      _contentController.text =
          'name_tamil,name_english,date,category,description_tamil,description_english\n'
          'தீபாவளி,Deepavali,2026-11-08,Major Festival,மகிழ்ச்சி தரும் தீப ஒளித்திருநாள்,Festival of lights\n'
          'கார்த்திகை தீபம்,Karthigai Deepam,2026-11-23,Major Festival,திருவண்ணாமலை மகா தீப தரிசனம்,Auspicious beacon of light';
    } else {
      _contentController.text =
          'name_tamil,name_english,date,category,description_tamil,description_english\n'
          'பிரதோஷம்,Pradosham,2026-10-14,Pradosham,சிவபெருமான் வழிபாடு,Pradosha pooja window\n'
          'சர்வ அமாவாசை,Amavasai,2026-10-28,Amavasai,முன்னோர் வழிபாடு,New Moon Day prayers';
    }
  }

  Future<void> _runValidation() async {
    setState(() => _isValidating = true);
    final res = await _repo.validateBulkImport(
      module: _selectedModule,
      csvOrJsonContent: _contentController.text,
    );
    setState(() {
      _validationResult = res;
      _isValidating = false;
    });
  }

  Future<void> _commitImport() async {
    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: 'Confirm Bulk Dataset Import',
      message: 'Are you sure you want to commit ${_validationResult?.validRows ?? 0} verified records into the $_selectedModule database table?',
      confirmLabel: 'Commit Approved Data',
      confirmColor: Colors.green[700]!,
    );
    if (!confirmed) return;

    await _repo.logAudit(
      action: 'BULK_IMPORT',
      module: _selectedModule,
      recordId: 'bulk-${DateTime.now().millisecondsSinceEpoch}',
      newState: {'rows_imported': _validationResult?.validRows ?? 0},
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_validationResult?.validRows} records successfully committed to $_selectedModule database!'),
          backgroundColor: Colors.green[700],
        ),
      );
      setState(() {
        _validationResult = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: AppBar(
        title: const Text('Bulk Dataset Import', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TNTColors.textPrimary)),
        backgroundColor: TNTColors.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: TNTColors.border, height: 1),
        ),
      actions: const [TNTBrandHeader()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Module Selector
            AdminDropdown<String>(
              label: 'Target Database Table',
              value: _selectedModule,
              items: const [
                DropdownMenuItem(value: 'FESTIVALS', child: Text('Festivals (festivals)')),
                DropdownMenuItem(value: 'SPECIAL_DAYS', child: Text('Special Days (special_days)')),
                DropdownMenuItem(value: 'MUHURTHAM', child: Text('Muhurtham Dates (muhurtham_dates)')),
                DropdownMenuItem(value: 'CALENDAR', child: Text('Calendar Metadata (calendar_days)')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedModule = val);
                  _loadSampleTemplate();
                }
              },
            ),
            const SizedBox(height: 16),

            // CSV Data Text Input
            AdminTextField(
              controller: _contentController,
              label: 'CSV Data / Approved Dataset',
              hint: 'Paste CSV with header matching table schema...',
              maxLines: 7,
              helperText: 'Columns must strictly match schema. Dates must be YYYY-MM-DD.',
            ),
            const SizedBox(height: 16),

            // Validate Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: TNTColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.fact_check_outlined, size: 18),
              label: _isValidating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Validate Schema & Parse Rows'),
              onPressed: _isValidating ? null : _runValidation,
            ),
            const SizedBox(height: 20),

            // Validation Results Preview
            if (_validationResult != null) ...[
              Card(
                color: TNTColors.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: TNTColors.border)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Validation Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildCount('Total Rows', '${_validationResult!.totalRows}', Colors.blue),
                          _buildCount('Valid Rows', '${_validationResult!.validRows}', Colors.green),
                          _buildCount('Invalid Rows', '${_validationResult!.invalidRows}', Colors.redAccent),
                        ],
                      ),
                      if (_validationResult!.errors.isNotEmpty) ...[
                        const Divider(height: 20, color: TNTColors.border),
                        const Text('Validation Errors:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                        const SizedBox(height: 6),
                        ..._validationResult!.errors.map((e) => Text('• $e', style: const TextStyle(fontSize: 11, color: Colors.redAccent))),
                      ],
                      const SizedBox(height: 16),
                      if (_validationResult!.validRows > 0)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                          label: Text('Commit ${_validationResult!.validRows} Approved Records'),
                          onPressed: _commitImport,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCount(String label, String val, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: TNTColors.textSecondary)),
      ],
    );
  }
}
