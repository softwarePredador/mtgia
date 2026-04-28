const int setCatalogDefaultLimit = 50;
const int setCatalogMaxLimit = 200;
const int setCatalogNewReleaseWindowDays = 30;
const int setCatalogCurrentReleaseWindowDays = 180;

String? normalizeSetSearchQuery(String? value) {
  final query = value?.trim();
  if (query == null || query.isEmpty) return null;
  return query;
}

String? normalizeSetCodeFilter(String? value) {
  final code = value?.trim();
  if (code == null || code.isEmpty) return null;
  return code.toUpperCase();
}

int safeSetCatalogLimit(String? value) {
  final parsed = int.tryParse(value ?? '') ?? setCatalogDefaultLimit;
  return parsed.clamp(1, setCatalogMaxLimit);
}

int safeSetCatalogPage(String? value) {
  final parsed = int.tryParse(value ?? '') ?? 1;
  return parsed < 1 ? 1 : parsed;
}

String resolveSetStatus(DateTime? releaseDate, {DateTime? now}) {
  if (releaseDate == null) return 'old';

  final today = _dateOnly(now ?? DateTime.now());
  final releaseDay = _dateOnly(releaseDate);
  if (releaseDay.isAfter(today)) return 'future';

  final ageDays = today.difference(releaseDay).inDays;
  if (ageDays <= setCatalogNewReleaseWindowDays) return 'new';
  if (ageDays <= setCatalogCurrentReleaseWindowDays) return 'current';
  return 'old';
}

Map<String, dynamic> mapSetCatalogRow(
  Map<String, dynamic> row, {
  DateTime? now,
}) {
  final releaseDate = row['release_date'] as DateTime?;
  return {
    'code': row['code'],
    'name': row['name'],
    'release_date': releaseDate?.toIso8601String().split('T').first,
    'type': row['type'],
    'block': row['block'],
    'is_online_only': row['is_online_only'],
    'is_foreign_only': row['is_foreign_only'],
    'card_count': (row['card_count'] as num?)?.toInt() ?? 0,
    'status': resolveSetStatus(releaseDate, now: now),
  };
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
