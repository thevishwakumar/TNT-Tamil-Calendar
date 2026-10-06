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
    
    # Add _errorMessage property
    content = content.replace("bool isLoading = true;", "bool isLoading = true;\n  String? _errorMessage;")
    
    # reset errorMessage in _loadEvents
    content = content.replace("setState(() => isLoading = true);", "setState(() {\n      isLoading = true;\n      _errorMessage = null;\n    });")
    
    # handle catch
    content = content.replace("    } catch (e) {\n      if (mounted) setState(() => isLoading = false);\n    }", "    } catch (e) {\n      print(e.toString());\n      if (mounted) setState(() {\n        isLoading = false;\n        _errorMessage = e.toString();\n      });\n    }")
    
    # Replace body
    old_body = """      body: isLoading
          ? const TNTLoadingWidget()
          : RefreshIndicator(
              color: TNTColors.primary,
              onRefresh: _loadEvents,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Month navigation bar
                    _buildMonthNavigationHeader(isTamil),

                    // Week Days Header Row
                    _buildWeekDaysHeader(isTamil),

                    // Days Grid
                    _buildCalendarGrid(isTamil),

                    const Divider(color: TNTColors.border, height: 1),

                    // Accessible Event Key Indicators List
                    _buildEventIndicatorsList(localizations, isTamil),
                  ],
                ),
              ),
            ),"""

    new_body = """      body: Stack(
        children: [
          RefreshIndicator(
            color: TNTColors.primary,
            onRefresh: _loadEvents,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Month navigation bar
                  _buildMonthNavigationHeader(isTamil),

                  // Week Days Header Row
                  _buildWeekDaysHeader(isTamil),

                  // Days Grid
                  _buildCalendarGrid(isTamil),

                  const Divider(color: TNTColors.border, height: 1),

                  // Accessible Event Key Indicators List
                  _buildEventIndicatorsList(localizations, isTamil),
                ],
              ),
            ),
          ),
          if (isLoading) const Positioned.fill(child: TNTLoadingOverlay()),
          if (_errorMessage != null && !isLoading)
            Positioned.fill(
              child: TNTErrorOverlay(
                onRetry: _loadEvents,
              ),
            ),
        ],
      ),"""
    
    content = content.replace(old_body, new_body)
    
    with open(filepath, 'w', encoding='utf-8', newline='') as f:
        f.write(content)

replace_lines('lib/calendar/screens/calendar_screen.dart')
print('Calendar screen overlay added.')
