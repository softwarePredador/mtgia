import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors Flutter's ListTile ink visibility contract on SDKs that predate the
/// framework diagnostic introduced in Flutter 3.44.
void expectListTileInkIsUnobscured(WidgetTester tester) {
  final failures = <String>[];

  for (final tileElement in find.byType(ListTile).evaluate()) {
    Widget? obscuringWidget;

    tileElement.visitAncestorElements((ancestor) {
      final widget = ancestor.widget;
      if (widget is Material) {
        return false;
      }

      final color = switch (widget) {
        ColoredBox(:final color) => color,
        DecoratedBox(decoration: BoxDecoration(:final color)) => color,
        DecoratedBox(decoration: ShapeDecoration(:final color)) => color,
        _ => null,
      };
      if (color != null && color.a > 0) {
        obscuringWidget = widget;
        return false;
      }
      return true;
    });

    if (obscuringWidget != null) {
      failures.add(
        '${tileElement.widget.toStringShort()} is obscured by '
        '${obscuringWidget.runtimeType}',
      );
    }
  }

  expect(
    failures,
    isEmpty,
    reason:
        'ListTile ink must reach its nearest Material without crossing an '
        'opaque ColoredBox or DecoratedBox.\n${failures.join('\n')}',
  );
}
