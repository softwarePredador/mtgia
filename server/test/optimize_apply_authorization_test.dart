import 'dart:io';

import 'package:test/test.dart';

import '../lib/ai/optimize_swap_integrity.dart';
import '../lib/decks/optimization_apply_authorization_support.dart';
import '../lib/decks/optimization_functional_role_floor_support.dart';

void main() {
  const secret = 'test-only-optimization-secret';
  final issuedAt = DateTime.utc(2026, 7, 30, 12);
  const response = <String, dynamic>{
    'mode': 'optimize',
    'bracket': 2,
    'can_apply': true,
    'learning_eligible': true,
    'functional_role_policy': {
      'policy': 'commander_functional_role_floors_v2',
      'archetype': 'midrange',
      'bracket': 2,
      'applies': true,
      'total_cards': 100,
      'minimum_counts': {'ramp': 8, 'draw': 8, 'interaction': 6, 'wipe': 2},
      'actual_counts': {'ramp': 8, 'draw': 8, 'interaction': 6, 'wipe': 2},
      'deficits': <String, int>{},
      'satisfied': true,
    },
    'removals_detailed': [
      {'card_id': 'old-a', 'quantity': 1},
      {'card_id': 'old-b', 'quantity': 2},
    ],
    'additions_detailed': [
      {'card_id': 'new-a', 'quantity': 1},
      {'card_id': 'new-b', 'quantity': 2},
    ],
  };

  Map<String, dynamic> buildAuthorization() =>
      buildOptimizeApplyAuthorizationForResponse(
        signingSecret: secret,
        deckId: 'deck-1',
        deckSignature: 'signature-1',
        responseBody: Map<String, dynamic>.from(response),
        bracket: 2,
        issuedAt: issuedAt,
      )!;

  group('signed optimization apply authorization', () {
    test(
      'binds the full preview to deck, signature, bracket and quantities',
      () {
        final authorization = buildAuthorization();
        final verification = verifyOptimizeApplyAuthorization(
          signingSecret: secret,
          token: authorization['token'] as String,
          deckId: 'deck-1',
          deckSignature: 'signature-1',
          expectedBracket: 2,
          actualRemovals: const [
            {'card_id': 'old-a', 'quantity': 1},
            {'card_id': 'old-b', 'quantity': 2},
          ],
          actualAdditions: const [
            {'card_id': 'new-a', 'quantity': 1},
            {'card_id': 'new-b', 'quantity': 2},
          ],
          now: issuedAt.add(const Duration(hours: 1)),
        );

        expect(verification.valid, isTrue);
        expect(verification.code, 'ok');
        expect(verification.payload['mode'], 'optimize');
        expect(
          verification.payload['functional_role_policy'],
          containsPair('satisfied', true),
        );
      },
    );

    test('rejects legacy or incomplete structural policies before signing', () {
      Map<String, dynamic>? signWithPolicy(Map<String, dynamic> policy) {
        return buildOptimizeApplyAuthorizationForResponse(
          signingSecret: secret,
          deckId: 'deck-1',
          deckSignature: 'signature-1',
          responseBody: {...response, 'functional_role_policy': policy},
          bracket: 2,
          issuedAt: issuedAt,
        );
      }

      final completePolicy = Map<String, dynamic>.from(
        response['functional_role_policy']! as Map,
      );
      expect(
        signWithPolicy({
          ...completePolicy,
          'policy': 'commander_functional_role_floors_v1',
        }),
        isNull,
      );
      expect(
        signWithPolicy({...completePolicy, 'bracket': 5}),
        isNull,
        reason: 'the signed role matrix must match the outer bracket',
      );
      expect(
        signWithPolicy({
          ...completePolicy,
          'minimum_counts': const {
            'ramp': 0,
            'draw': 0,
            'interaction': 0,
            'wipe': 0,
          },
          'actual_counts': const {
            'ramp': 0,
            'draw': 0,
            'interaction': 0,
            'wipe': 0,
          },
        }),
        isNull,
        reason: 'v2 cannot sign a weakened non-canonical floor matrix',
      );
      expect(
        signWithPolicy({
          ...completePolicy,
          'minimum_counts': const {'wipe': 2},
          'actual_counts': const {'wipe': 2},
        }),
        isNull,
      );
    });

    test(
      'apply floor distrusts a verified envelope with a weakened role policy',
      () {
        final completePolicy = Map<String, dynamic>.from(
          response['functional_role_policy']! as Map,
        );

        for (final policy in [
          {...completePolicy, 'bracket': 5},
          {
            ...completePolicy,
            'minimum_counts': const {
              'ramp': 0,
              'draw': 0,
              'interaction': 0,
              'wipe': 0,
            },
            'actual_counts': const {
              'ramp': 0,
              'draw': 0,
              'interaction': 0,
              'wipe': 0,
            },
          },
        ]) {
          expect(
            () => assessOptimizationApplyCommanderFunctionalRoleFloorFromCards(
              format: 'commander',
              cards: const <Map<String, dynamic>>[],
              mutationContext: const {'bracket': 2},
              authorizationVerification: OptimizeApplyAuthorizationVerification(
                valid: true,
                code: 'ok',
                payload: {
                  'mode': 'optimize',
                  'bracket': 2,
                  'removals': const {'old-a': 1},
                  'functional_role_policy': policy,
                },
              ),
              storedArchetype: 'midrange',
            ),
            throwsA(
              isA<OptimizationFunctionalRoleFloorViolation>().having(
                (error) => error.reason,
                'reason',
                'functional_role_policy_binding_missing',
              ),
            ),
          );
        }
      },
    );

    test('accepts an exact paired partial selection', () {
      final authorization = buildAuthorization();
      final verification = verifyOptimizeApplyAuthorization(
        signingSecret: secret,
        token: authorization['token'] as String,
        deckId: 'deck-1',
        deckSignature: 'signature-1',
        expectedBracket: 2,
        actualRemovals: const [
          {'card_id': 'old-a', 'quantity': 1},
        ],
        actualAdditions: const [
          {'card_id': 'new-a', 'quantity': 1},
        ],
        now: issuedAt.add(const Duration(hours: 1)),
      );

      expect(verification.valid, isTrue);
    });

    test('rejects crossing independently authorized swap pairs', () {
      final authorization = buildAuthorization();
      final verification = verifyOptimizeApplyAuthorization(
        signingSecret: secret,
        token: authorization['token'] as String,
        deckId: 'deck-1',
        deckSignature: 'signature-1',
        expectedBracket: 2,
        actualRemovals: const [
          {'card_id': 'old-a', 'quantity': 1},
        ],
        actualAdditions: const [
          {'card_id': 'new-b', 'quantity': 2},
        ],
        now: issuedAt.add(const Duration(hours: 1)),
      );

      expect(verification.valid, isFalse);
      expect(verification.code, 'swap_pairs_not_authorized');
    });

    test('rejects cards or quantities that were not in the preview', () {
      final authorization = buildAuthorization();

      final extraCard = verifyOptimizeApplyAuthorization(
        signingSecret: secret,
        token: authorization['token'] as String,
        deckId: 'deck-1',
        deckSignature: 'signature-1',
        expectedBracket: 2,
        actualRemovals: const [
          {'card_id': 'old-a', 'quantity': 1},
        ],
        actualAdditions: const [
          {'card_id': 'new-c', 'quantity': 1},
        ],
        now: issuedAt.add(const Duration(hours: 1)),
      );
      final excessQuantity = verifyOptimizeApplyAuthorization(
        signingSecret: secret,
        token: authorization['token'] as String,
        deckId: 'deck-1',
        deckSignature: 'signature-1',
        expectedBracket: 2,
        actualRemovals: const [
          {'card_id': 'old-b', 'quantity': 3},
        ],
        actualAdditions: const [],
        now: issuedAt.add(const Duration(hours: 1)),
      );

      expect(extraCard.valid, isFalse);
      expect(extraCard.code, 'swap_pairs_not_authorized');
      expect(excessQuantity.valid, isFalse);
      expect(excessQuantity.code, 'swap_pairs_not_authorized');
    });

    test('rejects tampering, expiry and mismatched binding', () {
      final authorization = buildAuthorization();
      final token = authorization['token'] as String;
      final tokenParts = token.split('.');
      final replacement = tokenParts.first.startsWith('A') ? 'B' : 'A';
      final tampered =
          '$replacement${tokenParts.first.substring(1)}.${tokenParts.last}';

      expect(
        verifyOptimizeApplyAuthorization(
          signingSecret: secret,
          token: tampered,
          deckId: 'deck-1',
          deckSignature: 'signature-1',
          actualRemovals: const [],
          actualAdditions: const [],
          now: issuedAt,
        ).code,
        'invalid_signature',
      );
      expect(
        verifyOptimizeApplyAuthorization(
          signingSecret: secret,
          token: token,
          deckId: 'deck-1',
          deckSignature: 'signature-1',
          actualRemovals: const [],
          actualAdditions: const [],
          now: issuedAt.add(const Duration(hours: 25)),
        ).code,
        'expired_token',
      );
      expect(
        verifyOptimizeApplyAuthorization(
          signingSecret: secret,
          token: token,
          deckId: 'deck-1',
          deckSignature: 'signature-1',
          expectedBracket: 3,
          actualRemovals: const [],
          actualAdditions: const [],
          now: issuedAt,
        ).code,
        'bracket_binding_mismatch',
      );
      expect(
        verifyOptimizeApplyAuthorization(
          signingSecret: secret,
          token: token,
          deckId: 'another-deck',
          deckSignature: 'signature-1',
          actualRemovals: const [],
          actualAdditions: const [],
          now: issuedAt,
        ).code,
        'deck_binding_mismatch',
      );
    });

    test('apply support verifies the actual before/after deck delta', () {
      final authorization =
          buildOptimizeApplyAuthorizationForResponse(
            signingSecret: secret,
            deckId: 'deck-1',
            deckSignature: 'signature-1',
            responseBody: const {
              'mode': 'optimize',
              'bracket': 2,
              'can_apply': true,
              'functional_role_policy': {
                'policy': 'commander_functional_role_floors_v2',
                'archetype': 'midrange',
                'bracket': 2,
                'applies': true,
                'total_cards': 100,
                'minimum_counts': {
                  'ramp': 8,
                  'draw': 8,
                  'interaction': 6,
                  'wipe': 2,
                },
                'actual_counts': {
                  'ramp': 8,
                  'draw': 8,
                  'interaction': 6,
                  'wipe': 2,
                },
                'deficits': <String, int>{},
                'satisfied': true,
              },
              'removals_detailed': [
                {'card_id': 'old-a', 'quantity': 1},
              ],
              'additions_detailed': [
                {'card_id': 'new-a', 'quantity': 1},
              ],
            },
            issuedAt: issuedAt,
          )!;

      expect(
        () => validateOptimizationApplyAuthorization(
          deckId: 'deck-1',
          currentDeckSignature: 'signature-1',
          beforeCards: const [
            {'card_id': 'old-a', 'quantity': 1},
            {'card_id': 'kept', 'quantity': 1},
          ],
          afterCards: const [
            {'card_id': 'new-a', 'quantity': 1},
            {'card_id': 'kept', 'quantity': 1},
          ],
          mutationContext: {'bracket': 2, 'apply_authorization': authorization},
          expectedBracket: 2,
          environment: const {'OPTIMIZATION_APPLY_SIGNING_SECRET': secret},
          now: issuedAt.add(const Duration(hours: 1)),
        ),
        returnsNormally,
      );
    });

    test('rejects mutation-context bracket different from signed bracket', () {
      final authorization = buildAuthorization();

      expect(
        () => validateOptimizationApplyAuthorization(
          deckId: 'deck-1',
          currentDeckSignature: 'signature-1',
          beforeCards: const [
            {'card_id': 'old-a', 'quantity': 1},
          ],
          afterCards: const [
            {'card_id': 'new-a', 'quantity': 1},
          ],
          mutationContext: {'bracket': 3, 'apply_authorization': authorization},
          expectedBracket: 2,
          environment: const {'OPTIMIZATION_APPLY_SIGNING_SECRET': secret},
          now: issuedAt.add(const Duration(hours: 1)),
        ),
        throwsA(
          isA<OptimizationApplyAuthorizationViolation>().having(
            (error) => error.code,
            'code',
            'context_bracket_binding_mismatch',
          ),
        ),
      );
    });

    test('accepts a signed and persisted bracket transition from 2 to 3', () {
      final authorization =
          buildOptimizeApplyAuthorizationForResponse(
            signingSecret: secret,
            deckId: 'deck-1',
            deckSignature: 'signature-1',
            responseBody: {
              ...response,
              'bracket': 3,
              'functional_role_policy': {
                ...(response['functional_role_policy']! as Map),
                'bracket': 3,
              },
              'removals_detailed': const [
                {'card_id': 'old-a', 'quantity': 1},
              ],
              'additions_detailed': const [
                {'card_id': 'new-a', 'quantity': 1},
              ],
            },
            bracket: 3,
            issuedAt: issuedAt,
          )!;

      expect(
        () => validateOptimizationApplyAuthorization(
          deckId: 'deck-1',
          currentDeckSignature: 'signature-1',
          beforeCards: const [
            {'card_id': 'old-a', 'quantity': 1},
          ],
          afterCards: const [
            {'card_id': 'new-a', 'quantity': 1},
          ],
          mutationContext: {'bracket': 3, 'apply_authorization': authorization},
          expectedBracket: 3,
          environment: const {'OPTIMIZATION_APPLY_SIGNING_SECRET': secret},
          now: issuedAt.add(const Duration(hours: 1)),
        ),
        returnsNormally,
      );
    });

    test('rejects condition and commander-role metadata tampering', () {
      final authorization = buildAuthorization();

      OptimizationApplyAuthorizationViolation captureViolation(
        List<Map<String, dynamic>> afterCards,
      ) {
        try {
          validateOptimizationApplyAuthorization(
            deckId: 'deck-1',
            currentDeckSignature: 'signature-1',
            beforeCards: const [
              {
                'card_id': 'kept',
                'quantity': 1,
                'condition': 'NM',
                'is_commander': false,
              },
            ],
            afterCards: afterCards,
            mutationContext: {
              'bracket': 2,
              'apply_authorization': authorization,
            },
            expectedBracket: 2,
            environment: const {'OPTIMIZATION_APPLY_SIGNING_SECRET': secret},
            now: issuedAt.add(const Duration(hours: 1)),
          );
        } on OptimizationApplyAuthorizationViolation catch (error) {
          return error;
        }
        fail('metadata tampering should be rejected');
      }

      expect(
        captureViolation(const [
          {
            'card_id': 'kept',
            'quantity': 1,
            'condition': 'LP',
            'is_commander': false,
          },
        ]).code,
        'condition_change_not_authorized',
      );
      expect(
        captureViolation(const [
          {
            'card_id': 'kept',
            'quantity': 1,
            'condition': 'NM',
            'is_commander': true,
          },
        ]).code,
        'commander_role_change_not_authorized',
      );
    });

    test('partial selection cannot omit wipes required by signed floor', () {
      final authorization =
          buildOptimizeApplyAuthorizationForResponse(
            signingSecret: secret,
            deckId: 'deck-1',
            deckSignature: 'signature-1',
            responseBody: const {
              'mode': 'optimize',
              'bracket': 2,
              'can_apply': true,
              'functional_role_policy': {
                'policy': 'commander_functional_role_floors_v2',
                'archetype': 'midrange',
                'bracket': 2,
                'applies': true,
                'total_cards': 100,
                'minimum_counts': {
                  'ramp': 8,
                  'draw': 8,
                  'interaction': 6,
                  'wipe': 2,
                },
                'actual_counts': {
                  'ramp': 8,
                  'draw': 8,
                  'interaction': 6,
                  'wipe': 2,
                },
                'deficits': <String, int>{},
                'satisfied': true,
              },
              'removals_detailed': [
                {'card_id': 'old-a', 'quantity': 1},
                {'card_id': 'old-b', 'quantity': 1},
                {'card_id': 'old-c', 'quantity': 1},
              ],
              'additions_detailed': [
                {'card_id': 'wipe-a', 'quantity': 1},
                {'card_id': 'wipe-b', 'quantity': 1},
                {'card_id': 'utility', 'quantity': 1},
              ],
            },
            issuedAt: issuedAt,
          )!;
      final verification = validateOptimizationApplyAuthorization(
        deckId: 'deck-1',
        currentDeckSignature: 'signature-1',
        beforeCards: const [
          {'card_id': 'old-a', 'quantity': 1},
          {'card_id': 'old-b', 'quantity': 1},
          {'card_id': 'old-c', 'quantity': 1},
        ],
        afterCards: const [
          {'card_id': 'old-a', 'quantity': 1},
          {'card_id': 'old-b', 'quantity': 1},
          {'card_id': 'utility', 'quantity': 1},
        ],
        mutationContext: {'bracket': 2, 'apply_authorization': authorization},
        expectedBracket: 2,
        environment: const {'OPTIMIZATION_APPLY_SIGNING_SECRET': secret},
        now: issuedAt.add(const Duration(hours: 1)),
      );

      expect(verification, isNotNull);
      final assessment =
          assessOptimizationApplyCommanderFunctionalRoleFloorFromCards(
            format: 'commander',
            cards: const [
              {
                'card_id': 'commander',
                'name': 'Commander',
                'type_line': 'Legendary Creature',
                'oracle_text': '',
                'quantity': 1,
              },
              {
                'card_id': 'ramp',
                'name': 'Arcane Signet',
                'type_line': 'Artifact',
                'oracle_text':
                    "{T}: Add one mana of any color in your commander's color identity.",
                'quantity': 8,
              },
              {
                'card_id': 'draw',
                'name': 'Structural Draw',
                'type_line': 'Sorcery',
                'oracle_text': 'Draw a card.',
                'quantity': 8,
              },
              {
                'card_id': 'interaction',
                'name': 'Structural Answer',
                'type_line': 'Instant',
                'oracle_text': 'Destroy target creature.',
                'quantity': 6,
              },
              {
                'card_id': 'filler',
                'name': 'Filler',
                'type_line': 'Creature',
                'oracle_text': '',
                'quantity': 77,
              },
            ],
            mutationContext: const {'bracket': 2},
            authorizationVerification: verification,
            storedArchetype: 'midrange',
          )!;

      expect(assessment.satisfied, isFalse);
      expect(assessment.minimumCounts, {
        'ramp': 8,
        'draw': 8,
        'interaction': 6,
        'wipe': 2,
      });
      expect(assessment.actualCounts, {
        'ramp': 8,
        'draw': 8,
        'interaction': 6,
        'wipe': 0,
      });
      expect(assessment.deficits, {'wipe': 2});

      final taggedAssessment =
          assessOptimizationApplyCommanderFunctionalRoleFloorFromCards(
            format: 'commander',
            cards: const [
              {
                'card_id': 'commander',
                'name': 'Commander',
                'type_line': 'Legendary Creature',
                'oracle_text': '',
                'quantity': 1,
              },
              {
                'card_id': 'ramp',
                'name': 'Arcane Signet',
                'type_line': 'Artifact',
                'oracle_text':
                    "{T}: Add one mana of any color in your commander's color identity.",
                'quantity': 8,
              },
              {
                'card_id': 'draw',
                'name': 'Structural Draw',
                'type_line': 'Sorcery',
                'oracle_text': 'Draw a card.',
                'quantity': 8,
              },
              {
                'card_id': 'interaction',
                'name': 'Structural Answer',
                'type_line': 'Instant',
                'oracle_text': 'Destroy target creature.',
                'quantity': 6,
              },
              {
                'card_id': 'filler',
                'name': 'Filler',
                'type_line': 'Creature',
                'oracle_text': '',
                'quantity': 75,
              },
              {
                'card_id': 'tagged-wipe',
                'name': 'Silent Structural Answer',
                'type_line': 'Sorcery',
                'oracle_text': '',
                'functional_tags': [
                  {'tag': 'board_wipe', 'confidence': 0.95, 'source': 'test'},
                ],
                'quantity': 2,
              },
            ],
            mutationContext: const {'bracket': 2},
            authorizationVerification: verification,
            storedArchetype: 'midrange',
          )!;
      expect(taggedAssessment.satisfied, isTrue);
      expect(taggedAssessment.actualCounts, {
        'ramp': 8,
        'draw': 8,
        'interaction': 6,
        'wipe': 2,
      });
    });

    test('authorization and signing secret are fail-closed', () {
      final unsignedPreview = Map<String, dynamic>.from(response);
      attachOptimizeApplyAuthorizationToResponse(
        deckId: 'deck-1',
        deckSignature: 'signature-1',
        responseBody: unsignedPreview,
        bracket: 2,
        environment: const {},
        issuedAt: issuedAt,
      );
      expect(unsignedPreview['apply_authorization'], isNull);
      expect(unsignedPreview['can_apply'], isFalse);
      expect(unsignedPreview['learning_eligible'], isFalse);
      expect(
        (unsignedPreview['quality_error'] as Map)['code'],
        'OPTIMIZATION_APPLY_SIGNING_UNAVAILABLE',
      );

      expect(
        () => validateOptimizationApplyAuthorization(
          deckId: 'deck-1',
          currentDeckSignature: 'signature-1',
          beforeCards: const [
            {'card_id': 'old-a', 'quantity': 1},
          ],
          afterCards: const [
            {'card_id': 'new-a', 'quantity': 1},
          ],
          mutationContext: const {},
          environment: const {'JWT_SECRET': secret},
        ),
        throwsA(
          isA<OptimizationApplyAuthorizationViolation>().having(
            (error) => error.code,
            'code',
            'authorization_required',
          ),
        ),
      );

      expect(
        () => validateOptimizationApplyAuthorization(
          deckId: 'deck-1',
          currentDeckSignature: 'signature-1',
          beforeCards: const [],
          afterCards: const [],
          mutationContext: const {},
          environment: const {},
        ),
        throwsA(
          isA<OptimizationApplyAuthorizationViolation>().having(
            (error) => error.code,
            'code',
            'signing_secret_unavailable',
          ),
        ),
      );
    });

    test('both apply routes authorize before replacing deck cards', () {
      for (final path in const [
        'routes/decks/[id]/index.dart',
        'routes/decks/[id]/cards/bulk/index.dart',
      ]) {
        final source = File(path).readAsStringSync();
        final authorizationGate = source.indexOf(
          'validateOptimizationApplyAuthorization',
        );
        final destructiveReplace = source.indexOf(
          "DELETE FROM deck_cards WHERE deck_id = @deckId",
          authorizationGate,
        );

        expect(authorizationGate, greaterThanOrEqualTo(0), reason: path);
        expect(
          destructiveReplace,
          greaterThan(authorizationGate),
          reason: path,
        );
        expect(
          source,
          contains('on OptimizationApplyAuthorizationViolation catch (e)'),
          reason: path,
        );
        expect(
          source,
          contains('assessOptimizationApplyCommanderFunctionalRoleFloor'),
          reason: path,
        );
        expect(
          source,
          contains('throw OptimizationFunctionalRoleFloorViolation'),
          reason: path,
        );
      }
      final floorSource =
          File(
            'lib/decks/optimization_functional_role_floor_support.dart',
          ).readAsStringSync();
      expect(floorSource, contains('card_intelligence_snapshot'));
      expect(floorSource, contains('function_tag_details'));
      expect(floorSource, contains('semantic_tags_v2'));
    });

    test('all deck card writers serialize on the owner deck row', () {
      for (final path in const [
        'routes/decks/[id]/cards/index.dart',
        'routes/decks/[id]/cards/set/index.dart',
        'routes/decks/[id]/cards/replace/index.dart',
        'routes/decks/[id]/cards/bulk/index.dart',
        'routes/decks/[id]/index.dart',
      ]) {
        final source = File(path).readAsStringSync();
        expect(source, contains('FOR UPDATE'), reason: path);
      }
    });
  });
}
