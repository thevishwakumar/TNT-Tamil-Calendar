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
    
    # Old code
    old_code = """    // 1. Initial full blocking loader
    if (_isLoading) {
      return Scaffold(
        backgroundColor: TNTColors.background,
        appBar: _buildHeaderBar(translate),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: TNTColors.primary),
              SizedBox(height: 12),
              Text(
                'Loading today astro metrics...',
                style: TextStyle(fontSize: 12, color: TNTColors.textSecondary, fontWeight: FontWeight.w500),
              )
            ],
          ),
        ),
      );
    }

    // 2. Safe localized error layout with retry hook
    if (_errorMsg != null) {
      return Scaffold(
        backgroundColor: TNTColors.background,
        body: TNTErrorWidget(
          message: translate('error_loading'),
          onRetry: _loadAllHomeData,
        ),
      );
    }

    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: _buildHeaderBar(translate),
      body: RefreshIndicator(
        color: TNTColors.primary,
        backgroundColor: TNTColors.surface,
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: ["""

    new_code = """    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: _buildHeaderBar(translate),
      body: Stack(
        children: [
          RefreshIndicator(
            color: TNTColors.primary,
            backgroundColor: TNTColors.surface,
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: ["""

    content = content.replace(old_code, new_code)
    
    # Bottom of Scaffold body
    old_bottom = """              _buildFeaturedContentCard(translate, isTamil),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );"""
    
    new_bottom = """              _buildFeaturedContentCard(translate, isTamil),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      if (_isLoading) const Positioned.fill(child: TNTLoadingOverlay()),
      if (_errorMsg != null && !_isLoading)
        Positioned.fill(
          child: TNTErrorOverlay(
            onRetry: _loadAllHomeData,
          ),
        ),
      ],
    ),
    );"""
    
    content = content.replace(old_bottom, new_bottom)
    
    with open(filepath, 'w', encoding='utf-8', newline='') as f:
        f.write(content)

replace_lines('lib/home/screens/home_screen.dart')
print('Home screen overlay added.')
