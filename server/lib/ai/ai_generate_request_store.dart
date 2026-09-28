import 'dart:convert';

import 'package:postgres/postgres.dart';

import '../decks/deck_review_artifact.dart';

/// O pedido durável do Generate (DCK-P0-04; decisão D-29 do dono).
///
/// A fila de jobs (`ai_generate_jobs`) vive 24 h (D-32); o pedido fica em
/// `ai_generate_requests`: a entrada original (prompt e controles), a
/// impressão do pedido, o resultado quando o job termina e o deck que o
/// servidor materializou a partir dele. O prompt bruto fica só 30 dias
/// ([aiGenerateRequestPromptRetention]); a limpeza por prazo o apaga, junto
/// com a impressão derivada dele. O deck nunca guarda o prompt na descrição.
const aiGenerateRequestPromptRetention = Duration(days: 30);

/// O tipo do `DeckReviewArtifact v1` que autoriza materializar o resultado.
const aiGenerateMaterializeArtifactKind = 'generate_materialize';

/// Mesmo `request_key` com outro pedido.
class AiGenerateRequestConflict implements Exception {
  const AiGenerateRequestConflict();
}

class AiGenerateRequestStore {
  AiGenerateRequestStore._();

  /// Grava o pedido na criação do job, idempotente por usuário e
  /// `request_key`. Devolve o id do pedido.
  static Future<String> record(
    Pool pool, {
    required String userId,
    required String requestKey,
    required String requestFingerprint,
    required String jobId,
    required String format,
    required Map<String, Object?> controls,
    required String prompt,
  }) async {
    final inserted = await pool.execute(
      Sql.named('''
        INSERT INTO ai_generate_requests (
          user_id, request_key, request_fingerprint, job_id, format,
          controls, prompt
        ) VALUES (
          CAST(@userId AS uuid), @requestKey, @fingerprint, @jobId, @format,
          CAST(@controls AS jsonb), @prompt
        )
        ON CONFLICT (user_id, request_key) DO NOTHING
        RETURNING id::text
      '''),
      parameters: {
        'userId': userId,
        'requestKey': requestKey,
        'fingerprint': requestFingerprint,
        'jobId': jobId,
        'format': format,
        'controls': jsonEncode(controls),
        'prompt': prompt,
      },
    );
    if (inserted.isNotEmpty) return inserted.first[0] as String;

    final existing = await pool.execute(
      Sql.named('''
        SELECT id::text, request_fingerprint
        FROM ai_generate_requests
        WHERE user_id = CAST(@userId AS uuid) AND request_key = @requestKey
      '''),
      parameters: {'userId': userId, 'requestKey': requestKey},
    );
    if (existing.isEmpty || existing.first[1] != requestFingerprint) {
      throw const AiGenerateRequestConflict();
    }
    return existing.first[0] as String;
  }

  /// Grava o resultado do job que terminou. [canMaterialize] é a mesma
  /// regra que decide se o resultado pode ser salvo (sem mock, sem carta
  /// inválida, validação ok).
  static Future<void> recordResult(
    Pool pool, {
    required String jobId,
    required Map<String, dynamic> result,
    required bool canMaterialize,
  }) async {
    final deck = result['generated_deck'];
    final resultDeck =
        deck is Map ? deck.cast<String, dynamic>() : const <String, dynamic>{};
    await pool.execute(
      Sql.named('''
        UPDATE ai_generate_requests
        SET status = 'completed',
            result_deck = CAST(@resultDeck AS jsonb),
            result_fingerprint = @resultFingerprint,
            can_materialize = @canMaterialize,
            updated_at = CURRENT_TIMESTAMP
        WHERE job_id = @jobId AND status = 'pending'
      '''),
      parameters: {
        'jobId': jobId,
        'resultDeck': jsonEncode(resultDeck),
        'resultFingerprint': canonicalDeckReviewHash(resultDeck),
        'canMaterialize': canMaterialize && resultDeck.isNotEmpty,
      },
    );
  }

  /// O pedido do usuário, com o estado do job ainda vivo. `id` pode ser
  /// `latest`.
  static Future<Map<String, dynamic>?> read(
    Session session, {
    required String userId,
    required String id,
    bool forUpdate = false,
  }) async {
    final latest = id == 'latest';
    final result = await session.execute(
      Sql.named('''
        SELECT r.id::text, r.request_key, r.request_fingerprint, r.job_id,
               r.format, r.controls, r.prompt, r.prompt_purged_at, r.status,
               r.result_deck, r.result_fingerprint, r.can_materialize,
               r.materialized_deck_id::text, r.materialized_at,
               r.created_at, r.updated_at,
               j.status AS job_status
        FROM ai_generate_requests r
        LEFT JOIN ai_generate_jobs j ON j.id = r.job_id
        WHERE r.user_id = CAST(@userId AS uuid)
          ${latest ? '' : 'AND r.id = CAST(@id AS uuid)'}
        ORDER BY r.created_at DESC
        LIMIT 1
        ${forUpdate ? 'FOR UPDATE OF r' : ''}
      '''),
      parameters: {'userId': userId, if (!latest) 'id': id},
    );
    if (result.isEmpty) return null;
    return result.first.toColumnMap();
  }

  /// O estado que o app vê: o do pedido, ou, pendente, o do job que ainda
  /// existe (`expired` quando a fila já apagou o job).
  static String effectiveStatus(Map<String, dynamic> row) {
    final status = '${row['status']}';
    if (status != 'pending') return status;
    return switch (row['job_status']) {
      'failed' => 'failed',
      'cancelled' => 'cancelled',
      null => 'expired',
      _ => 'pending',
    };
  }

  /// Os controles que o resultado liga (formato, bracket, comandante e as
  /// restrições): o hash deles vai no artefato de materialização.
  static Map<String, Object?> constraintsOf(Map<String, dynamic> row) => {
    'format': row['format'],
    'controls': _jsonMap(row['controls']),
  };

  static Map<String, dynamic> toJson(
    Map<String, dynamic> row, {
    Map<String, Object?>? reviewArtifact,
  }) {
    final created = row['created_at'] as DateTime?;
    final resultDeck = _jsonMap(row['result_deck']);
    final cards = resultDeck['cards'];
    return {
      'id': row['id'],
      'status': effectiveStatus(row),
      'format': row['format'],
      'controls': _jsonMap(row['controls']),
      'prompt': row['prompt'],
      'prompt_available': row['prompt'] != null,
      'prompt_expires_at':
          created
              ?.toUtc()
              .add(aiGenerateRequestPromptRetention)
              .toIso8601String(),
      'prompt_purged_at':
          (row['prompt_purged_at'] as DateTime?)?.toUtc().toIso8601String(),
      'job_id': row['job_id'],
      if (resultDeck.isNotEmpty)
        'result': {
          'commander': resultDeck['commander'],
          'cards': cards,
          'total_cards':
              (cards is List ? cards : const []).whereType<Map>().fold<int>(
                0,
                (sum, card) => sum + ((card['quantity'] as num?)?.toInt() ?? 1),
              ) +
              (resultDeck['commander'] is Map ? 1 : 0),
        },
      'can_materialize':
          row['can_materialize'] == true && row['materialized_deck_id'] == null,
      'materialized_deck_id': row['materialized_deck_id'],
      'materialized_at':
          (row['materialized_at'] as DateTime?)?.toUtc().toIso8601String(),
      'created_at': created?.toUtc().toIso8601String(),
      if (reviewArtifact != null) 'review_artifact': reviewArtifact,
    };
  }
}

Map<String, dynamic> _jsonMap(Object? raw) {
  final value = raw is String ? jsonDecode(raw) : raw;
  return value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};
}
