import os

repo_path = r'C:\Users\Vishw\Downloads\TNT\lib\features\admin\schedules\repositories\admin_schedule_repository.dart'
with open(repo_path, 'r', encoding='utf-8') as f:
    code = f.read()

old_get = '''Future<List<AdminScheduleItem>> getSchedules({
    String? category,
    String? status,
    String? search,
  }) async {
    final client = _client ?? SupabaseService().client;

    try {
      var query = client.from('admin_schedules').select();
      if (category != null && category != 'ALL') {
        query = query.eq('category', category);
      }
      if (status != null && status != 'ALL') {
        query = query.eq('status', status);
      }
      if (search != null && search.isNotEmpty) {
        query = query.or('title.ilike.%%,mandapam.ilike.%%,marriage_details.ilike.%%');
      }

      final res = await query.order('schedule_date', ascending: true);
      final list = (res as List?) ?? [];
      if (list.isEmpty) {
        return _getSimulatedSchedules(category: category, status: status, search: search);
      }
      return list.map((item) => AdminScheduleItem.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return _getSimulatedSchedules(category: category, status: status, search: search);
    }
  }'''

new_get = '''Future<List<AdminScheduleItem>> getSchedules({
    String? category,
    String? status,
    String? search,
    int page = 0,
    int pageSize = 50,
  }) async {
    final client = _client ?? SupabaseService().client;

    try {
      var query = client.from('admin_schedules').select();
      if (category != null && category != 'ALL') {
        query = query.eq('category', category);
      }
      if (status != null && status != 'ALL') {
        query = query.eq('status', status);
      }
      if (search != null && search.isNotEmpty) {
        query = query.or('title.ilike.%%,mandapam.ilike.%%,marriage_details.ilike.%%');
      }

      final start = page * pageSize;
      final end = start + pageSize - 1;

      final res = await query.order('schedule_date', ascending: true).range(start, end);
      final list = (res as List?) ?? [];
      
      return list.map((item) => AdminScheduleItem.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }'''

code = code.replace(old_get, new_get)

# Remove _getSimulatedSchedules completely
import re
code = re.sub(r'List<AdminScheduleItem> _getSimulatedSchedules\([^\{]+\{[^\}]+\}', '', code, flags=re.DOTALL)

with open(repo_path, 'w', encoding='utf-8') as f:
    f.write(code)


screen_path = r'C:\Users\Vishw\Downloads\TNT\lib\features\admin\schedules\screens\admin_schedules_screen.dart'
with open(screen_path, 'r', encoding='utf-8') as f:
    code = f.read()

# Add pagination state
if 'int _currentPage = 0;' not in code:
    code = code.replace('String _searchQuery = \'\';', 'String _searchQuery = \'\';\n  int _currentPage = 0;\n  bool _hasMore = true;\n  static const int _pageSize = 50;\n  final ScrollController _scrollController = ScrollController();')

    old_init = '''@override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCronJobs();
    _loadSchedules();
  }'''
    new_init = '''@override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadSchedules();
      }
    });
    _loadCronJobs();
    _loadSchedules(refresh: true);
  }'''
    code = code.replace(old_init, new_init)
    
    old_dispose = '''@override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }'''
    new_dispose = '''@override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }'''
    code = code.replace(old_dispose, new_dispose)

    old_load = '''Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    final list = await _repository.getSchedules(
      category: _selectedCategory,
      status: _selectedStatus,
      search: _searchQuery,
    );
    if (mounted) {
      setState(() {
        _schedules = list;
        _isLoading = false;
      });
    }
  }'''
    new_load = '''Future<void> _loadSchedules({bool refresh = false}) async {
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
  }'''
    code = code.replace(old_load, new_load)
    
    # Pass scroll controller to ListView
    code = code.replace('ListView.builder(', 'ListView.builder(\ncontroller: _scrollController,')
    
    # Make search/filter call _loadSchedules(refresh: true)
    code = code.replace('_loadSchedules();', '_loadSchedules(refresh: true);')

    with open(screen_path, 'w', encoding='utf-8') as f:
        f.write(code)

print("Pagination applied to Admin Schedules.")
