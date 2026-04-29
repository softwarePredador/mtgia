import 'dart:collection';

const marketMoversCacheTtl = Duration(minutes: 5);
const marketMoversQueryTimeout = Duration(seconds: 4);

const marketMoversSummarySql = '''
  WITH latest AS (
    SELECT price_date AS today
    FROM price_history
    ORDER BY price_date DESC
    LIMIT 1
  )
  SELECT
    latest.today,
    (
      SELECT ph.price_date
      FROM price_history ph
      WHERE ph.price_date < latest.today
      ORDER BY ph.price_date DESC
      LIMIT 1
    ) AS previous_date,
    (
      SELECT COUNT(*)
      FROM price_history ph
      WHERE ph.price_date = latest.today
    ) AS total_tracked
  FROM latest
''';

const marketMoversGainersSql = '''
  WITH today_prices AS MATERIALIZED (
    SELECT card_id, price_usd
    FROM price_history
    WHERE price_date = @today::date
      AND price_usd > 0
  ),
  previous_prices AS MATERIALIZED (
    SELECT card_id, price_usd
    FROM price_history
    WHERE price_date = @previous::date
      AND price_usd > @min_price
  ),
  movers AS (
    SELECT
      tp.card_id,
      tp.price_usd AS price_today,
      pp.price_usd AS price_yesterday,
      (tp.price_usd - pp.price_usd) AS change_usd,
      ROUND(
        ((tp.price_usd - pp.price_usd) / pp.price_usd * 100)::numeric,
        2
      ) AS change_pct
    FROM today_prices tp
    JOIN previous_prices pp ON pp.card_id = tp.card_id
    WHERE tp.price_usd > pp.price_usd
    ORDER BY change_pct DESC
    LIMIT @limit
  )
  SELECT
    c.id,
    c.name,
    c.set_code,
    c.image_url,
    c.rarity,
    c.type_line,
    m.price_today,
    m.price_yesterday,
    m.change_usd,
    m.change_pct
  FROM movers m
  JOIN cards c ON c.id = m.card_id
  ORDER BY m.change_pct DESC
''';

const marketMoversLosersSql = '''
  WITH today_prices AS MATERIALIZED (
    SELECT card_id, price_usd
    FROM price_history
    WHERE price_date = @today::date
      AND price_usd >= 0
  ),
  previous_prices AS MATERIALIZED (
    SELECT card_id, price_usd
    FROM price_history
    WHERE price_date = @previous::date
      AND price_usd > @min_price
  ),
  movers AS (
    SELECT
      tp.card_id,
      tp.price_usd AS price_today,
      pp.price_usd AS price_yesterday,
      (tp.price_usd - pp.price_usd) AS change_usd,
      ROUND(
        ((tp.price_usd - pp.price_usd) / pp.price_usd * 100)::numeric,
        2
      ) AS change_pct
    FROM today_prices tp
    JOIN previous_prices pp ON pp.card_id = tp.card_id
    WHERE tp.price_usd < pp.price_usd
    ORDER BY change_pct ASC
    LIMIT @limit
  )
  SELECT
    c.id,
    c.name,
    c.set_code,
    c.image_url,
    c.rarity,
    c.type_line,
    m.price_today,
    m.price_yesterday,
    m.change_usd,
    m.change_pct
  FROM movers m
  JOIN cards c ON c.id = m.card_id
  ORDER BY m.change_pct ASC
''';

int normalizeMarketMoversLimit(String? raw) {
  final parsed = int.tryParse(raw ?? '20') ?? 20;
  return parsed.clamp(1, 50);
}

double normalizeMarketMoversMinPrice(String? raw) {
  final parsed = double.tryParse(raw ?? '1.0') ?? 1.0;
  if (!parsed.isFinite || parsed < 0) return 1.0;
  return parsed;
}

String? dateStringOrNull(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toIso8601String().substring(0, 10);
  final text = value.toString();
  if (text.length < 10) return null;
  return text.substring(0, 10);
}

Map<String, dynamic> buildMarketMoversPayload({
  required String? date,
  required String? previousDate,
  required List<Map<String, dynamic>> gainers,
  required List<Map<String, dynamic>> losers,
  required int totalTracked,
  String? message,
}) {
  final payload = <String, dynamic>{
    'date': date,
    'previous_date': previousDate,
    'gainers': gainers,
    'losers': losers,
    'total_tracked': totalTracked,
  };

  if (message != null) {
    payload['message'] = message;
  }

  return payload;
}

Map<String, dynamic> buildMarketMoverRow(Object? Function(int index) read) {
  return {
    'card_id': read(0).toString(),
    'name': read(1),
    'set_code': read(2),
    'image_url': read(3),
    'rarity': read(4),
    'type_line': read(5),
    'price_today': toDouble(read(6)),
    'price_yesterday': toDouble(read(7)),
    'change_usd': toDouble(read(8)),
    'change_pct': toDouble(read(9)),
  };
}

double? toDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int toInt(Object? value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class MarketMoversCache {
  MarketMoversCache({
    this.ttl = marketMoversCacheTtl,
    this.maxEntries = 16,
  });

  final Duration ttl;
  final int maxEntries;
  final _entries = LinkedHashMap<String, _MarketMoversCacheEntry>();

  Map<String, dynamic>? get(
    int limit,
    double minPrice, {
    bool allowStale = false,
  }) {
    final entry = _entries[_key(limit, minPrice)];
    if (entry == null) return null;
    if (!allowStale && DateTime.now().difference(entry.createdAt) > ttl) {
      return null;
    }
    return Map<String, dynamic>.from(entry.payload);
  }

  void set(int limit, double minPrice, Map<String, dynamic> payload) {
    final key = _key(limit, minPrice);
    _entries.remove(key);
    while (_entries.length >= maxEntries) {
      _entries.remove(_entries.keys.first);
    }
    _entries[key] = _MarketMoversCacheEntry(
      createdAt: DateTime.now(),
      payload: Map<String, dynamic>.from(payload),
    );
  }

  static String _key(int limit, double minPrice) =>
      '$limit:${minPrice.toStringAsFixed(4)}';
}

class _MarketMoversCacheEntry {
  _MarketMoversCacheEntry({
    required this.createdAt,
    required this.payload,
  });

  final DateTime createdAt;
  final Map<String, dynamic> payload;
}
