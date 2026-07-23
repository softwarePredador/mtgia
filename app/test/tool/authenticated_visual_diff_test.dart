import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../../tool/authenticated_visual_diff.dart';

void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('manaloom-visual-diff-');
  });

  tearDown(() {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  test('passes matching PNGs and does not leave stale failures', () {
    final baseline = Directory('${temp.path}/baseline')..createSync();
    final actual = Directory('${temp.path}/actual')..createSync();
    final failure = Directory('${temp.path}/failure')..createSync();
    File('${failure.path}/stale.png').writeAsBytesSync(<int>[1]);
    _writeSolidPng(File('${baseline.path}/web/home.png'), 0xff112233);
    _writeSolidPng(File('${actual.path}/web/home.png'), 0xff112233);

    final report = compareVisualDirectories(
      baselineRoot: baseline,
      actualRoot: actual,
      failureRoot: failure,
    );

    expect(report.isSuccess, isTrue);
    expect(report.passed, 1);
    expect(report.failed, 0);
    expect(failure.existsSync(), isFalse);
  });

  test('fails changed, missing and unexpected PNGs with a diff artifact', () {
    final baseline = Directory('${temp.path}/baseline')..createSync();
    final actual = Directory('${temp.path}/actual')..createSync();
    final failure = Directory('${temp.path}/failure');
    _writeSolidPng(File('${baseline.path}/changed.png'), 0xff000000);
    _writeSolidPng(File('${actual.path}/changed.png'), 0xffffffff);
    _writeSolidPng(File('${baseline.path}/missing.png'), 0xff000000);
    _writeSolidPng(File('${actual.path}/unexpected.png'), 0xff000000);

    final report = compareVisualDirectories(
      baselineRoot: baseline,
      actualRoot: actual,
      failureRoot: failure,
      maximumChangedPixelRatio: 0.001,
    );

    expect(report.isSuccess, isFalse);
    expect(report.failed, 3);
    expect(File('${failure.path}/changed.png').existsSync(), isTrue);
    expect(
      report.entries.map((entry) => entry.detail),
      containsAll(<String?>['missing actual image', 'unexpected actual image']),
    );
  });

  test('accepts change at or below the configured ratio', () {
    final baseline = Directory('${temp.path}/baseline')..createSync();
    final actual = Directory('${temp.path}/actual')..createSync();
    final failure = Directory('${temp.path}/failure');
    final expected = img.Image(width: 10, height: 10)..clear();
    final observed = img.Image.from(expected)..setPixelRgba(0, 0, 1, 1, 1, 255);
    File('${baseline.path}/edge.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(img.encodePng(expected));
    File('${actual.path}/edge.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(img.encodePng(observed));

    final report = compareVisualDirectories(
      baselineRoot: baseline,
      actualRoot: actual,
      failureRoot: failure,
      maximumChangedPixelRatio: 0.01,
    );

    expect(report.isSuccess, isTrue);
    expect(report.entries.single.changedPixelRatio, 0.01);
  });
}

void _writeSolidPng(File file, int color) {
  final image = img.Image(width: 4, height: 4)
    ..clear(
      img.ColorRgba8(
        (color >> 16) & 0xff,
        (color >> 8) & 0xff,
        color & 0xff,
        (color >> 24) & 0xff,
      ),
    );
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(image));
}
