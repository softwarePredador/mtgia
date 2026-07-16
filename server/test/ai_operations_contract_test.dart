import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('operational dashboard reports persisted async job health', () {
    final source =
        File('routes/health/dashboard/index.dart').readAsStringSync();

    expect(source, contains("'ai_jobs': aiJobs"));
    expect(source, contains("status IN ('pending', 'processing')"));
    expect(source, contains("'oldest_active_seconds'"));
    expect(source, contains('ai_generate_jobs'));
    expect(source, contains('ai_optimize_jobs'));
  });

  test('backend deploy drains async jobs before service update', () {
    final source =
        File('../scripts/manaloom_deploy_backend_image.sh').readAsStringSync();
    final drain = source.indexOf('drain_timeout_seconds=');
    final generateJobs = source.indexOf('ai_generate_jobs', drain);
    final optimizeJobs = source.indexOf('ai_optimize_jobs', drain);
    final serviceUpdate = source.indexOf('docker service update', drain);

    expect(drain, greaterThanOrEqualTo(0));
    expect(generateJobs, greaterThan(drain));
    expect(optimizeJobs, greaterThan(drain));
    expect(serviceUpdate, greaterThan(optimizeJobs));
    expect(source, contains('with_new_server_pg.sh'));
    expect(source, contains('MANALOOM_DEPLOY_AI_DRAIN_TIMEOUT_SECONDS'));
    expect(source, contains('deploy recusado:'));
  });
}
