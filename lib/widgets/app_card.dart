import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
    this.onTap,
  });

  const AppCard.compact({
    super.key,
    required this.child,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
    this.onTap,
  }) : padding = const EdgeInsets.all(12);

  const AppCard.spacious({
    super.key,
    required this.child,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
    this.onTap,
  }) : padding = const EdgeInsets.all(20);

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? const EdgeInsets.all(16);
    final effectiveRadius = borderRadius ?? BorderRadius.circular(12);
    final card = Card(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      elevation: elevation ?? 1,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
      child: Padding(
        padding: effectivePadding,
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: effectiveRadius,
        child: card,
      );
    }
    return card;
  }
}
