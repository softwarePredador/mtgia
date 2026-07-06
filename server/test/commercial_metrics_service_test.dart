import 'package:server/commercial_metrics_service.dart';
import 'package:test/test.dart';

void main() {
  group('CommercialMetricsService', () {
    test('normalizes reporting window into supported commercial range', () {
      expect(CommercialMetricsService.normalizeWindowDays(-10), equals(1));
      expect(CommercialMetricsService.normalizeWindowDays(0), equals(1));
      expect(CommercialMetricsService.normalizeWindowDays(30), equals(30));
      expect(CommercialMetricsService.normalizeWindowDays(180), equals(90));
    });
  });
}
