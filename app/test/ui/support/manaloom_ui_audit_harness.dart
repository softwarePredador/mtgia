import 'package:accessibility_tools/accessibility_tools.dart';
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';

const manaloomMobileAuditSize = Size(390, 844);
const manaloomGoldenViewport = BoxConstraints(maxWidth: 430);
const manaloomGoldenScenarioConstraints = BoxConstraints(maxWidth: 390);
const manaloomFullScreenGoldenConstraints = BoxConstraints.tightFor(
  width: 390,
  height: 844,
);

AlchemistConfig manaloomAlchemistConfig() {
  return AlchemistConfig.current().merge(
    AlchemistConfig(
      theme: AppTheme.darkTheme,
      platformGoldensConfig: const PlatformGoldensConfig(enabled: false),
      ciGoldensConfig: const CiGoldensConfig(
        obscureText: true,
        renderShadows: false,
        diffThreshold: 0.001,
      ),
    ),
  );
}

void runManaLoomUiGoldenConfig({required void Function() run}) {
  AlchemistConfig.runWithConfig(config: manaloomAlchemistConfig(), run: run);
}

void setManaLoomMobileViewport(
  WidgetTester tester, {
  Size size = manaloomMobileAuditSize,
  double devicePixelRatio = 1,
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget manaloomDecoratedAuditSurface({required Widget child}) {
  return DecoratedBox(
    decoration: const BoxDecoration(gradient: AppTheme.scaffoldGradient),
    child: child,
  );
}

Widget manaloomAccessibilityShell({required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.darkTheme,
    builder: (context, appChild) => AccessibilityTools(
      logLevel: LogLevel.warning,
      checkFontOverflows: true,
      enableButtonsDrag: false,
      testingToolsConfiguration: const TestingToolsConfiguration(
        enabled: false,
      ),
      child: appChild ?? const SizedBox.shrink(),
    ),
    home: Scaffold(body: manaloomDecoratedAuditSurface(child: child)),
  );
}

Future<void> expectManaLoomBaselineAccessibility(WidgetTester tester) async {
  expect(find.byIcon(Icons.accessibility_new), findsNothing);
  expect(find.byIcon(Icons.build), findsNothing);
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}
