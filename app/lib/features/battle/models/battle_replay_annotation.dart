enum BattleReplayAnnotationKind {
  bookmark('bookmark'),
  note('note'),
  wouldDoDifferently('would_do_differently'),
  mulliganDecision('mulligan_decision'),
  helpfulFeedback('helpful_feedback'),
  eventReport('event_report');

  const BattleReplayAnnotationKind(this.wireValue);

  final String wireValue;

  static BattleReplayAnnotationKind? tryParse(Object? value) {
    final normalized = value?.toString().trim().toLowerCase();
    for (final kind in values) {
      if (kind.wireValue == normalized) return kind;
    }
    return null;
  }
}

class BattleReplayAnnotation {
  const BattleReplayAnnotation({
    required this.id,
    required this.replayId,
    required this.subjectDeckId,
    required this.subjectDeckRevision,
    required this.kind,
    required this.payload,
    required this.createdAt,
    this.eventRef,
    this.snapshotRef,
  });

  final String id;
  final String replayId;
  final String subjectDeckId;
  final String subjectDeckRevision;
  final BattleReplayAnnotationKind kind;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final String? eventRef;
  final String? snapshotRef;

  factory BattleReplayAnnotation.fromJson(Map<String, dynamic> json) {
    final schema = _requiredText(json['schema_version'], 'schema_version');
    if (schema != 'battle_replay_annotation_v1') {
      throw const FormatException('unsupported_annotation_schema');
    }
    final kind = BattleReplayAnnotationKind.tryParse(json['kind']);
    if (kind == null) {
      throw const FormatException('unsupported_annotation_kind');
    }
    final rawPayload = json['payload'];
    if (rawPayload is! Map) {
      throw const FormatException('invalid_annotation_payload');
    }
    final createdAt = DateTime.tryParse(
      _requiredText(json['created_at'], 'created_at'),
    );
    if (createdAt == null) {
      throw const FormatException('invalid_annotation_created_at');
    }

    return BattleReplayAnnotation(
      id: _requiredText(json['id'], 'id'),
      replayId: _requiredText(json['replay_id'], 'replay_id'),
      subjectDeckId: _requiredText(json['subject_deck_id'], 'subject_deck_id'),
      subjectDeckRevision: _requiredText(
        json['subject_deck_revision'],
        'subject_deck_revision',
      ),
      kind: kind,
      payload: Map<String, dynamic>.unmodifiable(
        rawPayload.map((key, value) => MapEntry(key.toString(), value)),
      ),
      createdAt: createdAt.toUtc(),
      eventRef: _optionalText(json['event_ref']),
      snapshotRef: _optionalText(json['snapshot_ref']),
    );
  }

  String get title {
    return switch (kind) {
      BattleReplayAnnotationKind.bookmark => 'Replay marcado',
      BattleReplayAnnotationKind.note =>
        _optionalText(payload['title']) ?? 'Nota pessoal',
      BattleReplayAnnotationKind.wouldDoDifferently => 'Eu faria diferente',
      BattleReplayAnnotationKind.mulliganDecision => 'Escolha de mão inicial',
      BattleReplayAnnotationKind.helpfulFeedback =>
        payload['helpful'] == true ? 'Isso ajudou' : 'Isso não ajudou',
      BattleReplayAnnotationKind.eventReport => 'Evento reportado',
    };
  }

  String get detail {
    return switch (kind) {
      BattleReplayAnnotationKind.bookmark =>
        _optionalText(payload['label']) ?? 'Sem rótulo',
      BattleReplayAnnotationKind.note =>
        _optionalText(payload['text']) ?? 'Sem texto',
      BattleReplayAnnotationKind.wouldDoDifferently => _wouldDoDifferentlyLabel(
        payload,
      ),
      BattleReplayAnnotationKind.mulliganDecision => _mulliganDecisionLabel(
        payload,
      ),
      BattleReplayAnnotationKind.helpfulFeedback =>
        _optionalText(payload['surface']) ?? 'Relatório pós-Battle',
      BattleReplayAnnotationKind.eventReport =>
        _optionalText(payload['reason_code']) ?? 'Motivo não informado',
    };
  }
}

class BattleReplayAnnotationDraft {
  const BattleReplayAnnotationDraft({
    required this.kind,
    required this.payload,
    this.eventRef,
    this.snapshotRef,
  });

  final BattleReplayAnnotationKind kind;
  final Map<String, dynamic> payload;
  final String? eventRef;
  final String? snapshotRef;

  Map<String, dynamic> toJson({required String idempotencyKey}) => {
    'kind': kind.wireValue,
    'payload': payload,
    if (eventRef != null) 'event_ref': eventRef,
    if (snapshotRef != null) 'snapshot_ref': snapshotRef,
    'idempotency_key': idempotencyKey,
  };
}

String _requiredText(Object? value, String field) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) {
    throw FormatException('missing_$field');
  }
  return text;
}

String? _optionalText(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

String _wouldDoDifferentlyLabel(Map<String, dynamic> payload) {
  final stance = _optionalText(payload['stance']);
  final stanceLabel = switch (stance) {
    'would_change' => 'Mudaria a escolha',
    'would_repeat' => 'Repetiria a escolha',
    'unsure' => 'Ainda não tenho certeza',
    _ => 'Posição não informada',
  };
  final reason = _optionalText(payload['reason']);
  return reason == null ? stanceLabel : '$stanceLabel · $reason';
}

String _mulliganDecisionLabel(Map<String, dynamic> payload) {
  final choice = payload['choice'] == 'keep' ? 'Keep' : 'Mulligan';
  final handSize = payload['hand_size'];
  return handSize is num ? '$choice · ${handSize.toInt()} cartas' : choice;
}
