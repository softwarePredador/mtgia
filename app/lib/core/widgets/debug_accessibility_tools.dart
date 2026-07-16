import 'package:accessibility_tools/accessibility_tools.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const bool _enableAccessibilityTools = bool.fromEnvironment(
  'MANALOOM_ENABLE_ACCESSIBILITY_TOOLS',
  defaultValue: false,
);

class ManaLoomDebugAccessibilityTools extends StatelessWidget {
  const ManaLoomDebugAccessibilityTools({
    super.key,
    required this.child,
    this.enabled = _enableAccessibilityTools,
  });

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode || !enabled) return child;

    return AccessibilityTools(
      logLevel: LogLevel.warning,
      checkFontOverflows: true,
      enableButtonsDrag: false,
      child: child,
    );
  }
}

Widget buildManaLoomDebugAccessibilityTools(
  BuildContext context,
  Widget? child,
) {
  return ManaLoomDebugAccessibilityTools(
    child: child ?? const SizedBox.shrink(),
  );
}
