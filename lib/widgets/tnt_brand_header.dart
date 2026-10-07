import 'package:flutter/material.dart';

class TNTBrandHeader extends StatelessWidget {
  const TNTBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine sizing based on available width
        final screenWidth = MediaQuery.of(context).size.width;
        double logoSize = 32.0;
        double fontSize = 14.0;
        double spacing = 8.0;

        if (screenWidth <= 360) {
          logoSize = 24.0;
          fontSize = 12.0;
          spacing = 4.0;
        } else if (screenWidth > 600) {
          logoSize = 40.0;
          fontSize = 16.0;
          spacing = 12.0;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(logoSize / 4),
                child: Image.asset(
                  'assets/images/tnt_logo.jpg',
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: logoSize,
                      height: logoSize,
                      color: Colors.grey[300],
                      child: Icon(Icons.calendar_today, size: logoSize * 0.6, color: Colors.grey[600]),
                    );
                  },
                ),
              ),
              if (screenWidth >= 500) ...[
                SizedBox(width: spacing),
                Text(
                  "TNT Tamil Calendar",
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
