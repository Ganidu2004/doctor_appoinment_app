// lib/widgets/doc_time_logo.dart

import 'package:flutter/material.dart';

enum DocTimeLogoVariant {
  horizontal, // Logo icon + text side-by-side (Header / AppBar)
  vertical,   // Logo icon top + text below (Splash / Welcome / Login)
  iconOnly,   // Rounded logo badge icon only
}

class DocTimeLogo extends StatelessWidget {
  final DocTimeLogoVariant variant;
  final double iconSize;
  final double fontSize;
  final Color? textColor;
  final bool showTagline;

  const DocTimeLogo({
    super.key,
    this.variant = DocTimeLogoVariant.horizontal,
    this.iconSize = 38.0,
    this.fontSize = 22.0,
    this.textColor,
    this.showTagline = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultTextColor = isDark ? Colors.white : Colors.black87;
    final effectiveTextColor = textColor ?? defaultTextColor;

    Widget iconWidget = Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF500CA4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(iconSize * 0.28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.35),
            blurRadius: iconSize * 0.35,
            offset: Offset(0, iconSize * 0.15),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: iconSize * 0.62,
          ),
          Positioned(
            right: iconSize * 0.1,
            bottom: iconSize * 0.1,
            child: Container(
              padding: EdgeInsets.all(iconSize * 0.04),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.access_time_filled_rounded,
                color: const Color(0xFF0EA5E9),
                size: iconSize * 0.36,
              ),
            ),
          ),
        ],
      ),
    );

    if (variant == DocTimeLogoVariant.iconOnly) {
      return iconWidget;
    }

    Widget textWidget = Column(
      crossAxisAlignment: variant == DocTimeLogoVariant.vertical
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          textAlign: variant == DocTimeLogoVariant.vertical ? TextAlign.center : TextAlign.start,
          text: TextSpan(
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
            children: [
              TextSpan(
                text: 'DOC ',
                style: TextStyle(color: effectiveTextColor),
              ),
              TextSpan(
                text: 'Time',
                style: TextStyle(
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                    ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 2),
          Text(
            'Your Health • On Time',
            style: TextStyle(
              fontSize: fontSize * 0.42,
              fontWeight: FontWeight.w600,
              color: effectiveTextColor.withValues(alpha: 0.7),
              letterSpacing: 1.0,
            ),
          ),
        ],
      ],
    );

    if (variant == DocTimeLogoVariant.vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          SizedBox(height: iconSize * 0.3),
          textWidget,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        iconWidget,
        SizedBox(width: iconSize * 0.3),
        textWidget,
      ],
    );
  }
}
