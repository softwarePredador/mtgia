import 'package:postgres/postgres.dart';

/// Serviço para gerenciar hate cards e counter-strategies por arquétipo
/// 
/// Este serviço busca cartas e estratégias para countar arquétipos específicos
/// a partir da tabela `archetype_counters` no banco de dados.
/// 
/// Exemplo de uso:
/// ```dart
/// final service = ArchetypeCountersService(pool);
/// final hateCards = await service.getHateCards(
///   archetype: 'graveyard',
///   colors: ['W', 'B'],
/// );
/// // Retorna: ['Rest in Peace', 'Leyline of the Void', 'Bojuka Bog', ...]
/// ```
class ArchetypeCountersService {
  final Pool _pool;
  
  ArchetypeCountersService(this._pool);

  /// Busca hate cards para countar um arquétipo específico
  /// 
  /// [archetype] - O arquétipo a ser counterado: 'graveyard', 'artifacts', 'tokens', etc.
  /// [colors] - Cores do deck que vai usar os hate cards (filtra por color identity)
  /// [format] - Formato do jogo (default: 'commander')
  /// [priorityMax] - Prioridade máxima a incluir (1=essencial, 2=bom, 3=situacional)
  Future<List<String>> getHateCards({
    required String archetype,
    List<String>? colors,
    String format = 'commander',
    int priorityMax = 2,
  }) async {
    try {
      final result = await _pool.execute(
        Sql.named('''
          SELECT hate_cards 
          FROM archetype_counters 
          WHERE archetype = @archetype 
            AND format = @format
            AND priority <= @priority
            AND (color_identity IS NULL OR color_identity <@ @colors OR @colors IS NULL)
          ORDER BY priority ASC, effectiveness_score DESC
          LIMIT 1
        '''),
        parameters: {
          'archetype': archetype.toLowerCase(),
          'format': format.toLowerCase(),
          'priority': priorityMax,
          'colors': colors != null ? TypedValue(Type.textArray, colors) : null,
        },
      );

      if (result.isNotEmpty) {
        final hateCards = result.first[0] as List?;
        return hateCards?.cast<String>() ?? [];
      }

      return [];
    } catch (e) {
      print('⚠️ Erro ao buscar hate cards para $archetype: $e');
      return [];
    }
  }

  /// Busca todos os counters disponíveis para um arquétipo
  Future<Map<String, dynamic>?> getCounterStrategy({
    required String archetype,
    String format = 'commander',
  }) async {
    try {
      final result = await _pool.execute(
        Sql.named('''
          SELECT archetype, hate_cards, priority, notes, effectiveness_score
          FROM archetype_counters 
          WHERE archetype = @archetype AND format = @format
          ORDER BY priority ASC
        '''),
        parameters: {
          'archetype': archetype.toLowerCase(),
          'format': format.toLowerCase(),
        },
      );

      if (result.isNotEmpty) {
        final row = result.first;
        return {
          'archetype': row[0] as String,
          'hate_cards': (row[1] as List?)?.cast<String>() ?? [],
          'priority': row[2] as int,
          'notes': row[3] as String?,
          'effectiveness_score': row[4] as int,
        };
      }

      return null;
    } catch (e) {
      print('⚠️ Erro ao buscar counter strategy para $archetype: $e');
      return null;
    }
  }

  /// Retorna todos os arquétipos que podem ser counterados
  Future<List<String>> getAvailableArchetypes({String format = 'commander'}) async {
    try {
      final result = await _pool.execute(
        Sql.named('''
          SELECT DISTINCT archetype 
          FROM archetype_counters 
          WHERE format = @format
          ORDER BY archetype
        '''),
        parameters: {'format': format.toLowerCase()},
      );

      return result.map((row) => row[0] as String).toList();
    } catch (e) {
      print('⚠️ Erro ao buscar arquétipos: $e');
      return [];
    }
  }

  /// Detecta o arquétipo de um deck baseado nas cartas
  /// Retorna o arquétipo detectado e a confiança (0-1)
  Future<Map<String, dynamic>> detectDeckArchetype({
    required List<Map<String, dynamic>> cards,
  }) async {
    // Contadores para diferentes estratégias
    int graveyardCount = 0;
    int artifactCount = 0;
    int tokenCount = 0;
    int enchantmentCount = 0;
    int creatureCount = 0;
    int instantSorceryCount = 0;
    int planeswalkerCount = 0;
    int rampCount = 0;
    
    for (final card in cards) {
      final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
      final oracleText = ((card['oracle_text'] as String?) ?? '').toLowerCase();
      
      // Detectar tipos
      if (typeLine.contains('artifact')) artifactCount++;
      if (typeLine.contains('enchantment')) enchantmentCount++;
      if (typeLine.contains('creature')) creatureCount++;
      if (typeLine.contains('instant') || typeLine.contains('sorcery')) instantSorceryCount++;
      if (typeLine.contains('planeswalker')) planeswalkerCount++;
      
      // Detectar temas pelo oracle text
      if (oracleText.contains('graveyard') || 
          oracleText.contains('return') && oracleText.contains('from') ||
          oracleText.contains('mill') ||
          oracleText.contains('reanimate')) {
        graveyardCount++;
      }
      
      if (oracleText.contains('token') || 
          oracleText.contains('create') && (oracleText.contains('creature') || oracleText.contains('token'))) {
        tokenCount++;
      }
      
      if (oracleText.contains('add {') || 
          oracleText.contains('search your library for a') && oracleText.contains('land')) {
        rampCount++;
      }
    }
    
    final total = cards.length;
    if (total == 0) {
      return {'archetype': 'unknown', 'confidence': 0.0};
    }
    
    // Calcular proporções
    final archetypeScores = <String, double>{
      'graveyard': graveyardCount / total,
      'artifacts': artifactCount / total,
      'tokens': tokenCount / total,
      'enchantments': enchantmentCount / total,
      'planeswalkers': planeswalkerCount / total,
      'ramp': rampCount / total,
      'aggro': creatureCount / total > 0.5 ? creatureCount / total : 0,
      'control': instantSorceryCount / total > 0.3 ? instantSorceryCount / total : 0,
    };
    
    // Encontrar o arquétipo dominante
    String topArchetype = 'midrange';
    double topScore = 0.0;
    
    archetypeScores.forEach((arch, score) {
      if (score > topScore && score > 0.15) { // Threshold mínimo de 15%
        topArchetype = arch;
        topScore = score;
      }
    });
    
    return {
      'archetype': topArchetype,
      'confidence': topScore,
      'all_scores': archetypeScores,
    };
  }

  /// Adiciona ou atualiza um counter no banco
  Future<bool> upsertCounter({
    required String archetype,
    required List<String> hateCards,
    int priority = 1,
    String format = 'commander',
    String? notes,
    int effectivenessScore = 5,
  }) async {
    try {
      await _pool.execute(
        Sql.named('''
          INSERT INTO archetype_counters 
            (archetype, hate_cards, priority, format, notes, effectiveness_score, last_synced_at)
          VALUES 
            (@archetype, @hate_cards, @priority, @format, @notes, @effectiveness, CURRENT_TIMESTAMP)
          ON CONFLICT (archetype) WHERE format = @format
          DO UPDATE SET 
            hate_cards = @hate_cards,
            priority = @priority,
            notes = @notes,
            effectiveness_score = @effectiveness,
            last_synced_at = CURRENT_TIMESTAMP
        '''),
        parameters: {
          'archetype': archetype.toLowerCase(),
          'hate_cards': TypedValue(Type.textArray, hateCards),
          'priority': priority,
          'format': format.toLowerCase(),
          'notes': notes,
          'effectiveness': effectivenessScore,
        },
      );
      return true;
    } catch (e) {
      print('⚠️ Erro ao upsert counter: $e');
      return false;
    }
  }
}
