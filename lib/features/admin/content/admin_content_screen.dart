import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../models/tnt_models.dart';
import '../repositories/admin_content_repository.dart';
import '../widgets/admin_form_widgets.dart';
import 'admin_content_form.dart';
import 'admin_content_preview.dart';

/// Admin Content / Poster Management Screen
class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({super.key});

  @override
  _AdminContentScreenState createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends State<AdminContentScreen> {
  final AdminContentRepository _repo = AdminContentRepository();

  List<ContentItem> _items = [];
  bool _isLoading = true;
  String _selectedStatusFilter = 'ALL';
  String? _selectedCategoryFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final status = _selectedStatusFilter == 'ALL' ? null : _selectedStatusFilter;
      final data = await _repo.getContentItems(
        status: status,
        category: _selectedCategoryFilter,
        searchQuery: _searchQuery,
      );
      if (mounted) {
        setState(() {
          _items = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PUBLISHED':
        return Colors.green;
      case 'SCHEDULED':
        return Colors.teal;
      case 'DRAFT':
        return Colors.orange;
      case 'ARCHIVED':
      default:
        return Colors.brown;
    }
  }

  void _openCreateEditForm([ContentItem? item]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminContentFormScreen(
          initialItem: item,
          onSaved: _loadItems,
        ),
      ),
    );
  }

  void _openPreview(ContentItem item) {
    showDialog(
      context: context,
      builder: (_) => AdminContentPreviewDialog(item: item),
    );
  }

  Future<void> _changeStatus(ContentItem item, String newStatus) async {
    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: 'Change Content Status',
      message: 'Are you sure you want to change status of "${item.titleEnglish}" to $newStatus?',
      confirmLabel: 'Update Status',
    );
    if (!confirmed) return;

    await _repo.updateContentStatus(item.id, newStatus);
    _loadItems();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Content updated to $newStatus'),
          backgroundColor: _getStatusColor(newStatus),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: AppBar(
        title: const Text(
          'Content & Posters Management',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
        ),
        backgroundColor: TNTColors.surface,
        elevation: 0,
        actions: [ const TNTBrandHeader(), 
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: TNTColors.primary),
            onPressed: _loadItems,
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: TNTColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('New Item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () => _openCreateEditForm(),
          ),
          const SizedBox(width: 12),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: TNTColors.border, height: 1),
        ),
      ),
      body: Column(
        children: [
          // Filter & Search Bar
          Container(
            color: TNTColors.surface,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) {
                    _searchQuery = val;
                    _loadItems();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search title (Tamil or English)...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: TNTColors.textMuted),
                    filled: true,
                    fillColor: TNTColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: TNTColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: TNTColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'ALL',
                      'DRAFT',
                      'SCHEDULED',
                      'PUBLISHED',
                      'ARCHIVED',
                    ].map((st) {
                      final isSelected = _selectedStatusFilter == st;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ChoiceChip(
                          label: Text(
                            st,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : TNTColors.textPrimary,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: TNTColors.primary,
                          backgroundColor: TNTColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: BorderSide(color: isSelected ? TNTColors.primary : TNTColors.border),
                          ),
                          onSelected: (sel) {
                            if (sel) {
                              setState(() => _selectedStatusFilter = st);
                              _loadItems();
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: TNTColors.border),

          // Items List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: TNTColors.primary))
                : _items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.inventory_2_outlined, size: 48, color: TNTColors.textMuted),
                              const SizedBox(height: 12),
                              const Text(
                                'No content items found',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Create a draft or change filter criteria',
                                style: TextStyle(fontSize: 12, color: TNTColors.textSecondary),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: TNTColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => _openCreateEditForm(),
                                child: const Text('Create First Content Item'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final statusCol = _getStatusColor(item.status);

                          return Card(
                            color: TNTColors.surface,
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: TNTColors.border),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
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
                                                    color: statusCol.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: statusCol.withValues(alpha: 0.3)),
                                                  ),
                                                  child: Text(
                                                    item.status.toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: statusCol,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  item.category,
                                                  style: const TextStyle(fontSize: 11, color: TNTColors.textMuted, fontWeight: FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              item.titleTamil,
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                                            ),
                                            Text(
                                              item.titleEnglish,
                                              style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Live Preview',
                                        icon: const Icon(Icons.remove_red_eye_outlined, color: TNTColors.primary),
                                        onPressed: () => _openPreview(item),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16, color: TNTColors.border),

                                  // Status change actions
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item.publishAt != null
                                            ? 'Published: ${item.publishAt!.day}/${item.publishAt!.month}/${item.publishAt!.year}'
                                            : 'Updated: ${item.updatedAt.day}/${item.updatedAt.month}/${item.updatedAt.year}',
                                        style: const TextStyle(fontSize: 10, color: TNTColors.textMuted),
                                      ),
                                      Row(
                                        children: [
                                          if (item.status != 'PUBLISHED')
                                            TextButton(
                                              onPressed: () => _changeStatus(item, 'PUBLISHED'),
                                              child: const Text('Publish', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                                            ),
                                          if (item.status != 'ARCHIVED')
                                            TextButton(
                                              onPressed: () => _changeStatus(item, 'ARCHIVED'),
                                              child: const Text('Archive', style: TextStyle(fontSize: 11, color: Colors.brown)),
                                            ),
                                          TextButton(
                                            onPressed: () => _openCreateEditForm(item),
                                            child: const Text('Edit', style: TextStyle(fontSize: 11, color: TNTColors.primary, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
