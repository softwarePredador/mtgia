/// Condições de carta no padrão TCGPlayer.
/// NM = Near Mint, LP = Lightly Played, MP = Moderately Played,
/// HP = Heavily Played, DMG = Damaged.
enum CardCondition {
  nm('NM', 'Near Mint'),
  lp('LP', 'Lightly Played'),
  mp('MP', 'Moderately Played'),
  hp('HP', 'Heavily Played'),
  dmg('DMG', 'Damaged');

  const CardCondition(this.code, this.label);
  final String code;
  final String label;

  static CardCondition fromCode(String? code) {
    if (code == null) return CardCondition.nm;
    final upper = code.trim().toUpperCase();
    return CardCondition.values.firstWhere(
      (c) => c.code == upper,
      orElse: () => CardCondition.nm,
    );
  }
}

class DeckCardItem {
  final String id;
  final String name;
  final String? manaCost;
  final String typeLine;
  final String? oracleText;
  final List<String> colors;
  final List<String> colorIdentity;
  final String? imageUrl;
  final String setCode;
  final String? setName;
  final String? setReleaseDate; // yyyy-mm-dd
  final String rarity;
  final bool isReserved;
  final int quantity;
  final bool isCommander;

  /// Número de colecionador (ex: "157", "157a")
  final String? collectorNumber;

  /// Status foil: true=foil, false=non-foil, null=desconhecido
  final bool? foil;

  /// Condição física da carta (TCGPlayer standard)
  final CardCondition condition;

  /// URL usada pela UI quando o backend/import ainda não trouxe `image_url`.
  ///
  /// Mantém a URL explícita como fonte principal e cai para a imagem pública do
  /// Scryfall por nome exato da carta apenas quando necessário.
  String? get effectiveImageUrl {
    final explicit = imageUrl?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }

    return fallbackImageUrl;
  }

  /// Imagem pública por nome, sem prender a UI a uma edição específica.
  ///
  /// Serve como fallback visual quando a imagem da impressão/importação falha.
  String? get fallbackImageUrl {
    final cardName = name.trim();
    if (cardName.isEmpty) {
      return null;
    }

    return Uri.https('api.scryfall.com', '/cards/named', {
      'exact': cardName,
      'format': 'image',
      'version': 'normal',
    }).toString();
  }

  DeckCardItem({
    required this.id,
    required this.name,
    this.manaCost,
    required this.typeLine,
    this.oracleText,
    this.colors = const [],
    this.colorIdentity = const [],
    this.imageUrl,
    required this.setCode,
    this.setName,
    this.setReleaseDate,
    required this.rarity,
    this.isReserved = false,
    required this.quantity,
    required this.isCommander,
    this.collectorNumber,
    this.foil,
    this.condition = CardCondition.nm,
  });

  /// Cria cópia com campos alterados.
  DeckCardItem copyWith({
    String? id,
    String? name,
    String? manaCost,
    String? typeLine,
    String? oracleText,
    List<String>? colors,
    List<String>? colorIdentity,
    String? imageUrl,
    String? setCode,
    String? setName,
    String? setReleaseDate,
    String? rarity,
    bool? isReserved,
    int? quantity,
    bool? isCommander,
    String? collectorNumber,
    bool? foil,
    CardCondition? condition,
  }) {
    return DeckCardItem(
      id: id ?? this.id,
      name: name ?? this.name,
      manaCost: manaCost ?? this.manaCost,
      typeLine: typeLine ?? this.typeLine,
      oracleText: oracleText ?? this.oracleText,
      colors: colors ?? this.colors,
      colorIdentity: colorIdentity ?? this.colorIdentity,
      imageUrl: imageUrl ?? this.imageUrl,
      setCode: setCode ?? this.setCode,
      setName: setName ?? this.setName,
      setReleaseDate: setReleaseDate ?? this.setReleaseDate,
      rarity: rarity ?? this.rarity,
      isReserved: isReserved ?? this.isReserved,
      quantity: quantity ?? this.quantity,
      isCommander: isCommander ?? this.isCommander,
      collectorNumber: collectorNumber ?? this.collectorNumber,
      foil: foil ?? this.foil,
      condition: condition ?? this.condition,
    );
  }

  factory DeckCardItem.fromJson(Map<String, dynamic> json) {
    return DeckCardItem(
      id: json['id'] as String,
      name: json['name'] as String,
      manaCost: json['mana_cost'] as String?,
      typeLine: json['type_line'] as String? ?? '',
      oracleText: json['oracle_text'] as String?,
      colors: (json['colors'] as List?)?.map((e) => e as String).toList() ?? [],
      colorIdentity:
          (json['color_identity'] as List?)?.map((e) => e as String).toList() ??
          [],
      imageUrl: json['image_url'] as String?,
      setCode: json['set_code'] as String? ?? '',
      setName: json['set_name'] as String?,
      setReleaseDate: json['set_release_date'] as String?,
      rarity: json['rarity'] as String? ?? '',
      isReserved: json['is_reserved'] as bool? ?? false,
      quantity: json['quantity'] as int? ?? 1,
      isCommander: json['is_commander'] as bool? ?? false,
      collectorNumber: json['collector_number'] as String?,
      foil: json['foil'] as bool?,
      condition: CardCondition.fromCode(json['condition'] as String?),
    );
  }
}
