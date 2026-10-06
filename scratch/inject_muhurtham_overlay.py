def replace_lines(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    import re
    content = "".join(lines)
    
    # Imports
    if 'import \'../../core/widgets/tnt_loading_overlay.dart\';' not in content:
        content = content.replace(
            "import '../../core/widgets/state_widgets.dart';",
            "import '../../core/widgets/state_widgets.dart';\nimport '../../core/widgets/tnt_loading_overlay.dart';\nimport '../../core/widgets/tnt_error_overlay.dart';"
        )
    
    # Error assignment
    content = content.replace("_errorMessage = e.toString();", "print(e.toString());\n        _errorMessage = e.toString();")
    
    # Stack replacement
    old_code = """            Expanded(
              child: _isLoading
                  ? const TNTLoadingWidget()
                  : _errorMessage != null
                      ? TNTErrorWidget(
                          message: _errorMessage!,
                          onRetry: _loadMuhurthams,
                        )
                      : _muhurthams.isEmpty
                          ? _buildEmptyState(isTamil, localizations)
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                              padding: const EdgeInsets.all(16),
                              itemCount: _muhurthams.length,
                              itemBuilder: (context, index) {
                                final item = _muhurthams[index];
                                return MuhurthamDateCard(
                                  item: item,
                                  onTap: () => _openDetailScreen(item),
                                  onToggleSave: () => _toggleSaveMuhurtham(item),
                                  onSetReminder: () => _openReminderDialog(item),
                                  onShare: () => _openShareSheet(item),
                                );
                              },
                            ),
            ),"""

    new_code = """            Expanded(
              child: Stack(
                children: [
                  _muhurthams.isEmpty && !_isLoading && _errorMessage == null
                      ? _buildEmptyState(isTamil, localizations)
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.all(16),
                          itemCount: _muhurthams.length,
                          itemBuilder: (context, index) {
                            final item = _muhurthams[index];
                            return MuhurthamDateCard(
                              item: item,
                              onTap: () => _openDetailScreen(item),
                              onToggleSave: () => _toggleSaveMuhurtham(item),
                              onSetReminder: () => _openReminderDialog(item),
                              onShare: () => _openShareSheet(item),
                            );
                          },
                        ),
                  if (_isLoading) const Positioned.fill(child: TNTLoadingOverlay()),
                  if (_errorMessage != null && !_isLoading)
                    Positioned.fill(
                      child: TNTErrorOverlay(
                        onRetry: _loadMuhurthams,
                      ),
                    ),
                ],
              ),
            ),"""
    
    content = content.replace(old_code, new_code)
    
    with open(filepath, 'w', encoding='utf-8', newline='') as f:
        f.write(content)

replace_lines('lib/muhurtham/screens/muhurtham_screen.dart')
print('Muhurtham screen overlay added.')
