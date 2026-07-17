import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android strips camera-plugin permissions unused by the scanner', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    expect(manifest, contains('android.permission.CAMERA'));
    expect(manifest, contains('android:allowBackup="false"'));
    for (final permission in const [
      'RECORD_AUDIO',
      'READ_EXTERNAL_STORAGE',
      'WRITE_EXTERNAL_STORAGE',
    ]) {
      expect(
        manifest,
        matches(
          RegExp(
            'android:name="android\\.permission\\.$permission"\\s+'
            'tools:node="remove"',
          ),
        ),
        reason: '$permission must be removed from the merged manifest',
      );
    }
  });

  test('iOS keeps strict ATS and the default app Keychain group', () {
    final info = File('ios/Runner/Info.plist').readAsStringSync();
    final entitlements =
        File('ios/Runner/Runner.entitlements').readAsStringSync();
    final project =
        File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();

    expect(info, contains('NSCameraUsageDescription'));
    expect(info, isNot(contains('NSAllowsArbitraryLoads')));
    expect(info, isNot(contains('NSAllowsLocalNetworking')));
    expect(info, isNot(contains('NSLocalNetworkUsageDescription')));
    expect(entitlements, isNot(contains('keychain-access-groups')));
    expect(project, isNot(contains('DEVELOPMENT_TEAM')));
  });
}
