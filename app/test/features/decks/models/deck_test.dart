import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/decks/models/deck.dart';

void main() {
  group('Deck Model', () {
    test('fromJson deve parsear corretamente um deck completo', () {
      final json = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'name': 'Meu Deck de Commander',
        'format': 'commander',
        'description': 'Deck de teste',
        'archetype': 'aggro',
        'bracket': 2,
        'synergy_score': 85,
        'strengths': 'Rápido',
        'weaknesses': 'Fraco contra controle',
        'is_public': true,
        'created_at': '2025-01-30T10:00:00Z',
        'card_count': 100,
      };

      final deck = Deck.fromJson(json);

      expect(deck.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(deck.name, 'Meu Deck de Commander');
      expect(deck.format, 'commander');
      expect(deck.description, 'Deck de teste');
      expect(deck.archetype, 'aggro');
      expect(deck.bracket, 2);
      expect(deck.synergyScore, 85);
      expect(deck.isPublic, true);
      expect(deck.cardCount, 100);
      expect(deck.colorIdentityKnown, isFalse);
    });

    test('fromJson deve lidar com campos opcionais nulos', () {
      final json = {
        'id': '123',
        'name': 'Deck Simples',
        'format': 'standard',
        'is_public': false,
        'created_at': '2025-01-30T10:00:00Z',
      };

      final deck = Deck.fromJson(json);

      expect(deck.id, '123');
      expect(deck.name, 'Deck Simples');
      expect(deck.format, 'standard');
      expect(deck.description, isNull);
      expect(deck.archetype, isNull);
      expect(deck.bracket, isNull);
      expect(deck.synergyScore, isNull);
      expect(deck.isPublic, false);
      expect(deck.cardCount, 0);
    });

    test('toJson deve serializar corretamente', () {
      final deck = Deck(
        id: '456',
        name: 'Test Deck',
        format: 'modern',
        description: 'Test',
        isPublic: true,
        createdAt: DateTime.parse('2025-01-30T10:00:00Z'),
        cardCount: 60,
      );

      final json = deck.toJson();

      expect(json['id'], '456');
      expect(json['name'], 'Test Deck');
      expect(json['format'], 'modern');
      expect(json['description'], 'Test');
      expect(json['is_public'], true);
    });

    test('distingue identidade incolor conhecida de metadata pendente', () {
      final colorless = Deck.fromJson({
        'id': 'colorless',
        'name': 'Colorless',
        'format': 'standard',
        'is_public': false,
        'created_at': '2025-01-30T10:00:00Z',
        'color_identity': <String>[],
        'color_identity_known': true,
      });
      final pending = Deck.fromJson({
        'id': 'pending',
        'name': 'Pending',
        'format': 'commander',
        'is_public': false,
        'created_at': '2025-01-30T10:00:00Z',
        'color_identity': <String>[],
        'color_identity_known': false,
      });

      expect(colorless.colorIdentity, isEmpty);
      expect(colorless.colorIdentityKnown, isTrue);
      expect(pending.colorIdentity, isEmpty);
      expect(pending.colorIdentityKnown, isFalse);
    });

    test('preserva estado draft e motivos de revisão da API', () {
      final updatedAt = DateTime.parse('2026-07-17T12:00:00Z');
      final deck = Deck.fromJson({
        'id': 'draft-1',
        'name': 'Esqueleto importado',
        'format': 'commander',
        'is_public': false,
        'created_at': '2026-07-17T11:00:00Z',
        'deck_state': 'draft',
        'requires_review': true,
        'review_reasons': ['unresolved_import_lines', 'missing_commander'],
        'validation_updated_at': updatedAt.toIso8601String(),
      });

      expect(deck.validationState, Deck.validationStateDraft);
      expect(deck.requiresReview, isTrue);
      expect(deck.reviewReasons, [
        'unresolved_import_lines',
        'missing_commander',
      ]);
      expect(deck.validationUpdatedAt, updatedAt);
      expect(deck.toJson()['deck_state'], 'draft');
      expect(deck.toJson()['requires_review'], isTrue);
    });

    test(
      'normaliza estado desconhecido sem confiar no requires_review legado',
      () {
        final deck = Deck.fromJson({
          'id': 'legacy',
          'name': 'Legacy',
          'format': 'standard',
          'is_public': false,
          'created_at': '2026-07-17T11:00:00Z',
          'deck_state': 'invented',
          'requires_review': false,
        });

        expect(deck.validationState, Deck.validationStateUnknown);
        expect(deck.requiresReview, isTrue);
        expect(deck.reviewReasons, ['validation_not_recorded']);
      },
    );
  });
}
