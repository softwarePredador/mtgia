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
      'status': status,
    };
  }

  bool get isFuture => status == 'future';

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
}
