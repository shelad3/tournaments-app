import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;

  const StatusBadge({
    super.key,
    required this.label,
    this.icon,
    required this.color,
  });

  const StatusBadge.green(String label, {super.key, IconData? icon})
      : label = label,
        icon = icon ?? Icons.check_circle,
        color = Colors.green;

  const StatusBadge.orange(String label, {super.key, IconData? icon})
      : label = label,
        icon = icon ?? Icons.timer,
        color = Colors.orange;

  const StatusBadge.red(String label, {super.key, IconData? icon})
      : label = label,
        icon = icon ?? Icons.warning,
        color = Colors.red;

  const StatusBadge.blue(String label, {super.key, IconData? icon})
      : label = label,
        icon = icon ?? Icons.info,
        color = Colors.blue;

  const StatusBadge.grey(String label, {super.key, IconData? icon})
      : label = label,
        icon = icon ?? Icons.check,
        color = Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              )),
        ],
      ),
    );
  }
}
