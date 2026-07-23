import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared bounded canvas for pages that should reflow instead of stretching.
///
/// The frame owns horizontal gutters and max-width. Scrolling remains the
/// responsibility of the screen so it can be used around forms, lists, grids,
/// and custom scroll views without creating nested scrollables.
class ResponsivePageFrame extends StatelessWidget {
  const ResponsivePageFrame({
    super.key,
    required this.child,
    this.maxWidth = AppTheme.contentMaxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = AppTheme.horizontalGutterForWidth(
          constraints.maxWidth,
        );
        return Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: padding ?? EdgeInsets.symmetric(horizontal: horizontal),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Two-pane composition used by operational desktop screens.
class AdaptiveMasterDetail extends StatelessWidget {
  const AdaptiveMasterDetail({
    super.key,
    required this.master,
    required this.detail,
    this.masterWidth = AppTheme.inspectorWidth,
    this.breakpoint = AppTheme.breakpointExpanded,
    this.gap = AppTheme.paneGap,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final Widget master;
  final Widget detail;
  final double masterWidth;
  final double breakpoint;
  final double gap;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              master,
              SizedBox(height: gap),
              detail,
            ],
          );
        }
        return Row(
          crossAxisAlignment: crossAxisAlignment,
          children: [
            SizedBox(width: masterWidth, child: master),
            SizedBox(width: gap),
            Expanded(child: detail),
          ],
        );
      },
    );
  }
}
