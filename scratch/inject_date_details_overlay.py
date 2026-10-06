def replace_lines(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    import re
    content = "".join(lines)
    
    # Import overlays
    if 'import \'../../core/widgets/tnt_loading_overlay.dart\';' not in content:
        content = content.replace(
            "import '../../core/widgets/state_widgets.dart';",
            "import '../../core/widgets/state_widgets.dart';\nimport '../../core/widgets/tnt_loading_overlay.dart';\nimport '../../core/widgets/tnt_error_overlay.dart';"
        )
    
    old_body = """      body: _isLoading
          ? const TNTLoadingWidget()
          : _errorMsg != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: TNTColors.primary, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          isTamil 
                              ? "தகவல்களைப் பெற முடியவில்லை. மீண்டும் முயற்சிக்கவும்."
                              : "Unable to load information. Please try again.",
                          style: const TextStyle(fontSize: 14, color: TNTColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadAllDayDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TNTColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(translate('retry_btn')),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView("""

    new_body = """      body: Stack(
        children: [
          SingleChildScrollView("""
          
    content = content.replace(old_body, new_body)

    old_end = """                      ],
                    ),
                  ),
                ),
    );
  }"""
    
    new_end = """                      ],
                    ),
                  ),
                ),
          if (_isLoading) const Positioned.fill(child: TNTLoadingOverlay()),
          if (_errorMsg != null && !_isLoading)
            Positioned.fill(
              child: TNTErrorOverlay(
                onRetry: _loadAllDayDetails,
              ),
            ),
        ],
      ),
    );
  }"""
    
    content = content.replace(old_end, new_end)
    
    with open(filepath, 'w', encoding='utf-8', newline='') as f:
        f.write(content)

replace_lines('lib/calendar/screens/date_details_screen.dart')
print('Date details screen overlay added.')
