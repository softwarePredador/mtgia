import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart' show visibleForTesting;

import '../logger.dart';

/// Serviço para integração com EDHREC JSON API
///
/// EDHREC fornece evidência agregada de decklists públicas. Esses sinais podem
/// priorizar hipóteses de Commander, mas não provam qualidade, sinergia
/// executável, legalidade ou que uma carta pertença a um deck específico.
///
/// A coleta de rede é fail-closed e só pode ser habilitada por uma flag de
/// autorização explícita. Sem a flag, nem resultados previamente em cache são
/// expostos por este serviço.
///
/// Endpoint principal: https://json.edhrec.com/pages/commanders/{slug}.json
class EdhrecService {
  static const automatedCollectionAuthorizationFlag =
      'MANALOOM_EDHREC_AUTOMATED_COLLECTION_AUTHORIZED';
  static const _baseUrl = 'https://json.edhrec.com';
  static const _cacheTimeout = Duration(
    hours: 6,
  ); // Cache para evitar requests excessivos

  EdhrecService({Map<String, String>? environment, http.Client? client})
    : _environment = environment ?? Platform.environment,
      _client = client;

  final Map<String, String> _environment;
  final http.Client? _client;

  // Cache em memória para evitar requests repetidos no mesmo ciclo de vida do server
  static final Map<String, _CachedResult> _cache = {};
  static final Map<String, _CachedAverageDeckResult> _averageDeckCache = {};

  @visibleForTesting
  static void clearCache() {
    _cache.clear();
    _averageDeckCache.clear();
  }

  /// Indica se a coleta automatizada foi explicitamente autorizada.
  ///
  /// Ausência, valor vazio ou qualquer valor diferente dos truthy suportados
  /// mantém o serviço desabilitado.
  bool get automatedCollectionAuthorized {
    final value =
        _environment[automatedCollectionAuthorizationFlag]
            ?.trim()
            .toLowerCase();
    return value == '1' || value == 'true' || value == 'yes' || value == 'on';
  }

  /// Busca os dados de co-ocorrência para um comandante específico.
  ///
  /// Retorna uma lista de cartas ordenadas por synergy score do EDHREC.
  /// Cada carta inclui:
  /// - name: Nome da carta
  /// - synergy: Score de sinergia (-1.0 a 1.0, onde 1.0 = só aparece neste deck)
  /// - inclusion: contagem absoluta de decks com esta carta
  /// - inclusionRate: fração de decks elegíveis que incluem esta carta
  /// - label: Categoria da carta (ramp, draw, removal, etc)
  Future<EdhrecCommanderData?> fetchCommanderData(String commanderName) async {
    if (!_canCollect('commander data')) return null;

    final slug = _toSlug(commanderName);

    // Check cache primeiro
    final cached = _cache[slug];
    if (cached != null && !cached.isExpired) {
      Log.d('EDHREC cache hit: $slug');
      return cached.data;
    }

    final url = '$_baseUrl/pages/commanders/$slug.json';
    Log.i('EDHREC fetch: $url');

    try {
      final response = await _get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
          'Accept': 'application/json, text/plain, */*',
          'Accept-Language': 'en-US,en;q=0.9',
          'Referer': 'https://edhrec.com/',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = _parseEdhrecResponse(json, commanderName);

        // Cache result
        _cache[slug] = _CachedResult(data, DateTime.now());

        Log.i(
          'EDHREC data loaded: ${data.topCards.length} cards for $commanderName',
        );
        return data;
      } else if (response.statusCode == 404) {
        // Commander não encontrado no EDHREC (muito novo ou muito obscuro)
        Log.w('EDHREC: commander not found: $slug');
        return null;
      } else {
        Log.w('EDHREC error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      Log.e('EDHREC request failed: $e');
      return null;
    }
  }

  Future<EdhrecAverageDeckData?> fetchAverageDeckData(
    String commanderName,
  ) async {
    if (!_canCollect('average-deck data')) return null;

    final slug = _toSlug(commanderName);

    final cached = _averageDeckCache[slug];
    if (cached != null && !cached.isExpired) {
      Log.d('EDHREC average-deck cache hit: $slug');
      return cached.data;
    }

    final url = '$_baseUrl/pages/average-decks/$slug.json';
    Log.i('EDHREC average-deck fetch: $url');

    try {
      final response = await _get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
          'Accept': 'application/json, text/plain, */*',
          'Accept-Language': 'en-US,en;q=0.9',
          'Referer': 'https://edhrec.com/',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = _parseAverageDeckResponse(json, commanderName);
        _averageDeckCache[slug] = _CachedAverageDeckResult(
          data,
          DateTime.now(),
        );
        Log.i(
          'EDHREC average-deck loaded: ${data.seedCards.length} seed cards for $commanderName',
        );
        return data;
      }

      if (response.statusCode == 404) {
        Log.w('EDHREC average-deck: commander not found: $slug');
        return null;
      }

      Log.w('EDHREC average-deck error: ${response.statusCode}');
      return null;
    } catch (e) {
      Log.e('EDHREC average-deck request failed: $e');
      return null;
    }
  }

  bool _canCollect(String operation) {
    if (automatedCollectionAuthorized) return true;
    Log.w(
      'EDHREC $operation blocked (fail-closed): set '
      '$automatedCollectionAuthorizationFlag only after explicit authorization.',
    );
    return false;
  }

  Future<http.Response> _get(Uri uri, {Map<String, String>? headers}) {
    final client = _client;
    if (client != null) return client.get(uri, headers: headers);
    return http.get(uri, headers: headers);
  }

  /// Converte nome do commander para slug do EDHREC
  /// Ex: "Jin-Gitaxias, Core Augur" → "jin-gitaxias-core-augur"
  /// Ex: "Jin-Gitaxias // The Great Synthesis" → "jin-gitaxias"
  String _toSlug(String name) {
    final slug = slugFor(name);
    Log.d('EDHREC slug: "$name" → "$slug"');
    return slug;
  }

  /// Versão pública/estática do conversor de slug, para reuso em
  /// serviços de snapshot/trend que precisam da mesma chave do EDHREC.
  static String slugFor(String name) {
    // Para cartas dupla face (flip/transform), usa apenas a primeira parte
    // Suporta vários formatos: " // ", "//", " / "
    var cleanName = name;
    for (final separator in [' // ', '//', ' / ']) {
      if (cleanName.contains(separator)) {
        cleanName = cleanName.split(separator).first.trim();
        break;
      }
    }

    return cleanName
        .toLowerCase()
        .replaceAll(RegExp(r'''[,'"]+'''), '') // Remove pontuação
        .replaceAll(RegExp(r'\s+'), '-') // Espaços → hífens
        .replaceAll(RegExp(r'-+'), '-') // Remove hífens duplicados
        .replaceAll(RegExp(r'[^a-z0-9-]'), ''); // Só letras, números, hífens
  }

  /// Parse da resposta JSON do EDHREC
  EdhrecCommanderData _parseEdhrecResponse(
    Map<String, dynamic> json,
    String commanderName,
  ) {
    final cardLists = <EdhrecCard>[];

    // Estrutura EDHREC: container.json_dict.cardlists[]
    // Cada cardlist tem: header (categoria) e cardviews[] (cartas)
    final container = json['container'] as Map<String, dynamic>?;
    final jsonDict = container?['json_dict'] as Map<String, dynamic>?;
    final cardlists = jsonDict?['cardlists'] as List<dynamic>? ?? [];

    for (final list in cardlists) {
      final header = (list['header'] as String?) ?? 'uncategorized';
      final cardviews = list['cardviews'] as List<dynamic>? ?? [];

      for (final card in cardviews) {
        final name = card['name'] as String?;
        if (name == null) continue;

        // Synergy score: -1.0 a 1.0 (1.0 = apenas usado com este commander)
        final synergy = (card['synergy'] as num?)?.toDouble() ?? 0.0;

        // `inclusion`/`num_decks` = contagem absoluta de decks com a carta.
        // O ratio real (% de inclusão) é num_decks / potential_decks.
        final inclusion = (card['inclusion'] as num?)?.toDouble() ?? 0.0;

        // Número de decks que usam esta carta
        final numDecks = card['num_decks'] as int? ?? 0;

        // Total de decks elegíveis (denominador do ratio de inclusão)
        final potentialDecks = card['potential_decks'] as int? ?? 0;

        cardLists.add(
          EdhrecCard(
            name: name,
            synergy: synergy,
            inclusion: inclusion,
            numDecks: numDecks,
            potentialDecks: potentialDecks,
            category: _normalizeCategory(header),
          ),
        );
      }
    }

    // Ordena por synergy score (maior primeiro)
    cardLists.sort((a, b) => b.synergy.compareTo(a.synergy));

    // Extrai temas/strategies do EDHREC
    final themes = <String>[];
    final panels =
        (json['panels'] as Map<String, dynamic>?) ??
        (jsonDict?['panels'] as Map<String, dynamic>?) ??
        {};
    final tagLinks = panels['taglinks'] as List<dynamic>? ?? [];
    for (final tag in tagLinks) {
      if (tag is Map && tag['value'] is String) {
        themes.add(tag['value'] as String);
      }
    }

    // Extrai número médio de decks
    final deckCount =
        _toInt(json['num_decks_avg']) ??
        _toInt((jsonDict?['card'] as Map<String, dynamic>?)?['num_decks']) ??
        0;

    final averageTypeDistribution = <String, int>{
      'land': _toInt(json['land']) ?? 0,
      'creature': _toInt(json['creature']) ?? 0,
      'instant': _toInt(json['instant']) ?? 0,
      'sorcery': _toInt(json['sorcery']) ?? 0,
      'artifact': _toInt(json['artifact']) ?? 0,
      'enchantment': _toInt(json['enchantment']) ?? 0,
      'planeswalker': _toInt(json['planeswalker']) ?? 0,
      'battle': _toInt(json['battle']) ?? 0,
      'basic': _toInt(json['basic']) ?? 0,
      'nonbasic': _toInt(json['nonbasic']) ?? 0,
      'deck_size': _toInt(json['deck_size']) ?? 0,
      'total_card_count': _toInt(json['total_card_count']) ?? 0,
    };

    final manaCurveRaw = panels['mana_curve'] as Map<String, dynamic>? ?? {};
    final manaCurve = <String, int>{
      for (final entry in manaCurveRaw.entries)
        entry.key: _toInt(entry.value) ?? 0,
    };

    final articlesRaw = panels['articles'] as List<dynamic>? ?? [];
    final articles = <Map<String, dynamic>>[];
    for (final article in articlesRaw.take(30)) {
      if (article is! Map) continue;
      final authorMap =
          article['author'] is Map
              ? (article['author'] as Map).cast<String, dynamic>()
              : const <String, dynamic>{};
      articles.add({
        'title': article['value']?.toString() ?? '',
        'date': article['date']?.toString() ?? '',
        'href': article['href']?.toString() ?? '',
        'excerpt': article['excerpt']?.toString() ?? '',
        'author': authorMap['name']?.toString() ?? '',
      });
    }

    return EdhrecCommanderData(
      commanderName: commanderName,
      deckCount: deckCount,
      themes: themes,
      topCards: cardLists,
      averageTypeDistribution: averageTypeDistribution,
      manaCurve: manaCurve,
      articles: articles,
    );
  }

  EdhrecAverageDeckData _parseAverageDeckResponse(
    Map<String, dynamic> json,
    String commanderName,
  ) {
    final container = json['container'] as Map<String, dynamic>?;
    final jsonDict = container?['json_dict'] as Map<String, dynamic>?;
    final cardPayload = jsonDict?['card'];

    final deckCount =
        _toInt(json['num_decks']) ??
        _toInt(json['num_decks_avg']) ??
        _toInt(cardPayload is Map ? cardPayload['num_decks'] : null) ??
        0;

    final rawDeck = json['deck'];
    final seedCounts = <String, int>{};
    if (rawDeck is Map) {
      for (final entry in rawDeck.entries) {
        final cardName = entry.key.toString().trim();
        if (cardName.isEmpty) continue;
        final qty = _toInt(entry.value) ?? 1;
        if (qty <= 0) continue;
        seedCounts[cardName] = qty;
      }
    }

    final cardlists = jsonDict?['cardlists'] as List<dynamic>? ?? const [];
    for (final list in cardlists) {
      if (list is! Map) continue;
      final cardviews = list['cardviews'] as List<dynamic>? ?? const [];
      for (final card in cardviews) {
        if (card is! Map) continue;
        final name = card['name']?.toString().trim() ?? '';
        if (name.isEmpty || seedCounts.containsKey(name)) continue;
        seedCounts[name] = 1;
      }
    }

    final seedCards =
        seedCounts.entries
            .map(
              (entry) =>
                  EdhrecAverageDeckCard(name: entry.key, quantity: entry.value),
            )
            .toList()
          ..sort((a, b) {
            final byQty = b.quantity.compareTo(a.quantity);
            if (byQty != 0) return byQty;
            return a.name.compareTo(b.name);
          });

    return EdhrecAverageDeckData(
      commanderName: commanderName,
      deckCount: deckCount,
      seedCards: seedCards,
    );
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Normaliza categoria do EDHREC para padrão interno
  String _normalizeCategory(String header) {
    final lower = header.toLowerCase();
    if (lower.contains('ramp')) return 'ramp';
    if (lower.contains('draw') || lower.contains('card advantage'))
      return 'card_draw';
    if (lower.contains('removal') || lower.contains('interaction'))
      return 'removal';
    if (lower.contains('wipe') || lower.contains('board')) return 'board_wipe';
    if (lower.contains('land')) return 'lands';
    if (lower.contains('creature')) return 'creatures';
    if (lower.contains('enchant')) return 'enchantments';
    if (lower.contains('artifact')) return 'artifacts';
    if (lower.contains('instant')) return 'instants';
    if (lower.contains('sorcery')) return 'sorceries';
    if (lower.contains('tutor')) return 'tutors';
    if (lower.contains('protection') || lower.contains('counter'))
      return 'protection';
    return 'other';
  }

  /// Retorna as top N cartas de uma categoria específica
  List<EdhrecCard> getTopByCategory(
    EdhrecCommanderData data,
    String category, {
    int limit = 10,
  }) {
    return data.topCards
        .where((c) => c.category == category)
        .take(limit)
        .toList();
  }

  /// Retorna cartas com synergy score acima de um threshold
  List<EdhrecCard> getHighSynergyCards(
    EdhrecCommanderData data, {
    double minSynergy = 0.3,
    int limit = 50,
  }) {
    return data.topCards
        .where((c) => c.synergy >= minSynergy)
        .take(limit)
        .toList();
  }

  /// Heurística ManaLoom de "encaixe" de uma carta no deck.
  /// Retorna um valor 0.0-1.0 baseado em:
  /// - synergy: Quanto maior, mais específico para este commander
  /// - inclusionRate: Quanto maior, mais adotada a carta é neste commander
  ///
  /// Fórmula interna 60/40:
  /// `(synergy + 1) / 2 * 0.6 + inclusionRate * 0.4`.
  ///
  /// Este valor não é um score oficial do EDHREC nem prova de qualidade ou de
  /// sinergia executável; serve apenas para ordenar evidência para revisão.
  double calculateFitScore(EdhrecCard card) {
    // Synergy vai de -1 a 1, normalizamos para 0-1
    final normalizedSynergy = (card.synergy + 1) / 2;
    // Heurística ManaLoom: 60% synergy e 40% taxa de inclusão.
    return normalizedSynergy * 0.6 + card.inclusionRate * 0.4;
  }

  /// Limpa cache expirado
  void cleanupCache() {
    _cache.removeWhere((_, v) => v.isExpired);
    _averageDeckCache.removeWhere((_, v) => v.isExpired);
  }
}

/// Dados de um commander do EDHREC
class EdhrecCommanderData {
  final String commanderName;
  final int deckCount; // Número de decks registrados
  final List<String> themes; // Temas/estratégias sugeridas
  final List<EdhrecCard> topCards; // Cartas ordenadas por synergy
  final Map<String, int>
  averageTypeDistribution; // Média de composição por tipo
  final Map<String, int> manaCurve; // Curva de mana média
  final List<Map<String, dynamic>>
  articles; // Artigos relacionados ao commander

  EdhrecCommanderData({
    required this.commanderName,
    required this.deckCount,
    required this.themes,
    required this.topCards,
    required this.averageTypeDistribution,
    required this.manaCurve,
    required this.articles,
  });

  /// Encontra uma carta por nome (case-insensitive)
  EdhrecCard? findCard(String name) {
    final lower = name.toLowerCase();
    for (final c in topCards) {
      if (c.name.toLowerCase() == lower) return c;
    }
    return null;
  }

  /// Verifica se uma carta está nas top N mais sinérgicas
  bool isHighSynergy(String cardName, {double minSynergy = 0.2}) {
    final card = findCard(cardName);
    return card != null && card.synergy >= minSynergy;
  }
}

/// Uma carta do EDHREC com seus scores
class EdhrecCard {
  final String name;
  final double
  synergy; // -1.0 a 1.0 (maior = mais específico para este commander)
  final double
  inclusion; // contagem absoluta de decks que incluem a carta (= numDecks)
  final int numDecks; // Número absoluto de decks com a carta
  final int potentialDecks; // Total de decks elegíveis (denominador do ratio)
  final String category; // ramp, card_draw, removal, etc

  EdhrecCard({
    required this.name,
    required this.synergy,
    required this.inclusion,
    required this.numDecks,
    this.potentialDecks = 0,
    required this.category,
  });

  /// Fração de decks (0.0 a 1.0) que realmente incluem a carta.
  double get inclusionRate =>
      potentialDecks > 0 ? numDecks / potentialDecks : 0.0;

  @override
  String toString() =>
      '$name (syn:${synergy.toStringAsFixed(2)}, inc:${(inclusionRate * 100).toStringAsFixed(0)}%)';
}

class EdhrecAverageDeckData {
  final String commanderName;
  final int deckCount;
  final List<EdhrecAverageDeckCard> seedCards;

  EdhrecAverageDeckData({
    required this.commanderName,
    required this.deckCount,
    required this.seedCards,
  });
}

class EdhrecAverageDeckCard {
  final String name;
  final int quantity;

  EdhrecAverageDeckCard({required this.name, required this.quantity});
}

/// Cache interno com timeout
class _CachedResult {
  final EdhrecCommanderData data;
  final DateTime fetchedAt;

  _CachedResult(this.data, this.fetchedAt);

  bool get isExpired =>
      DateTime.now().difference(fetchedAt) > EdhrecService._cacheTimeout;
}

class _CachedAverageDeckResult {
  final EdhrecAverageDeckData data;
  final DateTime fetchedAt;

  _CachedAverageDeckResult(this.data, this.fetchedAt);

  bool get isExpired =>
      DateTime.now().difference(fetchedAt) > EdhrecService._cacheTimeout;
}
