import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('fresh schema and verifier own cards.is_reserved', () {
    final setup = File('database_setup.sql').readAsStringSync().toLowerCase();
    final verifier = File('bin/verify_schema.dart').readAsStringSync();

    expect(setup, contains('is_reserved boolean not null default false'));
    expect(
      setup,
      contains(
        'update cards set is_reserved = false where is_reserved is null',
      ),
    );
    expect(setup, contains('alter column is_reserved set not null'));
    expect(verifier, contains("'is_reserved'"));
  });

  test('runtime card reads are backed by the migration-owned column', () {
    final cardsRoute = File('routes/cards/index.dart').readAsStringSync();
    final detailRoute = File('routes/decks/[id]/index.dart').readAsStringSync();

    expect(cardsRoute, contains('c.is_reserved'));
    expect(detailRoute, contains('c.is_reserved'));
  });
}
