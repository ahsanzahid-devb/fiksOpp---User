import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

/// A simple responsive wrapper that centers content and constrains
/// its maximum width on larger screens (like iPads), so that forms
/// and lists don't stretch edge-to-edge.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final bool isTablet = context.width() >= 600;
    final double effectiveMaxWidth =
        maxWidth ?? (isTablet ? 700.0 : double.infinity);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
          child: Padding(
            padding:
                padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: child,
          ),
        ),
      ),
    );
  }
}

