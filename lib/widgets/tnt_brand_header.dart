import 'package:flutter/material.dart';

class TNTBrandHeader extends StatelessWidget {
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  final double? logoSize;

  const TNTBrandHeader({
    super.key,
    this.padding,
    this.fontSize,
    this.logoSize,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine sizing based on available width
        final screenWidth = MediaQuery.of(context).size.width;
        double defaultLogoSize = 32.0;
        double defaultFontSize = 14.0;
        double spacing = 8.0;

        if (screenWidth <= 360) {
          defaultLogoSize = 24.0;
          defaultFontSize = 12.0;
          spacing = 4.0;
        } else if (screenWidth > 600) {
          defaultLogoSize = 40.0;
          defaultFontSize = 16.0;
          spacing = 12.0;
        }

        final effectiveLogoSize = logoSize ?? defaultLogoSize;
        final effectiveFontSize = fontSize ?? defaultFontSize;

        return Padding(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(effectiveLogoSize / 4),
                child: Image.asset(
                  'assets/images/tnt_logo.jpg',
                  width: effectiveLogoSize,
                  height: effectiveLogoSize,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: effectiveLogoSize,
                      height: effectiveLogoSize,
                      color: Colors.grey[300],
                      child: Icon(Icons.calendar_today, size: effectiveLogoSize * 0.6, color: Colors.grey[600]),
                    );
                  },
                ),
              ),
              SizedBox(width: spacing),
              Flexible(
                child: Text(
                  "TNT Tamil Calendar",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: effectiveFontSize,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
