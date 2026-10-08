import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../models/tnt_models.dart';
import '../repositories/admin_content_repository.dart';

/// Admin Audit Trail Screen (Strictly Admin View)
class AdminAuditScreen extends StatefulWidget {
  const AdminAuditScreen({super.key});

  @override
  _AdminAuditScreenState createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends State<AdminAuditScreen> {
  final AdminContentRepository _repo = AdminContentRepository();
  List<AdminAuditLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final logs = await _repo.getAuditLogs();
    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    }
  }

  Color _getActionColor(String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
        return Colors.green;
      case 'PUBLISH':
        return Colors.teal;
      case 'UPDATE':
        return Colors.blue;
      case 'SCHEDULE':
        return Colors.indigo;
      case 'ARCHIVE':
      case 'DELETE':
        return Colors.redAccent;
      default:
        return Colors.brown;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: AppBar(
        title: const Text('Admin Audit Trail', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TNTColors.textPrimary)),
        backgroundColor: TNTColors.surface,
        elevation: 0,
        actions: [  
          IconButton(icon: const Icon(Icons.refresh_rounded, color: TNTColors.primary), onPressed: _loadLogs),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: TNTColors.border, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: TNTColors.primary))
          : _logs.isEmpty
              ? const Center(
                  child: Text('No audit mutations recorded yet.', style: TextStyle(color: TNTColors.textSecondary)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    final actionCol = _getActionColor(log.action);

                    return Card(
                      color: TNTColors.surface,
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: TNTColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: actionCol.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                log.action,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: actionCol),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${log.module} • Record: ${log.recordId}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'By: ${log.adminEmail ?? log.adminId} • ${log.createdAt.toLocal().toString().split('.').first}',
                                    style: const TextStyle(fontSize: 11, color: TNTColors.textMuted),
                                  ),
                                ],
                              ),
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
