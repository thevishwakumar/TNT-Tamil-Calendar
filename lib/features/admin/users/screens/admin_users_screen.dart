import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../models/tnt_models.dart';
import '../../../../services/supabase_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<UserProfile> _users = [];
  bool _isLoading = true;
  String _filterRole = 'ALL';
  String _filterStatus = 'ALL';
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

  // Pagination
  static const int _pageSize = 20;
  int _currentPage = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadUsers(refresh: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _hasMore = true;
      _users.clear();
    }
    
    if (!_hasMore) return;

    setState(() => _isLoading = true);
    final client = SupabaseService().client;

    try {
      var query = client.from('profiles').select();
      
      if (_filterRole != 'ALL') {
        query = query.eq('role', _filterRole);
      }
      
      if (_filterStatus != 'ALL') {
        query = query.eq('account_status', _filterStatus);
      }

      if (_search.isNotEmpty) {
        query = query.or('full_name.ilike.%${_search}%,email.ilike.%${_search}%,phone.ilike.%${_search}%');
      }

      final start = _currentPage * _pageSize;
      final end = start + _pageSize - 1;

      final res = await query.order('created_at', ascending: false).range(start, end);
      
      final list = (res as List?) ?? [];
      
      if (mounted) {
        setState(() {
          if (list.length < _pageSize) {
            _hasMore = false;
          }
          _users.addAll(list.map((item) => UserProfile.fromJson(item as Map<String, dynamic>)).toList());
          _isLoading = false;
          _currentPage++;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading users: $e')));
      }
    }
  }

  Future<void> _updateUserStatus(UserProfile user, String newStatus) async {
    final client = SupabaseService().client;
    try {
      await client.rpc('admin_update_user_status', params: {
        'p_user_id': user.id,
        'p_status': newStatus,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User status updated successfully.')));
      _loadUsers(refresh: true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _updateUserRole(UserProfile user, String newRole) async {
    final client = SupabaseService().client;
    try {
      await client.rpc('admin_update_user_role', params: {
        'p_user_id': user.id,
        'p_role': newRole,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User role updated successfully.')));
      _loadUsers(refresh: true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showUserActionDialog(UserProfile user) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Manage ${user.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: ${user.email}'),
              Text('Role: ${user.isAdmin ? 'ADMIN' : 'USER'}'),
              Text('Status: ${user.accountStatus}'),
              const SizedBox(height: 20),
              if (user.accountStatus != 'SUSPENDED')
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmAction('Suspend User', 'Are you sure you want to suspend this user?', () => _updateUserStatus(user, 'SUSPENDED'));
                  },
                  child: const Text('Suspend Account'),
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmAction('Reactivate User', 'Reactivate this suspended account?', () => _updateUserStatus(user, 'ACTIVE'));
                  },
                  child: const Text('Reactivate Account'),
                ),
              const SizedBox(height: 10),
              if (!user.isAdmin)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmAction('Promote to Admin', 'Are you sure you want to grant ADMIN privileges?', () => _updateUserRole(user, 'ADMIN'));
                  },
                  child: const Text('Promote to Admin'),
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmAction('Demote to User', 'Are you sure you want to revoke ADMIN privileges?', () => _updateUserRole(user, 'USER'));
                  },
                  child: const Text('Demote to User'),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ],
        );
      },
    );
  }

  void _confirmAction(String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TNTColors.background,
      body: RefreshIndicator(
        onRefresh: () => _loadUsers(refresh: true),
        color: TNTColors.primary,
        child: Column(
          children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text('Users Management', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TNTColors.textPrimary)),
                    ),
            // Search and Role Filters
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, email, phone...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: TNTColors.textSecondary),
                      isDense: true,
                      filled: true,
                      fillColor: TNTColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: TNTColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: TNTColors.border)),
                    ),
                    onSubmitted: (v) {
                      setState(() => _search = v);
                      _loadUsers(refresh: true);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: _filterRole,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'ALL', child: Text('All Roles')),
                            DropdownMenuItem(value: 'ADMIN', child: Text('Admins Only')),
                            DropdownMenuItem(value: 'USER', child: Text('Users Only')),
                          ],
                          onChanged: (v) {
                            setState(() => _filterRole = v ?? 'ALL');
                            _loadUsers(refresh: true);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _filterStatus,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'ALL', child: Text('All Status')),
                            DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                            DropdownMenuItem(value: 'SUSPENDED', child: Text('Suspended')),
                            DropdownMenuItem(value: 'PENDING_EMAIL_VERIFICATION', child: Text('Pending Email')),
                          ],
                          onChanged: (v) {
                            setState(() => _filterStatus = v ?? 'ALL');
                            _loadUsers(refresh: true);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: _isLoading && _users.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: TNTColors.primary))
                  : _users.isEmpty
                      ? const Center(child: Text('No users match the criteria.'))
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _users.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _users.length) {
                              _loadUsers();
                              return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
                            }
                            final u = _users[index];
                            return _buildUserCard(u);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(UserProfile user) {
    final isAdmin = user.isAdmin;
    final isSuspended = user.accountStatus == 'SUSPENDED';
    return InkWell(
      onTap: () => _showUserActionDialog(user),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSuspended ? Colors.grey[300] : TNTColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isAdmin ? TNTColors.primary.withValues(alpha: 0.3) : TNTColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isAdmin ? TNTColors.primary : Colors.grey[200],
              radius: 20,
              child: Icon(
                isAdmin ? Icons.shield_rounded : Icons.person_rounded,
                color: isAdmin ? Colors.white : Colors.grey[700],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user.fullName.isEmpty ? 'Unnamed User' : user.fullName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isAdmin ? Colors.red.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isAdmin ? 'ADMIN' : 'USER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isAdmin ? Colors.red[800] : Colors.blue[800],
                          ),
                        ),
                      ),
                      if (isSuspended)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                          child: const Text('SUSPENDED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email ?? user.phoneNumber ?? 'No contact information',
                    style: const TextStyle(fontSize: 11, color: TNTColors.textSecondary),
                  ),
                  Text(
                    'Registered: ${user.createdAt.toIso8601String().substring(0, 10)}',
                    style: const TextStyle(fontSize: 10, color: TNTColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.more_vert, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

