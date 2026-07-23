import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/social/widgets/social_report_dialog.dart';

void main() {
  testWidgets('returns the selected reason and trimmed details', (
    tester,
  ) async {
    SocialReportDraft? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await showSocialReportDialog(
                  context,
                  targetLabel: 'mensagem',
                );
              },
              child: const Text('Denunciar'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Denunciar'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('social-report-dialog')), findsOneWidget);
    expect(find.text('Denunciar mensagem'), findsOneWidget);

    await tester.tap(find.byKey(const Key('social-report-reason-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Golpe ou fraude').last);
    await tester.enterText(
      find.byKey(const Key('social-report-details-field')),
      '  tentativa de fraude  ',
    );
    await tester.tap(find.byKey(const Key('social-report-confirm-button')));
    await tester.pumpAndSettle();

    expect(result?.reason, 'scam');
    expect(result?.details, 'tentativa de fraude');
  });

  testWidgets('requires an explicit cancel action', (tester) async {
    SocialReportDraft? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await showSocialReportDialog(
                  context,
                  targetLabel: 'perfil',
                );
              },
              child: const Text('Denunciar'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Denunciar'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('social-report-dialog')), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(find.byKey(const Key('social-report-dialog')), findsNothing);
  });
}
