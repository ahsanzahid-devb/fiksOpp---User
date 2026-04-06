import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  /// When false, content can extend under the status bar (caller handles top inset).
  final bool safeAreaTop;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.safeAreaTop = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isTablet = context.width() >= 600;
    final double effectiveMaxWidth =
        maxWidth ?? (isTablet ? 700.0 : double.infinity);

    return SafeArea(
      top: safeAreaTop,
      child: Align(
        alignment: safeAreaTop ? Alignment.center : Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
          child: Padding(
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: safeAreaTop
                ? child
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // SizedBox.expand breaks inside SingleChildScrollView (unbounded height).
                      if (!constraints.maxHeight.isFinite) {
                        return child;
                      }
                      return SizedBox(
                        width: constraints.maxWidth.isFinite
                            ? constraints.maxWidth
                            : double.infinity,
                        height: constraints.maxHeight,
                        child: child,
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
