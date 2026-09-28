import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:server/analytics/activation_event_catalog.dart';
import 'package:test/test.dart';

/// BT-KPI-001: o catálogo `activation_events_v1` aceita exatamente o que o
/// app atual emite, só com enumerados, inteiros com faixa e booleanos, e
/// recusa decklist, texto livre, ID interno e campo fora do esquema.
void main() {
  const deckId = '0b8f7a57-4d8e-4f7e-9c7a-2f3a1e5b6c7d';
  const userId = '5a0c1b2d-3e4f-4a5b-8c6d-7e8f9a0b1c2d';

  ActivationEventRecord accept(Map<String, Object?> body) {
    final validation = validateActivationEvent(body);
    expect(
      validation.rejection?.toJson(),
      isNull,
      reason: 'o evento deveria passar: $body',
    );
    return validation.record!;
  }

  ActivationEventRejection reject(Map<String, Object?> body) {
    final validation = validateActivationEvent(body);
    expect(validation.record, isNull, reason: 'o evento deveria cair: $body');
    return validation.rejection!;
  }

  /// Todo texto guardado no metadata é um valor de lista fechada.
  void expectOnlyClosedValues(Object? value) {
    if (value is Map) {
      value.values.forEach(expectOnlyClosedValues);
    } else {
      expect(
        value is bool || value is int || value is String,
        isTrue,
        reason: 'valor $value',
      );
    }
  }

  group('o que o app atual emite passa', () {
    test('onboarding: início, escolhas, tarefa, conclusão e pulo', () {
      final key = 'onboarding:v1:$userId:started';
      final started = accept({
        'event_name': 'core_flow_started',
        'format': 'commander',
        'source': 'onboarding',
        'metadata': {
          'goal': 'buildDeck',
          'experience': 'firstSteps',
          'idempotency_key': key,
        },
      });
      expect(started.metadata, {
        'experience': 'firstSteps',
        'goal': 'buildDeck',
      });
      expect(started.dedupeKey, sha256.convert(utf8.encode(key)).toString());
      expect(jsonEncode(started.metadata), isNot(contains(userId)));

      for (final event in const [
        'onboarding_goal_selected',
        'onboarding_experience_selected',
        'onboarding_build_mode_selected',
        'format_selected',
        'onboarding_task_started',
      ]) {
        final record = accept({
          'event_name': event,
          'format': 'modern',
          'source': 'onboarding',
          'metadata': {
            'goal': 'play',
            'experience': 'returning',
            'build_mode': 'guided',
            'idempotency_key': 'onboarding:v1:$userId:$event',
          },
        });
        expect(record.metadata, {
          'build_mode': 'guided',
          'experience': 'returning',
          'goal': 'play',
        });
        expect(record.format, 'modern');
      }

      for (final source in const [
        'onboarding',
        'onboarding_task',
        'home_intent',
      ]) {
        accept({
          'event_name': 'onboarding_completed',
          'format': 'commander',
          'source': source,
          'metadata': {
            'disposition': 'completed',
            'goal': 'importDeck',
            'idempotency_key': 'onboarding:v1:$userId:completed',
          },
        });
      }
      accept({
        'event_name': 'onboarding_skipped',
        'format': 'commander',
        'source': 'onboarding',
        'metadata': {
          'disposition': 'skipped',
          'idempotency_key': 'onboarding:v1:$userId:skipped',
        },
      });
    });

    test('deck: criar, gerar, prévia do Optimize e rebuild', () {
      final created = accept({
        'event_name': 'deck_created',
        'format': 'EDH',
        'source': 'deck_provider.createDeck',
        'metadata': <String, Object?>{},
      });
      expect(created.format, 'commander');
      expect(created.metadata, isEmpty);
      expect(created.dedupeKey, isNull);

      final generated = accept({
        'event_name': 'deck_generated',
        'format': 'commander',
        'source': 'deck_provider.generateDeck',
        'metadata': {
          'prompt_length': 240,
          'commander_selected': true,
          'bracket': 3,
          'prefer_collection': false,
          'collection_only': false,
          'budget_requested': true,
        },
      });
      expect(generated.metadata['prompt_length'], 240);

      final optimize = accept({
        'event_name': 'optimize_preview_received',
        'deck_id': deckId.toUpperCase(),
        'source': 'deck_provider.optimizeDeck',
        'metadata': {
          'archetype': 'Meu plano secreto de Talrand',
          'bracket': 2,
          'keep_theme': true,
          'intensity': 'focused',
          'recommendation_context': {
            'prefer_collection': true,
            'budget_limit_brl': 250,
            'rebuild_intent': 'upgraded',
            'report': 'before_after_shareable',
            'explain_swaps': true,
            'include_price_risk_curve_bracket': true,
            'post_game_note_id': 'nota-123',
          },
        },
      });
      expect(optimize.deckId, deckId);
      expect(optimize.droppedFields, [
        'metadata.archetype',
        'metadata.recommendation_context.post_game_note_id',
      ]);
      final stored = jsonEncode(optimize.metadata);
      expect(stored, isNot(contains('Talrand')));
      expect(stored, isNot(contains('nota-123')));
      expect(
        (optimize.metadata['recommendation_context']!
            as Map)['budget_limit_brl'],
        250,
      );

      final rebuild = accept({
        'event_name': 'deck_rebuild_created',
        'deck_id': deckId,
        'source': 'deck_provider.rebuildDeck',
        'metadata': {
          'source_deck_id': deckId,
          'rebuild_scope_selected': 'repair_partial',
          'save_mode': 'draft_clone',
        },
      });
      expect(rebuild.droppedFields, ['metadata.source_deck_id']);
      expect(rebuild.metadata, {
        'rebuild_scope_selected': 'repair_partial',
        'save_mode': 'draft_clone',
      });
      expectOnlyClosedValues(rebuild.metadata);
      expectOnlyClosedValues(optimize.metadata);
    });

    test('campo nulo não é guardado e a chave pode vir no primeiro nível', () {
      final record = accept({
        'event_name': 'deck_rebuild_created',
        'deck_id': deckId,
        'source': 'deck_provider.rebuildDeck',
        'idempotency_key': 'rebuild:1',
        'metadata': {
          'rebuild_scope_selected': null,
          'save_mode': 'preview_only',
        },
      });
      expect(record.metadata, {'save_mode': 'preview_only'});
      expect(record.dedupeKey, activationEventDedupeKey('rebuild:1'));
    });
  });

  group('o que não pode ir para analytics cai', () {
    test('evento fora do catálogo ou aposentado', () {
      for (final name in [
        'deck_optimized',
        'base_choice_generate',
        'base_choice_import',
        'deck_name_changed',
        null,
        42,
      ]) {
        final rejection = reject({'event_name': name, 'source': 'onboarding'});
        expect(rejection.errorCode, activationEventUnknown, reason: '$name');
        expect(rejection.field, 'event_name');
      }
      expect(
        retiredActivationEvents,
        isNot(anyElement(isIn(activationEventCatalog.keys))),
      );
    });

    test('decklist, nome de deck e texto livre no metadata', () {
      final decklist = reject({
        'event_name': 'deck_created',
        'source': 'deck_provider.createDeck',
        'metadata': {
          'cards': ['1 Sol Ring', '1 Talrand, Sky Summoner'],
        },
      });
      expect(decklist.errorCode, activationEventFieldNotAllowed);
      expect(decklist.field, 'metadata.cards');

      final deckName = reject({
        'event_name': 'deck_generated',
        'source': 'deck_provider.generateDeck',
        'metadata': {'prompt_length': 10, 'deck_name': 'Talrand do João'},
      });
      expect(deckName.field, 'metadata.deck_name');

      final freeText = reject({
        'event_name': 'onboarding_goal_selected',
        'source': 'onboarding',
        'metadata': {'goal': 'quero montar um deck de Talrand'},
      });
      expect(freeText.errorCode, activationEventValueInvalid);
      expect(freeText.field, 'metadata.goal');

      final prompt = reject({
        'event_name': 'deck_generated',
        'source': 'deck_provider.generateDeck',
        'metadata': {'prompt_length': 'um deck de Talrand com contramágicas'},
      });
      expect(prompt.field, 'metadata.prompt_length');

      final nested = reject({
        'event_name': 'optimize_preview_received',
        'source': 'deck_provider.optimizeDeck',
        'metadata': {
          'recommendation_context': {'note_text': 'perdi para Atraxa'},
        },
      });
      expect(nested.field, 'metadata.recommendation_context.note_text');
    });

    test('tipo, faixa e objeto errados', () {
      Map<String, Object?> generated(Map<String, Object?> metadata) => {
        'event_name': 'deck_generated',
        'source': 'deck_provider.generateDeck',
        'metadata': metadata,
      };
      expect(reject(generated({'bracket': 6})).field, 'metadata.bracket');
      expect(reject(generated({'bracket': 0})).field, 'metadata.bracket');
      expect(reject(generated({'bracket': 2.5})).field, 'metadata.bracket');
      expect(
        reject(generated({'prompt_length': 32769})).field,
        'metadata.prompt_length',
      );
      expect(
        reject(generated({'prompt_length': -1})).field,
        'metadata.prompt_length',
      );
      expect(
        reject(generated({'commander_selected': 'true'})).field,
        'metadata.commander_selected',
      );
      expect(
        reject({
          'event_name': 'optimize_preview_received',
          'source': 'deck_provider.optimizeDeck',
          'metadata': {'recommendation_context': 'upgraded'},
        }).field,
        'metadata.recommendation_context',
      );
      expect(
        reject({
          'event_name': 'deck_created',
          'source': 'deck_provider.createDeck',
          'metadata': ['cards'],
        }).field,
        'metadata',
      );
    });

    test('origem, formato, deck e campo de primeiro nível', () {
      expect(
        reject({'event_name': 'deck_created', 'source': 'app'}).field,
        'source',
      );
      expect(
        reject({'event_name': 'deck_created', 'source': null}).field,
        'source',
      );
      expect(
        reject({
          'event_name': 'deck_created',
          'source': 'deck_provider.createDeck',
          'format': 'Talrand casual',
        }).field,
        'format',
      );
      final deckOnWrongEvent = reject({
        'event_name': 'deck_created',
        'source': 'deck_provider.createDeck',
        'deck_id': deckId,
      });
      expect(deckOnWrongEvent.errorCode, activationEventFieldNotAllowed);
      expect(deckOnWrongEvent.field, 'deck_id');
      expect(
        reject({
          'event_name': 'optimize_preview_received',
          'source': 'deck_provider.optimizeDeck',
          'deck_id': 'meu-deck',
        }).field,
        'deck_id',
      );
      final extra = reject({
        'event_name': 'deck_created',
        'source': 'deck_provider.createDeck',
        'deck_name': 'Talrand',
      });
      expect(extra.errorCode, activationEventFieldNotAllowed);
      expect(extra.field, 'deck_name');
      expect(
        validateActivationEvent(['deck_created']).rejection!.errorCode,
        activationEventBodyInvalid,
      );
    });

    test('chave de idempotência vazia, longa ou em dobro', () {
      Map<String, Object?> body(Map<String, Object?> extra) => {
        'event_name': 'deck_created',
        'source': 'deck_provider.createDeck',
        ...extra,
      };
      expect(reject(body({'idempotency_key': ' '})).field, 'idempotency_key');
      expect(
        reject(
          body({
            'metadata': {'idempotency_key': 'x' * 201},
          }),
        ).field,
        'metadata.idempotency_key',
      );
      expect(
        reject(
          body({
            'metadata': {'idempotency_key': 42},
          }),
        ).field,
        'metadata.idempotency_key',
      );
      expect(
        reject(
          body({
            'idempotency_key': 'a',
            'metadata': {'idempotency_key': 'a'},
          }),
        ).field,
        'idempotency_key',
      );
      expect(
        accept(body({'idempotency_key': 'x' * 200})).dedupeKey,
        hasLength(64),
      );
    });
  });

  test('a recusa tem forma estável e o catálogo tem versão', () {
    final rejection = reject({'event_name': 'deck_optimized'});
    expect(rejection.toJson(), {
      'ok': false,
      'error': 'event_name fora do catálogo de eventos.',
      'error_code': 'activation_event_unknown',
      'field': 'event_name',
    });
    expect(activationEventCatalogVersion, 'activation_events_v1');
    expect(activationEventCatalog.keys, hasLength(12));
  });
}
