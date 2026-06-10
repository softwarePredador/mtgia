import 'dart:convert';

import 'package:crypto/crypto.dart';

// ============================================================================
// OPTIMIZE SWAP INTEGRITY
//
// Liga o conjunto de swaps sugeridos (remove X / add Y) ao estado do deck no
// momento da sugestão, via um hash determinístico (SHA-256). Permite que o
// caminho de aplicação (cliente ou um futuro endpoint de apply) verifique:
//   - que o conjunto de swaps não foi adulterado/dessincronizado;
//   - que o deck não mudou desde a geração da sugestão (deck_signature).
//
// O hash é calculado sobre uma forma canônica e estável (ordenada), de modo
// que reordenações no JSON não alteram o resultado.
// ============================================================================

const String kSwapIntegrityAlgo = 'sha256';
const String kSwapIntegrityVersion = 'v1';

class SwapIntegrity {
  final String version;
  final String algo;
  final String hash;
  final String deckSignature;
  final int removalCount;
  final int additionCount;

  const SwapIntegrity({
    required this.version,
    required this.algo,
    required this.hash,
    required this.deckSignature,
    required this.removalCount,
    required this.additionCount,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'algo': algo,
        'hash': hash,
        'deck_signature': deckSignature,
        'removal_count': removalCount,
        'addition_count': additionCount,
      };
}

/// Extrai pares `(card_id, quantity)` de uma lista `*_detailed`.
/// Quando `card_id` está ausente, cai para o `name` para não perder o item.
List<String> _canonicalEntries(List<Map<String, dynamic>> detailed) {
  final entries = <String>[];
  for (final item in detailed) {
    final id = (item['card_id'] ?? item['name'] ?? '').toString().trim();
    if (id.isEmpty) continue;
    final qty = (item['quantity'] as num?)?.toInt() ?? 1;
    entries.add('$id:$qty');
  }
  // Ordena para tornar o hash independente da ordem de iteração.
  entries.sort();
  return entries;
}

String _canonicalString({
  required String deckId,
  required String deckSignature,
  required List<String> removals,
  required List<String> additions,
}) {
  final buffer = StringBuffer()
    ..write(kSwapIntegrityVersion)
    ..write('|deck=')
    ..write(deckId)
    ..write('|sig=')
    ..write(deckSignature)
    ..write('|R=')
    ..write(removals.join(','))
    ..write('|A=')
    ..write(additions.join(','));
  return buffer.toString();
}

/// Calcula a integridade dos swaps a partir das listas `removals_detailed` /
/// `additions_detailed` (cada item com `card_id`/`name` e `quantity`).
SwapIntegrity computeSwapIntegrity({
  required String deckId,
  required String deckSignature,
  required List<Map<String, dynamic>> removalsDetailed,
  required List<Map<String, dynamic>> additionsDetailed,
}) {
  final removals = _canonicalEntries(removalsDetailed);
  final additions = _canonicalEntries(additionsDetailed);
  final canonical = _canonicalString(
    deckId: deckId,
    deckSignature: deckSignature,
    removals: removals,
    additions: additions,
  );
  final digest = sha256.convert(utf8.encode(canonical)).toString();
  return SwapIntegrity(
    version: kSwapIntegrityVersion,
    algo: kSwapIntegrityAlgo,
    hash: digest,
    deckSignature: deckSignature,
    removalCount: removals.length,
    additionCount: additions.length,
  );
}

/// Recalcula o hash e compara com `expectedHash`. Use no caminho de aplicação
/// para rejeitar swaps adulterados ou gerados contra um estado de deck antigo
/// (passe o `deckSignature` ATUAL do deck para detectar drift).
bool verifySwapIntegrity({
  required String expectedHash,
  required String deckId,
  required String deckSignature,
  required List<Map<String, dynamic>> removalsDetailed,
  required List<Map<String, dynamic>> additionsDetailed,
}) {
  final recomputed = computeSwapIntegrity(
    deckId: deckId,
    deckSignature: deckSignature,
    removalsDetailed: removalsDetailed,
    additionsDetailed: additionsDetailed,
  );
  // Comparação em tempo constante para evitar timing leaks.
  final a = utf8.encode(recomputed.hash);
  final b = utf8.encode(expectedHash);
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}

/// Helper que lê as listas `*_detailed` direto do corpo de resposta do optimize
/// e devolve o bloco `swap_integrity` pronto para anexar. Retorna `null` quando
/// não há swaps detalhados (nada a assinar).
Map<String, dynamic>? buildSwapIntegrityForResponse({
  required String deckId,
  required String deckSignature,
  required Map<String, dynamic> responseBody,
}) {
  final removalsDetailed = (responseBody['removals_detailed'] as List?)
          ?.whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList() ??
      const <Map<String, dynamic>>[];
  final additionsDetailed = (responseBody['additions_detailed'] as List?)
          ?.whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList() ??
      const <Map<String, dynamic>>[];

  if (removalsDetailed.isEmpty && additionsDetailed.isEmpty) return null;

  return computeSwapIntegrity(
    deckId: deckId,
    deckSignature: deckSignature,
    removalsDetailed: removalsDetailed,
    additionsDetailed: additionsDetailed,
  ).toJson();
}
