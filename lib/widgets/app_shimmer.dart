import 'package:flutter/material.dart';

class AppShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const AppShimmer({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListenableBuilder(
      listenable: _controller,
      builder: (_, __) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1 + _controller.value * 2, 0),
              end: Alignment(1 + _controller.value * 2, 0),
              colors: [
                isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                isDark ? Colors.grey.shade700 : Colors.grey.shade100,
                isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              ],
            ),
          ),
        );
      },
    );
  }
}

class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double spacing;
  final EdgeInsets padding;

  const ShimmerList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 100,
    this.spacing = 12,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (_, i) => Padding(
        padding: EdgeInsets.only(bottom: spacing),
        child: AppShimmer(height: itemHeight),
      ),
    );
  }
}
