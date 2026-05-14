import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool compact;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: compact ? 12 : 16,
          horizontal: compact ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: compact ? 20 : 24),
            SizedBox(height: compact ? 6 : 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: TextStyle(
                    fontSize: compact ? 14 : 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  )),
            ),
            SizedBox(height: compact ? 2 : 4),
            Text(label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: compact ? 10 : 12,
                )),
          ],
        ),
      ),
    );
  }
}
