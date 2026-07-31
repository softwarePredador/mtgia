import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../runtime_environment.dart';

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
const String kOptimizeApplyAuthorizationVersion = 'v2';
const String kOptimizeApplyAuthorizationAlgo = 'hmac-sha256';
const Duration kOptimizeApplyAuthorizationLifetime = Duration(hours: 24);

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
  final buffer =
      StringBuffer()
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
  final removalsDetailed =
      (responseBody['removals_detailed'] as List?)
          ?.whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList() ??
      const <Map<String, dynamic>>[];
  final additionsDetailed =
      (responseBody['additions_detailed'] as List?)
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

String resolveOptimizeApplySigningSecret({Map<String, String>? environment}) {
  if (environment != null) {
    final dedicated =
        environment['OPTIMIZATION_APPLY_SIGNING_SECRET']?.trim() ?? '';
    if (dedicated.isNotEmpty) return dedicated;
    return environment['JWT_SECRET']?.trim() ?? '';
  }

  final runtime = loadRuntimeEnvironment();
  final dedicated = runtime['OPTIMIZATION_APPLY_SIGNING_SECRET']?.trim() ?? '';
  if (dedicated.isNotEmpty) return dedicated;
  return runtime['JWT_SECRET']?.trim() ?? '';
}

String _base64UrlNoPadding(List<int> bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');

List<int> _decodeBase64UrlNoPadding(String value) {
  final padding = '=' * ((4 - value.length % 4) % 4);
  return base64Url.decode('$value$padding');
}

Map<String, int> _canonicalQuantityMap(
  Iterable<Map<String, dynamic>> detailed,
) {
  final quantities = <String, int>{};
  for (final item in detailed) {
    final key =
        (item['card_id'] ?? item['name'] ?? '').toString().trim().toLowerCase();
    if (key.isEmpty) continue;
    final quantity = switch (item['quantity']) {
      int value => value,
      num value => value.toInt(),
      String value => int.tryParse(value.trim()) ?? 1,
      _ => 1,
    };
    if (quantity <= 0) continue;
    quantities[key] = (quantities[key] ?? 0) + quantity;
  }
  return quantities;
}

List<Map<String, dynamic>> buildOptimizationCardDelta({
  required Iterable<Map<String, dynamic>> beforeCards,
  required Iterable<Map<String, dynamic>> afterCards,
  required bool additions,
}) {
  final before = _canonicalQuantityMap(beforeCards);
  final after = _canonicalQuantityMap(afterCards);
  final keys = <String>{...before.keys, ...after.keys}.toList()..sort();
  final result = <Map<String, dynamic>>[];
  for (final key in keys) {
    final delta = (after[key] ?? 0) - (before[key] ?? 0);
    final quantity = additions ? delta : -delta;
    if (quantity <= 0) continue;
    result.add({'card_id': key, 'quantity': quantity});
  }
  return result;
}

Map<String, dynamic>? buildOptimizeApplyAuthorizationForResponse({
  required String signingSecret,
  required String deckId,
  required String deckSignature,
  required Map<String, dynamic> responseBody,
  int? bracket,
  DateTime? issuedAt,
  Duration lifetime = kOptimizeApplyAuthorizationLifetime,
}) {
  if (signingSecret.trim().isEmpty ||
      responseBody['can_apply'] == false ||
      responseBody['learning_eligible'] == false ||
      responseBody['quality_error'] is Map) {
    return null;
  }
  final removals =
      (responseBody['removals_detailed'] as List?)
          ?.whereType<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .toList(growable: false) ??
      const <Map<String, dynamic>>[];
  final additions =
      (responseBody['additions_detailed'] as List?)
          ?.whereType<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .toList(growable: false) ??
      const <Map<String, dynamic>>[];
  if (removals.isEmpty && additions.isEmpty) return null;

  final mode = responseBody['mode']?.toString().trim().toLowerCase() ?? '';
  final resolvedBracket = bracket ?? _readNullableInt(responseBody['bracket']);
  final functionalRolePolicy = _canonicalFunctionalRolePolicy(
    responseBody['functional_role_policy'],
  );
  final optimizeLike = mode == 'optimize' || removals.isNotEmpty;
  final authorizedSwaps =
      optimizeLike ? _canonicalAuthorizedSwapPairs(removals, additions) : null;
  if (optimizeLike && authorizedSwaps == null) return null;
  final isCommanderOptimize = resolvedBracket != null && optimizeLike;
  if (isCommanderOptimize &&
      !_isSatisfiedFunctionalRolePolicy(functionalRolePolicy)) {
    return null;
  }

  final now = (issuedAt ?? DateTime.now().toUtc()).toUtc();
  final expiresAt = now.add(lifetime);
  final payload = <String, dynamic>{
    'version': kOptimizeApplyAuthorizationVersion,
    'deck_id': deckId,
    'deck_signature': deckSignature,
    'mode': mode,
    'bracket': resolvedBracket,
    if (functionalRolePolicy != null)
      'functional_role_policy': functionalRolePolicy,
    'removals': _canonicalQuantityMap(removals),
    'additions': _canonicalQuantityMap(additions),
    if (authorizedSwaps != null) 'swaps': authorizedSwaps,
    'issued_at': now.millisecondsSinceEpoch ~/ 1000,
    'expires_at': expiresAt.millisecondsSinceEpoch ~/ 1000,
  };
  final payloadSegment = _base64UrlNoPadding(utf8.encode(jsonEncode(payload)));
  final signature =
      Hmac(
        sha256,
        utf8.encode(signingSecret),
      ).convert(utf8.encode(payloadSegment)).bytes;
  final token = '$payloadSegment.${_base64UrlNoPadding(signature)}';
  return {
    'version': kOptimizeApplyAuthorizationVersion,
    'algo': kOptimizeApplyAuthorizationAlgo,
    'token': token,
    'expires_at': expiresAt.toIso8601String(),
  };
}

List<Map<String, dynamic>>? _canonicalAuthorizedSwapPairs(
  List<Map<String, dynamic>> removals,
  List<Map<String, dynamic>> additions,
) {
  if (removals.length != additions.length) return null;
  final pairs = <Map<String, dynamic>>[];
  for (var index = 0; index < removals.length; index++) {
    final removal = _canonicalAuthorizationCard(removals[index]);
    final addition = _canonicalAuthorizationCard(additions[index]);
    if (removal == null || addition == null) return null;
    pairs.add({
      'removal_id': removal.$1,
      'removal_quantity': removal.$2,
      'addition_id': addition.$1,
      'addition_quantity': addition.$2,
    });
  }
  pairs.sort((a, b) {
    final removalOrder = (a['removal_id'] as String).compareTo(
      b['removal_id'] as String,
    );
    if (removalOrder != 0) return removalOrder;
    final additionOrder = (a['addition_id'] as String).compareTo(
      b['addition_id'] as String,
    );
    if (additionOrder != 0) return additionOrder;
    final removalQuantityOrder = (a['removal_quantity'] as int).compareTo(
      b['removal_quantity'] as int,
    );
    if (removalQuantityOrder != 0) return removalQuantityOrder;
    return (a['addition_quantity'] as int).compareTo(
      b['addition_quantity'] as int,
    );
  });
  return pairs;
}

(String, int)? _canonicalAuthorizationCard(Map<String, dynamic> card) {
  final id =
      (card['card_id'] ?? card['name'] ?? '').toString().trim().toLowerCase();
  final quantity = _readNullableInt(card['quantity']) ?? 1;
  if (id.isEmpty || quantity <= 0) return null;
  return (id, quantity);
}

Map<String, dynamic>? _canonicalFunctionalRolePolicy(Object? raw) {
  if (raw is! Map) return null;
  final policy = raw.cast<Object?, Object?>();
  final minimumCounts = _canonicalRoleCountMap(policy['minimum_counts']);
  final actualCounts = _canonicalRoleCountMap(policy['actual_counts']);
  final deficits = _canonicalRoleCountMap(policy['deficits']);
  return {
    'policy': policy['policy']?.toString().trim() ?? '',
    'archetype': policy['archetype']?.toString().trim().toLowerCase() ?? '',
    'applies': policy['applies'] == true,
    'total_cards': _readNullableInt(policy['total_cards']),
    'minimum_counts': minimumCounts,
    'actual_counts': actualCounts,
    'deficits': deficits,
    'satisfied': policy['satisfied'] == true,
  };
}

Map<String, int> _canonicalRoleCountMap(Object? raw) {
  if (raw is! Map) return const <String, int>{};
  final result = <String, int>{};
  final entries =
      raw.entries.toList()
        ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
  for (final entry in entries) {
    final role = entry.key.toString().trim().toLowerCase();
    final count = _readNullableInt(entry.value);
    if (role.isNotEmpty && count != null && count >= 0) {
      result[role] = count;
    }
  }
  return result;
}

bool _isSatisfiedFunctionalRolePolicy(Map<String, dynamic>? policy) {
  if (policy == null ||
      policy['policy'] != 'commander_functional_role_floors_v1' ||
      policy['archetype']?.toString().isEmpty != false ||
      policy['applies'] != true ||
      policy['satisfied'] != true ||
      (_readNullableInt(policy['total_cards']) ?? 0) < 90) {
    return false;
  }
  final minimumCounts = _canonicalRoleCountMap(policy['minimum_counts']);
  final actualCounts = _canonicalRoleCountMap(policy['actual_counts']);
  final deficits = _canonicalRoleCountMap(policy['deficits']);
  if (minimumCounts.isEmpty || deficits.isNotEmpty) return false;
  for (final entry in minimumCounts.entries) {
    if ((actualCounts[entry.key] ?? -1) < entry.value) return false;
  }
  return true;
}

void attachOptimizeApplyAuthorizationToResponse({
  required String deckId,
  required String deckSignature,
  required Map<String, dynamic> responseBody,
  int? bracket,
  Map<String, String>? environment,
  DateTime? issuedAt,
  Duration lifetime = kOptimizeApplyAuthorizationLifetime,
}) {
  // Tokens cached by an older process may already be expired. Every response
  // receives a fresh authorization derived from the current server secret.
  responseBody.remove('apply_authorization');
  final signingSecret = resolveOptimizeApplySigningSecret(
    environment: environment,
  );
  if (signingSecret.isEmpty) {
    _markOptimizeApplySigningUnavailable(responseBody);
    return;
  }
  final authorization = buildOptimizeApplyAuthorizationForResponse(
    signingSecret: signingSecret,
    deckId: deckId,
    deckSignature: deckSignature,
    responseBody: responseBody,
    bracket: bracket,
    issuedAt: issuedAt,
    lifetime: lifetime,
  );
  if (authorization != null) {
    responseBody['apply_authorization'] = authorization;
  }
}

void _markOptimizeApplySigningUnavailable(Map<String, dynamic> responseBody) {
  final hasChanges =
      (responseBody['removals_detailed'] is List &&
          (responseBody['removals_detailed'] as List).isNotEmpty) ||
      (responseBody['additions_detailed'] is List &&
          (responseBody['additions_detailed'] as List).isNotEmpty);
  final otherwiseActionable =
      hasChanges &&
      responseBody['can_apply'] != false &&
      responseBody['quality_error'] is! Map;
  if (!otherwiseActionable) return;

  responseBody['can_apply'] = false;
  responseBody['learning_eligible'] = false;
  responseBody['outcome_code'] = 'optimization_apply_signing_unavailable';
  responseBody['quality_error'] = const {
    'code': 'OPTIMIZATION_APPLY_SIGNING_UNAVAILABLE',
    'message':
        'A aplicação segura está temporariamente indisponível. '
        'Atualize a análise mais tarde.',
  };
  final blockers =
      responseBody['apply_blockers'] is Iterable
          ? (responseBody['apply_blockers'] as Iterable)
              .map((entry) => entry.toString())
              .toSet()
          : <String>{};
  blockers.add('optimization_apply_signing_unavailable');
  responseBody['apply_blockers'] = blockers.toList()..sort();
}

class OptimizeApplyAuthorizationVerification {
  const OptimizeApplyAuthorizationVerification({
    required this.valid,
    required this.code,
    this.payload = const <String, dynamic>{},
  });

  final bool valid;
  final String code;
  final Map<String, dynamic> payload;
}

OptimizeApplyAuthorizationVerification verifyOptimizeApplyAuthorization({
  required String signingSecret,
  required String token,
  required String deckId,
  required String deckSignature,
  required Iterable<Map<String, dynamic>> actualRemovals,
  required Iterable<Map<String, dynamic>> actualAdditions,
  int? expectedBracket,
  DateTime? now,
}) {
  if (signingSecret.trim().isEmpty) {
    return const OptimizeApplyAuthorizationVerification(
      valid: false,
      code: 'signing_secret_unavailable',
    );
  }
  final parts = token.trim().split('.');
  if (parts.length != 2 || parts.any((part) => part.isEmpty)) {
    return const OptimizeApplyAuthorizationVerification(
      valid: false,
      code: 'malformed_token',
    );
  }

  try {
    final expectedSignature =
        Hmac(
          sha256,
          utf8.encode(signingSecret),
        ).convert(utf8.encode(parts[0])).bytes;
    final receivedSignature = _decodeBase64UrlNoPadding(parts[1]);
    if (!_constantTimeBytesEqual(expectedSignature, receivedSignature)) {
      return const OptimizeApplyAuthorizationVerification(
        valid: false,
        code: 'invalid_signature',
      );
    }

    final decoded = jsonDecode(
      utf8.decode(_decodeBase64UrlNoPadding(parts[0])),
    );
    if (decoded is! Map) {
      return const OptimizeApplyAuthorizationVerification(
        valid: false,
        code: 'invalid_payload',
      );
    }
    final payload = decoded.cast<String, dynamic>();
    if (payload['version'] != kOptimizeApplyAuthorizationVersion) {
      return OptimizeApplyAuthorizationVerification(
        valid: false,
        code: 'unsupported_version',
        payload: payload,
      );
    }
    if (payload['deck_id']?.toString() != deckId ||
        payload['deck_signature']?.toString() != deckSignature) {
      return OptimizeApplyAuthorizationVerification(
        valid: false,
        code: 'deck_binding_mismatch',
        payload: payload,
      );
    }
    final expiresAt = switch (payload['expires_at']) {
      int value => value,
      num value => value.toInt(),
      String value => int.tryParse(value),
      _ => null,
    };
    final currentEpoch =
        (now ?? DateTime.now().toUtc()).toUtc().millisecondsSinceEpoch ~/ 1000;
    if (expiresAt == null || expiresAt < currentEpoch) {
      return OptimizeApplyAuthorizationVerification(
        valid: false,
        code: 'expired_token',
        payload: payload,
      );
    }
    final tokenBracket = switch (payload['bracket']) {
      int value => value,
      num value => value.toInt(),
      String value => int.tryParse(value),
      _ => null,
    };
    if (expectedBracket != null && tokenBracket != expectedBracket) {
      return OptimizeApplyAuthorizationVerification(
        valid: false,
        code: 'bracket_binding_mismatch',
        payload: payload,
      );
    }

    final allowedRemovals = _readAuthorizationQuantityMap(payload['removals']);
    final allowedAdditions = _readAuthorizationQuantityMap(
      payload['additions'],
    );
    final actualRemovalQuantities = _canonicalQuantityMap(actualRemovals);
    final actualAdditionQuantities = _canonicalQuantityMap(actualAdditions);
    final authorizedPairs = _readAuthorizationSwapPairs(payload['swaps']);
    final changesAuthorized =
        authorizedPairs.isNotEmpty
            ? _isAuthorizedSwapPairSubset(
              actualRemovals: actualRemovalQuantities,
              actualAdditions: actualAdditionQuantities,
              authorizedPairs: authorizedPairs,
            )
            : _isQuantitySubset(actualRemovalQuantities, allowedRemovals) &&
                _isQuantitySubset(actualAdditionQuantities, allowedAdditions);
    if (!changesAuthorized) {
      return OptimizeApplyAuthorizationVerification(
        valid: false,
        code:
            authorizedPairs.isNotEmpty
                ? 'swap_pairs_not_authorized'
                : 'changes_not_authorized',
        payload: payload,
      );
    }
    return OptimizeApplyAuthorizationVerification(
      valid: true,
      code: 'ok',
      payload: payload,
    );
  } catch (_) {
    return const OptimizeApplyAuthorizationVerification(
      valid: false,
      code: 'invalid_payload',
    );
  }
}

List<Map<String, dynamic>> _readAuthorizationSwapPairs(Object? raw) {
  if (raw is! Iterable) return const <Map<String, dynamic>>[];
  final pairs = <Map<String, dynamic>>[];
  for (final entry in raw) {
    if (entry is! Map) continue;
    final removalId =
        entry['removal_id']?.toString().trim().toLowerCase() ?? '';
    final additionId =
        entry['addition_id']?.toString().trim().toLowerCase() ?? '';
    final removalQuantity = _readNullableInt(entry['removal_quantity']) ?? 0;
    final additionQuantity = _readNullableInt(entry['addition_quantity']) ?? 0;
    if (removalId.isEmpty ||
        additionId.isEmpty ||
        removalQuantity <= 0 ||
        additionQuantity <= 0) {
      continue;
    }
    pairs.add({
      'removal_id': removalId,
      'removal_quantity': removalQuantity,
      'addition_id': additionId,
      'addition_quantity': additionQuantity,
    });
  }
  return pairs;
}

bool _isAuthorizedSwapPairSubset({
  required Map<String, int> actualRemovals,
  required Map<String, int> actualAdditions,
  required List<Map<String, dynamic>> authorizedPairs,
}) {
  final memo = <String, bool>{};

  bool search(
    int index,
    Map<String, int> remainingRemovals,
    Map<String, int> remainingAdditions,
  ) {
    if (remainingRemovals.isEmpty && remainingAdditions.isEmpty) return true;
    if (index >= authorizedPairs.length) return false;
    final key =
        '$index|${_quantityMapKey(remainingRemovals)}|'
        '${_quantityMapKey(remainingAdditions)}';
    final cached = memo[key];
    if (cached != null) return cached;

    if (search(index + 1, remainingRemovals, remainingAdditions)) {
      memo[key] = true;
      return true;
    }

    final pair = authorizedPairs[index];
    final removalId = pair['removal_id'] as String;
    final removalQuantity = pair['removal_quantity'] as int;
    final additionId = pair['addition_id'] as String;
    final additionQuantity = pair['addition_quantity'] as int;
    if ((remainingRemovals[removalId] ?? 0) < removalQuantity ||
        (remainingAdditions[additionId] ?? 0) < additionQuantity) {
      memo[key] = false;
      return false;
    }
    final nextRemovals = Map<String, int>.from(remainingRemovals);
    final nextAdditions = Map<String, int>.from(remainingAdditions);
    _subtractQuantity(nextRemovals, removalId, removalQuantity);
    _subtractQuantity(nextAdditions, additionId, additionQuantity);
    final matched = search(index + 1, nextRemovals, nextAdditions);
    memo[key] = matched;
    return matched;
  }

  return search(
    0,
    Map<String, int>.from(actualRemovals),
    Map<String, int>.from(actualAdditions),
  );
}

void _subtractQuantity(Map<String, int> target, String id, int quantity) {
  final remaining = (target[id] ?? 0) - quantity;
  if (remaining <= 0) {
    target.remove(id);
  } else {
    target[id] = remaining;
  }
}

String _quantityMapKey(Map<String, int> quantities) {
  final entries =
      quantities.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  return entries.map((entry) => '${entry.key}:${entry.value}').join(',');
}

Map<String, int> _readAuthorizationQuantityMap(Object? raw) {
  if (raw is! Map) return const <String, int>{};
  final result = <String, int>{};
  for (final entry in raw.entries) {
    final key = entry.key.toString().trim().toLowerCase();
    final quantity = switch (entry.value) {
      int value => value,
      num value => value.toInt(),
      String value => int.tryParse(value.trim()) ?? 0,
      _ => 0,
    };
    if (key.isNotEmpty && quantity > 0) result[key] = quantity;
  }
  return result;
}

int? _readNullableInt(Object? raw) => switch (raw) {
  int value => value,
  num value => value.toInt(),
  String value => int.tryParse(value.trim()),
  _ => null,
};

bool _isQuantitySubset(Map<String, int> actual, Map<String, int> allowed) {
  if (actual.isEmpty) return true;
  for (final entry in actual.entries) {
    if (entry.value > (allowed[entry.key] ?? 0)) return false;
  }
  return true;
}

bool _constantTimeBytesEqual(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var difference = 0;
  for (var index = 0; index < a.length; index++) {
    difference |= a[index] ^ b[index];
  }
  return difference == 0;
}
