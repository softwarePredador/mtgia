import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

class AvoidManaLoomSecretLiteral extends DartLintRule {
  AvoidManaLoomSecretLiteral()
    : super(
        code: const LintCode(
          name: 'avoid_manaloom_secret_literal',
          problemMessage:
              'Token ou segredo real nao deve ficar hardcoded em codigo de producao do ManaLoom.',
          correctionMessage:
              'Mova o valor para ambiente seguro, EasyPanel secret, dart-define ou vault equivalente.',
        ),
      );

  static final _openAiLikeSecret = RegExp(
    r'\bsk-(proj|live|test|admin)-[A-Za-z0-9_-]{6,}',
    caseSensitive: false,
  );
  static final _stripeLikeSecret = RegExp(
    r'\b(sk_live_|rk_live_)[A-Za-z0-9]{6,}',
    caseSensitive: false,
  );
  static final _postgresDsnWithCredentials = RegExp(
    r'\bpostgres(?:ql)?://[^/\s:@]+:[^@\s]+@',
    caseSensitive: false,
  );
  static final _digitalOceanToken = RegExp(
    r'\bdop_v1_[A-Za-z0-9]{20,}',
    caseSensitive: false,
  );

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
      _reportIfSecret(node, node.value, reporter);
    });
    context.registry.addStringInterpolation((node) {
      for (final element in node.elements) {
        if (element case InterpolationString(:final value)) {
          _reportIfSecret(element, value, reporter);
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

  static bool containsSecretForTest(String value) {
    return _containsSecret(value);
  }

  void _reportIfSecret(
    AstNode node,
    String value,
    DiagnosticReporter reporter,
  ) {
    if (_containsSecret(value)) {
      reporter.atNode(node, code);
    }
  }

  static bool _containsSecret(String value) {
    return _openAiLikeSecret.hasMatch(value) ||
        _stripeLikeSecret.hasMatch(value) ||
        _postgresDsnWithCredentials.hasMatch(value) ||
        _digitalOceanToken.hasMatch(value);
  }
}
