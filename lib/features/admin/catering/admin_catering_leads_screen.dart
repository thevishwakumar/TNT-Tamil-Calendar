import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../catering/models/catering_enquiry.dart';
import '../../catering/repositories/catering_repository.dart';
import 'package:intl/intl.dart';
import 'admin_catering_lead_detail_screen.dart';

class AdminCateringLeadsScreen extends StatefulWidget {
  const AdminCateringLeadsScreen({super.key});

  @override
  State<AdminCateringLeadsScreen> createState() => _AdminCateringLeadsScreenState();
}

class _AdminCateringLeadsScreenState extends State<AdminCateringLeadsScreen> {
  final CateringRepository _repo = CateringRepository();
  bool _isLoading = true;
  List<CateringEnquiry> _leads = [];
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'New',
    'Contacted',
    'Follow_up',
    'Quoted',
    'Confirmed',
    'Completed',
    'Cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _loadLeads();
  }

  Future<void> _loadLeads() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repo.getAdminLeads(filter: _selectedFilter);
      setState(() {
        _leads = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading catering leads: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load leads: $e')),
        );
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
              Text('Catering Leads', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Enquiries received from TNT Tamil Calendar users.', style: TextStyle(color: TNTColors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
        
        // Filters
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              final filter = _filters[index];
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                child: ChoiceChip(
                  label: Text(filter.replaceAll('_', '-')),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedFilter = filter);
                      _loadLeads();
                    }
                  },
                ),
              );
            },
          ),
        ),

        // List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _leads.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_rounded, size: 64, color: TNTColors.textSecondary.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          const Text('No Catering Enquiries Yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          const Text('New enquiries submitted through TNT will appear here.', style: TextStyle(color: TNTColors.textSecondary)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadLeads,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _leads.length,
                        itemBuilder: (context, index) {
                          final lead = _leads[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => AdminCateringLeadDetailScreen(lead: lead)),
                                );
                                if (result == true) {
                                  _loadLeads();
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(lead.status).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            lead.status.toUpperCase(),
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(lead.status)),
                                          ),
                                        ),
                                        Text(
                                          lead.referenceCode,
                                          style: const TextStyle(fontSize: 11, color: TNTColors.textSecondary, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(lead.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.event, size: 14, color: TNTColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(lead.eventType, style: const TextStyle(fontSize: 13, color: TNTColors.textSecondary)),
                                        const SizedBox(width: 16),
                                        const Icon(Icons.calendar_today, size: 14, color: TNTColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(DateFormat('dd MMM yyyy').format(lead.eventDate), style: const TextStyle(fontSize: 13, color: TNTColors.textSecondary)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.people, size: 14, color: TNTColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text('${lead.guestCount ?? "?"} Guests', style: const TextStyle(fontSize: 13, color: TNTColors.textSecondary)),
                                        const SizedBox(width: 16),
                                        const Icon(Icons.location_on, size: 14, color: TNTColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Expanded(child: Text(lead.eventLocation ?? "N/A", style: const TextStyle(fontSize: 13, color: TNTColors.textSecondary), overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.phone, size: 14, color: TNTColors.primary),
                                            const SizedBox(width: 4),
                                            Text(lead.mobileNumber, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TNTColors.primary)),
                                          ],
                                        ),
                                        const Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TNTColors.primary)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
