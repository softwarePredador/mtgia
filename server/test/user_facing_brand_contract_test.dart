import 'dart:io';

import 'package:server/reports/shareable_report_service.dart';
import 'package:test/test.dart';

void main() {
  group('BrewTact user-facing brand boundary', () {
    test('public Web metadata, legal copy and navigation use BrewTact', () {
      final userFacingSources = [
            Directory('../web-public/src/app'),
            Directory('../web-public/src/components'),
          ]
          .expand((directory) => directory.listSync(recursive: true))
          .whereType<File>()
          .where(
            (file) => file.path.endsWith('.ts') || file.path.endsWith('.tsx'),
          )
          .map((file) => file.readAsStringSync())
          .join('\n');

      expect(userFacingSources, contains('BrewTact'));
      expect(userFacingSources, contains('Monte melhor. Jogue melhor.'));
      expect(userFacingSources, isNot(contains('ManaLoom')));
      expect(userFacingSources, isNot(contains('manaloom.com')));
    });

    test('Web and backend defaults use the owned BrewTact domain', () {
      final routes = File('../web-public/src/lib/routes.ts').readAsStringSync();
      final dockerfile = File('../web-public/Dockerfile').readAsStringSync();
      final environment = File('.env.example').readAsStringSync();

      for (final source in [routes, dockerfile, environment]) {
        expect(source, isNot(contains('https://manaloom.com')));
        expect(source, contains('https://brewtact.com'));
      }
      expect(
        environment,
        contains('MANALOOM_PUBLIC_SITE_URL=https://brewtact.com'),
      );
      expect(
        environment,
        contains('NEXT_PUBLIC_SITE_URL=https://brewtact.com'),
      );
      expect(environment, contains('RESEND_FROM_NAME=BrewTact'));
    });

    test('new output uses BrewTact while legacy generated reports normalize', () {
      final emailTransport =
          File('lib/account_email_delivery_transport.dart').readAsStringSync();
      final emailConfig =
          File('lib/account_email_delivery_config.dart').readAsStringSync();
      final billing =
          File('lib/billing/payment_provider.dart').readAsStringSync();
      final deckExport =
          File('routes/decks/[id]/export/index.dart').readAsStringSync();

      expect(emailTransport, contains('senha no BrewTact'));
      expect(emailTransport, contains('email no BrewTact'));
      expect(emailConfig, contains("?? 'BrewTact'"));
      expect(billing, contains('O BrewTact está em beta gratuita.'));
      expect(deckExport, contains('// Exported from BrewTact'));

      expect(
        normalizeShareableReportTitle('Relatorio ManaLoom - Atraxa'),
        'Relatorio BrewTact - Atraxa',
      );
      expect(
        normalizeShareableReportTitle('Análise pessoal sobre ManaLoom'),
        'Análise pessoal sobre ManaLoom',
        reason: 'user-authored report titles must not be rewritten broadly',
      );
      expect(
        normalizeShareableReportDescription(
          'Relatorio antes/depois gerado pelo ManaLoom para revisar trocas antes de aplicar.',
        ),
        'Relatorio antes/depois gerado pelo BrewTact para revisar trocas antes de aplicar.',
      );
    });

    test('internal compatibility identifiers keep the ManaLoom namespace', () {
      final rootRoute = File('routes/index.dart').readAsStringSync();
      final headers = File('lib/sets_catalog_contract.dart').readAsStringSync();
      final emailTransport =
          File('lib/account_email_delivery_transport.dart').readAsStringSync();

      expect(rootRoute, contains("'service': 'manaloom-api'"));
      expect(headers, contains('X-ManaLoom-Sets-Cache'));
      expect(emailTransport, contains("return 'manaloom/"));
    });
  });
}
