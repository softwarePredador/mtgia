import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android toolchain supports Flutter compile SDK and browser plugin', () {
    final settings = File('android/settings.gradle.kts').readAsStringSync();
    final wrapper =
        File(
          'android/gradle/wrapper/gradle-wrapper.properties',
        ).readAsStringSync();
    final appBuild = File('android/app/build.gradle.kts').readAsStringSync();
    final patrolRunner =
        File(
          'android/app/src/androidTest/java/com/mtgia/mtg_app/MainActivityTest.java',
        ).readAsStringSync();

    expect(
      settings,
      contains('id("com.android.application") version "8.11.1"'),
    );
    expect(
      settings,
      contains('id("org.jetbrains.kotlin.android") version "2.2.20"'),
    );
    expect(wrapper, contains('gradle-8.14-all.zip'));
    expect(appBuild, contains('JavaVersion.VERSION_17'));
    expect(appBuild, isNot(contains('JavaVersion.VERSION_11')));
    expect(appBuild, contains('compileSdk = flutter.compileSdkVersion'));
    expect(appBuild, contains('targetSdk = flutter.targetSdkVersion'));
    expect(
      appBuild,
      contains(
        'testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"',
      ),
    );
    expect(appBuild, contains('execution = "ANDROIDX_TEST_ORCHESTRATOR"'));
    expect(
      appBuild,
      contains('androidTestUtil("androidx.test:orchestrator:1.5.1")'),
    );
    expect(patrolRunner, contains('instrumentation.setUp(MainActivity.class)'));
    expect(patrolRunner, contains('instrumentation.listDartTests()'));
    expect(patrolRunner, contains('instrumentation.runDartTest(dartTestName)'));
  });
}
