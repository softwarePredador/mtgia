class DeckOptimizationEvent {
  const DeckOptimizationEvent({
    required this.id,
    required this.eventType,
    required this.mode,
    required this.intensity,
    required this.archetype,
    required this.selectedChangeCount,
    required this.removals,
    required this.additions,
    required this.validationStatus,
    required this.battleStatus,
    required this.battleMessage,
    required this.createdAt,
    required this.canRollback,
    required this.rollbackReason,
    required this.rollbackOfEventId,
    required this.sourceSummary,
    this.bracket,
  });

  final String id;
  final String eventType;
  final String mode;
  final String intensity;
  final String archetype;
  final int? bracket;
  final int selectedChangeCount;
  final List<Map<String, dynamic>> removals;
  final List<Map<String, dynamic>> additions;
  final String validationStatus;
  final String battleStatus;
  final String battleMessage;
  final DateTime? createdAt;
  final bool canRollback;
  final String rollbackReason;
  final String rollbackOfEventId;
  final Map<String, dynamic> sourceSummary;

  bool get isApply => eventType == 'optimize_apply';
  bool get isRollback => eventType == 'optimize_rollback';

  int get pairCount =>
      removals.length < additions.length ? removals.length : additions.length;

  factory DeckOptimizationEvent.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> maps(Object? raw) {
      if (raw is! List) return const <Map<String, dynamic>>[];
      return raw
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList(growable: false);
    }

    Map<String, dynamic> map(Object? raw) {
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return raw.cast<String, dynamic>();
      return const <String, dynamic>{};
    }

    int? integer(Object? raw) {
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      return int.tryParse(raw?.toString() ?? '');
    }

    final createdAtText = json['created_at']?.toString().trim();
    return DeckOptimizationEvent(
      id: json['id']?.toString() ?? '',
      eventType: json['event_type']?.toString() ?? '',
      mode: json['mode']?.toString() ?? '',
      intensity: json['intensity']?.toString() ?? '',
      archetype: json['archetype']?.toString() ?? '',
      bracket: integer(json['bracket']),
      selectedChangeCount: integer(json['selected_change_count']) ?? 0,
      removals: maps(json['removals']),
      additions: maps(json['additions']),
      validationStatus: json['validation_status']?.toString() ?? '',
      battleStatus: json['battle_status']?.toString() ?? '',
      battleMessage: json['battle_message']?.toString() ?? '',
      createdAt: createdAtText == null || createdAtText.isEmpty
          ? null
          : DateTime.tryParse(createdAtText),
      canRollback: json['can_rollback'] == true,
      rollbackReason: json['rollback_reason']?.toString() ?? '',
      rollbackOfEventId: json['rollback_of_event_id']?.toString() ?? '',
      sourceSummary: map(json['source_summary']),
    );
  }
}
