import 'dart:io';

import 'package:test/test.dart';

import '../bin/commander_reference_readiness_scorecard.dart' as scorecard;

void main() {
  final source =
      File(
        'bin/commander_reference_readiness_scorecard.dart',
      ).readAsStringSync();

  test('defaults scorecard artifacts to a safe temporary directory', () {
    expect(
      scorecard.resolveCommanderReferenceReadinessArtifactDir(const []),
      '/tmp/manaloom_commander_reference_readiness_scorecard',
    );
  });

  test('keeps an explicit artifact output override', () {
    expect(
      scorecard.resolveCommanderReferenceReadinessArtifactDir(const [
        '--commander=Lorehold, the Historian',
        '--artifact-dir=/tmp/manaloom_scorecard_explicit',
      ]),
      '/tmp/manaloom_scorecard_explicit',
    );
  });

  test('wires all-active discovery through the PostgreSQL pool', () {
    expect(source, contains('discoverActiveUsableCommanderReferenceProfiles'));
    expect(source, contains('database.connection.execute(sql)'));
    expect(source, contains('--all-active-profiles'));
  });
}
