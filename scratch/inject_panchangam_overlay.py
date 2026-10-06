def replace_lines(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    import re
    content = "".join(lines)
    
    # Stack replacement
    content = re.sub(
        r'Expanded\(\s*child:\s*_buildBody\(localizations, isTamil, translate\),\s*\)',
        '''Expanded(
              child: Stack(
                children: [
                  _buildBody(localizations, isTamil, translate),
                  if (_isLoading) const Positioned.fill(child: TNTLoadingOverlay()),
                  if (_errorMessage != null && !_isLoading)
                    Positioned.fill(
                      child: TNTErrorOverlay(
                        onRetry: () => _loadPanchangamData(forceRefresh: true),
                        overrideMessage: _errorMessage!.contains('No astronomical data') ? _errorMessage : null,
                      ),
                    ),
                ],
              ),
            )''',
        content
    )
    
    # Import
    if 'import \'../../core/widgets/tnt_loading_overlay.dart\';' not in content:
        content = content.replace(
            "import '../../core/widgets/state_widgets.dart';",
            "import '../../core/widgets/state_widgets.dart';\nimport '../../core/widgets/tnt_loading_overlay.dart';\nimport '../../core/widgets/tnt_error_overlay.dart';"
        )
        
    # _buildBody
    content = re.sub(
        r'    if \(_isLoading\) \{\s*return const TNTLoadingWidget\(\);\s*\}\s*if \(_errorMessage != null && _bundle == null\) \{\s*return TNTErrorWidget\(\s*message: _errorMessage!,\s*onRetry: \(\) => _loadPanchangamData\(forceRefresh: true\),\s*\);\s*\}',
        '''    // Loading and Error are now handled by overlays in the Stack.''',
        content
    )
    
    # Error message assignment
    content = content.replace("_errorMessage = e.toString();", "print(e.toString());\n        _errorMessage = e.toString();")
    
    with open(filepath, 'w', encoding='utf-8', newline='') as f:
        f.write(content)

replace_lines('lib/panchangam/screens/panchangam_screen.dart')
print('Panchangam screen overlay added.')
