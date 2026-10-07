import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/colors.dart';
import '../../../catering/models/catering_enquiry.dart';
import '../../../catering/repositories/catering_repository.dart';
import 'package:intl/intl.dart';

class AdminCateringLeadDetailScreen extends StatefulWidget {
  final CateringEnquiry lead;

  const AdminCateringLeadDetailScreen({super.key, required this.lead});

  @override
  State<AdminCateringLeadDetailScreen> createState() => _AdminCateringLeadDetailScreenState();
}

class _AdminCateringLeadDetailScreenState extends State<AdminCateringLeadDetailScreen> {
  late CateringEnquiry _lead;
  final CateringRepository _repo = CateringRepository();
  bool _isSaving = false;
  final TextEditingController _notesController = TextEditingController();

  final List<String> _statuses = [
    'new',
    'contacted',
    'follow_up',
    'quoted',
    'confirmed',
    'completed',
    'cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _lead = widget.lead;
    _notesController.text = _lead.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openWhatsApp() {
    final date = DateFormat('dd MMM yyyy').format(_lead.eventDate);
    final guests = _lead.guestCount?.toString() ?? 'Not specified';
    final loc = _lead.eventLocation ?? 'Not specified';
    final text = "Hello ${_lead.fullName},\n\nThis is from Shree Taste & Taste Catering.\n\nWe received your enquiry through TNT Tamil Calendar.\n\nEvent:\n${_lead.eventType}\n\nDate:\n$date\n\nGuests:\n$guests\n\nLocation:\n$loc\n\nReference:\n${_lead.referenceCode}\n\nThank you.";
    final encodedText = Uri.encodeComponent(text);
    
    // assuming mobile number doesn't have +91 prefix. The rules said to normalize it, 
    // but the lead object just has mobileNumber. If it's a 10 digit, prefix with 91.
    String formattedPhone = _lead.mobileNumber;
    if (formattedPhone.startsWith('0')) formattedPhone = formattedPhone.substring(1);
    if (formattedPhone.length == 10) formattedPhone = '91$formattedPhone';
    
    _launchUrl('https://wa.me/$formattedPhone?text=$encodedText');
  }

  Future<void> _updateLead(String newStatus) async {
    setState(() => _isSaving = true);
    try {
      final updated = await _repo.updateLeadStatus(_lead.id, newStatus, _notesController.text.trim());
      setState(() {
        _lead = updated;
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lead updated')));
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update lead')));
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new': return Colors.blue;
      case 'contacted': return Colors.orange;
      case 'follow_up': return Colors.deepOrange;
      case 'quoted': return Colors.purple;
      case 'confirmed': return Colors.green;
      case 'completed': return Colors.teal;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true); // Always return true to refresh
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lead Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          backgroundColor: TNTColors.surface,
        ),
        backgroundColor: TNTColors.background,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TNTColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TNTColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_lead.referenceCode, style: const TextStyle(fontWeight: FontWeight.bold, color: TNTColors.textSecondary)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(_lead.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _lead.status.toUpperCase(),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(_lead.status)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(_lead.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Submitted on ${DateFormat('dd MMM yyyy, hh:mm a').format(_lead.createdAt)}', style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary)),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _launchUrl('tel:${_lead.mobileNumber}'),
                            icon: const Icon(Icons.call, size: 16),
                            label: const Text('Call'),
                            style: ElevatedButton.styleFrom(backgroundColor: TNTColors.surface, foregroundColor: TNTColors.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _openWhatsApp,
                            icon: const Icon(Icons.chat, size: 16),
                            label: const Text('WhatsApp'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Event Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TNTColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TNTColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Event Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.event, 'Event Type', _lead.eventType),
                    const Divider(),
                    _buildDetailRow(Icons.calendar_today, 'Event Date', DateFormat('dd MMM yyyy').format(_lead.eventDate)),
                    const Divider(),
                    _buildDetailRow(Icons.people, 'Guests', _lead.guestCount?.toString() ?? 'Not specified'),
                    const Divider(),
                    _buildDetailRow(Icons.location_on, 'Location', _lead.eventLocation ?? 'Not specified'),
                    if (_lead.message != null && _lead.message!.isNotEmpty) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text('Additional Message', style: TextStyle(fontSize: 12, color: TNTColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(_lead.message!, style: const TextStyle(fontSize: 14)),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Status and Notes Management
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TNTColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TNTColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Admin Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    const Text('Status', style: TextStyle(fontSize: 12, color: TNTColors.textSecondary)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _lead.status,
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                      items: _statuses.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) _updateLead(val);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Private Admin Notes', style: TextStyle(fontSize: 12, color: TNTColors.textSecondary)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Add notes about this lead...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : () => _updateLead(_lead.status),
                        style: ElevatedButton.styleFrom(backgroundColor: TNTColors.primary, foregroundColor: Colors.white),
                        child: _isSaving 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Save Notes'),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: TNTColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
