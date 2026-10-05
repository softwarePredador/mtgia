import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'raw network image callers stay limited to the card loader and avatars',
    () {
      const allowedFiles = <String>{
        'lib/core/widgets/cached_card_image.dart',
        'lib/features/binder/screens/marketplace_screen.dart',
        'lib/features/community/screens/community_screen.dart',
        'lib/features/messages/screens/chat_screen.dart',
        'lib/features/messages/screens/message_inbox_screen.dart',
        'lib/features/profile/profile_screen.dart',
        'lib/features/social/screens/user_profile_screen.dart',
        'lib/features/social/screens/user_search_screen.dart',
      };
      const rawNetworkConstructors = <String>[
        'CachedNetworkImage(',
        'Image.network(',
        'NetworkImage(',
        'CachedNetworkImageProvider(',
      ];

      final callers = _dartFiles(Directory('lib'))
          .where((file) {
            final source = file.readAsStringSync();
            return rawNetworkConstructors.any(source.contains);
          })
          .map((file) => file.path.replaceAll('\\', '/'))
          .toSet();

      expect(callers, unorderedEquals(allowedFiles));
    },
  );

  test('feature surfaces do not request art crops', () {
    final offenders = _dartFiles(Directory('lib/features'))
        .where((file) => file.readAsStringSync().contains('art_crop'))
        .map((file) => file.path.replaceAll('\\', '/'))
        .toList(growable: false);

    expect(offenders, isEmpty);
  });

  // BT-UX-IMG-001: card images go through CardArtwork, which owns the 63:88
  // frame, the labelled states and the fallback name. The direct
  // CachedCardImage calls left are on surfaces that are OFF in the beta
  // (battle, social, community); they migrate before those flags open.
  test('direct CachedCardImage calls stay on surfaces outside the beta', () {
    const allowed = <String, int>{
      'lib/features/battle/screens/battle_coach_screen.dart': 4,
      'lib/features/battle/screens/battle_replays_screen.dart': 2,
      'lib/features/community/screens/community_screen.dart': 3,
      'lib/features/social/screens/user_profile_screen.dart': 4,
    };

    final found = <String, int>{};
    for (final file in _dartFiles(Directory('lib/features'))) {
      final count = 'CachedCardImage('
          .allMatches(file.readAsStringSync())
          .length;
      if (count > 0) found[file.path.replaceAll('\\', '/')] = count;
    }

    expect(found, equals(allowed));
  });

  // BT-ART-01 / D-37: card artwork is always shown whole. A card widget
  // that receives cover, fill or fitWidth would crop the card.
  test('card image widgets never crop the card', () {
    final offenders = <String>[];
    for (final file in _dartFiles(Directory('lib/features'))) {
      final source = file.readAsStringSync();
      for (final call in _calls(source, const [
        'CachedCardImage(',
        'CardArtwork(',
      ])) {
        if (RegExp(r'BoxFit\.(cover|fill|fitWidth|fitHeight)').hasMatch(call)) {
          offenders.add(file.path.replaceAll('\\', '/'));
        }
      }
    }

    expect(offenders, isEmpty);
  });

  // BT-ART-01: a reference image is labelled. Only thumbnails too small for
  // the badge may hide it; they keep the semantic label. The deck hero is a
  // beta surface where reference art is common, so it always shows the badge.
  test('only listed thumbnails hide the artwork status badge', () {
    const allowed = <String, int>{
      'lib/features/battle/screens/battle_live_spectator_screen.dart': 2,
      'lib/features/collection/screens/sets_catalog_screen.dart': 1,
      'lib/features/decks/widgets/deck_optimize_sheet_widgets.dart': 1,
      'lib/features/decks/widgets/deck_workshop_tab.dart': 1,
      'lib/features/home/home_screen.dart': 1,
      'lib/features/retention/screens/post_game_notes_screen.dart': 3,
      'lib/features/scanner/widgets/scanned_card_preview.dart': 1,
    };

    final found = <String, int>{};
    for (final file in _dartFiles(Directory('lib'))) {
      final count = 'showStatusBadge: false'
          .allMatches(file.readAsStringSync())
          .length;
      if (count > 0) found[file.path.replaceAll('\\', '/')] = count;
    }

    expect(found, equals(allowed));
  });
}

/// Source of every call to one of [constructors], up to its closing paren.
Iterable<String> _calls(String source, List<String> constructors) sync* {
  for (final constructor in constructors) {
    var start = source.indexOf(constructor);
    while (start >= 0) {
      var depth = 0;
      var end = start + constructor.length - 1;
      for (; end < source.length; end++) {
        final char = source[end];
        if (char == '(') depth++;
        if (char == ')' && --depth == 0) break;
      }
      yield source.substring(start, end.clamp(start, source.length));
      start = source.indexOf(constructor, end);
    }
  }
}

Iterable<File> _dartFiles(Directory root) sync* {
  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('.dart')) yield entity;
  }
}
