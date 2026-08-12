import 'package:server/public_site_url.dart';
import 'package:test/test.dart';

void main() {
  group('public site URL contract', () {
    test('uses the owned BrewTact domain when no override is configured', () {
      expect(
        resolvePublicSiteBaseUrl(const {'ENVIRONMENT': 'production'}),
        currentPublicSiteFallbackUrl,
      );
      expect(currentPublicSiteFallbackUrl, 'https://brewtact.com');
    });

    test(
      'accepts a configured HTTPS origin and removes its trailing slash',
      () {
        expect(
          resolvePublicSiteBaseUrl(const {
            'ENVIRONMENT': 'production',
            'MANALOOM_PUBLIC_SITE_URL': ' https://cards.example.test/ ',
          }),
          'https://cards.example.test',
        );
      },
    );

    test(
      'rejects insecure, credentialed and path-scoped production values',
      () {
        for (final candidate in const [
          'http://cards.example.test',
          'https://user:secret@cards.example.test',
          'https://cards.example.test/public',
          'javascript:alert(1)',
        ]) {
          expect(
            resolvePublicSiteBaseUrl({
              'ENVIRONMENT': 'production',
              'MANALOOM_PUBLIC_SITE_URL': candidate,
            }),
            currentPublicSiteFallbackUrl,
            reason: candidate,
          );
        }
      },
    );

    test('allows HTTP only for a loopback development origin', () {
      expect(
        resolvePublicSiteBaseUrl(const {
          'ENVIRONMENT': 'development',
          'MANALOOM_PUBLIC_SITE_URL': 'http://127.0.0.1:8088/',
        }),
        'http://127.0.0.1:8088',
      );
      expect(
        resolvePublicSiteBaseUrl(const {
          'ENVIRONMENT': 'development',
          'MANALOOM_PUBLIC_SITE_URL': 'http://public.example.test',
        }),
        currentPublicSiteFallbackUrl,
      );
    });

    test('builds an encoded BrewTact report URL', () {
      expect(
        buildPublicReportUrl(const {
          'ENVIRONMENT': 'production',
          'MANALOOM_PUBLIC_SITE_URL': 'https://cards.example.test',
        }, 'rpt/example'),
        'https://cards.example.test/reports/rpt%2Fexample',
      );
    });
  });
}
