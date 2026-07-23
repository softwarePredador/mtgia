import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/services/onboarding_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('missing state is pending and never inferred from analytics', () async {
    final store = OnboardingStateStore();

    final state = await store.load('user-a');

    expect(state.disposition, OnboardingDisposition.pending);
    expect(state.selectedFormat, 'commander');
    expect(state.isSettled, isFalse);
  });

  test('progress resumes with the last valid format', () async {
    final store = OnboardingStateStore();

    await store.saveProgress('user-a', selectedFormat: 'pioneer');
    final state = await OnboardingStateStore().load('user-a');

    expect(state.disposition, OnboardingDisposition.pending);
    expect(state.selectedFormat, 'pioneer');
    expect(state.updatedAt, isNotNull);
  });

  test('completed and skipped decisions remain isolated per user', () async {
    final store = OnboardingStateStore();

    await store.settle(
      'user-a',
      selectedFormat: 'commander',
      disposition: OnboardingDisposition.completed,
    );
    await store.settle(
      'user-b',
      selectedFormat: 'modern',
      disposition: OnboardingDisposition.skipped,
    );

    expect(
      (await store.load('user-a')).disposition,
      OnboardingDisposition.completed,
    );
    expect(
      (await store.load('user-b')).disposition,
      OnboardingDisposition.skipped,
    );
    expect(
      (await store.load('user-c')).disposition,
      OnboardingDisposition.pending,
    );
  });

  test('malformed and future-version values fail safely to pending', () async {
    SharedPreferences.setMockInitialValues({
      'manaloom.onboarding.v1.user.user-a': '{',
      'manaloom.onboarding.v1.user.user-b':
          '{"version":2,"disposition":"completed"}',
    });
    final store = OnboardingStateStore();

    expect((await store.load('user-a')).isSettled, isFalse);
    expect((await store.load('user-b')).isSettled, isFalse);
  });

  test('invalid user and pending settlement are rejected', () async {
    final store = OnboardingStateStore();

    await expectLater(
      store.saveProgress('', selectedFormat: 'commander'),
      throwsA(isA<OnboardingPersistenceException>()),
    );
    await expectLater(
      store.settle(
        'user-a',
        selectedFormat: 'commander',
        disposition: OnboardingDisposition.pending,
      ),
      throwsA(isA<OnboardingPersistenceException>()),
    );
  });
}
