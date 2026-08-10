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
}

Iterable<File> _dartFiles(Directory root) sync* {
  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('.dart')) yield entity;
  }
}
