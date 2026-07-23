import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android release removes scanner camera access and plugin extras', () {
    final mainManifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final releaseManifest = File(
      'android/app/src/release/AndroidManifest.xml',
    ).readAsStringSync();
    final verifier = File(
      '../scripts/manaloom_verify_android_release_artifacts.sh',
    ).readAsStringSync();

    expect(mainManifest, contains('android.permission.CAMERA'));
    expect(mainManifest, contains('android:allowBackup="false"'));
    for (final permission in const [
      'RECORD_AUDIO',
      'READ_EXTERNAL_STORAGE',
      'WRITE_EXTERNAL_STORAGE',
    ]) {
      expect(
        mainManifest,
        matches(
          RegExp(
            'android:name="android\\.permission\\.$permission"\\s+'
            'tools:node="remove"',
          ),
        ),
        reason: '$permission must be removed from the merged manifest',
      );
    }
    expect(
      releaseManifest,
      matches(
        RegExp(
          'android:name="android\\.permission\\.CAMERA"\\s+'
          'tools:node="remove"',
        ),
      ),
    );
    expect(
      RegExp(
        'android:name="android\\.hardware\\.camera(?:\\.autofocus)?"\\s+'
        'tools:node="remove"',
      ).allMatches(releaseManifest),
      hasLength(2),
    );
    expect(
      verifier,
      contains(
        'APK de beta nao pode declarar camera com Scanner DEFERRED_BY_SCOPE',
      ),
    );
    expect(
      verifier,
      isNot(contains('android.permission.CAMERA|\\')),
      reason: 'camera cannot remain in the release permission allowlist',
    );
  });

  test('iOS keeps strict ATS and the default app Keychain group', () {
    final info = File('ios/Runner/Info.plist').readAsStringSync();
    final entitlements = File(
      'ios/Runner/Runner.entitlements',
    ).readAsStringSync();
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();

    expect(info, contains('NSCameraUsageDescription'));
    expect(info, isNot(contains('NSAllowsArbitraryLoads')));
    expect(info, isNot(contains('NSAllowsLocalNetworking')));
    expect(info, isNot(contains('NSLocalNetworkUsageDescription')));
    expect(entitlements, isNot(contains('keychain-access-groups')));
    expect(project, isNot(contains('DEVELOPMENT_TEAM')));
  });

  test('iOS deployment target stays aligned across CocoaPods and Xcode', () {
    final podfile = File('ios/Podfile').readAsStringSync();
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    final deploymentTargetMatches = RegExp(
      r'IPHONEOS_DEPLOYMENT_TARGET = ([0-9.]+);',
    ).allMatches(project).toList();
    final deploymentTargets = deploymentTargetMatches
        .map((match) => match.group(1))
        .toSet();

    expect(podfile, contains("platform :ios, '15.5'"));
    expect(deploymentTargetMatches, hasLength(6));
    expect(deploymentTargets, {'15.5'});
  });
}
