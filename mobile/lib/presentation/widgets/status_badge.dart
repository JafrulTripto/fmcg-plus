import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

enum BadgeType { success, warning, alert, neutral }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = BadgeType.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bg;
    Color fg;
    Color border;

    if (isDark) {
      switch (type) {
        case BadgeType.success:
          bg = AppConstants.secondaryEmeraldDark.withValues(alpha: 0.12);
          fg = AppConstants.secondaryEmeraldDark;
          border = AppConstants.secondaryEmeraldDark.withValues(alpha: 0.3);
          break;
        case BadgeType.warning:
          bg = AppConstants.dueAmberDark.withValues(alpha: 0.12);
          fg = AppConstants.dueAmberDark;
          border = AppConstants.dueAmberDark.withValues(alpha: 0.3);
          break;
        case BadgeType.alert:
          bg = AppConstants.alertCrimsonDark.withValues(alpha: 0.12);
          fg = AppConstants.alertCrimsonDark;
          border = AppConstants.alertCrimsonDark.withValues(alpha: 0.3);
          break;
        case BadgeType.neutral:
          bg = AppConstants.surfaceContainerLowDark;
          fg = AppConstants.textSecondaryDark;
          border = AppConstants.borderInteractiveDark;
          break;
      }
    } else {
      switch (type) {
        case BadgeType.success:
          bg = AppConstants.secondaryLight;
          fg = AppConstants.secondaryDark;
          border = AppConstants.secondaryEmerald.withValues(alpha: 0.4);
          break;
        case BadgeType.warning:
          bg = AppConstants.dueLight;
          fg = AppConstants.dueAmber;
          border = AppConstants.dueAmber.withValues(alpha: 0.4);
          break;
        case BadgeType.alert:
          bg = AppConstants.alertLight;
          fg = AppConstants.alertCrimson;
          border = AppConstants.alertCrimson.withValues(alpha: 0.4);
          break;
        case BadgeType.neutral:
          bg = Colors.grey.shade100;
          fg = Colors.grey.shade800;
          border = Colors.grey.shade300;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(isDark ? 8 : 9999),
        border: Border.all(color: border, width: isDark ? 1.0 : 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: isDark ? 0.06 * 10 : null,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
