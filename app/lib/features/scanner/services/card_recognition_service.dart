import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import '../models/card_recognition_result.dart';
import 'scanner_ocr_parser.dart';

/// Serviço AVANÇADO de reconhecimento de cartas MTG usando ML Kit
/// Múltiplas estratégias de OCR para máxima precisão em TODAS as eras (1993-2026)
///
/// Estratégias implementadas:
/// 1. Processamento da imagem original
/// 2. Crop da região do nome (topo da carta)
/// 3. Alto contraste + sharpening
/// 4. Binarização adaptativa
/// 5. Múltiplas regiões (para layouts não-padrão)
/// 6. Análise por linhas e blocos
class CardRecognitionService {
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // BANCO DE PALAVRAS PARA FILTRAGEM
  // ══════════════════════════════════════════════════════════════════════════

  /// Palavras que NUNCA são nomes de cartas (filtro negativo)
  static const _nonNameKeywords = <String>{
    // Tipos de carta
    'creature', 'instant', 'sorcery', 'enchantment', 'artifact', 'land',
    'planeswalker', 'legendary', 'tribal', 'snow', 'basic', 'token',
    'world', 'ongoing', 'conspiracy', 'phenomenon', 'plane', 'scheme',
    'vanguard', 'battle', 'kindred',
    // Subtipos muito comuns
    'human', 'wizard', 'soldier', 'elf', 'goblin', 'zombie', 'vampire',
    'dragon', 'angel', 'demon', 'beast', 'elemental', 'spirit', 'knight',
    'merfolk', 'rogue', 'warrior', 'cleric', 'shaman', 'druid', 'ally',
    'bird', 'cat', 'dog', 'wolf', 'bear', 'snake', 'rat', 'spider',
    // Habilidades de palavra-chave (mais completas)
    'flying', 'trample', 'haste', 'vigilance', 'lifelink', 'deathtouch',
    'first strike', 'double strike', 'hexproof', 'indestructible',
    'flash', 'reach', 'menace', 'defender', 'protection', 'shroud',
    'ward', 'prowess', 'cycling', 'kicker', 'flashback', 'equip',
    'intimidate', 'fear', 'shadow', 'flanking', 'banding', 'morph',
    'storm', 'affinity', 'convoke', 'dredge', 'cascade', 'infect',
    'undying', 'persist', 'evolve', 'extort', 'bestow', 'dash',
    'exploit', 'emerge', 'crew', 'fabricate', 'improvise', 'ascend',
    'escape', 'mutate', 'foretell', 'learn', 'disturb', 'decayed',
    'training', 'casualty', 'connive', 'blitz', 'enlist', 'read ahead',
    'toxic', 'for mirrodin', 'backup', 'bargain', 'craft', 'descend',
    // Texto de regras comum
    'tap', 'untap', 'add', 'mana', 'target', 'damage', 'life', 'draw',
    'discard', 'sacrifice', 'destroy', 'exile', 'return', 'counter',
    'copy', 'cast', 'pay', 'controller', 'opponent', 'player', 'owner',
    'permanent', 'spell', 'ability', 'graveyard', 'library', 'hand',
    'battlefield', 'combat', 'attack', 'block', 'tokens', 'enters',
    'leaves', 'dies', 'whenever', 'choose', 'reveal', 'search', 'shuffle',
    'scry', 'surveil', 'mill', 'loot', 'rummage', 'fight', 'proliferate',
    // Texto de edição/colecionador
    'illustrated', 'artist', 'illus', 'wotc', 'wizards', 'reserved',
    'collector', 'number', 'rarity', 'mythic', 'rare', 'uncommon', 'common',
    'foil', 'promo', 'set', 'edition',
    // Texto de rodapé / créditos
    'copyright', 'licensed', 'trademark', 'rights',
    'hasbro', 'coast', 'print', 'printed',
  };

  /// Padrões que indicam linha de crédito do artista.
  /// Cartas MTG mostram `Ill. by (Artista)` ou `Illus. (Artista)` perto
  /// do texto de tipo/poder. Estes aparecem geralmente em 55-85% da altura.
  static final _artistLinePatterns = <RegExp>[
    // "Ill." "Illus." "Illus" no início
    RegExp(r'^ill(us)?\.?\s', caseSensitive: false),
    // "Illustrated by" / "Art by"
    RegExp(r'(illustrated|art)\s+by\b', caseSensitive: false),
    // Padrão OCR corrompido: ex "Tla En" (Ill. by), "IIl" (Ill), "Tla" é
    // OCR common misread de "Ill."
    RegExp(r'^(tla|iia|lla|ila|tia)\s+(en|by)\s', caseSensitive: false),
    // "© <year>" copyright
    RegExp(r'[©®™]', caseSensitive: false),
    // "Wizards of the Coast" / "WOTC"
    RegExp(r'wizards\s+of\s+the', caseSensitive: false),
    // Year pattern in footer: "2024 Wizards" / "TM & © 2025"
    RegExp(r'(19|20)\d{2}\s+(wizards|hasbro|wotc)', caseSensitive: false),
  ];

  /// Padrões de nomes MTG válidos (validação positiva)
  static final _validNamePatterns = <RegExp>[
    // Nome simples: "Lightning Bolt", "Sol Ring"
    RegExp(r'^[A-Z][a-z]+(\s+[A-Z][a-z]+){0,5}$'),
    // Nome com apóstrofe: "Jace's Ingenuity", "Urza's Tower"
    RegExp(r"^[A-Z][a-z]+'s?\s+[A-Z]"),
    // Nome com hífen: "Will-o'-the-Wisp"
    RegExp(r'^[A-Z][a-z]+-'),
    // Nome com vírgula (títulos): "Emrakul, the Aeons Torn"
    RegExp(r'^[A-Z][a-z]+,\s+'),
    // Nome com "of/the/and": "Wrath of God"
    RegExp(r'^(The\s+)?[A-Z][a-z]+\s+(of|the|and)\s+', caseSensitive: false),
    // Split cards: "Fire // Ice"
    RegExp(r'^[A-Z][a-z]+\s*//\s*[A-Z]'),
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // MÉTODO PRINCIPAL - MÚLTIPLAS ESTRATÉGIAS
  // ══════════════════════════════════════════════════════════════════════════

  /// Reconhece carta usando MÚLTIPLAS estratégias para máxima precisão
  Future<CardRecognitionResult> recognizeCard(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(bytes);
    if (originalImage == null) {
      return CardRecognitionResult.failed('Erro ao decodificar imagem');
    }

    CardRecognitionResult bestResult = CardRecognitionResult.failed(
      'Nenhum resultado',
    );

    // ═══════════════════════════════════════════════════════════════════════
    // ESTRATÉGIA 1: Imagem original (mais rápido, funciona bem em 70% casos)
    // ═══════════════════════════════════════════════════════════════════════
    var result = await _processImage(imageFile, originalImage, 'original');
    if (result.success && result.confidence >= 80) {
      return result; // Alta confiança, retorna direto
    }
    if (result.success && result.confidence > bestResult.confidence) {
      bestResult = result;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // ESTRATÉGIA 2: Região do nome apenas (crop topo)
    // ═══════════════════════════════════════════════════════════════════════
    result = await _processNameRegion(originalImage);
    if (result.success && result.confidence >= 85) {
      return result;
    }
    if (result.success && result.confidence > bestResult.confidence) {
      bestResult = result;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // ESTRATÉGIA 3: Alto contraste + sharpening
    // ═══════════════════════════════════════════════════════════════════════
    result = await _processWithHighContrast(originalImage);
    if (result.success && result.confidence >= 85) {
      return result;
    }
    if (result.success && result.confidence > bestResult.confidence) {
      bestResult = result;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // ESTRATÉGIA 4: Binarização adaptativa (cartas desgastadas/foil)
    // ═══════════════════════════════════════════════════════════════════════
    if (bestResult.confidence < 70) {
      result = await _processWithBinarization(originalImage);
      if (result.success && result.confidence > bestResult.confidence) {
        bestResult = result;
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // ESTRATÉGIA 5: Múltiplas regiões (layouts não-padrão/showcase)
    // ═══════════════════════════════════════════════════════════════════════
    if (bestResult.confidence < 60) {
      result = await _processMultipleRegions(originalImage);
      if (result.success && result.confidence > bestResult.confidence) {
        bestResult = result;
      }
    }

    return bestResult;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // IMPLEMENTAÇÃO DAS ESTRATÉGIAS
  // ══════════════════════════════════════════════════════════════════════════

  /// Processa a imagem original
  Future<CardRecognitionResult> _processImage(
    File imageFile,
    img.Image image,
    String strategy,
  ) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.blocks.isEmpty) {
        return CardRecognitionResult.failed('Sem texto ($strategy)');
      }

      return _analyzeRecognizedText(
        recognizedText,
        image.width.toDouble(),
        image.height.toDouble(),
        strategy,
      );
    } catch (e) {
      return CardRecognitionResult.failed('Erro ($strategy): $e');
    }
  }

  /// Processa apenas a região do nome (topo da carta)
  Future<CardRecognitionResult> _processNameRegion(img.Image original) async {
    // Calcula região do nome (primeiros ~12% da altura, excluindo mana cost à direita)
    final nameHeight = (original.height * 0.12).round().clamp(40, 250);
    final nameWidth =
        (original.width * 0.70).round(); // Exclui área de mana cost

    var cropped = img.copyCrop(
      original,
      x: (original.width * 0.05).round(),
      y: (original.height * 0.02).round(),
      width: nameWidth,
      height: nameHeight,
    );

    // Pré-processamento otimizado para texto
    cropped = img.grayscale(cropped);
    cropped = img.adjustColor(cropped, contrast: 1.6, brightness: 1.1);
    cropped = _sharpen(cropped);

    return await _processTemporaryImage(cropped, 'name_region');
  }

  /// Processa com alto contraste
  Future<CardRecognitionResult> _processWithHighContrast(
    img.Image original,
  ) async {
    var processed = img.grayscale(original);
    processed = img.adjustColor(processed, contrast: 1.8, brightness: 1.15);
    processed = _sharpen(processed);

    return await _processTemporaryImage(processed, 'high_contrast');
  }

  /// Processa com binarização adaptativa
  Future<CardRecognitionResult> _processWithBinarization(
    img.Image original,
  ) async {
    var processed = img.grayscale(original);
    processed = _adaptiveThreshold(processed, blockSize: 25, constant: 12);

    return await _processTemporaryImage(processed, 'binarized');
  }

  /// Processa múltiplas regiões da carta
  Future<CardRecognitionResult> _processMultipleRegions(
    img.Image original,
  ) async {
    // Regiões para diferentes layouts de carta
    final regions = <_Region>[
      _Region(0.02, 0.02, 0.70, 0.15, 'top_name'), // Nome padrão
      _Region(0.02, 0.05, 0.95, 0.18, 'top_full'), // Topo completo
      _Region(0.10, 0.78, 0.90, 0.95, 'bottom'), // Showcase/borderless
      _Region(0.05, 0.40, 0.95, 0.55, 'middle'), // DFC verso
    ];

    CardRecognitionResult bestResult = CardRecognitionResult.failed(
      'Nenhuma região',
    );

    for (final region in regions) {
      final x = (original.width * region.left).round();
      final y = (original.height * region.top).round();
      final w = ((region.right - region.left) * original.width).round();
      final h = ((region.bottom - region.top) * original.height).round();

      if (w < 50 || h < 20) continue;

      var cropped = img.copyCrop(original, x: x, y: y, width: w, height: h);
      cropped = img.grayscale(cropped);
      cropped = img.adjustColor(cropped, contrast: 1.5);

      final result = await _processTemporaryImage(cropped, region.name);
      if (result.success && result.confidence > bestResult.confidence) {
        bestResult = result;
      }
    }

    return bestResult;
  }

  /// Processa uma imagem temporária
  Future<CardRecognitionResult> _processTemporaryImage(
    img.Image image,
    String strategy,
  ) async {
    File? tempFile;
    try {
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      tempFile = File('${tempDir.path}/mtg_ocr_$timestamp.jpg');
      await tempFile.writeAsBytes(
        Uint8List.fromList(img.encodeJpg(image, quality: 95)),
      );

      final inputImage = InputImage.fromFile(tempFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.blocks.isEmpty) {
        return CardRecognitionResult.failed('Sem texto ($strategy)');
      }

      return _analyzeRecognizedText(
        recognizedText,
        image.width.toDouble(),
        image.height.toDouble(),
        strategy,
      );
    } finally {
      try {
        await tempFile?.delete();
      } catch (_) {}
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ANÁLISE DE TEXTO RECONHECIDO
  // ══════════════════════════════════════════════════════════════════════════

  /// Analisa texto e extrai candidatos a nome de carta.
  ///
  /// Se [cardGuideRect] é fornecido, apenas blocos de texto que estão
  /// significativamente dentro da região do guia são considerados, e as
  /// posições relativas são calculadas em relação ao guia (= carta),
  /// não ao frame inteiro. Isso é crítico para:
  /// 1. Ignorar texto de outras cartas que estejam parcialmente no frame
  /// 2. Mapear posições corretamente (topo do guia = nome, bottom = collector)
  CardRecognitionResult _analyzeRecognizedText(
    RecognizedText recognizedText,
    double imageWidth,
    double imageHeight,
    String strategy, {
    Rect? cardGuideRect,
  }) {
    final candidates = <CardNameCandidate>[];

    // Se temos guia, usamos as dimensões do guia para posicionamento relativo
    // Caso contrário, usamos o frame inteiro (fallback)
    final refWidth = cardGuideRect?.width ?? imageWidth;
    final refHeight = cardGuideRect?.height ?? imageHeight;

    // Processa blocos e linhas
    for (final block in recognizedText.blocks) {
      // Se temos guia, verifica se o bloco está dentro da região do guia
      if (cardGuideRect != null) {
        if (!_isInsideGuide(block.boundingBox, cardGuideRect)) continue;
      }

      // Avalia cada linha individualmente
      for (final line in block.lines) {
        if (cardGuideRect != null) {
          if (!_isInsideGuide(line.boundingBox, cardGuideRect)) continue;
        }

        // Recalcula bounding box relativa ao guia (ou usa original)
        final relBox =
            cardGuideRect != null
                ? _relativizeToGuide(line.boundingBox, cardGuideRect)
                : line.boundingBox;

        final candidate = _evaluateCandidate(
          line.text,
          relBox,
          refWidth,
          refHeight,
        );
        if (candidate != null) candidates.add(candidate);
      }

      // Avalia bloco completo (pode pegar nome com quebra de linha)
      final blockBox =
          cardGuideRect != null
              ? _relativizeToGuide(block.boundingBox, cardGuideRect)
              : block.boundingBox;

      final blockCandidate = _evaluateCandidate(
        block.text,
        blockBox,
        refWidth,
        refHeight,
      );
      if (blockCandidate != null) candidates.add(blockCandidate);
    }

    if (candidates.isEmpty) {
      return CardRecognitionResult.failed('Nenhum nome válido ($strategy)');
    }

    // Remove duplicatas e ordena
    final unique = _deduplicate(candidates);
    unique.sort((a, b) => b.score.compareTo(a.score));

    // Debug: mostra top candidatos para diagnóstico
    if (unique.isNotEmpty) {
      final top = unique
          .take(3)
          .map((c) {
            final relY = (c.boundingBox.top / refHeight * 100).round();
            return '"${c.text}" (score=${c.score.toStringAsFixed(0)}, y=$relY%)';
          })
          .join(', ');
      debugPrint('[🏷️ Candidatos] $strategy: $top');
    }

    // Calcula confiança
    final confidence = _calculateConfidence(unique);
    final setCodeCandidates = _extractSetCodeCandidates(recognizedText.text);

    // Extrai informações do colecionador da parte inferior da carta
    // Usa as dimensões do guia se disponível para que >80% = bottom real da carta
    final collectorInfo = _extractCollectorInfo(
      recognizedText,
      imageWidth,
      imageHeight,
      cardGuideRect: cardGuideRect,
    );

    return CardRecognitionResult.success(
      primaryName: unique.first.text,
      alternatives:
          unique
              .skip(1)
              .take(5)
              .map((c) => c.text)
              .where((t) => t != unique.first.text)
              .toList(),
      setCodeCandidates: setCodeCandidates,
      confidence: confidence,
      allCandidates: unique,
      collectorInfo: collectorInfo,
    );
  }

  List<String> _extractSetCodeCandidates(String rawText) {
    return ScannerOcrParser.extractSetCodeCandidates(rawText);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FILTRAGEM POR REGIÃO DO GUIA (card guide rect)
  // ══════════════════════════════════════════════════════════════════════════

  /// Verifica se um bloco de texto está significativamente dentro do guia.
  /// Usa overlap de 50% — o centro do bloco deve estar dentro do guia.
  bool _isInsideGuide(Rect textBox, Rect guideRect) {
    // Centro do bloco de texto
    final centerX = textBox.left + textBox.width / 2;
    final centerY = textBox.top + textBox.height / 2;

    // Margem de 10% para tolerar blocos que estão um pouco fora mas são
    // parte da carta (ex: nome levemente fora do guia)
    final margin = guideRect.width * 0.10;
    final expandedGuide = Rect.fromLTRB(
      guideRect.left - margin,
      guideRect.top - margin,
      guideRect.right + margin,
      guideRect.bottom + margin,
    );

    return expandedGuide.contains(Offset(centerX, centerY));
  }

  /// Recalcula o bounding box de um bloco de texto para ser relativo ao guia.
  /// Assim, um bloco no topo do guia tem relTop ≈ 0, e no bottom ≈ 1.
  Rect _relativizeToGuide(Rect textBox, Rect guideRect) {
    return Rect.fromLTWH(
      textBox.left - guideRect.left,
      textBox.top - guideRect.top,
      textBox.width,
      textBox.height,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EXTRAÇÃO DE INFORMAÇÕES DO COLECIONADOR (parte inferior da carta)
  // ══════════════════════════════════════════════════════════════════════════

  /// Extrai número de colecionador, set code e status foil da parte inferior
  /// da carta.
  ///
  /// Cartas modernas (2020+) têm na parte inferior um formato como:
  ///   "157/274 • BLB • EN"    (non-foil)
  ///   "157/274 ★ BLB ★ EN"    (foil)
  ///   "157 BLB EN"            (simplificado)
  ///   "BLB • 157/274"         (ordem alternativa)
  ///
  /// Também funciona para layouts mais antigos como "CMM 157"
  CollectorInfo? _extractCollectorInfo(
    RecognizedText recognizedText,
    double imageWidth,
    double imageHeight, {
    Rect? cardGuideRect,
  }) {
    // Se temos guia, usamos as coordenadas do guia como referência
    // para encontrar "bottom da carta" (>80% da altura do guia)
    final refTop = cardGuideRect?.top ?? 0.0;
    final refHeight = cardGuideRect?.height ?? imageHeight;
    final refLeft = cardGuideRect?.left ?? 0.0;
    final refRight = cardGuideRect?.right ?? imageWidth;

    // Coleta texto RAW de blocos/linhas na parte inferior da carta (>80%)
    final bottomTexts = <String>[];

    for (final block in recognizedText.blocks) {
      // Se temos guia, verifica se o bloco está horizontalmente dentro
      final blockCenterX = block.boundingBox.left + block.boundingBox.width / 2;
      if (cardGuideRect != null) {
        if (blockCenterX < refLeft - 20 || blockCenterX > refRight + 20) {
          continue;
        }
      }

      final relTop = (block.boundingBox.top - refTop) / refHeight;

      // Blocos na região inferior da carta (>80% da altura)
      if (relTop > 0.80) {
        bottomTexts.add(block.text);
        for (final line in block.lines) {
          bottomTexts.add(line.text);
        }
      } else {
        // Mesmo em blocos mais altos, linhas individuais podem estar embaixo
        for (final line in block.lines) {
          final lineRelTop = (line.boundingBox.top - refTop) / refHeight;
          if (lineRelTop > 0.80) {
            bottomTexts.add(line.text);
          }
        }
      }
    }

    if (bottomTexts.isEmpty) return null;

    // Junta todo o texto inferior para análise
    final rawBottom = bottomTexts.join(' ').trim();
    final collectorInfo = ScannerOcrParser.extractCollectorInfo(rawBottom);
    if (collectorInfo == null) return null;

    debugPrint(
      '[🔍 Collector] Bottom: "$rawBottom" → '
      '#${collectorInfo.collectorNumber ?? "?"}'
      '/${collectorInfo.totalInSet ?? "?"} '
      '${collectorInfo.isFoil == true
          ? "★FOIL"
          : collectorInfo.isFoil == false
          ? "•NON-FOIL"
          : "?"} '
      '${collectorInfo.setCode ?? "?"} '
      '${collectorInfo.language ?? "?"}',
    );

    return collectorInfo;
  }

  /// Avalia se um texto é candidato a nome de carta
  CardNameCandidate? _evaluateCandidate(
    String rawText,
    Rect box,
    double imgWidth,
    double imgHeight,
  ) {
    final firstLine = rawText.split('\n').first.trim();
    if (firstLine.length < 2 || firstLine.length > 55) return null;

    final cleaned = _cleanText(firstLine);
    if (cleaned.isEmpty || cleaned.length < 2) return null;

    final score = _calculateScore(cleaned, firstLine, box, imgWidth, imgHeight);
    if (score <= 0) return null;

    return CardNameCandidate(
      text: cleaned,
      rawText: firstLine,
      score: score,
      boundingBox: box,
    );
  }

  /// Calcula score de probabilidade de ser nome de carta
  double _calculateScore(
    String cleaned,
    String original,
    Rect box,
    double imgWidth,
    double imgHeight,
  ) {
    double score = 0.0;
    final lower = cleaned.toLowerCase();

    // ═══════════════════════════════════════════════════════════════════════
    // FILTROS NEGATIVOS (eliminam candidatos ruins)
    // ═══════════════════════════════════════════════════════════════════════

    // Apenas números/símbolos
    if (RegExp(r'^[\d\s\W]+$').hasMatch(cleaned)) return 0;

    // Palavra-chave de regras
    if (_nonNameKeywords.contains(lower)) return 0;
    for (final kw in _nonNameKeywords) {
      if (lower.startsWith('$kw ') || lower.endsWith(' $kw')) {
        score -= 20; // Penalidade mas não elimina
      }
    }

    // Power/Toughness
    if (RegExp(r'^\d+\s*/\s*\d+$').hasMatch(cleaned)) return 0;

    // Custo de mana
    if (RegExp(
      r'^[\dWUBRGCX\{\}\s]+$',
      caseSensitive: false,
    ).hasMatch(cleaned)) {
      return 0;
    }

    // Texto de regras longo
    if (cleaned.contains(':') && cleaned.length > 25) return 0;

    // Texto que parece frase longa (flavor text ou rules text)
    // Nomes de cartas MTG raramente têm mais de 5 palavras
    final wordCount = cleaned.split(RegExp(r'\s+')).length;
    if (wordCount > 6) return 0; // frases longas nunca são nomes

    // Frase que começa com artigo/preposição minúscula ou tem padrão de frase
    // Ex: "A turtle-duckling's greatest defense..."
    // Ex: "Until end of turn, this creature..."
    if (RegExp(
          r'^(a|an|the|this|that|if|when|whenever|until|at|for|each|all|you|it|its)\s',
          caseSensitive: false,
        ).hasMatch(cleaned) &&
        wordCount > 3) {
      return 0; // provavelmente rules text ou flavor text
    }

    // Texto que contém palavras-chave de regras em quantidade (>= 2 keywords)
    // Só conta keywords isoladas (word boundaries) para evitar falsos positivos
    // Ex: "creature has base power" contém "creature" keyword = hit
    if (wordCount >= 4) {
      var keywordHits = 0;
      for (final word in cleaned.toLowerCase().split(RegExp(r'\s+'))) {
        if (_nonNameKeywords.contains(word) && word.length >= 4) {
          keywordHits++;
          if (keywordHits >= 2) return 0; // forte indicação de rules text
        }
      }
    }

    // Linha de tipo (usa original para preservar em-dash —)
    if (_isTypeLine(original.toLowerCase())) return 0;

    // Linha de crédito de artista ("Ill. by Sylvain Sarrailh" etc)
    if (_isArtistLine(original)) return 0;

    // ═══════════════════════════════════════════════════════════════════════
    // SCORES POR POSIÇÃO
    // ═══════════════════════════════════════════════════════════════════════

    final relTop = box.top / imgHeight;
    final relLeft = box.left / imgWidth;
    final relWidth = box.width / imgWidth;

    // Topo (0-18%): nome padrão — posição mais provável do nome da carta
    if (relTop < 0.18) {
      score += 55;
      if (relTop < 0.10) score += 15;
      if (relLeft < 0.15) score += 12;
      if (relWidth > 0.30 && relWidth < 0.80) score += 8;
    }
    // Inferior (80-95%): showcase/borderless nomes
    // NOTA: reduzido de 75% para 80% para evitar pegar texto de artista
    // que fica entre 55-80%
    else if (relTop > 0.80 && relTop < 0.95) {
      score += 35; // reduzido de 40 para não competir com topo
      if (relLeft > 0.10 && relLeft < 0.45) score += 10;
    }
    // Meio-topo (18-35%): alguns layouts
    else if (relTop > 0.18 && relTop < 0.35) {
      score += 20;
    }
    // Zona do artista/tipo (55-80%): penalidade
    // Crédito de artista, tipo de carta, P/T ficam nessa faixa
    else if (relTop > 0.55 && relTop <= 0.80) {
      score -= 30;
    }

    // Penalidade: muito à direita no topo (provavelmente mana)
    if (relLeft > 0.65 && relTop < 0.20) {
      score -= 35;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SCORES POR CARACTERÍSTICAS DO TEXTO
    // ═══════════════════════════════════════════════════════════════════════

    // Começa com maiúscula
    if (cleaned.isNotEmpty && _isUpperCase(cleaned[0])) {
      score += 15;
    }

    // Padrão de nome MTG válido
    for (final pattern in _validNamePatterns) {
      if (pattern.hasMatch(cleaned)) {
        score += 25;
        break;
      }
    }

    // Múltiplas palavras capitalizadas
    final words = cleaned.split(RegExp(r'\s+'));
    final capCount =
        words.where((w) => w.isNotEmpty && _isUpperCase(w[0])).length;
    if (capCount >= 2 && capCount <= 6) {
      score += capCount * 7;
    }

    // Comprimento típico (3-35 chars)
    if (cleaned.length >= 3 && cleaned.length <= 35) {
      score += 10;
    } else if (cleaned.length > 40) {
      score -= 20;
    }

    // Apóstrofe possessivo (extremamente comum: "Jace's", "Urza's", "Bender's")
    if (RegExp(r"'s\b", caseSensitive: false).hasMatch(cleaned)) {
      score += 20; // Padrão possessivo = forte indicador de nome MTG
    } else if (cleaned.contains("'")) {
      score += 12;
    }

    // Hífen (comum: "Will-o'-the-Wisp")
    if (cleaned.contains("-")) score += 10;

    // Vírgula (títulos: "Emrakul, the Aeons Torn")
    if (cleaned.contains(",")) score += 18;

    // Palavras conectoras comuns
    if (lower.contains(' the ')) score += 8;
    if (lower.contains(' of ')) score += 8;

    // ═══════════════════════════════════════════════════════════════════════
    // PENALIDADES
    // ═══════════════════════════════════════════════════════════════════════

    // Caracteres estranhos (OCR ruim)
    final strange = RegExp(r"[^a-zA-Z\s'\-,]").allMatches(cleaned).length;
    score -= strange * 6;

    // Muitos números
    final digits = RegExp(r'\d').allMatches(cleaned).length;
    score -= digits * 10;

    return math.max(0, score);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // UTILIDADES
  // ══════════════════════════════════════════════════════════════════════════

  /// Verifica se é linha de tipo
  bool _isTypeLine(String text) {
    final patterns = [
      // "Legendary Creature — Human Wizard", "Artifact Creature — Golem"
      RegExp(
        r'^(legendary\s+)?(artifact\s+)?(creature|artifact|enchantment|instant|sorcery|land|planeswalker|battle)',
        caseSensitive: false,
      ),
      // "Creature — Turtle" mas NÃO "Turtle-Duck" (nomes hyphenados)
      // Type lines usam EM DASH (—) ou EN DASH (–), não hífen simples (-)
      // Ex: "Creature — Turtle", "Artifact — Equipment"
      RegExp(r'^\w+\s*[—–]\s*\w+'),
      RegExp(r'^basic\s+(land|snow)', caseSensitive: false),
    ];
    return patterns.any((p) => p.hasMatch(text));
  }

  /// Verifica se é linha de crédito do artista
  /// Exemplos reais: "Ill. by Sylvain Sarrailh", "Illustrated by Magali"
  /// OCR corrompido: "Tla En Sylvain Sarrailh", "IIl by John Avon"
  bool _isArtistLine(String text) {
    return _artistLinePatterns.any((p) => p.hasMatch(text));
  }

  /// Limpa e normaliza texto
  String _cleanText(String text) {
    var result = text;

    // Remove símbolos de mana
    result = result.replaceAll(RegExp(r'\{[^}]+\}'), '');

    // Normaliza apóstrofes e hífens
    result = result.replaceAll(RegExp(r"['`']"), "'");
    result = result.replaceAll(RegExp(r'[—–]'), '-');

    // Remove caracteres inválidos
    result = result.replaceAll(RegExp(r"[^a-zA-Z\s'\-,]"), '');

    // Limpa espaços
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Corrige capitalização se necessário
    if (result == result.toLowerCase() || result == result.toUpperCase()) {
      result = _toTitleCase(result);
    }

    return result;
  }

  /// Converte para Title Case inteligente
  String _toTitleCase(String text) {
    const smallWords = {
      'a',
      'an',
      'the',
      'and',
      'but',
      'or',
      'for',
      'nor',
      'of',
      'to',
      'in',
      'on',
      'at',
      'by',
    };

    return text
        .split(' ')
        .asMap()
        .entries
        .map((e) {
          final word = e.value;
          if (word.isEmpty) return word;

          if (e.key == 0 || !smallWords.contains(word.toLowerCase())) {
            return word[0].toUpperCase() + word.substring(1).toLowerCase();
          }
          return word.toLowerCase();
        })
        .join(' ');
  }

  /// Verifica se caractere é maiúsculo
  bool _isUpperCase(String char) {
    return char == char.toUpperCase() && char != char.toLowerCase();
  }

  /// Remove duplicatas
  List<CardNameCandidate> _deduplicate(List<CardNameCandidate> candidates) {
    final seen = <String>{};
    final unique = <CardNameCandidate>[];

    for (final c in candidates) {
      final key = c.text.toLowerCase();
      if (!seen.contains(key)) {
        seen.add(key);
        unique.add(c);
      }
    }

    return unique;
  }

  /// Calcula confiança final
  ///
  /// O score máximo realista no live_stream para um nome perfeito no topo
  /// da carta é ~100-110 pontos (posição 55+15+12+8 = 90, texto ~20-30).
  /// Usar maxScore=150 fazia nomes perfeitos darem 66% — recalibrado.
  double _calculateConfidence(List<CardNameCandidate> candidates) {
    if (candidates.isEmpty) return 0;

    const maxScore = 115.0; // calibrado para score realista no topo da carta
    var conf = (candidates.first.score / maxScore) * 100;

    // Bônus por diferença clara entre primeiro e segundo
    if (candidates.length >= 2) {
      final diff = candidates[0].score - candidates[1].score;
      if (diff > 20) conf += 5;
      if (diff > 40) conf += 5;
      if (diff > 60) conf += 5;
    }

    // Bônus por poucos candidatos (menos ambiguidade)
    if (candidates.length <= 3) conf += 5;
    if (candidates.length == 1) conf += 5; // candidato único = alta certeza

    return conf.clamp(0, 100);
  }

  /// Aplica sharpening
  img.Image _sharpen(img.Image image) {
    return img.convolution(
      image,
      filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
      div: 1,
    );
  }

  /// Threshold adaptativo
  img.Image _adaptiveThreshold(
    img.Image image, {
    int blockSize = 15,
    int constant = 10,
  }) {
    final result = img.Image.from(image);
    final half = blockSize ~/ 2;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        double sum = 0;
        int count = 0;

        for (int dy = -half; dy <= half; dy++) {
          for (int dx = -half; dx <= half; dx++) {
            final nx = (x + dx).clamp(0, image.width - 1);
            final ny = (y + dy).clamp(0, image.height - 1);
            sum += img.getLuminance(image.getPixel(nx, ny));
            count++;
          }
        }

        final threshold = (sum / count) - constant;
        final lum = img.getLuminance(image.getPixel(x, y));

        result.setPixel(
          x,
          y,
          lum < threshold
              ? img.ColorRgb8(0, 0, 0)
              : img.ColorRgb8(255, 255, 255),
        );
      }
    }

    return result;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // OCR LEVE PARA STREAM CONTÍNUO (sem pré-processamento pesado)
  // ══════════════════════════════════════════════════════════════════════════

  bool _isProcessingStream = false;

  /// Processa um frame da câmera em tempo real (leve, sem pré-processamento).
  /// Retorna resultado ou null se nada detectado / frame ignorado.
  ///
  /// [cardGuideRect] define a região do guia (em coordenadas da imagem) onde
  /// a carta deve estar. Blocos de texto fora dessa região são ignorados,
  /// e as posições relativas (para scoring) são recalculadas em relação
  /// à carta, não ao frame inteiro. Isso garante que:
  /// - Se houver 2 cartas no frame, apenas a que está no guia é lida
  /// - As posições relativas mapeiam a anatomia real da carta:
  ///   0-10% = nome, 55-65% = tipo, 80-95% = colecionador/artista
  Future<CardRecognitionResult?> recognizeFromCameraImage(
    CameraImage cameraImage,
    CameraDescription camera, {
    Rect? cardGuideRect,
  }) async {
    if (_isProcessingStream) return null;
    _isProcessingStream = true;

    try {
      final inputImage = _cameraImageToInputImage(cameraImage, camera);
      if (inputImage == null) return null;

      final recognizedText = await _textRecognizer.processImage(inputImage);
      if (recognizedText.blocks.isEmpty) return null;

      final result = _analyzeRecognizedText(
        recognizedText,
        cameraImage.width.toDouble(),
        cameraImage.height.toDouble(),
        'live_stream',
        cardGuideRect: cardGuideRect,
      );

      // Só retorna se confiança mínima
      if (result.success && result.confidence >= 50) {
        return result;
      }
      return null;
    } catch (e) {
      debugPrint('[OCR Stream] Erro: $e');
      return null;
    } finally {
      _isProcessingStream = false;
    }
  }

  /// Converte CameraImage para InputImage (zero-copy, sem salvar arquivo)
  InputImage? _cameraImageToInputImage(
    CameraImage image,
    CameraDescription camera,
  ) {
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    }
    rotation ??= InputImageRotation.rotation0deg;

    // iOS entrega bgra8888, Android entrega nv21 (ou yuv420)
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    // Monta os planes
    final planes =
        image.planes.map((plane) {
          return InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation!,
            format: format,
            bytesPerRow: plane.bytesPerRow,
          );
        }).toList();

    if (planes.isEmpty) return null;

    // Concatena bytes de todos os planes
    final allBytes = WriteBuffer();
    for (final plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }

    return InputImage.fromBytes(
      bytes: allBytes.done().buffer.asUint8List(),
      metadata: planes.first,
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}

/// Região para processamento
class _Region {
  final double left, top, right, bottom;
  final String name;
  _Region(this.left, this.top, this.right, this.bottom, this.name);
}
