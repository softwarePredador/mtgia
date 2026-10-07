import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/config/release_capabilities.dart';
import 'package:manaloom/features/home/onboarding_goal_policy.dart';
import 'package:manaloom/features/home/services/onboarding_state_store.dart';

void main() {
  final allOff = ReleaseCapabilitiesSnapshot.forTesting(const {});
  final firstCohort = ReleaseCapabilitiesSnapshot.forTesting(const {
    ReleaseCapability.catalogPrivate,
    ReleaseCapability.decksPrivate,
    ReleaseCapability.collectionPrivate,
    ReleaseCapability.lifeCounterLocal,
  });

  String? redirect(
    String location, {
    ReleaseCapabilitiesLoadState loadState = ReleaseCapabilitiesLoadState.ready,
    ReleaseCapabilitiesSnapshot? capabilities,
  }) {
    return onboardingDeadEndRedirect(
      uri: Uri.parse(location),
      loadState: loadState,
      capabilities: capabilities ?? allOff,
    );
  }

  test('an all-off answer sends the onboarding to Home', () {
    expect(redirect('/onboarding/core-flow'), '/home');
    expect(redirect('/onboarding/core-flow/'), '/home');
    expect(redirect('/onboarding/core-flow?storage=unavailable'), '/home');
    expect(
      redirect(
        '/onboarding/core-flow',
        loadState: ReleaseCapabilitiesLoadState.unavailable,
      ),
      '/home',
    );
  });

  test('no decision before /capabilities answers', () {
    for (final state in const [
      ReleaseCapabilitiesLoadState.initial,
      ReleaseCapabilitiesLoadState.loading,
    ]) {
      expect(
        redirect('/onboarding/core-flow', loadState: state),
        isNull,
        reason: state.name,
      );
    }
  });

  test('the first cohort keeps its onboarding', () {
    expect(
      redirect('/onboarding/core-flow', capabilities: firstCohort),
      isNull,
    );
    expect(availableOnboardingGoals(firstCohort), const [
      OnboardingGoal.buildDeck,
      OnboardingGoal.importDeck,
      OnboardingGoal.catalogCollection,
      OnboardingGoal.play,
    ]);
  });

  test('each goal opens with exactly the capabilities its task needs', () {
    ReleaseCapabilitiesSnapshot only(Set<ReleaseCapability> allowed) =>
        ReleaseCapabilitiesSnapshot.forTesting(allowed);

    expect(
      availableOnboardingGoals(only({ReleaseCapability.lifeCounterLocal})),
      const [OnboardingGoal.play],
    );
    expect(
      availableOnboardingGoals(only({ReleaseCapability.catalogPrivate})),
      isEmpty,
    );
    expect(
      availableOnboardingGoals(
        only({
          ReleaseCapability.catalogPrivate,
          ReleaseCapability.collectionPrivate,
        }),
      ),
      const [OnboardingGoal.catalogCollection],
    );
    expect(
      availableOnboardingGoals(
        only({
          ReleaseCapability.decksPrivate,
          ReleaseCapability.aiAnalyzeOptimizeAdvisory,
          ReleaseCapability.aiGenerateRebuild,
        }),
      ),
      const [
        OnboardingGoal.buildDeck,
        OnboardingGoal.importDeck,
        OnboardingGoal.improveDeck,
      ],
    );
  });

  test('other routes are left alone', () {
    expect(redirect('/home'), isNull);
    expect(redirect('/onboarding'), isNull);
    expect(redirect('/decks'), isNull);
  });
}
