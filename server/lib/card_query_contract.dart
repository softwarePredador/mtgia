String? normalizeCardSetFilter(String? value) {
  final setCode = value?.trim();
  if (setCode == null || setCode.isEmpty) return null;
  return setCode;
}
