import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

class VisualDiffEntry {
  const VisualDiffEntry({
    required this.relativePath,
    required this.status,
    required this.changedPixels,
    required this.totalPixels,
    required this.changedPixelRatio,
    this.detail,
    this.diffPath,
  });

  final String relativePath;
  final String status;
  final int changedPixels;
  final int totalPixels;
  final double changedPixelRatio;
  final String? detail;
  final String? diffPath;

  Map<String, Object?> toJson() => <String, Object?>{
    'path': relativePath,
    'status': status,
    'changed_pixels': changedPixels,
    'total_pixels': totalPixels,
    'changed_pixel_ratio': changedPixelRatio,
    if (detail != null) 'detail': detail,
    if (diffPath != null) 'diff_path': diffPath,
  };
}

class VisualDiffReport {
  const VisualDiffReport({required this.threshold, required this.entries});

  final double threshold;
  final List<VisualDiffEntry> entries;

  int get passed => entries.where((entry) => entry.status == 'pass').length;
  int get failed => entries.length - passed;
  bool get isSuccess => entries.isNotEmpty && failed == 0;

  Map<String, Object?> toJson() => <String, Object?>{
    'schema_version': 1,
    'status': isSuccess ? 'pass' : 'fail',
    'maximum_changed_pixel_ratio': threshold,
    'total_files': entries.length,
    'passed_files': passed,
    'failed_files': failed,
    'entries': entries.map((entry) => entry.toJson()).toList(),
  };
}

VisualDiffReport compareVisualDirectories({
  required Directory baselineRoot,
  required Directory actualRoot,
  required Directory failureRoot,
  double maximumChangedPixelRatio = 0.001,
}) {
  if (!baselineRoot.existsSync()) {
    throw ArgumentError('Baseline root does not exist: ${baselineRoot.path}');
  }
  if (!actualRoot.existsSync()) {
    throw ArgumentError('Actual root does not exist: ${actualRoot.path}');
  }
  if (maximumChangedPixelRatio < 0 || maximumChangedPixelRatio > 1) {
    throw ArgumentError.value(
      maximumChangedPixelRatio,
      'maximumChangedPixelRatio',
      'must be between 0 and 1',
    );
  }

  if (failureRoot.existsSync()) {
    failureRoot.deleteSync(recursive: true);
  }

  final baselineFiles = _pngFilesByRelativePath(baselineRoot);
  final actualFiles = _pngFilesByRelativePath(actualRoot);
  final paths = <String>{...baselineFiles.keys, ...actualFiles.keys}.toList()
    ..sort();
  final entries = <VisualDiffEntry>[];

  for (final path in paths) {
    final baselineFile = baselineFiles[path];
    final actualFile = actualFiles[path];
    if (baselineFile == null || actualFile == null) {
      entries.add(
        VisualDiffEntry(
          relativePath: path,
          status: 'fail',
          changedPixels: 0,
          totalPixels: 0,
          changedPixelRatio: 1,
          detail: baselineFile == null
              ? 'unexpected actual image'
              : 'missing actual image',
        ),
      );
      continue;
    }

    final baseline = img.decodePng(baselineFile.readAsBytesSync());
    final actual = img.decodePng(actualFile.readAsBytesSync());
    if (baseline == null || actual == null) {
      entries.add(
        VisualDiffEntry(
          relativePath: path,
          status: 'fail',
          changedPixels: 0,
          totalPixels: 0,
          changedPixelRatio: 1,
          detail: 'invalid PNG payload',
        ),
      );
      continue;
    }
    if (baseline.width != actual.width || baseline.height != actual.height) {
      entries.add(
        VisualDiffEntry(
          relativePath: path,
          status: 'fail',
          changedPixels: 0,
          totalPixels: baseline.width * baseline.height,
          changedPixelRatio: 1,
          detail:
              'dimension mismatch: baseline ${baseline.width}x${baseline.height}, '
              'actual ${actual.width}x${actual.height}',
        ),
      );
      continue;
    }

    final diff = img.Image(width: baseline.width, height: baseline.height);
    var changed = 0;
    for (var y = 0; y < baseline.height; y++) {
      for (var x = 0; x < baseline.width; x++) {
        final expected = baseline.getPixel(x, y);
        final observed = actual.getPixel(x, y);
        final isDifferent =
            expected.r != observed.r ||
            expected.g != observed.g ||
            expected.b != observed.b ||
            expected.a != observed.a;
        if (isDifferent) {
          changed++;
          diff.setPixelRgba(x, y, 255, 0, 80, 255);
        } else {
          final luminance = ((expected.r + expected.g + expected.b) / 3)
              .round();
          final muted = (luminance * 0.18).round();
          diff.setPixelRgba(x, y, muted, muted, muted, 255);
        }
      }
    }
    final total = baseline.width * baseline.height;
    final ratio = total == 0 ? 1.0 : changed / total;
    final passed = ratio <= maximumChangedPixelRatio;
    String? diffPath;
    if (!passed) {
      final output = File('${failureRoot.path}/$path');
      output.parent.createSync(recursive: true);
      output.writeAsBytesSync(img.encodePng(diff));
      diffPath = output.path;
    }
    entries.add(
      VisualDiffEntry(
        relativePath: path,
        status: passed ? 'pass' : 'fail',
        changedPixels: changed,
        totalPixels: total,
        changedPixelRatio: ratio,
        diffPath: diffPath,
      ),
    );
  }

  return VisualDiffReport(
    threshold: maximumChangedPixelRatio,
    entries: entries,
  );
}

Map<String, File> _pngFilesByRelativePath(Directory root) {
  final prefix = root.absolute.path.endsWith(Platform.pathSeparator)
      ? root.absolute.path
      : '${root.absolute.path}${Platform.pathSeparator}';
  final result = <String, File>{};
  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.toLowerCase().endsWith('.png')) {
      continue;
    }
    final relative = entity.absolute.path
        .substring(prefix.length)
        .replaceAll(Platform.pathSeparator, '/');
    result[relative] = entity;
  }
  return result;
}

Never _usage([String? message]) {
  if (message != null) stderr.writeln(message);
  stderr.writeln(
    'Usage: dart run tool/authenticated_visual_diff.dart '
    '--baseline <dir> --actual <dir> --failure <dir> '
    '[--threshold 0.001] [--summary <file>]',
  );
  exit(2);
}

void main(List<String> args) {
  final values = <String, String>{};
  for (var index = 0; index < args.length; index++) {
    final name = args[index];
    if (!name.startsWith('--') || index + 1 >= args.length) {
      _usage('Invalid argument: $name');
    }
    values[name] = args[++index];
  }
  final baseline = values['--baseline'];
  final actual = values['--actual'];
  final failure = values['--failure'];
  if (baseline == null || actual == null || failure == null) _usage();
  final threshold = double.tryParse(values['--threshold'] ?? '0.001');
  if (threshold == null) _usage('Invalid threshold');

  try {
    final report = compareVisualDirectories(
      baselineRoot: Directory(baseline),
      actualRoot: Directory(actual),
      failureRoot: Directory(failure),
      maximumChangedPixelRatio: threshold,
    );
    final encoded = const JsonEncoder.withIndent('  ').convert(report.toJson());
    stdout.writeln(encoded);
    final summary = values['--summary'];
    if (summary != null) {
      final file = File(summary);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('$encoded\n');
    }
    if (!report.isSuccess) exitCode = 1;
  } on Object catch (error) {
    stderr.writeln(error);
    exitCode = 2;
  }
}
