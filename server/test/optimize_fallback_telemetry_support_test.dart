import 'package:test/test.dart';
import 'package:server/ai/optimize_fallback_telemetry_support.dart'
    as telemetry;
import 'package:server/ai/optimize_runtime_support.dart' as runtime;

void main() {
  group('optimize fallback telemetry support', () {
    test('empty aggregate keeps stable zero shape', () {
      final aggregate = telemetry.emptyOptimizeFallbackAggregate();

      expect(aggregate['all_time']['request_count'], 0);
      expect(aggregate['all_time']['trigger_rate'], 0.0);
      expect(aggregate['last_24h']['apply_rate'], 0.0);
    });

    test('builds aggregate rates from postgres row values', () {
      final aggregate = telemetry.buildOptimizeFallbackAggregateFromRow({
        'total_requests': 10,
        'triggered_count': 4,
        'applied_count': 2,
        'no_candidate_count': 1,
        'no_replacement_count': 1,
        'total_requests_24h': '5',
        'triggered_count_24h': '2',
        'applied_count_24h': '1',
        'no_candidate_count_24h': '0',
        'no_replacement_count_24h': '1',
      });

      expect(aggregate['all_time']['trigger_rate'], 0.4);
      expect(aggregate['all_time']['apply_rate'], 0.5);
      expect(aggregate['last_24h']['request_count'], 5);
      expect(aggregate['last_24h']['trigger_rate'], 0.4);
      expect(aggregate['last_24h']['apply_rate'], 0.5);
      expect(aggregate['last_24h']['no_replacement_count'], 1);
    });

    test('runtime export remains compatible for pure aggregate helpers', () {
      final aggregate = runtime.buildOptimizeFallbackAggregateFromRow({
        'total_requests': 0,
        'triggered_count': null,
        'applied_count': null,
        'no_candidate_count': null,
        'no_replacement_count': null,
        'total_requests_24h': 0,
        'triggered_count_24h': null,
        'applied_count_24h': null,
        'no_candidate_count_24h': null,
        'no_replacement_count_24h': null,
      });

      expect(aggregate['all_time']['trigger_rate'], 0.0);
      expect(aggregate['last_24h']['apply_rate'], 0.0);
    });
  });
}
