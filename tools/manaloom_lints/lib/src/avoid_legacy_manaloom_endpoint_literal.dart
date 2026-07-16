import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

class AvoidLegacyManaLoomEndpointLiteral extends DartLintRule {
  AvoidLegacyManaLoomEndpointLiteral()
    : super(
        code: const LintCode(
          name: 'avoid_legacy_manaloom_endpoint_literal',
          problemMessage:
              'Endpoint legado/local do ManaLoom nao deve ficar hardcoded em codigo de producao.',
          correctionMessage:
              'Use dart-define, variavel de ambiente ou um helper centralizado de configuracao.',
        ),
      );

  static const _blockedFragments = <String>[
    '8ktevp',
    'whatsapi',
    'http://localhost:8080',
    'http://127.0.0.1:8080',
  ];

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    final path = resolver.source.fullName.replaceAll('\\', '/');
    if (!_isProductionDart(path)) {
      return;
    }

    context.registry.addSimpleStringLiteral((node) {
      _reportIfBlocked(node, node.value, reporter);
    });
    context.registry.addStringInterpolation((node) {
      for (final element in node.elements) {
        if (element case InterpolationString(:final value)) {
          _reportIfBlocked(element, value, reporter);
        }
      }
    });
  }

  static bool _isProductionDart(String path) {
    return path.endsWith('.dart') &&
        (path.contains('/app/lib/') ||
            path.contains('/server/lib/') ||
            path.contains('/server/routes/'));
  }

  static bool isProductionPathForTest(String path) {
    return _isProductionDart(path.replaceAll('\\', '/'));
  }

  static bool containsBlockedFragmentForTest(String value) {
    return _containsBlockedFragment(value);
  }

  void _reportIfBlocked(
    AstNode node,
    String value,
    DiagnosticReporter reporter,
  ) {
    if (_containsBlockedFragment(value)) {
      reporter.atNode(node, code);
    }
  }

  static bool _containsBlockedFragment(String value) {
    final normalized = value.toLowerCase();
    return _blockedFragments.any(normalized.contains);
  }
}
