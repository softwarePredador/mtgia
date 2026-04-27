import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';

import '../lib/ai/optimize_runtime_support.dart';
import '../lib/database.dart';
import '../lib/meta/meta_deck_format_support.dart';
import '../lib/meta/meta_deck_reference_support.dart';

Future<void> main(List<String> args) async {
  final config = _MetaReferenceProbeConfig.parse(args);
  final db = Database();
  await db.connect();
  if (!db.isConnected) {
    throw StateError('Falha ao conectar ao banco para o probe de referencias.');
  }

  final pool = db.connection;
  try {
    final externalDecks = await _loadPromotedExternalCommanderDecks(pool);
    final optimizeProbes = <Map<String, dynamic>>[];
    final generateProbes = <Map<String, dynamic>>[];

    for (final deck in externalDecks) {
      optimizeProbes.add(
        await _buildOptimizeProbe(
          pool: pool,
          deck: deck,
          bracket: 4,
        ),
      );
      optimizeProbes.add(
        await _buildOptimizeProbe(
          pool: pool,
          deck: deck,
          bracket: 2,
        ),
      );

      generateProbes.add(
        await _buildGenerateProbe(
          pool: pool,
          deck: deck,
          prompt:
              'Build a cEDH bracket 4 ${deck.shellLabel} deck with a ${deck.strategyArchetype} plan.',
          format: 'Commander',
          label: 'generate_competitive',
        ),
      );
      generateProbes.add(
        await _buildGenerateProbe(
          pool: pool,
          deck: deck,
          prompt:
              'Build a casual commander ${deck.shellLabel} deck with fun table play.',
          format: 'Commander',
          label: 'generate_casual_guard',
        ),
      );
      generateProbes.add(
        await _buildGenerateProbe(
          pool: pool,
          deck: deck,
          prompt: 'Build a duel commander ${deck.shellLabel} deck.',
          format: 'Commander',
          label: 'generate_duel_guard',
        ),
      );
    }

    final payload = <String, dynamic>{
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'promoted_external_decks':
          externalDecks.map((deck) => deck.toJson()).toList(growable: false),
      'summary': <String, dynamic>{
        'promoted_external_count': externalDecks.length,
        'optimize_competitive_external_match_count': optimizeProbes
            .where(
              (probe) =>
                  probe['label'] == 'optimize_competitive' &&
                  probe['matched_external_reference'] == true,
            )
            .length,
        'optimize_casual_guard_ok_count': optimizeProbes
            .where(
              (probe) =>
                  probe['label'] == 'optimize_casual_guard' &&
                  probe['has_references'] == false,
            )
            .length,
        'generate_competitive_external_match_count': generateProbes
            .where(
              (probe) =>
                  probe['label'] == 'generate_competitive' &&
                  probe['matched_external_reference'] == true,
            )
            .length,
        'generate_casual_guard_ok_count': generateProbes
            .where(
              (probe) =>
                  probe['label'] == 'generate_casual_guard' &&
                  probe['should_use_meta'] == false &&
                  probe['has_references'] == false,
            )
            .length,
        'generate_duel_guard_ok_count': generateProbes
            .where(
              (probe) =>
                  probe['label'] == 'generate_duel_guard' &&
                  probe['matched_external_reference'] == false,
            )
            .length,
      },
      'optimize_probes': optimizeProbes,
      'generate_probes': generateProbes,
    };

    final encoded = const JsonEncoder.withIndent('  ').convert(payload);
    if (config.outputPath != null) {
      final outputFile = File(config.outputPath!);
      await outputFile.parent.create(recursive: true);
      await outputFile.writeAsString(encoded);
      stdout.writeln('Meta reference probe salvo em: ${outputFile.path}');
    } else {
      stdout.writeln(encoded);
    }
  } finally {
    await db.close();
  }
}

class _MetaReferenceProbeConfig {
  const _MetaReferenceProbeConfig({
    required this.outputPath,
  });

  final String? outputPath;

  factory _MetaReferenceProbeConfig.parse(List<String> args) {
    String? outputPath;
    for (final arg in args) {
      if (arg == '--help' || arg == '-h') {
        stdout.writeln('''
Usage:
  dart run bin/meta_reference_probe.dart [options]

Options:
  --output=<path>  Salva o JSON do probe nesse caminho.
''');
        exit(0);
      }
      if (arg.startsWith('--output=')) {
        outputPath = arg.substring('--output='.length).trim();
      }
    }
    return _MetaReferenceProbeConfig(outputPath: outputPath);
  }
}

class _PromotedExternalCommanderDeck {
  const _PromotedExternalCommanderDeck({
    required this.commanderName,
    required this.partnerCommanderName,
    required this.shellLabel,
    required this.strategyArchetype,
    required this.sourceUrl,
    required this.placement,
    required this.createdAt,
  });

  final String commanderName;
  final String partnerCommanderName;
  final String shellLabel;
  final String strategyArchetype;
  final String sourceUrl;
  final String placement;
  final DateTime? createdAt;

  List<String> get commanderNames => [
        commanderName,
        if (partnerCommanderName.trim().isNotEmpty) partnerCommanderName,
      ];

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'commander_name': commanderName,
      'partner_commander_name':
          partnerCommanderName.trim().isEmpty ? null : partnerCommanderName,
      'shell_label': shellLabel,
      'strategy_archetype': strategyArchetype,
      'source_url': sourceUrl,
      'placement': placement,
      'created_at': createdAt?.toUtc().toIso8601String(),
    };
  }
}

Future<List<_PromotedExternalCommanderDeck>>
    _loadPromotedExternalCommanderDecks(
  Pool pool,
) async {
  final result = await pool.execute('''
    SELECT
      COALESCE(commander_name, ''),
      COALESCE(partner_commander_name, ''),
      COALESCE(shell_label, ''),
      COALESCE(strategy_archetype, ''),
      source_url,
      COALESCE(placement, ''),
      created_at
    FROM meta_decks
    WHERE format = 'cEDH'
      AND source_url NOT ILIKE 'https://www.mtgtop8.com/%'
    ORDER BY created_at ASC, source_url ASC
  ''');

  return [
    for (final row in result)
      _PromotedExternalCommanderDeck(
        commanderName: (row[0] as String?) ?? '',
        partnerCommanderName: (row[1] as String?) ?? '',
        shellLabel: (row[2] as String?) ?? '',
        strategyArchetype: (row[3] as String?) ?? '',
        sourceUrl: (row[4] as String?) ?? '',
        placement: (row[5] as String?) ?? '',
        createdAt: row[6] as DateTime?,
      ),
  ];
}

Future<Map<String, dynamic>> _buildOptimizeProbe({
  required Pool pool,
  required _PromotedExternalCommanderDeck deck,
  required int bracket,
}) async {
  final metaScope = resolveCommanderOptimizeMetaScope(
    deckFormat: 'Commander',
    bracket: bracket,
  );
  final selection = metaScope == null
      ? _emptySelection()
      : await loadCommanderMetaReferenceSelection(
          pool: pool,
          commanderNames: deck.commanderNames,
          limitDecks: 4,
          priorityCardLimit: 14,
          metaScope: metaScope,
          preferExternalCompetitive: true,
        );

  return <String, dynamic>{
    'label': bracket >= 3 ? 'optimize_competitive' : 'optimize_casual_guard',
    'shell_label': deck.shellLabel,
    'target_source_url': deck.sourceUrl,
    'bracket': bracket,
    'meta_scope': metaScope,
    'priority_source': selection.optimizePrioritySource,
    ..._selectionSnapshot(selection, targetSourceUrl: deck.sourceUrl),
  };
}

Future<Map<String, dynamic>> _buildGenerateProbe({
  required Pool pool,
  required _PromotedExternalCommanderDeck deck,
  required String prompt,
  required String format,
  required String label,
}) async {
  final metaKeywordPatterns = prompt
      .split(' ')
      .where((word) => word.length > 3)
      .map((word) => word.replaceAll(RegExp(r'[^a-zA-Z0-9]'), ''))
      .where((word) => word.isNotEmpty)
      .map((word) => '%$word%')
      .toSet()
      .toList(growable: false);

  final normalizedFormat = format.trim().toLowerCase();
  final isCommanderFormat =
      normalizedFormat == 'commander' || normalizedFormat == 'edh';
  final commanderMetaScope = isCommanderFormat
      ? resolveCommanderMetaScopeFromPromptText(prompt)
      : null;
  final shouldUseMeta = metaKeywordPatterns.isNotEmpty &&
      (!isCommanderFormat || commanderMetaScope != null);
  final metaFormats = shouldUseMeta
      ? metaDeckFormatCodesForDeckFormat(
          format,
          commanderScope: commanderMetaScope ?? 'competitive_commander',
        )
      : const <String>[];

  final selection = metaFormats.isEmpty
      ? _emptySelection(commanderScope: commanderMetaScope)
      : selectMetaDeckReferenceCandidates(
          candidates: await queryMetaDeckReferenceCandidates(
            pool: pool,
            formatCodes: metaFormats,
            keywordPatterns: metaKeywordPatterns,
            limit: 200,
          ),
          keywordPatterns: metaKeywordPatterns,
          commanderScope: commanderMetaScope,
          deckLimit: 3,
          priorityCardLimit: 14,
          preferExternalCompetitive:
              commanderMetaScope == 'competitive_commander',
        );

  return <String, dynamic>{
    'label': label,
    'shell_label': deck.shellLabel,
    'target_source_url': deck.sourceUrl,
    'prompt': prompt,
    'format': format,
    'commander_scope': commanderMetaScope,
    'should_use_meta': shouldUseMeta,
    'meta_formats': metaFormats,
    ..._selectionSnapshot(selection, targetSourceUrl: deck.sourceUrl),
  };
}

Map<String, dynamic> _selectionSnapshot(
  MetaDeckReferenceSelectionResult selection, {
  required String targetSourceUrl,
}) {
  final matchedIndex = selection.references.indexWhere(
    (candidate) => candidate.sourceUrl == targetSourceUrl,
  );
  return <String, dynamic>{
    'has_references': selection.hasReferences,
    'selection_reason': selection.selectionReason,
    'source_breakdown': selection.sourceBreakdown,
    'priority_cards':
        selection.priorityCardNames.take(14).toList(growable: false),
    'matched_external_reference': matchedIndex >= 0,
    'matched_external_reference_rank':
        matchedIndex >= 0 ? matchedIndex + 1 : null,
    'references': selection.references
        .map(
          (candidate) => <String, dynamic>{
            'shell_label': candidate.bestShellLabel,
            'strategy_archetype': candidate.strategyArchetype,
            'placement': candidate.placement,
            'meta_scope': candidate.commanderSubformat,
            'source': candidate.sourceLabel,
            'source_kind': candidate.sourceKind,
            'source_url': candidate.sourceUrl,
            'source_chain': candidate.effectiveSourceChain,
          },
        )
        .toList(growable: false),
  };
}

MetaDeckReferenceSelectionResult _emptySelection({String? commanderScope}) {
  return MetaDeckReferenceSelectionResult(
    commanderScope: commanderScope,
    selectionReason: 'no_match',
    references: const <MetaDeckReferenceCandidate>[],
    priorityCardNames: const <String>[],
    sourceBreakdown: const <String, int>{},
  );
}
