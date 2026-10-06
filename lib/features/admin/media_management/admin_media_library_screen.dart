import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../models/tnt_models.dart';
import '../repositories/admin_content_repository.dart';
import '../widgets/admin_form_widgets.dart';

/// Admin Media Library Screen
class AdminMediaLibraryScreen extends StatefulWidget {
  const AdminMediaLibraryScreen({super.key});

  @override
  _AdminMediaLibraryScreenState createState() => _AdminMediaLibraryScreenState();
}

class _AdminMediaLibraryScreenState extends State<AdminMediaLibraryScreen> {
  final AdminContentRepository _repo = AdminContentRepository();

  List<MediaAsset> _assets = [];
  bool _isLoading = true;
  String _selectedType = 'ALL';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    setState(() => _isLoading = true);
    try {
      final type = _selectedType == 'ALL' ? null : _selectedType;
      final data = await _repo.getMediaAssets(
        mediaType: type,
        searchQuery: _searchQuery,
      );
      if (mounted) {
        setState(() {
          _assets = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openUploadDialog() {
    final fileNameController = TextEditingController();
    final publicUrlController = TextEditingController();
    String mediaType = 'IMAGE';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: TNTColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('Register Storage Asset', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminTextField(
                    controller: fileNameController,
                    label: 'File Name',
                    hint: 'e.g. deepavali_2026_banner.jpg',
                    isRequired: true,
                  ),
                  const SizedBox(height: 12),
                  AdminTextField(
                    controller: publicUrlController,
                    label: 'Storage Public URL',
                    hint: 'https://images.unsplash.com/...',
                    isRequired: true,
                  ),
                  const SizedBox(height: 12),
                  AdminDropdown<String>(
                    label: 'Media Type',
                    value: mediaType,
                    items: const [
                      DropdownMenuItem(value: 'IMAGE', child: Text('IMAGE')),
                      DropdownMenuItem(value: 'POSTER', child: Text('POSTER')),
                      DropdownMenuItem(value: 'BANNER', child: Text('BANNER')),
                      DropdownMenuItem(value: 'ICON', child: Text('ICON')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => mediaType = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel', style: TextStyle(color: TNTColors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: TNTColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (fileNameController.text.trim().isEmpty || publicUrlController.text.trim().isEmpty) return;

                  final newAsset = MediaAsset(
                    id: '',
                    fileName: fileNameController.text.trim(),
                    fileSize: 350000,
                    mimeType: 'image/jpeg',
                    storagePath: 'media/${fileNameController.text.trim()}',
                    publicUrl: publicUrlController.text.trim(),
                    mediaType: mediaType,
                    createdBy: 'admin',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  await _repo.registerMediaAsset(newAsset);
                  Navigator.of(ctx).pop();
                  _loadAssets();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Media asset registered successfully!'), backgroundColor: Colors.green),
                    );
                  }
                },
                child: const Text('Save Asset'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _previewAsset(MediaAsset asset) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: TNTColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      asset.fileName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  asset.publicUrl,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 150,
                    color: TNTColors.background,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined, size: 40, color: TNTColors.textMuted),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Size: ${asset.formattedSize} | Type: ${asset.mediaType}', style: const TextStyle(fontSize: 12, color: TNTColors.textSecondary)),
              Text('Storage Path: ${asset.storagePath}', style: const TextStyle(fontSize: 11, color: TNTColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TNTColors.background,
      body: Column(
        children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text('Media Library', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TNTColors.textPrimary)),
                    ),
          // Filter Tabs & Search
          Container(
            color: TNTColors.surface,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) {
                    _searchQuery = val;
                    _loadAssets();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search media by file name...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: TNTColors.textMuted),
                    filled: true,
                    fillColor: TNTColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
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
                      'IMAGE',
                      'POSTER',
                      'BANNER',
                      'ICON',
                    ].map((type) {
                      final isSelected = _selectedType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ChoiceChip(
                          label: Text(type, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : TNTColors.textPrimary)),
                          selected: isSelected,
                          selectedColor: TNTColors.primary,
                          backgroundColor: TNTColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: BorderSide(color: isSelected ? TNTColors.primary : TNTColors.border),
                          ),
                          onSelected: (sel) {
                            if (sel) {
                              setState(() => _selectedType = type);
                              _loadAssets();
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

          // Grid of Media Assets
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: TNTColors.primary))
                : _assets.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.perm_media_outlined, size: 48, color: TNTColors.textMuted),
                              const SizedBox(height: 12),
                              const Text(
                                'No media assets found',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: TNTColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _openUploadDialog,
                                child: const Text('Add Media Asset'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: _assets.length,
                        itemBuilder: (context, index) {
                          final asset = _assets[index];

                          return InkWell(
                            onTap: () => _previewAsset(asset),
                            borderRadius: BorderRadius.circular(10),
                            child: Card(
                              color: TNTColors.surface,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: TNTColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                      child: Image.network(
                                        asset.publicUrl,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: TNTColors.background,
                                          alignment: Alignment.center,
                                          child: const Icon(Icons.image_outlined, size: 36, color: TNTColors.textMuted),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          asset.fileName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TNTColors.textPrimary),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(asset.mediaType, style: const TextStyle(fontSize: 10, color: TNTColors.primary, fontWeight: FontWeight.bold)),
                                            Text(asset.formattedSize, style: const TextStyle(fontSize: 10, color: TNTColors.textMuted)),
                                          ],
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
          ),
        ],
      ),
    );
  }
}
