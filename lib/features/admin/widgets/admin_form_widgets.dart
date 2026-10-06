import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

/// Reusable Admin Text Field with clean typography and validation
class AdminTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helperText;
  final bool isRequired;
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;

  const AdminTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.helperText,
    this.isRequired = false,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: TNTColors.textPrimary,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: validator ?? (isRequired
              ? (val) => (val == null || val.trim().isEmpty) ? '$label is required' : null
              : null),
          style: const TextStyle(fontSize: 14, color: TNTColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            helperMaxLines: 2,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: TNTColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: TNTColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: TNTColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }
}

/// Reusable Admin Dropdown Field
class AdminDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final bool isRequired;
  final String? hint;

  const AdminDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isRequired = false,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
            ),
            if (isRequired)
              const Text(' *', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: TNTColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              hint: hint != null ? Text(hint!, style: const TextStyle(fontSize: 13, color: TNTColors.textMuted)) : null,
              items: items,
              onChanged: onChanged,
              icon: const Icon(Icons.arrow_drop_down, color: TNTColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}

/// Admin Date Picker Field
class AdminDatePicker extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final bool isRequired;

  const AdminDatePicker({
    super.key,
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = selectedDate != null
        ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
        : 'Select Date';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
            ),
            if (isRequired)
              const Text(' *', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? now,
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
              builder: (context, child) {
                return Theme(
                  data: ThemeData.light().copyWith(
                    primaryColor: TNTColors.primary,
                    colorScheme: const ColorScheme.light(primary: TNTColors.primary),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              onDateSelected(picked);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: TNTColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateText,
                  style: TextStyle(
                    fontSize: 14,
                    color: selectedDate != null ? TNTColors.textPrimary : TNTColors.textMuted,
                  ),
                ),
                const Icon(Icons.calendar_month_rounded, size: 18, color: TNTColors.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Admin Time Picker Field
class AdminTimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay? selectedTime;
  final ValueChanged<TimeOfDay> onTimeSelected;
  final bool isRequired;

  const AdminTimePicker({
    super.key,
    required this.label,
    required this.selectedTime,
    required this.onTimeSelected,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeText = selectedTime != null
        ? selectedTime!.format(context)
        : 'Select Time';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
            ),
            if (isRequired)
              const Text(' *', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
            );
            if (picked != null) {
              onTimeSelected(picked);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: TNTColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  timeText,
                  style: TextStyle(
                    fontSize: 14,
                    color: selectedTime != null ? TNTColors.textPrimary : TNTColors.textMuted,
                  ),
                ),
                const Icon(Icons.access_time_rounded, size: 18, color: TNTColors.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Reusable Admin Status Selector (Draft, Scheduled, Published, Archived)
class AdminStatusSelector extends StatelessWidget {
  final String status;
  final ValueChanged<String> onStatusChanged;

  const AdminStatusSelector({
    super.key,
    required this.status,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = [
      {'key': 'DRAFT', 'label': 'Draft', 'color': Colors.grey},
      {'key': 'SCHEDULED', 'label': 'Scheduled', 'color': Colors.teal},
      {'key': 'PUBLISHED', 'label': 'Published', 'color': Colors.green},
      {'key': 'ARCHIVED', 'label': 'Archived', 'color': Colors.brown},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Publication Status',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: statuses.map((item) {
            final isSelected = status == item['key'];
            final Color color = item['color'] as Color;

            return ChoiceChip(
              label: Text(
                item['label'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : TNTColors.textPrimary,
                ),
              ),
              selected: isSelected,
              selectedColor: color,
              backgroundColor: TNTColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(color: isSelected ? color : TNTColors.border),
              ),
              onSelected: (selected) {
                if (selected) {
                  onStatusChanged(item['key'] as String);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Admin Bilingual Language Switcher for Forms & Previews
class AdminLanguageTabs extends StatelessWidget {
  final String currentLang; // 'ta' | 'en'
  final ValueChanged<String> onLanguageChanged;

  const AdminLanguageTabs({
    super.key,
    required this.currentLang,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TNTColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TNTColors.border),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTab('ta', 'தமிழ் (Tamil)'),
          _buildTab('en', 'English'),
        ],
      ),
    );
  }

  Widget _buildTab(String code, String title) {
    final isSelected = currentLang == code;
    return InkWell(
      onTap: () => onLanguageChanged(code),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? TNTColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : TNTColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Confirmation Dialog for Sensitive Admin Actions
Future<bool> showAdminConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  Color confirmColor = TNTColors.primary,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: TNTColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      content: Text(message, style: const TextStyle(fontSize: 13, color: TNTColors.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel', style: TextStyle(color: TNTColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
