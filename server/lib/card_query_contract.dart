enum CardDedupeMode {
  /// Backward-compatible behavior: one representative printing per set.
  set,

  /// One representative printing per playable card identity.
  identity,

  /// Every physical printing/variant.
  none,
}

String? normalizeCardSetFilter(String? value) {
  final setCode = value?.trim();
  if (setCode == null || setCode.isEmpty) return null;
  return setCode;
}

CardDedupeMode? parseCardDedupeMode(String? value) {
  final normalized = value?.trim().toLowerCase();
  return switch (normalized) {
    null || '' || 'true' => CardDedupeMode.set,
    'identity' => CardDedupeMode.identity,
    'false' => CardDedupeMode.none,
    _ => null,
  };
}
