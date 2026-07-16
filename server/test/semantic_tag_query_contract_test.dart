import 'dart:io';

import 'package:test/test.dart';

void main() {
  test(
    'semantic role lookups read tag objects instead of array string keys',
    () {
      const paths = <String>[
        'routes/decks/[id]/recommendations/index.dart',
        'routes/ai/weakness-analysis/index.dart',
      ];

      for (final path in paths) {
        final source = File(path).readAsStringSync();
        expect(source, contains('jsonb_array_elements(cstv2.tags)'));
        expect(source, contains("semantic_tag->>'tag'"));
        expect(source, isNot(contains('cstv2.tags ?| @role_tags')));
      }
    },
  );
}
