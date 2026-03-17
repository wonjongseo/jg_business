/// 앱 전반에서 쓰는 반투명 패널 스타일을 공용화한다.
import 'package:flutter/material.dart';
import 'package:jg_business/shared/theme/app_tokens.dart';

class AppPanel extends StatelessWidget {
  const AppPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 28,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface.withOpacity(0.92)
            : Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3833) : AppColors.outline,
        ),
      ),
      child: child,
    );
  }
}
