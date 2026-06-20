import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String source;

  setUpAll(() {
    source =
        File('bin/canonicalize_learned_deck_metadata.dart').readAsStringSync();
  });

  test('keeps dry-run as default and apply explicit', () {
    expect(source, contains("final apply = args.contains('--apply')"));
    expect(source, contains("'mode': apply ? 'apply' : 'dry_run'"));
    expect(source, contains("'db_mutations': apply"));
    expect(source, contains('if (apply && args.contains(\'--dry-run\'))'));
  });

  test('supports auditable chunked dry-run output', () {
    expect(source, contains("--offset=<N>"));
    expect(source, contains("--progress"));
    expect(source, contains("--include-full-metadata"));
    expect(source, contains("'before_full': deck.input.metadata"));
    expect(source, contains("'after_full': canonicalMetadata"));
  });

  test('keeps stdout machine-readable while routing logs to stderr', () {
    expect(source, contains('ZoneSpecification'));
    expect(source, contains('stderr.writeln(line)'));
    expect(source, contains('JSON limpo em stdout'));
  });
}
