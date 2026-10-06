import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../models/tnt_models.dart';
import '../repositories/admin_content_repository.dart';
import '../widgets/admin_form_widgets.dart';
import 'admin_content_preview.dart';

/// Admin Create & Edit Content Form
class AdminContentFormScreen extends StatefulWidget {
  final ContentItem? initialItem;
  final VoidCallback onSaved;

  const AdminContentFormScreen({
    super.key,
    this.initialItem,
    required this.onSaved,
  });

  @override
  _AdminContentFormScreenState createState() => _AdminContentFormScreenState();
}

class _AdminContentFormScreenState extends State<AdminContentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminContentRepository _repo = AdminContentRepository();

  late final TextEditingController _titleTaController;
  late final TextEditingController _titleEnController;
  late final TextEditingController _descTaController;
  late final TextEditingController _descEnController;
  late final TextEditingController _mediaUrlController;

  String _category = 'POSTER';
  String _status = 'DRAFT';
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  int _priority = 0;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;

    _titleTaController = TextEditingController(text: item?.titleTamil ?? '');
    _titleEnController = TextEditingController(text: item?.titleEnglish ?? '');
    _descTaController = TextEditingController(text: item?.descriptionTamil ?? '');
    _descEnController = TextEditingController(text: item?.descriptionEnglish ?? '');
    _mediaUrlController = TextEditingController(
      text: item != null && item.mediaList.isNotEmpty ? item.mediaList.first.mediaUrl : '',
    );

    if (item != null) {
      _category = item.category;
      _status = item.status;
      _scheduledDate = item.publishAt;
      if (item.publishAt != null) {
        _scheduledTime = TimeOfDay(hour: item.publishAt!.hour, minute: item.publishAt!.minute);
      }
      _priority = item.priority;
    }
  }

  @override
  void dispose() {
    _titleTaController.dispose();
    _titleEnController.dispose();
    _descTaController.dispose();
    _descEnController.dispose();
    _mediaUrlController.dispose();
    super.dispose();
  }

  ContentItem _buildCurrentItem() {
    DateTime? publishTime;
    if (_status == 'PUBLISHED') {
      publishTime = DateTime.now();
    } else if (_status == 'SCHEDULED' && _scheduledDate != null) {
      final time = _scheduledTime ?? const TimeOfDay(hour: 9, minute: 0);
      publishTime = DateTime(
        _scheduledDate!.year,
        _scheduledDate!.month,
        _scheduledDate!.day,
        time.hour,
        time.minute,
      );
    }

    final mediaList = <ContentMedia>[];
    if (_mediaUrlController.text.trim().isNotEmpty) {
      mediaList.add(
        ContentMedia(
          id: 'media-local',
          contentId: widget.initialItem?.id ?? '',
          mediaType: _category == 'POSTER' ? 'POSTER' : 'IMAGE',
          mediaUrl: _mediaUrlController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    return ContentItem(
      id: widget.initialItem?.id ?? '',
      titleTamil: _titleTaController.text.trim(),
      titleEnglish: _titleEnController.text.trim(),
      descriptionTamil: _descTaController.text.trim().isNotEmpty ? _descTaController.text.trim() : null,
      descriptionEnglish: _descEnController.text.trim().isNotEmpty ? _descEnController.text.trim() : null,
      category: _category,
      status: _status,
      publishAt: publishTime,
      priority: _priority,
      createdBy: widget.initialItem?.createdBy ?? 'admin',
      createdAt: widget.initialItem?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      mediaList: mediaList,
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_status == 'SCHEDULED' && _scheduledDate == null) {
      setState(() {
        _errorMessage = 'Please select a scheduled date for publication';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final item = _buildCurrentItem();
      await _repo.saveContentItem(item);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.initialItem == null ? 'Content created successfully!' : 'Content updated successfully!'),
            backgroundColor: Colors.green[700],
          ),
        );
        widget.onSaved();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to save: $e';
        });
      }
    }
  }

  void _openPreview() {
    final item = _buildCurrentItem();
    showDialog(
      context: context,
      builder: (_) => AdminContentPreviewDialog(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.initialItem == null;

    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: AppBar(
        title: Text(
          isNew ? 'Create Content Item' : 'Edit Content Item',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
        ),
        backgroundColor: TNTColors.surface,
        elevation: 0,
        actions: [ const TNTBrandHeader(), 
          IconButton(
            tooltip: 'Live Preview',
            icon: const Icon(Icons.remove_red_eye_outlined, color: TNTColors.primary),
            onPressed: _openPreview,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: TNTColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Bilingual Fields Section
              Card(
                color: TNTColors.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: TNTColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.translate_rounded, size: 18, color: TNTColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'Bilingual Content Fields',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tamil Title
                      AdminTextField(
                        controller: _titleTaController,
                        label: 'தலைப்பு (Tamil Title)',
                        hint: 'எ.கா: புரட்டாசி சனிக்கிழமை சிறப்பு வழிபாடு',
                        isRequired: true,
                      ),
                      const SizedBox(height: 14),

                      // English Title
                      AdminTextField(
                        controller: _titleEnController,
                        label: 'English Title',
                        hint: 'e.g. Purattasi Saturday Special Pooja',
                        isRequired: true,
                      ),
                      const SizedBox(height: 14),

                      // Tamil Description
                      AdminTextField(
                        controller: _descTaController,
                        label: 'விளக்கம் (Tamil Description)',
                        hint: 'தமிழ் விவரங்களை உள்ளிடவும்...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),

                      // English Description
                      AdminTextField(
                        controller: _descEnController,
                        label: 'English Description',
                        hint: 'Enter English content details...',
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category & Status Settings Card
              Card(
                color: TNTColors.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: TNTColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Category & Media',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                      ),
                      const SizedBox(height: 14),

                      AdminDropdown<String>(
                        label: 'Content Category',
                        value: _category,
                        items: const [
                          DropdownMenuItem(value: 'POSTER', child: Text('POSTER (Daily Poster)')),
                          DropdownMenuItem(value: 'FESTIVAL', child: Text('FESTIVAL (Festival Announcement)')),
                          DropdownMenuItem(value: 'SPECIAL_DAY', child: Text('SPECIAL_DAY (Auspicious Observance)')),
                          DropdownMenuItem(value: 'MUHURTHAM', child: Text('MUHURTHAM (Marriage/Subha)')),
                          DropdownMenuItem(value: 'PANCHANGAM', child: Text('PANCHANGAM (Daily Timings)')),
                          DropdownMenuItem(value: 'ANNOUNCEMENT', child: Text('ANNOUNCEMENT (Temple Notice)')),
                          DropdownMenuItem(value: 'INFORMATION', child: Text('INFORMATION (General Info)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _category = val);
                        },
                      ),
                      const SizedBox(height: 14),

                      AdminTextField(
                        controller: _mediaUrlController,
                        label: 'Poster Image URL / Media Reference',
                        hint: 'https://images.unsplash.com/...',
                        helperText: 'Provide public Supabase Storage URL or approved poster asset',
                      ),
                      const SizedBox(height: 16),

                      // Workflow Status Selector
                      AdminStatusSelector(
                        status: _status,
                        onStatusChanged: (newStatus) => setState(() => _status = newStatus),
                      ),

                      // Scheduled Time Selectors if status == SCHEDULED
                      if (_status == 'SCHEDULED') ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: AdminDatePicker(
                                label: 'Scheduled Date',
                                selectedDate: _scheduledDate,
                                isRequired: true,
                                onDateSelected: (date) => setState(() => _scheduledDate = date),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AdminTimePicker(
                                label: 'Scheduled Time',
                                selectedTime: _scheduledTime,
                                onTimeSelected: (time) => setState(() => _scheduledTime = time),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TNTColors.textPrimary,
                        side: const BorderSide(color: TNTColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TNTColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isSaving ? null : _handleSave,
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isNew ? 'Create Content' : 'Save Changes'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
