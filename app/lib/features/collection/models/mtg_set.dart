class MtgSet {
  final String code;
  final String name;
  final String? releaseDate;
  final String? type;
  final String? block;
  final bool? isOnlineOnly;
  final bool? isForeignOnly;
  final int cardCount;
  final String status;
  final String? representativeImageUrl;
  final String? iconSvgUri;

  const MtgSet({
    required this.code,
    required this.name,
    required this.status,
    this.releaseDate,
    this.type,
    this.block,
    this.isOnlineOnly,
    this.isForeignOnly,
    this.cardCount = 0,
    this.representativeImageUrl,
    this.iconSvgUri,
  });

  factory MtgSet.fromJson(Map<String, dynamic> json) {
    return MtgSet(
      code: json['code']?.toString().toUpperCase() ?? '',
      name: json['name']?.toString() ?? 'Coleção sem nome',
      releaseDate: json['release_date']?.toString(),
      type: json['type']?.toString(),
      block: json['block']?.toString(),
      isOnlineOnly: json['is_online_only'] as bool?,
      isForeignOnly: json['is_foreign_only'] as bool?,
      cardCount: (json['card_count'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString().toLowerCase() ?? 'old',
      representativeImageUrl: _optionalString(json['representative_image_url']),
      iconSvgUri: _optionalString(json['icon_svg_uri']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'release_date': releaseDate,
      'type': type,
      'block': block,
      'is_online_only': isOnlineOnly,
      'is_foreign_only': isForeignOnly,
      'card_count': cardCount,
      'representative_image_url': representativeImageUrl,
      'icon_svg_uri': iconSvgUri,
      'status': status,
    };
  }

  bool get isFuture => status == 'future';

  String? get resolvedIconSvgUri {
    final explicit = iconSvgUri?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final normalizedCode = code.trim().toLowerCase();
    if (normalizedCode.isEmpty) return null;
    return Uri.https('svgs.scryfall.io', '/sets/$normalizedCode.svg', const {
      'v': '1',
    }).toString();
  }

  String get statusLabel {
    switch (status) {
      case 'future':
        return 'Futura';
      case 'new':
        return 'Nova';
      case 'current':
        return 'Atual';
      default:
        return 'Antiga';
    }
  }

  static String? _optionalString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
