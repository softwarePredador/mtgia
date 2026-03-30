import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'life_counter_session.dart';

const int lifeCounterPlayerAppearanceTransferVersion = 1;

@immutable
class LifeCounterPlayerAppearanceTransfer {
  const LifeCounterPlayerAppearanceTransfer({
    required this.version,
    required this.exportedAt,
    required this.appearance,
  });

  final int version;
  final DateTime exportedAt;
  final LifeCounterPlayerAppearance appearance;

  factory LifeCounterPlayerAppearanceTransfer.fromAppearance(
    LifeCounterPlayerAppearance appearance,
  ) {
    return LifeCounterPlayerAppearanceTransfer(
      version: lifeCounterPlayerAppearanceTransferVersion,
      exportedAt: DateTime.now().toUtc(),
      appearance: appearance,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'exported_at': exportedAt.toIso8601String(),
      'appearance': appearance.toJson(),
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static LifeCounterPlayerAppearanceTransfer? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      return tryFromJson(decoded.cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  static LifeCounterPlayerAppearanceTransfer? tryFromJson(
    Map<String, dynamic> raw,
  ) {
    final version = (raw['version'] as num?)?.toInt();
    if (version == null || version < 1) {
      return null;
    }

    final exportedAtRaw = raw['exported_at'];
    final exportedAt =
        exportedAtRaw is String ? DateTime.tryParse(exportedAtRaw) : null;
    if (exportedAt == null) {
      return null;
    }

    final appearance = LifeCounterPlayerAppearance.tryFromJson(
      raw['appearance'],
    );
    if (appearance == null) {
      return null;
    }

    return LifeCounterPlayerAppearanceTransfer(
      version: version,
      exportedAt: exportedAt,
      appearance: appearance,
    );
  }
}
