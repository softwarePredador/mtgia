import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/avoid_legacy_manaloom_endpoint_literal.dart';
import 'src/avoid_manaloom_secret_literal.dart';

PluginBase createPlugin() => _ManaLoomLintPlugin();

class _ManaLoomLintPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    return [AvoidLegacyManaLoomEndpointLiteral(), AvoidManaLoomSecretLiteral()];
  }
}
