import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/core/widgets/responsive_page_frame.dart';

Future<void> _pump(WidgetTester tester, Size size, Widget child) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: ResponsivePageFrame(child: child))),
  );
}

void main() {
  testWidgets('bounds wide pages and applies compact gutters', (tester) async {
    await _pump(
      tester,
      const Size(1880, 900),
      const SizedBox(key: Key('content'), width: double.infinity, height: 40),
    );
    expect(
      tester.getSize(find.byKey(const Key('content'))).width,
      AppTheme.contentMaxWidth - (AppTheme.pageGutter * 2),
    );

    await _pump(
      tester,
      const Size(390, 844),
      const SizedBox(key: Key('compact-content'), width: double.infinity),
    );
    expect(
      tester.getSize(find.byKey(const Key('compact-content'))).width,
      390 - (AppTheme.pageGutterCompact * 2),
    );
  });

  testWidgets('master detail stacks then becomes two panes', (tester) async {
    await _pump(
      tester,
      const Size(390, 844),
      const AdaptiveMasterDetail(
        master: SizedBox(key: Key('master'), height: 40),
        detail: SizedBox(key: Key('detail'), height: 40),
      ),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('detail'))).dy,
      greaterThan(tester.getBottomLeft(find.byKey(const Key('master'))).dy),
    );

    await _pump(
      tester,
      const Size(1440, 900),
      const AdaptiveMasterDetail(
        master: SizedBox(key: Key('wide-master'), height: 40),
        detail: SizedBox(key: Key('wide-detail'), height: 40),
      ),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('wide-detail'))).dx,
      greaterThan(tester.getTopRight(find.byKey(const Key('wide-master'))).dx),
    );
  });
}
