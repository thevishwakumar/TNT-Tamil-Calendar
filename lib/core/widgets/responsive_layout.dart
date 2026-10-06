import 'package:flutter/material.dart';

class TNTBreakpoints {
  static const double compact = 600.0;
  static const double medium = 1024.0;
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  static bool isMobile(BuildContext context) => MediaQuery.sizeOf(context).width < TNTBreakpoints.compact;
  static bool isTablet(BuildContext context) => MediaQuery.sizeOf(context).width >= TNTBreakpoints.compact && MediaQuery.sizeOf(context).width < TNTBreakpoints.medium;
  static bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= TNTBreakpoints.medium;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= TNTBreakpoints.medium) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= TNTBreakpoints.compact) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

class TNTResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final double maxWidth;

  const TNTResponsiveScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.maxWidth = 800.0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: body,
          ),
        ),
      ),
    );
  }
}
