import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../models/admin_schedule_models.dart';
import '../repositories/admin_schedule_repository.dart';

class AdminSchedulesScreen extends StatefulWidget {
  const AdminSchedulesScreen({super.key});

  @override
  State<AdminSchedulesScreen> createState() => _AdminSchedulesScreenState();
}

class _AdminSchedulesScreenState extends State<AdminSchedulesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminScheduleRepository _repository = AdminScheduleRepository();

  List<AdminScheduleItem> _schedules = [];
  List<AutomatedCronJob> _cronJobs = [];
  bool _isLoading = true;
  String _selectedCategory = 'ALL';
  String _selectedStatus = 'ALL';
  String _searchQuery = '';
  int _currentPage = 0;
  bool _hasMore = true;
  static const int _pageSize = 50;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'ALL',
    'CONTENT_PREP',
    'MANDAPAM',
    'VERIFICATION',
    'NOTIFICATIONS',
    'MAINTENANCE',
    'GENERAL',
  ];

  final List<String> _statuses = [
    'ALL',
    'SCHEDULED',
    'IN_PROGRESS',
    'COMPLETED',
    'CANCELLED',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadSchedules(refresh: true);
      }
    });
    _loadCronJobs();
    _loadSchedules(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  
  Future<void> _loadCronJobs() async {
    final jobs = await _repository.getAutomatedCronJobs();
    if (mounted) setState(() => _cronJobs = jobs);
  }

  Future<void> _loadSchedules({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _hasMore = true;
      _schedules.clear();
    }
    if (!_hasMore || (_isLoading && !refresh)) return;

    setState(() => _isLoading = true);
    final list = await _repository.getSchedules(
      category: _selectedCategory,
      status: _selectedStatus,
      search: _searchQuery,
      page: _currentPage,
      pageSize: _pageSize,
    );
    
    if (mounted) {
      setState(() {
        if (list.length < _pageSize) _hasMore = false;
        _schedules.addAll(list);
        _isLoading = false;
        _currentPage++;
      });
    }
  }

  void _showCreateEditDialog({AdminScheduleItem? item}) {
    final titleCtrl = TextEditingController(text: item?.title ?? '');
    final descCtrl = TextEditingController(text: item?.description ?? '');
    final dateCtrl = TextEditingController(
      text: item?.scheduleDate ?? DateTime.now().toIso8601String().substring(0, 10),
    );
    final startTimeCtrl = TextEditingController(text: item?.startTime ?? '09:00 AM');
    final endTimeCtrl = TextEditingController(text: item?.endTime ?? '05:00 PM');
    final mandapamCtrl = TextEditingController(text: item?.mandapam ?? '');
    final eventTypeCtrl = TextEditingController(text: item?.eventType ?? '');
    final marriageDetailsCtrl = TextEditingController(text: item?.marriageDetails ?? '');
    final internalNotesCtrl = TextEditingController(text: item?.internalNotes ?? '');

    String category = item?.category ?? 'CONTENT_PREP';
    String priority = item?.priority ?? 'MEDIUM';
    String status = item?.status ?? 'SCHEDULED';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: TNTColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(item == null ? Icons.add_circle_rounded : Icons.edit_note_rounded, color: TNTColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    item == null ? 'New Operational Schedule' : 'Edit Schedule',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Schedule Title *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Date & Timings
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: dateCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Date (YYYY-MM-DD)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: startTimeCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Start Time',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Category & Priority
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: category,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: ['CONTENT_PREP', 'MANDAPAM', 'VERIFICATION', 'NOTIFICATIONS', 'MAINTENANCE', 'GENERAL']
                                  .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12))))
                                  .toList(),
                              onChanged: (val) => setDialogState(() => category = val ?? 'GENERAL'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: priority,
                              decoration: const InputDecoration(
                                labelText: 'Priority',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: ['LOW', 'MEDIUM', 'HIGH', 'URGENT']
                                  .map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 12))))
                                  .toList(),
                              onChanged: (val) => setDialogState(() => priority = val ?? 'MEDIUM'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Status
                      DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: ['SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12))))
                            .toList(),
                        onChanged: (val) => setDialogState(() => status = val ?? 'SCHEDULED'),
                      ),
                      const SizedBox(height: 10),

                      // Mandapam / Location
                      TextField(
                        controller: mandapamCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Mandapam / Venue / Zone',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Marriage / Event Details
                      TextField(
                        controller: marriageDetailsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Marriage / Event Details',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Internal Confidential Notes
                      TextField(
                        controller: internalNotesCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Internal Admin Notes (Strictly Confidential)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: TNTColors.primary),
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;

                    final scheduleObj = AdminScheduleItem(
                      id: item?.id ?? 'sched_${DateTime.now().millisecondsSinceEpoch}',
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                      scheduleDate: dateCtrl.text.trim(),
                      startTime: startTimeCtrl.text.trim(),
                      endTime: endTimeCtrl.text.trim(),
                      category: category,
                      priority: priority,
                      status: status,
                      mandapam: mandapamCtrl.text.trim().isNotEmpty ? mandapamCtrl.text.trim() : null,
                      marriageDetails: marriageDetailsCtrl.text.trim().isNotEmpty ? marriageDetailsCtrl.text.trim() : null,
                      internalNotes: internalNotesCtrl.text.trim().isNotEmpty ? internalNotesCtrl.text.trim() : null,
                      createdAt: item?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    if (item == null) {
                      await _repository.createSchedule(scheduleObj);
                    } else {
                      await _repository.updateSchedule(scheduleObj);
                    }

                    if (context.mounted) {
                      Navigator.pop(ctx);
                      _loadSchedules(refresh: true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(item == null ? 'Schedule created successfully!' : 'Schedule updated!'),
                          backgroundColor: Colors.green[700],
                        ),
                      );
                    }
                  },
                  child: Text(item == null ? 'Create Schedule' : 'Save Changes', style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _triggerCronJob(AutomatedCronJob job) async {
    setState(() {
      final index = _cronJobs.indexWhere((j) => j.id == job.id);
      if (index != -1) {
        _cronJobs[index] = _cronJobs[index].copyWith(status: 'RUNNING');
      }
    });

    final updated = await _repository.triggerJobExecution(job);

    if (mounted) {
      setState(() {
        final index = _cronJobs.indexWhere((j) => j.id == job.id);
        if (index != -1) {
          _cronJobs[index] = updated;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${job.name} completed successfully (${updated.durationMs}ms)!'),
          backgroundColor: Colors.green[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TNTColors.background,
      body: Column(
        children: [
          // Header Tabs
          Container(
            color: TNTColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: TNTColors.primary,
              unselectedLabelColor: TNTColors.textSecondary,
              indicatorColor: TNTColors.primary,
              tabs: const [
                Tab(
                  icon: Icon(Icons.calendar_today_rounded, size: 18),
                  text: 'Operational Schedules',
                ),
                Tab(
                  icon: Icon(Icons.settings_suggest_rounded, size: 18),
                  text: 'Automated System Cron Jobs',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: TNTColors.border),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOperationalSchedulesTab(),
                _buildAutomatedCronJobsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: TNTColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Schedule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showCreateEditDialog(),
      ),
    );
  }

  Widget _buildOperationalSchedulesTab() {
    return RefreshIndicator(
      onRefresh: _loadSchedules,
      color: TNTColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(16.0),
        children: [
          // Search & Filter controls
          _buildSearchAndFilters(),
          const SizedBox(height: 16),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: CircularProgressIndicator(color: TNTColors.primary),
              ),
            )
          else if (_schedules.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: TNTColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TNTColors.border),
              ),
              child: const Column(
                children: [
                  Icon(Icons.event_busy_rounded, size: 48, color: TNTColors.textSecondary),
                  SizedBox(height: 12),
                  Text('No operational schedules found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(height: 4),
                  Text('Tap + New Schedule to add an internal administrative task or event.', style: TextStyle(fontSize: 12, color: TNTColors.textSecondary)),
                ],
              ),
            )
          else
            ..._schedules.map((item) => _buildScheduleCard(item)),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        // Search Bar
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search schedules, mandapam, marriage details...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: TNTColors.textSecondary),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      _loadSchedules(refresh: true);
                    },
                  )
                : null,
            filled: true,
            fillColor: TNTColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TNTColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TNTColors.border)),
          ),
          onChanged: (val) {
            setState(() => _searchQuery = val);
            _loadSchedules(refresh: true);
          },
        ),
        const SizedBox(height: 10),

        // Filter chips row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              // Category filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: TNTColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: TNTColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isDense: true,
                    style: const TextStyle(fontSize: 12, color: TNTColors.textPrimary),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text('Category: $c'))).toList(),
                    onChanged: (val) {
                      setState(() => _selectedCategory = val ?? 'ALL');
                      _loadSchedules(refresh: true);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Status filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: TNTColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: TNTColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    isDense: true,
                    style: const TextStyle(fontSize: 12, color: TNTColors.textPrimary),
                    items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text('Status: $s'))).toList(),
                    onChanged: (val) {
                      setState(() => _selectedStatus = val ?? 'ALL');
                      _loadSchedules(refresh: true);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleCard(AdminScheduleItem item) {
    Color priorityColor;
    switch (item.priority) {
      case 'URGENT':
        priorityColor = Colors.red;
        break;
      case 'HIGH':
        priorityColor = Colors.orange;
        break;
      case 'MEDIUM':
        priorityColor = Colors.blue;
        break;
      default:
        priorityColor = Colors.grey;
    }

    Color statusColor;
    switch (item.status) {
      case 'COMPLETED':
        statusColor = Colors.green;
        break;
      case 'IN_PROGRESS':
        statusColor = Colors.amber[800]!;
        break;
      case 'CANCELLED':
        statusColor = Colors.red[300]!;
        break;
      default:
        statusColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: TNTColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TNTColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date, category, status
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.priority,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: priorityColor),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.category,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
          ),

          // Date & Location Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: TNTColors.background,
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: TNTColors.textSecondary),
                const SizedBox(width: 4),
                Text('${item.scheduleDate} (${item.startTime} - ${item.endTime})', style: const TextStyle(fontSize: 11, color: TNTColors.textSecondary)),
                if (item.mandapam != null && item.mandapam!.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.location_on_outlined, size: 14, color: TNTColors.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(item.mandapam!, style: const TextStyle(fontSize: 11, color: TNTColors.primary, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ],
            ),
          ),

          // Description & Confidential Notes
          if (item.description != null && item.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(item.description!, style: const TextStyle(fontSize: 12, color: TNTColors.textPrimary)),
            ),

          if (item.internalNotes != null && item.internalNotes!.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 14, color: Colors.brown),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Internal Notes: ${item.internalNotes}', style: TextStyle(fontSize: 11, color: Colors.brown[900], fontStyle: FontStyle.italic)),
                  ),
                ],
              ),
            ),

          // Action Toolbar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit_rounded, size: 14, color: TNTColors.primary),
                  label: const Text('Edit', style: TextStyle(fontSize: 12, color: TNTColors.primary)),
                  onPressed: () => _showCreateEditDialog(item: item),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
                  label: const Text('Delete', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                  onPressed: () async {
                    await _repository.deleteSchedule(item.id);
                    _loadSchedules(refresh: true);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutomatedCronJobsTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      children: [
        // System Engine Info Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.indigo[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.indigo[100]!),
          ),
          child: const Row(
            children: [
              Icon(Icons.hub_rounded, color: Colors.indigo, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Automated Production Engine',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Background jobs scheduled via Supabase pg_cron & Edge Functions. You can trigger on-demand runs below.',
                      style: TextStyle(fontSize: 11, color: Colors.indigo),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ..._cronJobs.map((job) => _buildCronJobCard(job)),
      ],
    );
  }

  Widget _buildCronJobCard(AutomatedCronJob job) {
    final isRunning = job.status == 'RUNNING';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 12, color: TNTColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(job.frequency, style: const TextStyle(fontSize: 11, color: TNTColors.textSecondary)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(3)),
                          child: Text(job.cronExpression, style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: isRunning ? null : () => _triggerCronJob(job),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TNTColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: isRunning
                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.play_arrow_rounded, size: 14, color: Colors.white),
                label: Text(isRunning ? 'Running...' : 'Run Now', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(job.description, style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary)),
          const SizedBox(height: 10),

          // Log / Execution Output
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: TNTColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 14, color: Colors.green),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    job.lastLogMessage ?? 'Ready for execution',
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.black87),
                  ),
                ),
                if (job.durationMs != null)
                  Text('${job.durationMs}ms', style: const TextStyle(fontSize: 10, color: TNTColors.textSecondary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
