const explicitOptimizeQualityRejectionCodes = <String>{
  'OPTIMIZE_QUALITY_REJECTED',
  'OPTIMIZE_SEMANTIC_V2_REJECTED',
  'OPTIMIZE_ASYNC_QUALITY_REJECTED',
};

bool isExplicitOptimizeQualityRejection(Map<String, dynamic>? reasoning) {
  if (reasoning == null || reasoning.containsKey('validation_run_token')) {
    return false;
  }
  final statusCode = reasoning['status_code']?.toString().trim() ?? '';
  final qualityErrorCode =
      reasoning['quality_error_code']?.toString().trim() ?? '';
  return statusCode.isNotEmpty &&
      statusCode != '200' &&
      explicitOptimizeQualityRejectionCodes.contains(qualityErrorCode);
}

String explicitOptimizeQualityRejectionSql(String tableAlias) {
  if (!RegExp(r'^[a-z_][a-z0-9_]*$').hasMatch(tableAlias)) {
    throw ArgumentError.value(tableAlias, 'tableAlias', 'invalid SQL alias');
  }
  final codes = explicitOptimizeQualityRejectionCodes
      .map((code) => "'$code'")
      .join(', ');
  return '''
NOT (COALESCE($tableAlias.decisions_reasoning, '{}'::jsonb)
  ? 'validation_run_token')
AND NULLIF($tableAlias.decisions_reasoning->>'status_code', '') IS NOT NULL
AND $tableAlias.decisions_reasoning->>'status_code' <> '200'
AND $tableAlias.decisions_reasoning->>'quality_error_code' IN ($codes)
''';
}
