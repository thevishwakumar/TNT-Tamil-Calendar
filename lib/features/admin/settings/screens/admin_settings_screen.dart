import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../repositories/system_settings_repository.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final SystemSettingsRepository _repo = SystemSettingsRepository();
  bool _isLoading = true;
  List<SystemSetting> _settings = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repo.getAllSettings();
      setState(() {
        _settings = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load system settings. Make sure system_settings.sql is executed.')),
        );
      }
    }
  }

  Future<void> _updateBooleanSetting(SystemSetting setting, bool newValue) async {
    try {
      await _repo.updateSetting(setting.key, newValue);
      _loadSettings(); // Refresh
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${setting.key} updated to $newValue')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update setting')));
      }
    }
  }

  Future<void> _editStringOrNumberSetting(SystemSetting setting) async {
    final TextEditingController controller = TextEditingController(text: setting.value.toString());
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${setting.key}'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter new value',
            helperText: setting.description,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('SAVE')),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        dynamic parsedValue = result;
        if (int.tryParse(result) != null) {
          parsedValue = int.parse(result);
        } else if (double.tryParse(result) != null) {
          parsedValue = double.parse(result);
        }
        await _repo.updateSetting(setting.key, parsedValue);
        _loadSettings();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update setting')));
        }
      }
    }
  }

  Widget _buildSettingTile(SystemSetting setting) {
    final isBoolean = setting.value is bool;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(setting.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(setting.description ?? 'No description provided', style: const TextStyle(color: TNTColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: TNTColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Current Value: ${setting.value}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TNTColors.primary),
              ),
            ),
          ],
        ),
        trailing: isBoolean
            ? Switch(
                value: setting.value as bool,
                activeColor: TNTColors.primary,
                onChanged: (val) => _updateBooleanSetting(setting, val),
              )
            : IconButton(
                icon: const Icon(Icons.edit, color: TNTColors.primary),
                onPressed: () => _editStringOrNumberSetting(setting),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          color: TNTColors.surface,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('System Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Manage global app configurations and features.', style: TextStyle(color: TNTColors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
        
        // List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _settings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.settings_applications, size: 64, color: TNTColors.textSecondary.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          const Text('No System Settings Found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          const Text('Execute system_settings.sql in Supabase to initialize.', style: TextStyle(color: TNTColors.textSecondary)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadSettings,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                          )
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadSettings,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _settings.length,
                        itemBuilder: (context, index) {
                          return _buildSettingTile(_settings[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
