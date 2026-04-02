import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../lotus/lotus_storage_snapshot.dart';
import 'life_counter_session.dart';

@immutable
class LifeCounterHistoryEntry {
  const LifeCounterHistoryEntry({
    required this.message,
    this.occurredAt,
    this.source = LifeCounterHistoryEntrySource.currentGame,
  });

  final String message;
  final DateTime? occurredAt;
  final LifeCounterHistoryEntrySource source;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'message': message,
      'occurred_at': occurredAt?.toIso8601String(),
      'source': source.name,
    };
  }

  static LifeCounterHistoryEntry? tryFromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }

    final message = LifeCounterHistorySnapshot._readString(raw['message']);
    if (message == null) {
      return null;
    }

    final sourceRaw = raw['source'];
    final source = switch (sourceRaw) {
      'archive' => LifeCounterHistoryEntrySource.archive,
      'fallback' => LifeCounterHistoryEntrySource.fallback,
      _ => LifeCounterHistoryEntrySource.currentGame,
    };

    return LifeCounterHistoryEntry(
      message: message,
      occurredAt: LifeCounterHistorySnapshot._readDateTime(raw['occurred_at']),
      source: source,
    );
  }
}

enum LifeCounterHistoryEntrySource { currentGame, archive, fallback }

@immutable
class LifeCounterHistoryState {
  const LifeCounterHistoryState({
    required this.currentGameEntries,
    required this.archiveEntries,
    required this.archivedGameCount,
    this.currentGameName,
    this.currentGameMeta,
    this.gameCounter = 1,
    this.lastTableEvent,
  });

  const LifeCounterHistoryState.empty()
    : currentGameName = null,
      currentGameMeta = null,
      currentGameEntries = const [],
      archiveEntries = const [],
      archivedGameCount = 0,
      gameCounter = 1,
      lastTableEvent = null;

  final String? currentGameName;
  final Map<String, Object?>? currentGameMeta;
  final List<LifeCounterHistoryEntry> currentGameEntries;
  final List<LifeCounterHistoryEntry> archiveEntries;
  final int archivedGameCount;
  final int gameCounter;
  final String? lastTableEvent;

  bool get hasContent =>
      (lastTableEvent?.trim().isNotEmpty ?? false) ||
      currentGameEntries.isNotEmpty ||
      archiveEntries.isNotEmpty;

  factory LifeCounterHistoryState.fromSources({
    LifeCounterSession? session,
    LotusStorageSnapshot? snapshot,
  }) {
    final currentGameMeta = decodeCurrentGameMeta(
      snapshot?.values[_currentGameMetaKey],
    );
    final archivePayload = LifeCounterHistorySnapshot._decodeSnapshotJson(
      snapshot?.values[_allGamesHistoryKey],
    );

    return LifeCounterHistoryState(
      currentGameName: LifeCounterHistorySnapshot._readString(
        currentGameMeta['name'],
      ),
      currentGameMeta: currentGameMeta,
      currentGameEntries: LifeCounterHistorySnapshot._extractEntries(
        LifeCounterHistorySnapshot._decodeSnapshotJson(
          snapshot?.values[_gameHistoryKey],
        ),
        source: LifeCounterHistoryEntrySource.currentGame,
      ),
      archiveEntries: LifeCounterHistorySnapshot._extractArchiveEntries(
        archivePayload,
      ),
      archivedGameCount: LifeCounterHistorySnapshot._countArchivedGames(
        archivePayload,
      ),
      gameCounter: decodeGameCounter(snapshot?.values[_gameCounterKey]),
      lastTableEvent: LifeCounterHistorySnapshot._normalizeLastTableEvent(
        session?.lastTableEvent,
      ),
    );
  }

  static LifeCounterHistoryState? tryFromJson(Map<String, dynamic> raw) {
    final currentGameEntries = _readPersistedEntries(
      raw['current_game_entries'],
    );
    final archiveEntries = _readPersistedEntries(raw['archive_entries']);
    if (currentGameEntries == null || archiveEntries == null) {
      return null;
    }

    return LifeCounterHistoryState(
      currentGameName:
          LifeCounterHistorySnapshot._readString(raw['current_game_name']) ??
          LifeCounterHistorySnapshot._readString(
            _readPersistedMeta(raw['current_game_meta'])?['name'],
          ),
      currentGameMeta: _readPersistedMeta(raw['current_game_meta']),
      currentGameEntries: currentGameEntries,
      archiveEntries: archiveEntries,
      archivedGameCount: _readArchivedGameCount(raw['archived_game_count']),
      gameCounter: _readGameCounter(raw['game_counter']),
      lastTableEvent: LifeCounterHistorySnapshot._readString(
        raw['last_table_event'],
      ),
    );
  }

  static const Object _unset = Object();
  static const String _gameHistoryKey = 'gameHistory';
  static const String _allGamesHistoryKey = 'allGamesHistory';
  static const String _currentGameMetaKey = 'currentGameMeta';
  static const String _gameCounterKey = 'gameCounter';

  LifeCounterHistoryState copyWith({
    Object? currentGameName = _unset,
    Object? currentGameMeta = _unset,
    List<LifeCounterHistoryEntry>? currentGameEntries,
    List<LifeCounterHistoryEntry>? archiveEntries,
    int? archivedGameCount,
    int? gameCounter,
    Object? lastTableEvent = _unset,
  }) {
    return LifeCounterHistoryState(
      currentGameName:
          identical(currentGameName, _unset)
              ? this.currentGameName
              : LifeCounterHistorySnapshot._readString(currentGameName),
      currentGameMeta:
          identical(currentGameMeta, _unset)
              ? this.currentGameMeta
              : _normalizeCurrentGameMeta(
                currentGameMeta,
                fallbackName:
                    identical(currentGameName, _unset)
                        ? this.currentGameName
                        : LifeCounterHistorySnapshot._readString(
                          currentGameName,
                        ),
              ),
      currentGameEntries:
          currentGameEntries == null
              ? this.currentGameEntries
              : List<LifeCounterHistoryEntry>.unmodifiable(currentGameEntries),
      archiveEntries:
          archiveEntries == null
              ? this.archiveEntries
              : List<LifeCounterHistoryEntry>.unmodifiable(archiveEntries),
      archivedGameCount:
          archivedGameCount == null
              ? this.archivedGameCount
              : archivedGameCount < 0
              ? 0
              : archivedGameCount,
      gameCounter:
          gameCounter == null
              ? this.gameCounter
              : gameCounter < 1
              ? 1
              : gameCounter,
      lastTableEvent:
          identical(lastTableEvent, _unset)
              ? this.lastTableEvent
              : LifeCounterHistorySnapshot._readString(lastTableEvent),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'current_game_name': currentGameName,
      'current_game_meta': currentGameMeta,
      'current_game_entries':
          currentGameEntries.map((e) => e.toJson()).toList(),
      'archive_entries': archiveEntries.map((e) => e.toJson()).toList(),
      'archived_game_count': archivedGameCount,
      'game_counter': gameCounter,
      'last_table_event': lastTableEvent,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  Map<String, String> buildLotusSnapshotValues({
    Map<String, Object?>? currentGameMetaSeed,
  }) {
    final resolvedCurrentGameMeta = _normalizeCurrentGameMeta(<String, Object?>{
      ...?currentGameMetaSeed,
      ...?currentGameMeta,
    }, fallbackName: currentGameName);

    final archiveGames = _buildArchiveGames();

    return <String, String>{
      _currentGameMetaKey: jsonEncode(resolvedCurrentGameMeta),
      _gameHistoryKey: jsonEncode(
        currentGameEntries
            .map(LifeCounterHistorySnapshot._encodeEntryForLotus)
            .toList(growable: false),
      ),
      _allGamesHistoryKey: jsonEncode(archiveGames),
      _gameCounterKey: jsonEncode(gameCounter < 1 ? 1 : gameCounter),
    };
  }

  List<Map<String, Object?>> _buildArchiveGames() {
    if (archiveEntries.isEmpty || archivedGameCount <= 0) {
      return const <Map<String, Object?>>[];
    }

    final archiveGames = <Map<String, Object?>>[
      <String, Object?>{
        'name': currentGameName ?? 'Imported History',
        'history': archiveEntries
            .map(LifeCounterHistorySnapshot._encodeEntryForLotus)
            .toList(growable: false),
      },
    ];

    for (var index = 1; index < archivedGameCount; index += 1) {
      archiveGames.add(<String, Object?>{
        'name': 'Archived Game #${index + 1}',
        'history': const <Object?>[],
      });
    }

    return archiveGames;
  }

  static Map<String, Object?> decodeCurrentGameMeta(String? raw) {
    if (raw == null || raw.isEmpty) {
      return _defaultCurrentGameMeta();
    }

    try {
      final decoded = jsonDecode(raw);
      return _normalizeCurrentGameMeta(decoded);
    } catch (_) {}

    return _defaultCurrentGameMeta();
  }

  static int decodeGameCounter(String? raw) {
    if (raw == null || raw.isEmpty) {
      return 1;
    }

    try {
      final decoded = jsonDecode(raw);
      return _readGameCounter(decoded);
    } catch (_) {
      return 1;
    }
  }

  static List<LifeCounterHistoryEntry>? _readPersistedEntries(Object? raw) {
    if (raw == null) {
      return const [];
    }
    if (raw is! List) {
      return null;
    }

    final entries = <LifeCounterHistoryEntry>[];
    for (final item in raw) {
      final entry = LifeCounterHistoryEntry.tryFromJson(item);
      if (entry == null) {
        return null;
      }
      entries.add(entry);
    }

    return List<LifeCounterHistoryEntry>.unmodifiable(entries);
  }

  static int _readArchivedGameCount(Object? raw) {
    if (raw is int) {
      return raw < 0 ? 0 : raw;
    }
    if (raw is num) {
      return raw < 0 ? 0 : raw.toInt();
    }
    return 0;
  }

  static int _readGameCounter(Object? raw) {
    if (raw is int) {
      return raw < 1 ? 1 : raw;
    }
    if (raw is num) {
      return raw < 1 ? 1 : raw.toInt();
    }
    return 1;
  }

  static Map<String, Object?>? _readPersistedMeta(Object? raw) {
    if (raw == null) {
      return null;
    }

    final normalized = _normalizeCurrentGameMeta(raw);
    return normalized.isEmpty ? null : normalized;
  }

  static Map<String, Object?> _normalizeCurrentGameMeta(
    Object? raw, {
    String? fallbackName,
  }) {
    final values = <String, Object?>{};
    if (raw is Map<String, dynamic>) {
      values.addAll(raw);
    } else if (raw is Map) {
      values.addAll(
        raw.map<String, Object?>(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
    }

    values['id'] =
        LifeCounterHistorySnapshot._readString(values['id']) ??
        'canonical-history-bootstrap';
    values['name'] =
        fallbackName ??
        LifeCounterHistorySnapshot._readString(values['name']) ??
        'Imported History';
    values['startDate'] =
        values['startDate'] is num
            ? (values['startDate'] as num).toInt()
            : DateTime.now().millisecondsSinceEpoch;
    return Map<String, Object?>.unmodifiable(values);
  }

  static Map<String, Object?> _defaultCurrentGameMeta() {
    return _normalizeCurrentGameMeta(const <String, Object?>{});
  }
}

@immutable
class LifeCounterHistorySnapshot {
  const LifeCounterHistorySnapshot({
    required this.currentGameName,
    required this.currentGameMeta,
    required this.currentGameEntries,
    required this.archiveEntries,
    required this.archivedGameCount,
    required this.gameCounter,
    required this.lastTableEvent,
  });

  final String? currentGameName;
  final Map<String, Object?>? currentGameMeta;
  final List<LifeCounterHistoryEntry> currentGameEntries;
  final List<LifeCounterHistoryEntry> archiveEntries;
  final int archivedGameCount;
  final int gameCounter;
  final String? lastTableEvent;

  int get currentGameEventCount => currentGameEntries.length;
  int get archivedEventCount => archiveEntries.length;
  bool get hasContent =>
      (lastTableEvent?.trim().isNotEmpty ?? false) ||
      currentGameEntries.isNotEmpty ||
      archiveEntries.isNotEmpty;

  factory LifeCounterHistorySnapshot.fromSources({
    LifeCounterHistoryState? historyState,
    LifeCounterSession? session,
    LotusStorageSnapshot? snapshot,
  }) {
    final canonicalState = (historyState ??
            LifeCounterHistoryState.fromSources(
              session: session,
              snapshot: snapshot,
            ))
        .copyWith(
          lastTableEvent:
              _normalizeLastTableEvent(session?.lastTableEvent) ??
              historyState?.lastTableEvent,
        );

    if (canonicalState.currentGameEntries.isEmpty &&
        canonicalState.lastTableEvent != null) {
      return LifeCounterHistorySnapshot(
        currentGameName: canonicalState.currentGameName,
        currentGameMeta: canonicalState.currentGameMeta,
        currentGameEntries: [
          LifeCounterHistoryEntry(
            message: canonicalState.lastTableEvent!,
            source: LifeCounterHistoryEntrySource.fallback,
          ),
        ],
        archiveEntries: canonicalState.archiveEntries,
        archivedGameCount: canonicalState.archivedGameCount,
        gameCounter: canonicalState.gameCounter,
        lastTableEvent: canonicalState.lastTableEvent,
      );
    }

    return LifeCounterHistorySnapshot(
      currentGameName: canonicalState.currentGameName,
      currentGameMeta: canonicalState.currentGameMeta,
      currentGameEntries: canonicalState.currentGameEntries,
      archiveEntries: canonicalState.archiveEntries,
      archivedGameCount: canonicalState.archivedGameCount,
      gameCounter: canonicalState.gameCounter,
      lastTableEvent: canonicalState.lastTableEvent,
    );
  }

  static Object? _decodeSnapshotJson(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  static int _countArchivedGames(Object? rawArchive) {
    if (rawArchive is List) {
      return rawArchive.length;
    }

    return 0;
  }

  static List<LifeCounterHistoryEntry> _extractArchiveEntries(
    Object? rawArchive,
  ) {
    if (rawArchive is! List) {
      return const [];
    }

    final entries = <LifeCounterHistoryEntry>[];
    for (final item in rawArchive) {
      if (item is Map) {
        final nested = item['history'] ?? item['gameHistory'] ?? item['events'];
        final nestedEntries = _extractEntries(
          nested,
          source: LifeCounterHistoryEntrySource.archive,
        );
        if (nestedEntries.isNotEmpty) {
          entries.addAll(nestedEntries);
          continue;
        }
      }

      entries.addAll(
        _extractEntries([item], source: LifeCounterHistoryEntrySource.archive),
      );
    }

    return List<LifeCounterHistoryEntry>.unmodifiable(entries.reversed);
  }

  static List<LifeCounterHistoryEntry> _extractEntries(
    Object? rawEntries, {
    required LifeCounterHistoryEntrySource source,
  }) {
    if (rawEntries is! List) {
      return const [];
    }

    final entries = <LifeCounterHistoryEntry>[];
    for (final item in rawEntries) {
      final entry = _extractSingleEntry(item, source: source);
      if (entry != null) {
        entries.add(entry);
      }
    }

    return List<LifeCounterHistoryEntry>.unmodifiable(entries.reversed);
  }

  static LifeCounterHistoryEntry? _extractSingleEntry(
    Object? rawEntry, {
    required LifeCounterHistoryEntrySource source,
  }) {
    if (rawEntry is String) {
      final message = rawEntry.trim();
      if (message.isEmpty) {
        return null;
      }
      return LifeCounterHistoryEntry(message: message, source: source);
    }

    if (rawEntry is! Map) {
      return null;
    }

    final message =
        _readString(rawEntry['message']) ??
        _readString(rawEntry['text']) ??
        _readString(rawEntry['event']) ??
        _readString(rawEntry['action']) ??
        _readString(rawEntry['description']) ??
        _readString(rawEntry['label']) ??
        _readString(rawEntry['title']) ??
        _readString(rawEntry['name']) ??
        _compactMapMessage(rawEntry);

    if (message == null || message.isEmpty) {
      return null;
    }

    return LifeCounterHistoryEntry(
      message: message,
      occurredAt: _readDateTime(
        rawEntry['timestamp'] ??
            rawEntry['date'] ??
            rawEntry['createdAt'] ??
            rawEntry['startDate'],
      ),
      source: source,
    );
  }

  static String? _compactMapMessage(Map<dynamic, dynamic> raw) {
    const ignoredKeys = {
      'timestamp',
      'date',
      'createdAt',
      'startDate',
      'history',
      'gameHistory',
      'events',
    };

    final parts = <String>[];
    for (final entry in raw.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || ignoredKeys.contains(key)) {
        continue;
      }
      if (value is Map || value is List || value == null) {
        continue;
      }

      final text = value.toString().trim();
      if (text.isEmpty) {
        continue;
      }
      parts.add('$key: $text');
    }

    if (parts.isEmpty) {
      return null;
    }

    return parts.join(' • ');
  }

  static String? _readString(Object? value) {
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static DateTime? _readDateTime(Object? value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  static Map<String, Object?> _encodeEntryForLotus(
    LifeCounterHistoryEntry entry,
  ) {
    return <String, Object?>{
      'message': entry.message,
      if (entry.occurredAt != null)
        'timestamp': entry.occurredAt!.millisecondsSinceEpoch,
    };
  }

  static String? _normalizeLastTableEvent(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
