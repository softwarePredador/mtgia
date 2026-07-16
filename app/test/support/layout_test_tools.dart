import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void enableFatalHitTestWarnings() {
  final previous = WidgetController.hitTestWarningShouldBeFatal;
  WidgetController.hitTestWarningShouldBeFatal = true;
  addTearDown(() {
    WidgetController.hitTestWarningShouldBeFatal = previous;
  });
}

void setTestViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void expectNoLayoutExceptions(WidgetTester tester) {
  expect(tester.takeException(), isNull);
}
