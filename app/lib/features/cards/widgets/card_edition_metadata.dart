import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

String cardEditionCodeLabel({String? setCode, String? collectorNumber}) {
  final code = (setCode ?? '').trim().toUpperCase();
  final collector = (collectorNumber ?? '').trim();
  if (code.isEmpty) return collector.isEmpty ? '' : '#$collector';
  return collector.isEmpty ? code : '$code #$collector';
}

String cardFoilLabel(bool? foil) {
  if (foil == null) return '';
  return foil ? 'Foil' : 'Non-foil';
}

String cardEditionDescription({
  String? setName,
  String? setReleaseDate,
  String? rarity,
  bool? foil,
  bool releaseYearOnly = false,
}) {
  final release = (setReleaseDate ?? '').trim();
  final releaseLabel =
      releaseYearOnly && release.length >= 4
          ? release.substring(0, 4)
          : release;
  final parts = [
    if ((setName ?? '').trim().isNotEmpty) setName!.trim(),
    if (releaseLabel.isNotEmpty) releaseLabel,
    if ((rarity ?? '').trim().isNotEmpty) _capitalize(rarity!.trim()),
    if (cardFoilLabel(foil).isNotEmpty) cardFoilLabel(foil),
  ];
  return parts.join(' • ');
}

String cardEditionFullLabel(Map<String, dynamic> printing) {
  final parts =
      [
        cardEditionCodeLabel(
          setCode: printing['set_code']?.toString(),
          collectorNumber: printing['collector_number']?.toString(),
        ),
        cardFoilLabel(printing['foil'] as bool?),
        if ((printing['set_name'] ?? '').toString().trim().isNotEmpty)
          printing['set_name'].toString().trim(),
        if ((printing['rarity'] ?? '').toString().trim().isNotEmpty)
          _capitalize(printing['rarity'].toString().trim()),
        if ((printing['set_release_date'] ?? '').toString().trim().isNotEmpty)
          printing['set_release_date'].toString().trim(),
      ].where((part) => part.trim().isNotEmpty).toList();
  return parts.join(' • ');
}

class CardEditionMetadataLine extends StatelessWidget {
  const CardEditionMetadataLine({
    super.key,
    required this.setCode,
    this.collectorNumber,
    this.setName,
    this.setReleaseDate,
    this.rarity,
    this.foil,
    this.warning,
  });

  final String setCode;
  final String? collectorNumber;
  final String? setName;
  final String? setReleaseDate;
  final String? rarity;
  final bool? foil;
  final String? warning;

  @override
  Widget build(BuildContext context) {
    final codeLabel = cardEditionCodeLabel(
      setCode: setCode,
      collectorNumber: collectorNumber,
    );
    final description = cardEditionDescription(
      setName: setName,
      setReleaseDate: setReleaseDate,
      rarity: rarity,
      foil: foil,
      releaseYearOnly: true,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (codeLabel.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: AppTheme.frost400.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                  border: Border.all(
                    color: AppTheme.frost400.withValues(alpha: 0.36),
                  ),
                ),
                child: Text(
                  codeLabel,
                  style: const TextStyle(
                    fontSize: AppTheme.fontXs,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.frost400,
                    letterSpacing: 0.35,
                  ),
                ),
              ),
            Flexible(
              child: Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: AppTheme.fontSm,
                ),
              ),
            ),
          ],
        ),
        if ((warning ?? '').isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            warning!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.warning,
              fontSize: AppTheme.fontSm,
            ),
          ),
        ],
      ],
    );
  }
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}
