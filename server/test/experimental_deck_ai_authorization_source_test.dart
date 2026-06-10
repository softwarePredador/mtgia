import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('experimental deck/AI authorization source guards', () {
    test('deck simulation and recommendations scope deck reads by owner', () {
      final simulate = File(
        'routes/decks/[id]/simulate/index.dart',
      ).readAsStringSync();
      final recommendations = File(
        'routes/decks/[id]/recommendations/index.dart',
      ).readAsStringSync();

      expect(simulate, contains('final userId = context.read<String>()'));
      expect(simulate, contains('AND user_id = CAST(@userId AS uuid)'));
      expect(simulate, contains('JOIN decks d ON d.id = dc.deck_id'));
      expect(simulate, contains('AND d.user_id = CAST(@userId AS uuid)'));
      expect(
          recommendations, contains('final userId = context.read<String>()'));
      expect(
        recommendations,
        contains('AND user_id = CAST(@userId AS uuid)'),
      );
    });

    test('AI matchup and weakness routes do not read private decks by id only',
        () {
      final matchup = File(
        'routes/ai/simulate-matchup/index.dart',
      ).readAsStringSync();
      final weakness = File(
        'routes/ai/weakness-analysis/index.dart',
      ).readAsStringSync();

      expect(matchup, contains('final userId = context.read<String>()'));
      expect(matchup, contains('user_id = CAST(@user_id AS uuid)'));
      expect(
        matchup,
        contains('OR (CAST(@allow_public AS boolean) AND is_public = true)'),
      );
      expect(
        matchup,
        isNot(contains('SELECT id, name, format FROM decks WHERE id = @id')),
      );
      expect(weakness, contains('final userId = context.read<String>()'));
      expect(weakness, contains('AND user_id = CAST(@user_id AS uuid)'));
      expect(
        weakness,
        isNot(contains('SELECT name, format FROM decks WHERE id = @id')),
      );
    });

    test('/ai/archetypes scopes deck reads by owner', () {
      final archetypes = File(
        'routes/ai/archetypes/index.dart',
      ).readAsStringSync();

      expect(archetypes, contains('final userId = context.read<String>()'));
      expect(archetypes, contains('AND user_id = CAST(@user_id AS uuid)'));
      expect(
        archetypes,
        isNot(contains('SELECT name, format FROM decks WHERE id = @id')),
      );
    });

    test('following community feed has explicit app-facing route file', () {
      final dedicatedRoute = File(
        'routes/community/decks/following/index.dart',
      ).readAsStringSync();
      final dynamicRoute = File(
        'routes/community/decks/[id].dart',
      ).readAsStringSync();

      expect(dedicatedRoute, contains('getFollowingFeed(context)'));
      expect(dynamicRoute, contains("if (id == 'following')"));
      expect(dynamicRoute, contains('getFollowingFeed(context)'));
    });
  });
}
