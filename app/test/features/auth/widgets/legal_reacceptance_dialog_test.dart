import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/auth/providers/legal_acceptance_provider.dart';
import 'package:manaloom/features/auth/widgets/legal_reacceptance_dialog.dart';
import 'package:manaloom/features/commercial/legal_policy.dart';

class _AcceptApi extends ApiClient {
  _AcceptApi(this.response);

  final ApiResponse response;
  var posts = 0;

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    posts++;
    return response;
  }
}

Map<String, Object?> _legal({
  String currentTerms = currentTermsVersion,
  bool required = true,
}) => {
  'legal': {
    'accepted_terms_version': required ? '2026-01-01' : currentTerms,
    'accepted_privacy_version': currentPrivacyVersion,
    'current_terms_version': currentTerms,
    'current_privacy_version': currentPrivacyVersion,
    'reacceptance_required': required,
  },
};

Future<bool?> _open(
  WidgetTester tester,
  LegalAcceptanceProvider provider, {
  List<String>? reads,
}) async {
  bool? result;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.darkTheme,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await showLegalReacceptanceDialog(
                  context: context,
                  provider: provider,
                  onReadDocument: (section) => reads?.add(section),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('accepting needs the checkbox and closes on success', (
    tester,
  ) async {
    final api = _AcceptApi(ApiResponse(200, _legal(required: false)));
    final provider = LegalAcceptanceProvider(apiClient: api)
      ..markRequiredFromBody(_legal());
    addTearDown(provider.dispose);
    final reads = <String>[];
    await _open(tester, provider, reads: reads);

    expect(find.byKey(const Key('legal-reaccept-dialog')), findsOneWidget);
    final submit = find.byKey(const Key('legal-reaccept-submit'));
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tester.tap(find.byKey(const Key('legal-reaccept-read-terms')));
    await tester.tap(find.byKey(const Key('legal-reaccept-read-privacy')));
    expect(reads, ['terms', 'privacy']);

    await tester.tap(find.byKey(const Key('legal-reaccept-checkbox')));
    await tester.pump();
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(api.posts, 1);
    expect(find.byKey(const Key('legal-reaccept-dialog')), findsNothing);
    expect(provider.reacceptanceRequired, isFalse);
  });

  testWidgets('"Agora não" closes without recording anything', (tester) async {
    final api = _AcceptApi(ApiResponse(200, _legal(required: false)));
    final provider = LegalAcceptanceProvider(apiClient: api)
      ..markRequiredFromBody(_legal());
    addTearDown(provider.dispose);
    await _open(tester, provider);

    await tester.tap(find.byKey(const Key('legal-reaccept-later')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('legal-reaccept-dialog')), findsNothing);
    expect(api.posts, 0);
    expect(provider.reacceptanceRequired, isTrue);
  });

  testWidgets('a server error stays inside the dialog', (tester) async {
    final api = _AcceptApi(
      ApiResponse(503, const {
        'error': 'service_unavailable',
        'message': 'Serviço indisponível agora.',
      }),
    );
    final provider = LegalAcceptanceProvider(apiClient: api)
      ..markRequiredFromBody(_legal());
    addTearDown(provider.dispose);
    await _open(tester, provider);

    await tester.tap(find.byKey(const Key('legal-reaccept-checkbox')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('legal-reaccept-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('legal-reaccept-dialog')), findsOneWidget);
    expect(find.byKey(const Key('legal-reaccept-error')), findsOneWidget);
    expect(find.textContaining('service_unavailable'), findsNothing);
  });

  testWidgets('an outdated app cannot accept a text it does not have', (
    tester,
  ) async {
    final api = _AcceptApi(ApiResponse(200, _legal(required: false)));
    final provider = LegalAcceptanceProvider(apiClient: api)
      ..markRequiredFromBody(_legal(currentTerms: '2099-01-01'));
    addTearDown(provider.dispose);
    await _open(tester, provider);

    expect(find.byKey(const Key('legal-reaccept-submit')), findsNothing);
    expect(find.byKey(const Key('legal-reaccept-checkbox')), findsNothing);
    expect(find.textContaining('Atualize o app'), findsOneWidget);
  });
}
