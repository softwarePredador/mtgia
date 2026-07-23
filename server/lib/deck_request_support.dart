class DeckRequestException implements Exception {
  const DeckRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}

Map<String, dynamic> requireJsonObject(Object? value) {
  if (value is! Map) {
    throw const DeckRequestException('Request body must be a JSON object.');
  }
  return value.cast<String, dynamic>();
}

String requireNonEmptyString(Map<String, dynamic> body, String key) {
  final value = body[key];
  if (value is! String || value.trim().isEmpty) {
    throw DeckRequestException('Field $key must be a non-empty string.');
  }
  return value.trim();
}

String? readOptionalString(
  Map<String, dynamic> body,
  String key, {
  bool trim = false,
}) {
  final value = body[key];
  if (value == null) return null;
  if (value is! String) {
    throw DeckRequestException('Field $key must be a string.');
  }
  return trim ? value.trim() : value;
}

bool? readOptionalBool(Map<String, dynamic> body, String key) {
  final value = body[key];
  if (value == null) return null;
  if (value is! bool) {
    throw DeckRequestException('Field $key must be a boolean.');
  }
  return value;
}

List<dynamic>? readOptionalList(Map<String, dynamic> body, String key) {
  final value = body[key];
  if (value == null) return null;
  if (value is! List) {
    throw DeckRequestException('Field $key must be a list.');
  }
  return value;
}

Map<String, dynamic>? readOptionalObject(
  Map<String, dynamic> body,
  String key,
) {
  final value = body[key];
  if (value == null) return null;
  if (value is! Map) {
    throw DeckRequestException('Field $key must be an object.');
  }
  return value.cast<String, dynamic>();
}

List<Map<String, dynamic>> requireObjectList(
  List<dynamic> values, {
  String field = 'cards',
}) {
  final objects = <Map<String, dynamic>>[];
  for (var index = 0; index < values.length; index++) {
    final value = values[index];
    if (value is! Map) {
      throw DeckRequestException('$field[$index] must be an object.');
    }
    objects.add(value.cast<String, dynamic>());
  }
  return objects;
}

int requirePositiveInteger(Map<String, dynamic> body, String key) {
  final raw = body[key];
  final value = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
  if (value == null || value <= 0) {
    throw DeckRequestException('Field $key must be a positive integer.');
  }
  return value;
}
