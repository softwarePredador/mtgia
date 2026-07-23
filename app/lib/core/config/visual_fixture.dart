/// Compile-time switch used only by the isolated authenticated visual harness.
///
/// Production builds keep the default `false`. The visual fixture opts in so
/// time-dependent labels do not create false pixel-diff failures.
const bool manaloomVisualFixtureMode = bool.fromEnvironment(
  'MANALOOM_VISUAL_FIXTURE_MODE',
  defaultValue: false,
);

String visualFixtureStableText(
  String productionText, {
  required String fixtureText,
  bool? enabled,
}) {
  return (enabled ?? manaloomVisualFixtureMode) ? fixtureText : productionText;
}
