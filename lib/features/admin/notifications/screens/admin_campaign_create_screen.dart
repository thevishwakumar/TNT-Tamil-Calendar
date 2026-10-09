import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../models/tnt_models.dart';
import '../../widgets/admin_form_widgets.dart';
import '../repositories/admin_campaign_repository.dart';
import '../services/notification_deep_link_router.dart';
import '../widgets/admin_notification_preview_dialog.dart';

/// Admin Campaign Create & Edit Screen
class AdminCampaignCreateScreen extends StatefulWidget {
  final NotificationCampaign? initialCampaign;
  final VoidCallback onSaved;

  const AdminCampaignCreateScreen({
    super.key,
    this.initialCampaign,
    required this.onSaved,
  });

  @override
  State<AdminCampaignCreateScreen> createState() => _AdminCampaignCreateScreenState();
}

class _AdminCampaignCreateScreenState extends State<AdminCampaignCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminCampaignRepository _repository = AdminCampaignRepository();

  late TextEditingController _titleController;
  late TextEditingController _titleTaController;
  late TextEditingController _titleEnController;
  late TextEditingController _bodyTaController;
  late TextEditingController _bodyEnController;
  late TextEditingController _deepLinkController;
  late TextEditingController _mediaUrlController;

  String _selectedLanguageTab = 'ta'; // 0: Tamil, 1: English
  String _selectedCategory = 'MUHURTHAM';
  String _selectedAudience = 'all_eligible';
  bool _sendImmediately = true;
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _scheduledTime = const TimeOfDay(hour: 9, minute: 0);

  bool _isSaving = false;
  int _estimatedAudience = 1;

  final List<String> _categories = [
    'PANCHANGAM',
    'MUHURTHAM',
    'FESTIVAL',
    'SPECIAL_DAY',
    'REMINDER',
    'IMPORTANT_UPDATE',
    'ANNOUNCEMENT',
    'MARKETING',
  ];

  final List<Map<String, String>> _audienceOptions = [
    {'value': 'all_eligible', 'label': 'All Eligible Users (Respects Preferences)'},
    {'value': 'opt_in_marketing', 'label': 'Marketing Consent Opt-Ins Only'},
    {'value': 'active_users', 'label': 'Active Users (Last 30 Days)'},
    {'value': 'category_subscribers', 'label': 'Category Subscribers Only'},
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.initialCampaign;
    _titleController = TextEditingController(text: c?.title ?? '');
    _titleTaController = TextEditingController(text: c?.titleTamil ?? '');
    _titleEnController = TextEditingController(text: c?.titleEnglish ?? '');
    _bodyTaController = TextEditingController(text: c?.messageTamil ?? '');
    _bodyEnController = TextEditingController(text: c?.messageEnglish ?? '');
    _deepLinkController = TextEditingController(text: c?.deepLink ?? 'tnt://muhurtham');
    _mediaUrlController = TextEditingController(text: c?.mediaReference ?? '');

    if (c != null) {
      _selectedCategory = c.category.toUpperCase();
      _selectedAudience = c.audienceType;
      if (c.scheduledAt != null) {
        _sendImmediately = false;
        _scheduledDate = c.scheduledAt!;
        _scheduledTime = TimeOfDay(hour: c.scheduledAt!.hour, minute: c.scheduledAt!.minute);
      }
    }

    _updateAudienceEstimate();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleTaController.dispose();
    _titleEnController.dispose();
    _bodyTaController.dispose();
    _bodyEnController.dispose();
    _deepLinkController.dispose();
    _mediaUrlController.dispose();
    super.dispose();
  }

  Future<void> _updateAudienceEstimate() async {
    final count = await _repository.calculateAudienceSize(_selectedAudience, _selectedCategory);
    if (mounted) {
      setState(() {
        _estimatedAudience = count;
      });
    }
  }

  NotificationCampaign _buildCampaignObject({String status = 'DRAFT'}) {
    final schedDateTime = DateTime(
      _scheduledDate.year,
      _scheduledDate.month,
      _scheduledDate.day,
      _scheduledTime.hour,
      _scheduledTime.minute,
    );

    final titleEn = _titleEnController.text.trim();
    final titleTa = _titleTaController.text.trim();
    final titleGen = _titleController.text.trim();
    final effectiveTitle = titleEn.isNotEmpty
        ? titleEn
        : (titleTa.isNotEmpty ? titleTa : (titleGen.isNotEmpty ? titleGen : 'Notification'));
    final effectiveTitleTa = titleTa.isNotEmpty ? titleTa : effectiveTitle;
    final effectiveTitleEn = titleEn.isNotEmpty ? titleEn : effectiveTitle;

    final bodyEn = _bodyEnController.text.trim();
    final bodyTa = _bodyTaController.text.trim();
    final effectiveBody = bodyEn.isNotEmpty ? bodyEn : (bodyTa.isNotEmpty ? bodyTa : '');
    final effectiveBodyTa = bodyTa.isNotEmpty ? bodyTa : effectiveBody;
    final effectiveBodyEn = bodyEn.isNotEmpty ? bodyEn : effectiveBody;

    return NotificationCampaign(
      id: widget.initialCampaign?.id ?? 'camp-${DateTime.now().millisecondsSinceEpoch}',
      title: effectiveTitle,
      titleTamil: effectiveTitleTa,
      titleEnglish: effectiveTitleEn,
      body: effectiveBody,
      messageTamil: effectiveBodyTa,
      messageEnglish: effectiveBodyEn,
      category: _selectedCategory,
      audienceType: _selectedAudience,
      status: status,
      scheduledAt: _sendImmediately ? null : schedDateTime,
      deepLink: _deepLinkController.text.isNotEmpty ? _deepLinkController.text : null,
      mediaReference: _mediaUrlController.text.isNotEmpty ? _mediaUrlController.text : null,
      createdBy: 'dev-admin-id',
      createdAt: widget.initialCampaign?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  void _handlePreview() {
    final previewCamp = _buildCampaignObject();
    showDialog(
      context: context,
      builder: (_) => AdminNotificationPreviewDialog(campaign: previewCamp),
    );
  }

  Future<void> _handleSaveDraft() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final camp = _buildCampaignObject(status: 'DRAFT');
      if (widget.initialCampaign != null) {
        await _repository.updateCampaign(camp);
      } else {
        await _repository.createCampaign(camp);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign draft saved successfully!')),
        );
        widget.onSaved();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save draft: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleScheduleOrSend() async {
    if (!_formKey.currentState!.validate()) return;

    if (_sendImmediately) {
      // Immediate send requires explicit confirmation dialog
      final confirmed = await showAdminConfirmDialog(
        context: context,
        title: 'Dispatch Campaign Immediately?',
        message: 'This action will instantly send notifications to $_estimatedAudience eligible devices through the secure FCM pipeline. Marketing consent and user notification category settings will be strictly enforced.',
        confirmLabel: 'Send Campaign Now',
        confirmColor: const Color(0xFFF44336),
      );

      if (confirmed != true) return;

      setState(() => _isSaving = true);
      try {
        final camp = _buildCampaignObject(status: 'DRAFT');
        final created = widget.initialCampaign != null
            ? await _repository.updateCampaign(camp)
            : await _repository.createCampaign(camp);

        await _repository.sendCampaignNow(created.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Campaign dispatched successfully via secure FCM pipeline!'), backgroundColor: Colors.green),
          );
          widget.onSaved();
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delivery error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    } else {
      // Schedule for future
      setState(() => _isSaving = true);
      try {
        final camp = _buildCampaignObject(status: 'SCHEDULED');
        if (widget.initialCampaign != null) {
          await _repository.updateCampaign(camp);
        } else {
          await _repository.createCampaign(camp);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Campaign scheduled successfully for automated server-side dispatch!'), backgroundColor: Colors.green),
          );
          widget.onSaved();
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Scheduling error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialCampaign != null;

    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Campaign' : 'Create Notification Campaign',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
        ),
        backgroundColor: TNTColors.surface,
        elevation: 0,
        actions: [  
          IconButton(
            tooltip: 'Live Preview',
            icon: const Icon(Icons.preview_rounded, color: TNTColors.primary),
            onPressed: _handlePreview,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: TNTColors.border, height: 1),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Security & Consent Guidance Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TNTColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: TNTColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: TNTColors.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Server-Side Delivery & Consent Enforcement',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TNTColors.primary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedCategory == 'MARKETING'
                                ? 'Marketing campaigns are strictly restricted to users who explicitly opt in. Default = OFF.'
                                : 'Push alerts will only be delivered to users who have enabled the "$_selectedCategory" notification category.',
                            style: const TextStyle(fontSize: 11, color: TNTColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Campaign Settings Card
              Card(
                color: TNTColors.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: TNTColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '1. Campaign Category & Audience',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                      ),
                      const SizedBox(height: 14),

                      // Category Dropdown
                      AdminDropdown<String>(
                        label: 'Notification Category',
                        value: _selectedCategory,
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCategory = val;
                              if (val == 'MARKETING') {
                                _selectedAudience = 'opt_in_marketing';
                              }
                            });
                            _updateAudienceEstimate();
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // Audience Dropdown
                      AdminDropdown<String>(
                        label: 'Target Audience Scope',
                        value: _selectedAudience,
                        items: _audienceOptions.map((opt) => DropdownMenuItem(value: opt['value'], child: Text(opt['label']!))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedAudience = val);
                            _updateAudienceEstimate();
                          }
                        },
                      ),
                      const SizedBox(height: 8),

                      // Audience Count Indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: TNTColors.background,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: TNTColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.people_alt_rounded, size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              'Estimated Eligible Recipients: $_estimatedAudience user(s)',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bilingual Message Content Card
              Card(
                color: TNTColors.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: TNTColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '2. Bilingual Notification Content',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                      ),
                      const SizedBox(height: 12),

                      AdminLanguageTabs(
                        currentLang: _selectedLanguageTab,
                        onLanguageChanged: (idx) => setState(() => _selectedLanguageTab = idx),
                      ),
                      const SizedBox(height: 16),

                      if (_selectedLanguageTab == 'ta') ...[
                        // Tamil Fields
                        AdminTextField(
                          controller: _titleTaController,
                          label: 'அறிவிப்பு தலைப்பு (Tamil Title)',
                          hint: 'எ.கா. நாளை சுப முகூர்த்த நாள்',
                          isRequired: _titleEnController.text.trim().isEmpty,
                        ),
                        const SizedBox(height: 14),
                        AdminTextField(
                          controller: _bodyTaController,
                          label: 'அறிவிப்பு செய்தி (Tamil Body)',
                          hint: 'முழு விவரங்கள் மற்றும் நேரங்கள்...',
                          maxLines: 4,
                          isRequired: _bodyEnController.text.trim().isEmpty,
                        ),
                      ] else ...[
                        // English Fields
                        AdminTextField(
                          controller: _titleEnController,
                          label: 'Notification Title (English)',
                          hint: 'e.g. Auspicious Muhurtham Day Tomorrow',
                          isRequired: _titleTaController.text.trim().isEmpty,
                        ),
                        const SizedBox(height: 14),
                        AdminTextField(
                          controller: _bodyEnController,
                          label: 'Notification Message (English)',
                          hint: 'Detailed message body for English users...',
                          maxLines: 4,
                          isRequired: _bodyTaController.text.trim().isEmpty,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Deep Link & Rich Media Card
              Card(
                color: TNTColors.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: TNTColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '3. Actionable Deep Link & Rich Media',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                      ),
                      const SizedBox(height: 14),

                      AdminTextField(
                        controller: _deepLinkController,
                        label: 'Deep Link Destination URI',
                        hint: 'tnt://muhurtham',
                        isRequired: true,
                      ),
                      const SizedBox(height: 8),

                      // Quick Presets selector
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: NotificationDeepLinkRouter.presetDeepLinks.map((p) {
                          return ActionChip(
                            label: Text(p['label']!, style: const TextStyle(fontSize: 10)),
                            backgroundColor: TNTColors.background,
                            side: const BorderSide(color: TNTColors.border),
                            onPressed: () {
                              setState(() {
                                _deepLinkController.text = p['uri']!;
                                _selectedCategory = p['category']!;
                              });
                              _updateAudienceEstimate();
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      AdminTextField(
                        controller: _mediaUrlController,
                        label: 'Rich Banner Image URL (Optional)',
                        hint: 'https://.../posters/banner.jpg',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Scheduling & Dispatch Mode Card
              Card(
                color: TNTColors.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: TNTColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '4. Dispatch Timing & Execution',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Send Immediately', style: TextStyle(fontWeight: FontWeight.bold))),
                              selected: _sendImmediately,
                              selectedColor: TNTColors.primary.withValues(alpha: 0.15),
                              labelStyle: TextStyle(color: _sendImmediately ? TNTColors.primary : TNTColors.textSecondary),
                              onSelected: (val) => setState(() => _sendImmediately = true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Schedule for Later', style: TextStyle(fontWeight: FontWeight.bold))),
                              selected: !_sendImmediately,
                              selectedColor: TNTColors.primary.withValues(alpha: 0.15),
                              labelStyle: TextStyle(color: !_sendImmediately ? TNTColors.primary : TNTColors.textSecondary),
                              onSelected: (val) => setState(() => _sendImmediately = false),
                            ),
                          ),
                        ],
                      ),

                      if (!_sendImmediately) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: AdminDatePicker(
                                label: 'Scheduled Date',
                                selectedDate: _scheduledDate,
                                onDateSelected: (d) => setState(() => _scheduledDate = d),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AdminTimePicker(
                                label: 'Scheduled Time',
                                selectedTime: _scheduledTime,
                                onTimeSelected: (t) => setState(() => _scheduledTime = t),
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

              // Actions Bar
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
                      onPressed: _handlePreview,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.preview_rounded, size: 18),
                          SizedBox(width: 6),
                          Text('Preview Notification', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TNTColors.primary,
                        side: const BorderSide(color: TNTColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isSaving ? null : _handleSaveDraft,
                      child: const Text('Save Draft', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _sendImmediately ? TNTColors.primary : Colors.teal[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isSaving ? null : _handleScheduleOrSend,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_sendImmediately ? Icons.send_rounded : Icons.schedule_send_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _sendImmediately ? 'Send Campaign Now' : 'Schedule Campaign',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
