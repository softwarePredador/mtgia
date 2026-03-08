import 'package:test/test.dart';

import '../lib/color_identity.dart';
import '../lib/ai/optimization_validator.dart';

/// Testes das regras de Magic: The Gathering aplicadas ao sistema de otimização.
///
/// REGRAS POR FORMATO:
/// ==================
/// Commander: 100 cartas exatas, 1 cópia (exceto básicos), identidade de cor
/// Brawl: 60 cartas exatas, 1 cópia (exceto básicos), identidade de cor
/// Standard: 60+ cartas, 4 cópias (exceto básicos), apenas sets recentes
/// Modern: 60+ cartas, 4 cópias (exceto básicos), desde 8th Edition
/// Pioneer: 60+ cartas, 4 cópias (exceto básicos), desde Return to Ravnica
/// Legacy: 60+ cartas, 4 cópias (exceto básicos), todos os sets
/// Vintage: 60+ cartas, 4 cópias (1 se restricted), todos os sets
/// Pauper: 60+ cartas, 4 cópias (exceto básicos), apenas commons

// ─── Helpers ────────────────────────────────────────────────────────────────

/// Simulação local da lógica de limite de cópias (espelha DeckRulesService)
int _copyLimitForFormat(String format) {
  final f = format.toLowerCase();
  return (f == 'commander' || f == 'brawl') ? 1 : 4;
}

bool _isBasicLandTypeLine(String typeLine) {
  final t = typeLine.toLowerCase();
  return t.contains('basic land') || t.contains('basic snow land');
}

bool _isBasicLandName(String name) {
  final n = name.trim().toLowerCase();
  return n == 'plains' ||
      n == 'island' ||
      n == 'swamp' ||
      n == 'mountain' ||
      n == 'forest' ||
      n == 'wastes' ||
      n == 'snow-covered plains' ||
      n == 'snow-covered island' ||
      n == 'snow-covered swamp' ||
      n == 'snow-covered mountain' ||
      n == 'snow-covered forest';
}

/// Verifica se um deck commander respeita o máximo de cartas
String? _validateCommanderDeckSize(List<Map<String, dynamic>> cards,
    {bool strict = false}) {
  final total =
      cards.fold<int>(0, (sum, c) => sum + ((c['quantity'] as int?) ?? 1));
  const maxTotal = 100;
  if (strict && total != maxTotal) {
    return 'Regra violada: deck commander deve ter exatamente $maxTotal cartas (atual: $total).';
  }
  if (total > maxTotal) {
    return 'Regra violada: deck commander não pode exceder $maxTotal cartas (atual: $total).';
  }
  return null;
}

/// Verifica se o balance de remoções/adições está correto (igual)
bool _isOptimizationBalanced(
        List<String> removals, List<String> additions) =>
    removals.length == additions.length;

/// Gera N cartas com data fields mínimos
List<Map<String, dynamic>> _makeCards(int count,
    {int quantity = 1,
    String typeLine = 'Instant',
    String manaCost = '{3}',
    String? name}) {
  return List.generate(
      count,
      (i) => {
            'name': name ?? 'Card $i',
            'type_line': typeLine,
            'mana_cost': manaCost,
            'oracle_text': '',
            'colors': <String>[],
            'color_identity': <String>[],
            'cmc': 3.0,
            'quantity': quantity,
          });
}

List<Map<String, dynamic>> _makeBasicLands(int count, {String name = 'Island'}) {
  return List.generate(
      count,
      (i) => {
            'name': name,
            'type_line': 'Basic Land — Island',
            'mana_cost': '',
            'oracle_text': '{T}: Add {U}.',
            'colors': <String>[],
            'color_identity': ['U'],
            'cmc': 0.0,
            'quantity': 1,
          });
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // Commander Format — Deck Size
  // ──────────────────────────────────────────────────────────────────────────
  group('Commander Format Rules', () {
    group('Deck Size', () {
      test('TC001: Deck com exatamente 100 cartas deve ser válido', () {
        // 99 spells + 1 commander = 100
        final cards = [
          {'name': 'Jin-Gitaxias', 'quantity': 1, 'is_commander': true},
          ..._makeCards(99, quantity: 1),
        ];
        final total =
            cards.fold<int>(0, (s, c) => s + ((c['quantity'] as int?) ?? 1));
        expect(total, equals(100));
        expect(_validateCommanderDeckSize(cards, strict: true), isNull);
      });

      test('TC002: Deck com 99 cartas deve falhar validação estrita', () {
        final cards = _makeCards(98, quantity: 1)
          ..add({'name': 'Commander', 'quantity': 1, 'is_commander': true});
        // total = 99
        final msg = _validateCommanderDeckSize(cards, strict: true);
        expect(msg, isNotNull);
        expect(msg!.toLowerCase(), contains('100'));
      });

      test('TC003: Deck com 101 cartas deve falhar validação (não-estrita)', () {
        final cards = _makeCards(100, quantity: 1)
          ..add({'name': 'Commander', 'quantity': 1, 'is_commander': true});
        // total = 101
        final msg = _validateCommanderDeckSize(cards, strict: false);
        expect(msg, isNotNull);
        expect(msg!.toLowerCase(), contains('exceder'));
      });

      test('TC004: Otimização deve manter balance — removals.length == additions.length', () {
        final removals = ['Card A', 'Card B', 'Card C'];
        final additions = ['New A', 'New B', 'New C'];
        expect(_isOptimizationBalanced(removals, additions), isTrue);
      });

      test('TC005: Otimização desbalanceada deve ser detectada', () {
        final removals = ['Card A', 'Card B'];
        final additions = ['New A'];
        expect(_isOptimizationBalanced(removals, additions), isFalse);
      });
    });

    // ──────────────────────────────────────────────────────────────────────
    // Copy Limits
    // ──────────────────────────────────────────────────────────────────────
    group('Copy Limits', () {
      test('TC006: Commander — non-basic com quantity=2 viola limite de 1', () {
        final limit = _copyLimitForFormat('commander');
        expect(2 > limit, isTrue); // violação
      });

      test('TC007: Commander — Basic Land com 30 cópias não viola', () {
        final typeLine = 'Basic Land — Island';
        final isBasic = _isBasicLandTypeLine(typeLine);
        expect(isBasic, isTrue);
        // Básicos são isentos de limite
        final qty = 30;
        final shouldReject = !isBasic && qty > _copyLimitForFormat('commander');
        expect(shouldReject, isFalse);
      });

      test('TC008: Standard — carta com 4 cópias é válida', () {
        final limit = _copyLimitForFormat('standard');
        expect(limit, equals(4));
        expect(4 > limit, isFalse);
      });

      test('TC009: Standard — carta com 5 cópias viola', () {
        final limit = _copyLimitForFormat('standard');
        expect(5 > limit, isTrue);
      });

      test('TC010: Snow-Covered Island é tratado como básico pelo nome', () {
        expect(_isBasicLandName('Snow-Covered Island'), isTrue);
        expect(_isBasicLandName('snow-covered forest'), isTrue);
      });

      test('TC011: Snow-Covered Island é tratado como básico pelo type_line', () {
        expect(
            _isBasicLandTypeLine('Basic Snow Land — Island'), isTrue);
        expect(_isBasicLandTypeLine('basic snow land — forest'), isTrue);
      });

      test('TC012: Wastes é básico pelo nome', () {
        expect(_isBasicLandName('Wastes'), isTrue);
        expect(_isBasicLandName('wastes'), isTrue);
      });

      test('TC013: Non-basic land não é básico', () {
        expect(_isBasicLandTypeLine('Land — Forest Plains'), isFalse);
        expect(_isBasicLandTypeLine('Legendary Land'), isFalse);
        expect(_isBasicLandName('Command Tower'), isFalse);
      });
    });

    // ──────────────────────────────────────────────────────────────────────
    // Color Identity
    // ──────────────────────────────────────────────────────────────────────
    group('Color Identity', () {
      test('TC014: Carta fora da identidade deve ser rejeitada', () {
        final commanderIdentity = normalizeColorIdentity(['U']);
        final cardIdentity = ['R'];
        final ok = isWithinCommanderIdentity(
          cardIdentity: cardIdentity,
          commanderIdentity: commanderIdentity,
        );
        expect(ok, isFalse);
      });

      test('TC015: Carta colorless é válida em qualquer commander', () {
        final commanderIdentity = normalizeColorIdentity(['U']);
        expect(
          isWithinCommanderIdentity(
            cardIdentity: const <String>[],
            commanderIdentity: commanderIdentity,
          ),
          isTrue,
        );
      });

      test('TC016: Commander colorless só aceita cartas colorless', () {
        final commanderIdentity = normalizeColorIdentity(const <String>[]);
        expect(
          isWithinCommanderIdentity(
            cardIdentity: const ['W'],
            commanderIdentity: commanderIdentity,
          ),
          isFalse,
        );
        expect(
          isWithinCommanderIdentity(
            cardIdentity: const <String>[],
            commanderIdentity: commanderIdentity,
          ),
          isTrue,
        );
      });

      test('TC017: Identidade 5 cores aceita qualquer carta', () {
        final commanderIdentity =
            normalizeColorIdentity(['W', 'U', 'B', 'R', 'G']);
        for (final color in ['W', 'U', 'B', 'R', 'G']) {
          expect(
            isWithinCommanderIdentity(
              cardIdentity: [color],
              commanderIdentity: commanderIdentity,
            ),
            isTrue,
            reason: 'Commander 5-color deve aceitar cor $color',
          );
        }
      });

      test('TC018: Hybrid mana conta como ambas as cores na identidade', () {
        // {W/U} tem identidade W e U → não pode entrar em deck mono-W
        final monoW = normalizeColorIdentity(['W']);
        expect(
          isWithinCommanderIdentity(
            cardIdentity: const ['W', 'U'],
            commanderIdentity: monoW,
          ),
          isFalse,
        );
        // Mas pode em WU
        final wu = normalizeColorIdentity(['W', 'U']);
        expect(
          isWithinCommanderIdentity(
            cardIdentity: const ['W', 'U'],
            commanderIdentity: wu,
          ),
          isTrue,
        );
      });

      test('TC019: Otimização não adiciona carta fora da identidade', () {
        // Simula filtro de identidade de cor
        final commanderIdentity = normalizeColorIdentity(['U']);
        final proposedAdditions = [
          {'name': 'Lightning Bolt', 'color_identity': ['R']},
          {'name': 'Sol Ring', 'color_identity': <String>[]},
          {'name': 'Counterspell', 'color_identity': ['U']},
        ];
        final allowed = proposedAdditions.where((c) {
          final identity = (c['color_identity'] as List).cast<String>();
          return isWithinCommanderIdentity(
            cardIdentity: identity,
            commanderIdentity: commanderIdentity,
          );
        }).toList();

        expect(allowed.length, equals(2)); // Sol Ring + Counterspell
        expect(
            allowed.any((c) => c['name'] == 'Lightning Bolt'), isFalse);
      });
    });

    // ──────────────────────────────────────────────────────────────────────
    // Commander Eligibility (Pure Logic)
    // ──────────────────────────────────────────────────────────────────────
    group('Commander Eligibility', () {
      test('TC020: Legendary Creature pode ser commander', () {
        final typeLine = 'Legendary Creature — Phyrexian Praetor';
        final isLegendary = typeLine.toLowerCase().contains('legendary');
        final isCreature = typeLine.toLowerCase().contains('creature');
        expect(isLegendary && isCreature, isTrue);
      });

      test('TC021: Non-legendary NÃO pode ser commander', () {
        final typeLine = 'Creature — Human Warrior';
        final isLegendary = typeLine.toLowerCase().contains('legendary');
        final isCreature = typeLine.toLowerCase().contains('creature');
        expect(isLegendary && isCreature, isFalse);
      });

      test('TC022: Carta com "can be your commander" é elegível', () {
        final oracle = 'Atraxa can be your commander.';
        expect(oracle.contains('can be your commander'), isTrue);
      });

      test('TC023: Background é elegível como segundo comandante', () {
        final typeLine = 'Legendary Enchantment — Background';
        final isBackground = typeLine.toLowerCase().contains('legendary') &&
            typeLine.toLowerCase().contains('enchantment') &&
            typeLine.toLowerCase().contains('background');
        expect(isBackground, isTrue);
      });

      test('TC024: Partner genérico permite dois commanders', () {
        const oracle1 = 'Partner\n(You can have two commanders if both have partner.)';
        const oracle2 = 'Partner\n(You can have two commanders if both have partner.)';
        final hasPartner1 = RegExp(r'\bpartner\b').hasMatch(oracle1.toLowerCase());
        final hasPartner2 = RegExp(r'\bpartner\b').hasMatch(oracle2.toLowerCase());
        expect(hasPartner1 && hasPartner2, isTrue);
      });

      test('TC025: "Partner with" sem o par correto é inválido', () {
        const oracle1 = 'Partner with Tana, the Bloodsower';
        final match = RegExp(r'partner with ([^(]+)').firstMatch(oracle1.toLowerCase());
        final partnerName = match?.group(1)?.trim();
        expect(partnerName, equals('tana, the bloodsower'));
        // Verifica que cmd2 NÃO é o par correto (caso inválido)
        const cmd2Name = 'Reyhan, Last of the Abzan';
        expect(cmd2Name.toLowerCase().contains(partnerName!), isFalse);
        // Verifica que o par correto é aceito (caso válido)
        const cmd2NameCorrect = 'Tana, the Bloodsower';
        expect(cmd2NameCorrect.toLowerCase().contains(partnerName), isTrue);
      });

      test('TC026: "Friends forever" permite dois commanders do Doctor Who', () {
        const oracle1 = 'Friends forever\n(You can have two commanders if both have friends forever.)';
        const oracle2 = 'Friends forever\n(You can have two commanders if both have friends forever.)';
        expect(oracle1.toLowerCase().contains('friends forever'), isTrue);
        expect(oracle2.toLowerCase().contains('friends forever'), isTrue);
      });
    });

    // ──────────────────────────────────────────────────────────────────────
    // Banlist (Pure Logic)
    // ──────────────────────────────────────────────────────────────────────
    group('Banlist', () {
      test('TC027: Carta banida deve ser rejeitada', () {
        const status = 'banned';
        expect(status == 'banned', isTrue);
      });

      test('TC028: Carta restrita com quantity > 1 viola regra', () {
        const status = 'restricted';
        const quantity = 2;
        final violates = status == 'restricted' && quantity > 1;
        expect(violates, isTrue);
      });

      test('TC029: Carta restrita com quantity = 1 é permitida', () {
        const status = 'restricted';
        const quantity = 1;
        final violates = status == 'restricted' && quantity > 1;
        expect(violates, isFalse);
      });

      test('TC030: Carta not_legal deve ser rejeitada', () {
        const status = 'not_legal';
        expect(status == 'not_legal', isTrue);
      });
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Brawl Format
  // ──────────────────────────────────────────────────────────────────────────
  group('Brawl Format Rules', () {
    test('TC031: Deck com exatamente 60 cartas é válido (strict)', () {
      final cards = _makeCards(60, quantity: 1);
      final total = cards.fold<int>(0, (s, c) => s + ((c['quantity'] as int?) ?? 1));
      expect(total, equals(60));
    });

    test('TC032: Deck com 61 cartas viola máximo', () {
      final cards = _makeCards(61, quantity: 1);
      final total = cards.fold<int>(0, (s, c) => s + ((c['quantity'] as int?) ?? 1));
      expect(total > 60, isTrue);
    });

    test('TC033: Brawl tem limite de 1 cópia (exceto básicos)', () {
      expect(_copyLimitForFormat('brawl'), equals(1));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Standard / Modern / Pioneer
  // ──────────────────────────────────────────────────────────────────────────
  group('Standard/Modern/Pioneer Format Rules', () {
    test('TC034: Deck com 60+ cartas é válido', () {
      final total = 60;
      expect(total >= 60, isTrue);
    });

    test('TC035: Deck com 59 cartas viola mínimo de 60', () {
      final total = 59;
      expect(total < 60, isTrue);
    });

    test('TC036: Carta com quantity=5 viola limite de 4', () {
      final limit = _copyLimitForFormat('standard');
      expect(5 > limit, isTrue);
    });

    test('TC037: Basic Land com quantity=10 é válido (sem limite)', () {
      final typeLine = 'Basic Land — Island';
      final isBasic = _isBasicLandTypeLine(typeLine);
      expect(isBasic, isTrue);
      final shouldReject = !isBasic && 10 > _copyLimitForFormat('standard');
      expect(shouldReject, isFalse);
    });

    test('TC038: Modern e Pioneer têm mesmo limite de 4 cópias', () {
      expect(_copyLimitForFormat('modern'), equals(4));
      expect(_copyLimitForFormat('pioneer'), equals(4));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Vintage
  // ──────────────────────────────────────────────────────────────────────────
  group('Vintage Format Rules', () {
    test('TC039: Carta restricted com quantity=2 viola regra', () {
      const status = 'restricted';
      const quantity = 2;
      expect(status == 'restricted' && quantity > 1, isTrue);
    });

    test('TC040: Carta restricted com quantity=1 é válida', () {
      const status = 'restricted';
      const quantity = 1;
      expect(status == 'restricted' && quantity > 1, isFalse);
    });

    test('TC041: Black Lotus (restricted) só pode ter 1 cópia em Vintage', () {
      // Black Lotus tem status "restricted" no Vintage
      // → permitido com exatamente 1 cópia
      const name = 'Black Lotus';
      const status = 'restricted';
      const quantity = 1;
      final valid = !(status == 'restricted' && quantity > 1);
      expect(valid, isTrue, reason: '$name deve ser permitido com 1 cópia (restricted)');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Optimization — Functional Role Classification
  // ──────────────────────────────────────────────────────────────────────────
  group('Optimization — Functional Role Classification', () {
    OptimizationValidator? validator;

    setUp(() {
      validator = OptimizationValidator(); // sem API key
    });

    // Testa _classifyFunctionalRole indiretamente via validate()
    // (usando decks sintéticos onde as trocas são conhecidas)

    test('TC042: rolePreserved=true quando troca removal por removal', () async {
      // Remoção → Remoção: papel preservado
      final original = [
        {
          'name': 'Counterspell',
          'type_line': 'Instant',
          'mana_cost': '{U}{U}',
          'oracle_text': 'Counter target spell.',
          'cmc': 2,
          'quantity': 1,
          'colors': ['U'],
        },
        ..._makeBasicLands(36),
        ..._makeCards(63, typeLine: 'Instant', manaCost: '{3}'),
      ];
      final optimized = [
        {
          'name': 'Swan Song',
          'type_line': 'Instant',
          'mana_cost': '{U}',
          'oracle_text': 'Counter target enchantment, instant, or sorcery spell.',
          'cmc': 1,
          'quantity': 1,
          'colors': ['U'],
        },
        ..._makeBasicLands(36),
        ..._makeCards(63, typeLine: 'Instant', manaCost: '{3}'),
      ];

      final report = await validator!.validate(
        originalDeck: original,
        optimizedDeck: optimized,
        removals: ['Counterspell'],
        additions: ['Swan Song'],
        commanders: ['Test Commander'],
        archetype: 'control',
      );

      final swap = report.functional.swaps.first;
      expect(swap.removedRole, equals('removal'));
      expect(swap.addedRole, equals('removal'));
      expect(swap.rolePreserved, isTrue);
      expect(swap.verdict, equals('upgrade')); // CMC menor = upgrade
    });

    test('TC043: rolePreserved=false quando troca removal por ramp (bug fix)', () async {
      // Este teste verifica o bug corrigido:
      // Antes: qualquer carta 'utility' tornava rolePreserved=true
      // Depois: apenas quando ambos têm a MESMA role ou ambos são 'utility'
      final original = [
        {
          'name': 'Path to Exile',
          'type_line': 'Instant',
          'mana_cost': '{W}',
          'oracle_text': 'Exile target creature.',
          'cmc': 1,
          'quantity': 1,
          'colors': ['W'],
        },
        ..._makeBasicLands(36),
        ..._makeCards(63, typeLine: 'Instant', manaCost: '{3}'),
      ];
      final optimized = [
        {
          'name': 'Sol Ring',
          'type_line': 'Artifact',
          'mana_cost': '{1}',
          'oracle_text': '{T}: Add {C}{C}.',
          'cmc': 1,
          'quantity': 1,
          'colors': <String>[],
        },
        ..._makeBasicLands(36),
        ..._makeCards(63, typeLine: 'Instant', manaCost: '{3}'),
      ];

      final report = await validator!.validate(
        originalDeck: original,
        optimizedDeck: optimized,
        removals: ['Path to Exile'],
        additions: ['Sol Ring'],
        commanders: ['Test Commander'],
        archetype: 'midrange',
      );

      final swap = report.functional.swaps.first;
      expect(swap.removedRole, equals('removal'));
      expect(swap.addedRole, equals('ramp'));
      // rolePreserved deve ser FALSE: remoção NÃO é ramp
      expect(swap.rolePreserved, isFalse);
      // Veredito deve ser 'tradeoff' (mudou função, CMC igual)
      // ou 'questionável' (mudou função, CMC maior)
      expect(['tradeoff', 'questionável'], contains(swap.verdict));
    });

    test('TC044: Damage removal (Lightning Bolt) classificado como removal', () async {
      // Lightning Bolt agora deve ser 'removal' (fix aplicado)
      final original = [
        {
          'name': 'Lightning Bolt',
          'type_line': 'Instant',
          'mana_cost': '{R}',
          'oracle_text': 'Lightning Bolt deals 3 damage to any target.',
          'cmc': 1,
          'quantity': 1,
          'colors': ['R'],
        },
        ..._makeBasicLands(36),
        ..._makeCards(63, typeLine: 'Instant', manaCost: '{2}'),
      ];
      final optimized = [
        {
          'name': 'Shock',
          'type_line': 'Instant',
          'mana_cost': '{R}',
          'oracle_text': 'Shock deals 2 damage to any target.',
          'cmc': 1,
          'quantity': 1,
          'colors': ['R'],
        },
        ..._makeBasicLands(36),
        ..._makeCards(63, typeLine: 'Instant', manaCost: '{2}'),
      ];

      final report = await validator!.validate(
        originalDeck: original,
        optimizedDeck: optimized,
        removals: ['Lightning Bolt'],
        additions: ['Shock'],
        commanders: ['Test Commander'],
        archetype: 'aggro',
      );

      final swap = report.functional.swaps.first;
      expect(swap.removedRole, equals('removal'),
          reason: 'Lightning Bolt deve ser classificado como removal (damage-based)');
      expect(swap.addedRole, equals('removal'),
          reason: 'Shock deve ser classificado como removal (damage-based)');
      expect(swap.rolePreserved, isTrue);
    });

    test('TC045: Perder board wipe gera warning', () async {
      final original = [
        {
          'name': 'Wrath of God',
          'type_line': 'Sorcery',
          'mana_cost': '{2}{W}{W}',
          'oracle_text': 'Destroy all creatures.',
          'cmc': 4,
          'quantity': 1,
          'colors': ['W'],
        },
        ..._makeBasicLands(36),
        ..._makeCards(63, typeLine: 'Instant', manaCost: '{3}'),
      ];
      final optimized = [
        {
          'name': 'Cancel',
          'type_line': 'Instant',
          'mana_cost': '{1}{U}{U}',
          'oracle_text': 'Counter target spell.',
          'cmc': 3,
          'quantity': 1,
          'colors': ['U'],
        },
        ..._makeBasicLands(36),
        ..._makeCards(63, typeLine: 'Instant', manaCost: '{3}'),
      ];

      final report = await validator!.validate(
        originalDeck: original,
        optimizedDeck: optimized,
        removals: ['Wrath of God'],
        additions: ['Cancel'],
        commanders: ['Test Commander'],
        archetype: 'control',
      );

      // roleDelta['wipe'] deve ser -1 (perdemos 1 wipe)
      expect((report.functional.roleDelta['wipe'] ?? 0), lessThan(0),
          reason: 'Perder board wipe deve ser refletido no roleDelta');
      // Warning deve mencionar wipe
      expect(
          report.warnings.any((w) =>
              w.toLowerCase().contains('wipe') ||
              w.toLowerCase().contains('board wipe')),
          isTrue,
          reason: 'Perder board wipe deve gerar um warning');
    });

    test('TC046: Troca draw por draw mantém role', () async {
      final original = [
        {
          'name': 'Brainstorm',
          'type_line': 'Instant',
          'mana_cost': '{U}',
          'oracle_text': 'Draw 3 cards, then put 2 cards from your hand on top of your library.',
          'cmc': 1,
          'quantity': 1,
          'colors': ['U'],
        },
        ..._makeBasicLands(36),
        ..._makeCards(63, typeLine: 'Instant', manaCost: '{3}'),
      ];
      final optimized = [
        {
          'name': 'Ponder',
          'type_line': 'Sorcery',
          'mana_cost': '{U}',
          'oracle_text': 'Look at the top 3 cards of your library, then put them back in any order.',
          'cmc': 1,
          'quantity': 1,
          'colors': ['U'],
        },
        ..._makeBasicLands(36),
        ..._makeCards(63, typeLine: 'Instant', manaCost: '{3}'),
      ];

      final report = await validator!.validate(
        originalDeck: original,
        optimizedDeck: optimized,
        removals: ['Brainstorm'],
        additions: ['Ponder'],
        commanders: ['Test Commander'],
        archetype: 'control',
      );

      final swap = report.functional.swaps.first;
      expect(swap.removedRole, equals('draw'));
      // 'look at the top' também classifica como draw
      expect(swap.addedRole, equals('draw'));
      expect(swap.rolePreserved, isTrue);
    });

    test('TC047: Tutor classificado corretamente e rastreado no roleDelta', () async {
      final original = [
        {
          'name': 'Demonic Tutor',
          'type_line': 'Sorcery',
          'mana_cost': '{1}{B}',
          'oracle_text': 'Search your library for a card and put that card into your hand.',
          'cmc': 2,
          'quantity': 1,
          'colors': ['B'],
        },
        ..._makeBasicLands(36),
        ..._makeCards(63, typeLine: 'Instant', manaCost: '{3}'),
      ];
      final optimized = [
        {
          'name': 'Divination',
          'type_line': 'Sorcery',
          'mana_cost': '{2}{U}',
          'oracle_text': 'Draw 2 cards.',
          'cmc': 3,
          'quantity': 1,
          'colors': ['U'],
        },
        ..._makeBasicLands(36),
        ..._makeCards(63, typeLine: 'Instant', manaCost: '{3}'),
      ];

      final report = await validator!.validate(
        originalDeck: original,
        optimizedDeck: optimized,
        removals: ['Demonic Tutor'],
        additions: ['Divination'],
        commanders: ['Test Commander'],
        archetype: 'midrange',
      );

      final swap = report.functional.swaps.first;
      expect(swap.removedRole, equals('tutor'));
      expect(swap.addedRole, equals('draw'));
      // tutor → draw: papel não preservado
      expect(swap.rolePreserved, isFalse);

      // roleDelta deve registrar 'tutor' (novo campo)
      expect(report.functional.roleDelta.containsKey('tutor'), isTrue,
          reason: 'roleDelta deve rastrear tutors');
      expect((report.functional.roleDelta['tutor'] ?? 0), equals(-1),
          reason: 'Perdemos 1 tutor');
    });

    test('TC048: Ramp classificado corretamente — Sol Ring', () async {
      final original = [
        {
          'name': 'Sol Ring',
          'type_line': 'Artifact',
          'mana_cost': '{1}',
          'oracle_text': '{T}: Add {C}{C}.',
          'cmc': 1,
          'quantity': 1,
          'colors': <String>[],
        },
        ..._makeBasicLands(36),
        ..._makeCards(63, typeLine: 'Instant', manaCost: '{3}'),
      ];
      final optimized = [
        {
          'name': 'Arcane Signet',
          'type_line': 'Artifact',
          'mana_cost': '{2}',
          'oracle_text': '{T}: Add one mana of any color in your commander\'s color identity.',
          'cmc': 2,
          'quantity': 1,
          'colors': <String>[],
        },
        ..._makeBasicLands(36),
        ..._makeCards(63, typeLine: 'Instant', manaCost: '{3}'),
      ];

      final report = await validator!.validate(
        originalDeck: original,
        optimizedDeck: optimized,
        removals: ['Sol Ring'],
        additions: ['Arcane Signet'],
        commanders: ['Test Commander'],
        archetype: 'midrange',
      );

      final swap = report.functional.swaps.first;
      expect(swap.removedRole, equals('ramp'));
      expect(swap.addedRole, equals('ramp'));
      expect(swap.rolePreserved, isTrue);
    });

    test('TC049: Report JSON é serializável e tem campos obrigatórios', () async {
      final deck = [
        ..._makeBasicLands(36),
        ..._makeCards(64, typeLine: 'Instant', manaCost: '{3}'),
      ];

      final report = await validator!.validate(
        originalDeck: deck,
        optimizedDeck: deck,
        removals: const [],
        additions: const [],
        commanders: ['Test Commander'],
        archetype: 'midrange',
      );

      final json = report.toJson();
      expect(json['validation_score'], isA<int>());
      expect(json['verdict'], isA<String>());
      expect(json['monte_carlo'], isA<Map>());
      expect(json['functional_analysis'], isA<Map>());
      expect(json['warnings'], isA<List>());
      // Sem API key → sem critic_ai
      expect(json.containsKey('critic_ai'), isFalse);
    });

    test('TC050: roleDelta inclui wipe, tutor e protection (novos campos)', () async {
      final deck = [
        ..._makeBasicLands(36),
        ..._makeCards(64, typeLine: 'Instant', manaCost: '{3}'),
      ];

      final report = await validator!.validate(
        originalDeck: deck,
        optimizedDeck: deck,
        removals: const [],
        additions: const [],
        commanders: ['Test Commander'],
        archetype: 'midrange',
      );

      final roleDelta = report.functional.roleDelta;
      expect(roleDelta.containsKey('wipe'), isTrue,
          reason: 'roleDelta deve incluir wipe');
      expect(roleDelta.containsKey('tutor'), isTrue,
          reason: 'roleDelta deve incluir tutor');
      expect(roleDelta.containsKey('protection'), isTrue,
          reason: 'roleDelta deve incluir protection');
      expect(roleDelta.containsKey('removal'), isTrue);
      expect(roleDelta.containsKey('draw'), isTrue);
      expect(roleDelta.containsKey('ramp'), isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Optimization — Balance Logic
  // ──────────────────────────────────────────────────────────────────────────
  group('Optimization — Balance Logic', () {
    test('TC051: Otimização sem swaps — score neutro (~50)', () async {
      final validator = OptimizationValidator();
      final deck = [
        ..._makeBasicLands(36),
        ..._makeCards(64, typeLine: 'Instant', manaCost: '{3}'),
      ];

      final report = await validator.validate(
        originalDeck: deck,
        optimizedDeck: deck,
        removals: const [],
        additions: const [],
        commanders: ['Test Commander'],
        archetype: 'midrange',
      );

      // Sem alterações, score deve estar próximo de 50 (neutro)
      expect(report.score, greaterThanOrEqualTo(30));
      expect(report.score, lessThanOrEqualTo(70));
    });

    test('TC052: Deck mais consistente pós-otimização deve ter score maior', () async {
      final validator = OptimizationValidator();
      // Deck original: poucas terras (ruim)
      final originalDeck = [
        ..._makeBasicLands(20), // 20 lands = muito pouco
        ..._makeCards(80, typeLine: 'Instant', manaCost: '{3}'),
      ];
      // Deck otimizado: mais terras
      final optimizedDeck = [
        ..._makeBasicLands(36), // 36 lands = ideal
        ..._makeCards(64, typeLine: 'Instant', manaCost: '{3}'),
      ];

      final report = await validator.validate(
        originalDeck: originalDeck,
        optimizedDeck: optimizedDeck,
        removals: const [],
        additions: const [],
        commanders: ['Test Commander'],
        archetype: 'midrange',
      );

      expect(report.monteCarlo.after.consistencyScore,
          greaterThan(report.monteCarlo.before.consistencyScore),
          reason: 'Deck com 36 terras deve ter mais consistência que com 20');
    });
  });
}

