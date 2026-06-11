const optimizeGenericRequestedArchetypes = <String>{
  'midrange',
  'value',
  'goodstuff',
  'general',
  'tempo',
};

String normalizeOptimizeArchetypeLabel(String? value) =>
    (value ?? '').trim().toLowerCase();

bool isGenericOptimizeRequestedArchetype(String? value) =>
    optimizeGenericRequestedArchetypes.contains(
      normalizeOptimizeArchetypeLabel(value),
    );

String resolveEffectiveOptimizeArchetype({
  required String? requestedArchetype,
  required String? detectedArchetype,
}) {
  final requested = normalizeOptimizeArchetypeLabel(requestedArchetype);
  final detected = normalizeOptimizeArchetypeLabel(detectedArchetype);

  if (requested.isEmpty) {
    return detected.isNotEmpty && detected != 'unknown' ? detected : 'midrange';
  }
  if (detected.isEmpty || detected == 'unknown') return requested;
  if (requested == detected) return requested;

  if (isGenericOptimizeRequestedArchetype(requested)) {
    return detected;
  }

  return requested;
}
