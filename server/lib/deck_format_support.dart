const supportedDeckFormats = <String>{
  'commander',
  'brawl',
  'standard',
  'modern',
  'pioneer',
  'legacy',
  'vintage',
  'pauper',
};

String? normalizeSupportedDeckFormat(Object? value) {
  if (value is! String) return null;

  var normalized = value.trim().toLowerCase();
  if (normalized == 'edh') {
    normalized = 'commander';
  }

  return supportedDeckFormats.contains(normalized) ? normalized : null;
}

String unsupportedDeckFormatMessage(Object? value) {
  final received = value is String ? value.trim() : '';
  final suffix = received.isEmpty ? '' : ' (received: $received)';
  return 'Unsupported deck format$suffix. Supported formats: '
      '${supportedDeckFormats.join(', ')}.';
}
