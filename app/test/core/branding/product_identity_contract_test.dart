import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/branding/product_identity.dart';

void main() {
  test('canonical public identity stays stable', () {
    expect(ProductIdentity.displayName, 'BrewTact');
    expect(ProductIdentity.taglinePtBr, 'Monte melhor. Jogue melhor.');
    expect(ProductIdentity.taglineEn, 'Build smarter. Play better.');
    expect(
      ProductIdentity.descriptionPtBr,
      'Monte, analise, teste e acompanhe seus decks de Magic.',
    );
    expect(
      ProductIdentity.descriptionEn,
      'Build, analyze, test, and track your Magic decks.',
    );
  });

  test('platform metadata exposes BrewTact consistently', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final webIndex = File('web/index.html').readAsStringSync();
    final webManifest =
        jsonDecode(File('web/manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    final androidManifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final mainActivity = File(
      'android/app/src/main/kotlin/com/mtgia/mtg_app/MainActivity.kt',
    ).readAsStringSync();
    final iosInfo = File('ios/Runner/Info.plist').readAsStringSync();
    final lotusIndex = File('assets/lotus/index.html').readAsStringSync();

    expect(pubspec, contains('description: "BrewTact - '));
    expect(pubspec, contains('app_name: BrewTact'));
    expect(webManifest['name'], ProductIdentity.displayName);
    expect(webManifest['short_name'], ProductIdentity.displayName);
    expect(
      webManifest['description'],
      'BrewTact — ${ProductIdentity.descriptionEn}',
    );
    expect(webIndex, contains('<title>BrewTact</title>'));
    expect(
      webIndex,
      contains('apple-mobile-web-app-title" content="BrewTact"'),
    );
    expect(androidManifest, contains('android:label="BrewTact"'));
    expect(mainActivity, contains('"BrewTact",'));
    expect(iosInfo, contains('<string>BrewTact</string>'));
    expect(lotusIndex, contains('<title>BrewTact Life Counter</title>'));

    for (final publicSurface in <String, String>{
      'pubspec.yaml': pubspec,
      'web/index.html': webIndex,
      'web/manifest.json': jsonEncode(webManifest),
      'android/app/src/main/AndroidManifest.xml': androidManifest,
      'ios/Runner/Info.plist': iosInfo,
      'assets/lotus/index.html': lotusIndex,
    }.entries) {
      expect(
        publicSurface.value,
        isNot(contains('ManaLoom')),
        reason: '${publicSurface.key} still exposes the previous public name',
      );
    }
  });

  test(
    'public Dart copy drops the old name without renaming machine contracts',
    () {
      final stringLiteralWithOldName = RegExp(
        r'''(?:r)?'[^'\n]*ManaLoom[^'\n]*'|(?:r)?"[^"\n]*ManaLoom[^"\n]*"''',
      );
      const allowedMachineFacingLiterals = <String>{
        "'ManaLoom/1.0'",
        "'ManaLoomAuth'",
        "'ManaLoomAuthPublicKey'",
        "'FlutterManaLoomShellBridge'",
        "'FlutterManaLoomStorageBridge'",
        "'[ManaLoomShell] Blocked branded link:'",
        "'[ManaLoomShell] Blocked branded window.open:'",
        "r'^ManaLoom nativo(?: revisado)?\\b'",
      };
      final unexpected = <String>[];

      final dartFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final source = file.readAsStringSync();
        for (final match in stringLiteralWithOldName.allMatches(source)) {
          final literal = match.group(0)!;
          if (!allowedMachineFacingLiterals.contains(literal)) {
            unexpected.add('${file.path}: $literal');
          }
        }
      }

      expect(
        unexpected,
        isEmpty,
        reason: 'The previous name remains in customer-facing Dart copy',
      );

      final pubspec = File('pubspec.yaml').readAsStringSync();
      final androidManifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      final mainActivity = File(
        'android/app/src/main/kotlin/com/mtgia/mtg_app/MainActivity.kt',
      ).readAsStringSync();
      final iosProject = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();
      final authStore = File(
        'lib/core/security/auth_token_store.dart',
      ).readAsStringSync();
      final bridgeContract = File(
        'lib/features/home/lotus/lotus_js_bridges.dart',
      ).readAsStringSync();

      expect(pubspec, contains('name: manaloom'));
      expect(androidManifest, contains('manaloom_notifications'));
      expect(androidManifest, contains('ic_stat_manaloom_notification'));
      expect(mainActivity, contains('"manaloom_notifications"'));
      expect(iosProject, contains('com.mtgia.mtgApp'));
      expect(authStore, contains("'manaloom.auth.token.v1'"));
      expect(bridgeContract, contains("'FlutterManaLoomShellBridge'"));
      expect(bridgeContract, contains("'FlutterManaLoomStorageBridge'"));
    },
  );
}
