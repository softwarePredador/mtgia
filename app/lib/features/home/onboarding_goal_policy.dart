import '../../core/config/release_capabilities.dart';
import 'services/onboarding_state_store.dart';

/// Onboarding goals in the order the screen offers them.
const onboardingGoalOrder = <OnboardingGoal>[
  OnboardingGoal.buildDeck,
  OnboardingGoal.importDeck,
  OnboardingGoal.catalogCollection,
  OnboardingGoal.play,
  OnboardingGoal.improveDeck,
];

const onboardingRoutePath = '/onboarding/core-flow';

/// Whether the release policy opens the screens [goal] leads to.
bool onboardingGoalIsAllowed(
  OnboardingGoal goal,
  ReleaseCapabilitiesSnapshot capabilities,
) {
  return switch (goal) {
    OnboardingGoal.buildDeck || OnboardingGoal.importDeck =>
      capabilities.isAllowed(ReleaseCapability.decksPrivate),
    OnboardingGoal.catalogCollection =>
      capabilities.isAllowed(ReleaseCapability.catalogPrivate) &&
          capabilities.isAllowed(ReleaseCapability.collectionPrivate),
    OnboardingGoal.play => capabilities.isAllowed(
      ReleaseCapability.lifeCounterLocal,
    ),
    OnboardingGoal.improveDeck =>
      capabilities.isAllowed(ReleaseCapability.decksPrivate) &&
          capabilities.isAllowed(ReleaseCapability.aiAnalyzeOptimizeAdvisory) &&
          capabilities.isAllowed(ReleaseCapability.aiGenerateRebuild),
  };
}

List<OnboardingGoal> availableOnboardingGoals(
  ReleaseCapabilitiesSnapshot capabilities,
) {
  return onboardingGoalOrder
      .where((goal) => onboardingGoalIsAllowed(goal, capabilities))
      .toList(growable: false);
}

/// Sends the first authenticated screen to `/home` when the policy leaves the
/// onboarding without any goal to pick (BT-NAV-03).
///
/// It waits for an answer from `/capabilities`: at boot the matrix is all-off
/// until the first response, and that must not skip the onboarding of a
/// person who will have goals. A failed load is an answer: the matrix stays
/// all-off, and the Home is the screen that explains it.
String? onboardingDeadEndRedirect({
  required Uri uri,
  required ReleaseCapabilitiesLoadState loadState,
  required ReleaseCapabilitiesSnapshot capabilities,
}) {
  final path = uri.path.length > 1 && uri.path.endsWith('/')
      ? uri.path.substring(0, uri.path.length - 1)
      : uri.path;
  if (path != onboardingRoutePath) return null;
  if (loadState != ReleaseCapabilitiesLoadState.ready &&
      loadState != ReleaseCapabilitiesLoadState.unavailable) {
    return null;
  }
  if (availableOnboardingGoals(capabilities).isNotEmpty) return null;
  return '/home';
}
