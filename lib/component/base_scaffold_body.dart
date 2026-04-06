import 'package:fiksOpp/component/loader_widget.dart';
import 'package:fiksOpp/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

class Body extends StatelessWidget {
  final Widget child;
  final bool showLoader;

  const Body({Key? key, required this.child, this.showLoader = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : context.width();
        final h = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : context.height();
        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            fit: StackFit.expand,
            children: [
              child,
              if (showLoader)
                Observer(
                    builder: (_) =>
                        LoaderWidget().center().visible(appStore.isLoading)),
            ],
          ),
        );
      },
    );
  }
}
