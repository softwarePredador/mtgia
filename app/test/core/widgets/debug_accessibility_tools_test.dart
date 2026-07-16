import 'package:accessibility_tools/accessibility_tools.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/widgets/debug_accessibility_tools.dart';

void main() {
  testWidgets('does not wrap the app when the debug audit flag is off', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ManaLoomDebugAccessibilityTools(
          enabled: false,
          child: SizedBox(key: Key('subject')),
        ),
      ),
    );

    expect(find.byKey(const Key('subject')), findsOneWidget);
    expect(find.byType(AccessibilityTools), findsNothing);
  });

  test('keeps the enabled flag explicit for debug-only app launches', () {
    const widget = ManaLoomDebugAccessibilityTools(
      enabled: true,
      child: SizedBox(key: Key('subject')),
    );

    expect(widget.enabled, isTrue);
    expect(kDebugMode, isTrue);
  });
}
