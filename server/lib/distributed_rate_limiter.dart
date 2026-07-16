import 'package:postgres/postgres.dart';

class DistributedRateLimiter {
  final Pool pool;
  final String bucket;
  final int maxRequests;
  final int windowSeconds;

  const DistributedRateLimiter({
    required this.pool,
    required this.bucket,
    required this.maxRequests,
    required this.windowSeconds,
  });

  Future<bool> isAllowed(String identifier) async {
    return pool.runTx((session) async {
      // Acquire the lock in its own statement. PostgreSQL READ COMMITTED takes
      // a fresh snapshot per statement, so contenders see prior committed
      // inserts after the advisory lock becomes available.
      await session.execute(
        Sql.named('''
          SELECT pg_advisory_xact_lock(
            hashtext(@bucket),
            hashtext(@identifier)
          )
        '''),
        parameters: {'bucket': bucket, 'identifier': identifier},
      );
      await session.execute(
        Sql.named('''
          DELETE FROM rate_limit_events
          WHERE bucket = @bucket
            AND identifier = @identifier
            AND created_at <
              NOW() - (CAST(@window_seconds AS int) * INTERVAL '2 second')
        '''),
        parameters: {
          'bucket': bucket,
          'identifier': identifier,
          'window_seconds': windowSeconds,
        },
      );

      final countResult = await session.execute(
        Sql.named('''
          SELECT COUNT(*)::int AS c
          FROM rate_limit_events
          WHERE bucket = @bucket
            AND identifier = @identifier
            AND created_at >=
              NOW() - (CAST(@window_seconds AS int) * INTERVAL '1 second')
        '''),
        parameters: {
          'bucket': bucket,
          'identifier': identifier,
          'window_seconds': windowSeconds,
        },
      );
      final count = countResult.first.toColumnMap()['c'] as int? ?? 0;
      if (count >= maxRequests) return false;

      await session.execute(
        Sql.named('''
          INSERT INTO rate_limit_events (bucket, identifier, created_at)
          VALUES (@bucket, @identifier, NOW())
        '''),
        parameters: {'bucket': bucket, 'identifier': identifier},
      );
      return true;
    });
  }
}
