import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../lotus/lotus_storage_snapshot.dart';
import 'life_counter_session.dart';

@immutable
class LifeCounterHistoryEntry {
  const LifeCounterHistoryEntry({
    required this.message,
    this.occurredAt,
    this.rawOccurredAt,
    this.source = LifeCounterHistoryEntrySource.currentGame,
  });

  final String message;
  final DateTime? occurredAt;
  final String? rawOccurredAt;
  final LifeCounterHistoryEntrySource source;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'message': message,
      'occurred_at': occurredAt?.toIso8601String(),
      'raw_occurred_at': rawOccurredAt,
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

    final occurredAt = LifeCounterHistorySnapshot._readDateTime(
      raw['occurred_at'],
    );
    return LifeCounterHistoryEntry(
      message: message,
      occurredAt: occurredAt,
      rawOccurredAt:
          LifeCounterHistorySnapshot._readString(raw['raw_occurred_at']) ??
          (occurredAt == null
              ? LifeCounterHistorySnapshot._readString(raw['occurred_at'])
              : null),
      source: source,
    );
  }
}

enum LifeCounterHistoryEntrySource { currentGame, archive, fallback }

@immutable
class LifeCounterArchivedGame {
  const LifeCounterArchivedGame({
    required this.entries,
    this.name,
    this.metadata = const <String, Object?>{},
  });

  final String? name;
  final Map<String, Object?> metadata;
  final List<LifeCounterHistoryEntry> entries;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'metadata': metadata,
      'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
    };
  }

  Map<String, Object?> toLotusJson() {
    return <String, Object?>{
      ...metadata,
      if (name != null) 'name': name,
      'history': entries.reversed
          .map(LifeCounterHistorySnapshot._encodeEntryForLotus)
          .toList(growable: false),
    };
  }

  static LifeCounterArchivedGame? tryFromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }

    final entries = LifeCounterHistoryState._readPersistedEntries(
      raw['entries'],
    );
    if (entries == null) {
      return null;
    }

    final metadataRaw = raw['metadata'];
    if (metadataRaw != null && metadataRaw is! Map) {
      return null;
    }
    final metadata = <String, Object?>{};
    if (metadataRaw is Map) {
      metadata.addAll(
        metadataRaw.map<String, Object?>(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
    }

    return LifeCounterArchivedGame(
      name: LifeCounterHistorySnapshot._readString(raw['name']),
      metadata: Map<String, Object?>.unmodifiable(metadata),
      entries: List<LifeCounterHistoryEntry>.unmodifiable(
        entries.map(
          (entry) => LifeCounterHistoryEntry(
            message: entry.message,
            occurredAt: entry.occurredAt,
            rawOccurredAt: entry.rawOccurredAt,
            source: LifeCounterHistoryEntrySource.archive,
          ),
        ),
      ),
    );
  }
}

@immutable
class LifeCounterHistoryState {
  const LifeCounterHistoryState({
    required this.currentGameEntries,
    required this.archiveEntries,
    required this.archivedGameCount,
    this.archivedGames = const <LifeCounterArchivedGame>[],
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
      archivedGames = const [],
      archivedGameCount = 0,
      gameCounter = 1,
      lastTableEvent = null;

  final String? currentGameName;
  final Map<String, Object?>? currentGameMeta;
  final List<LifeCounterHistoryEntry> currentGameEntries;
  final List<LifeCounterHistoryEntry> archiveEntries;
  final List<LifeCounterArchivedGame> archivedGames;
  final int archivedGameCount;
  final int gameCounter;
  final String? lastTableEvent;

  bool get hasContent =>
      (lastTableEvent?.trim().isNotEmpty ?? false) ||
      currentGameEntries.isNotEmpty ||
      archiveEntries.isNotEmpty ||
      archivedGames.isNotEmpty;

  bool get hasStableCurrentGameMeta {
    final startDate = currentGameMeta?['startDate'];
    return startDate is num && startDate.isFinite && startDate.toInt() >= 0;
  }

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
    final archivedGames = LifeCounterHistorySnapshot._extractArchivedGames(
      archivePayload,
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
      archiveEntries: LifeCounterHistorySnapshot._flattenArchivedGames(
        archivedGames,
      ),
      archivedGames: archivedGames,
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
    final archivedGames = _readPersistedArchivedGames(raw['archived_games']);
    if (currentGameEntries == null ||
        archiveEntries == null ||
        archivedGames == null) {
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
      archivedGames: archivedGames,
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
  static const Set<String> snapshotDomainKeys = <String>{
    _gameHistoryKey,
    _allGamesHistoryKey,
    _currentGameMetaKey,
    _gameCounterKey,
  };

  static bool hasSnapshotDomain(LotusStorageSnapshot? snapshot) {
    final values = snapshot?.values;
    if (values == null) {
      return false;
    }

    return snapshotDomainKeys.any(values.containsKey);
  }

  LifeCounterHistoryState copyWith({
    Object? currentGameName = _unset,
    Object? currentGameMeta = _unset,
    List<LifeCounterHistoryEntry>? currentGameEntries,
    List<LifeCounterHistoryEntry>? archiveEntries,
    List<LifeCounterArchivedGame>? archivedGames,
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
      archivedGames:
          archivedGames == null
              ? this.archivedGames
              : List<LifeCounterArchivedGame>.unmodifiable(archivedGames),
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

  LifeCounterHistoryState withStableCurrentGameMeta({
    required int startDateEpochMs,
    LifeCounterSession? session,
  }) {
    final existingMeta = <String, Object?>{...?currentGameMeta};
    final existingStartDate = existingMeta['startDate'];
    final resolvedStartDate =
        existingStartDate is num &&
                existingStartDate.isFinite &&
                existingStartDate.toInt() >= 0
            ? existingStartDate.toInt()
            : startDateEpochMs < 0
            ? 0
            : startDateEpochMs;
    final resolvedName =
        currentGameName ??
        LifeCounterHistorySnapshot._readString(existingMeta['name']) ??
        'Partida #${gameCounter < 1 ? 1 : gameCounter}';
    final resolvedId =
        LifeCounterHistorySnapshot._readString(existingMeta['id']) ??
        'canonical-game-${gameCounter < 1 ? 1 : gameCounter}-$resolvedStartDate';

    final resolvedMeta = <String, Object?>{
      ...existingMeta,
      'id': resolvedId,
      'name': resolvedName,
      'startDate': resolvedStartDate,
    };
    if (session != null) {
      resolvedMeta.putIfAbsent('startingLife', () => session.startingLife);
      resolvedMeta.putIfAbsent('playerCount', () => session.playerCount);
      resolvedMeta.putIfAbsent(
        'gameMode',
        () =>
            session.playerCount > 2 && session.startingLife >= 40
                ? 'commander'
                : 'standard',
      );
      if (session.playSessionId != null) {
        resolvedMeta['playSessionId'] = session.playSessionId;
      }
      if (session.deckId != null) {
        resolvedMeta['deckId'] = session.deckId;
      }
      if (session.deckName != null) {
        resolvedMeta['deckName'] = session.deckName;
      }
      if (session.startedAtEpochMs != null) {
        resolvedMeta['startedAtEpochMs'] = session.startedAtEpochMs;
      }
    }

    return copyWith(
      currentGameName: resolvedName,
      currentGameMeta: resolvedMeta,
    );
  }

  /// Starts a distinct game without relabelling the previous game's events.
  ///
  /// When the current game has events, it is moved into the archive with its
  /// existing metadata. An empty placeholder game is simply replaced so that
  /// opening one deck and immediately choosing another does not create noise.
  LifeCounterHistoryState startNewGameForSession({
    required LifeCounterSession session,
    required int startDateEpochMs,
  }) {
    final hasCurrentEvents = currentGameEntries.isNotEmpty;
    final archivedCurrentEntries = currentGameEntries
        .map(
          (entry) => LifeCounterHistoryEntry(
            message: entry.message,
            occurredAt: entry.occurredAt,
            rawOccurredAt: entry.rawOccurredAt,
            source: LifeCounterHistoryEntrySource.archive,
          ),
        )
        .toList(growable: false);
    final nextArchivedGames = <LifeCounterArchivedGame>[
      ...archivedGames,
      if (hasCurrentEvents)
        LifeCounterArchivedGame(
          name: currentGameName,
          metadata: Map<String, Object?>.unmodifiable(<String, Object?>{
            ...?currentGameMeta,
          }),
          entries: List<LifeCounterHistoryEntry>.unmodifiable(
            archivedCurrentEntries,
          ),
        ),
    ];
    final cleared = copyWith(
      currentGameName: null,
      currentGameMeta: null,
      currentGameEntries: const <LifeCounterHistoryEntry>[],
      archiveEntries: <LifeCounterHistoryEntry>[
        ...archiveEntries,
        ...archivedCurrentEntries,
      ],
      archivedGames: nextArchivedGames,
      archivedGameCount:
          hasCurrentEvents ? archivedGameCount + 1 : archivedGameCount,
      gameCounter: hasCurrentEvents ? gameCounter + 1 : gameCounter,
      lastTableEvent: null,
    );
    return cleared.withStableCurrentGameMeta(
      startDateEpochMs: startDateEpochMs,
      session: session,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'current_game_name': currentGameName,
      'current_game_meta': currentGameMeta,
      'current_game_entries':
          currentGameEntries.map((e) => e.toJson()).toList(),
      'archive_entries': archiveEntries.map((e) => e.toJson()).toList(),
      'archived_games': archivedGames.map((game) => game.toJson()).toList(),
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
        currentGameEntries.reversed
            .map(LifeCounterHistorySnapshot._encodeEntryForLotus)
            .toList(growable: false),
      ),
      _allGamesHistoryKey: jsonEncode(archiveGames),
      _gameCounterKey: jsonEncode(gameCounter < 1 ? 1 : gameCounter),
    };
  }

  List<Map<String, Object?>> _buildArchiveGames() {
    if (archivedGames.isNotEmpty) {
      return archivedGames
          .map((game) => game.toLotusJson())
          .toList(growable: false);
    }

    if (archiveEntries.isEmpty || archivedGameCount <= 0) {
      return const <Map<String, Object?>>[];
    }

    final archiveGames = <Map<String, Object?>>[
      <String, Object?>{
        'name': currentGameName ?? 'Histórico importado',
        'history': archiveEntries
            .map(LifeCounterHistorySnapshot._encodeEntryForLotus)
            .toList(growable: false),
      },
    ];

    for (var index = 1; index < archivedGameCount; index += 1) {
      archiveGames.add(<String, Object?>{
        'name': 'Partida arquivada #${index + 1}',
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

  static List<LifeCounterArchivedGame>? _readPersistedArchivedGames(
    Object? raw,
  ) {
    if (raw == null) {
      return const <LifeCounterArchivedGame>[];
    }
    if (raw is! List) {
      return null;
    }

    final games = <LifeCounterArchivedGame>[];
    for (final item in raw) {
      final game = LifeCounterArchivedGame.tryFromJson(item);
      if (game == null) {
        return null;
      }
      games.add(game);
    }
    return List<LifeCounterArchivedGame>.unmodifiable(games);
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

    final id = LifeCounterHistorySnapshot._readString(values['id']);
    if (id == null) {
      values.remove('id');
    } else {
      values['id'] = id;
    }
    final name =
        fallbackName ?? LifeCounterHistorySnapshot._readString(values['name']);
    if (name == null) {
      values.remove('name');
    } else {
      values['name'] = name;
    }
    final startDate = values['startDate'];
    if (startDate is num && startDate.isFinite && startDate.toInt() >= 0) {
      values['startDate'] = startDate.toInt();
    } else {
      values.remove('startDate');
    }
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
    this.archivedGames = const <LifeCounterArchivedGame>[],
    required this.archivedGameCount,
    required this.gameCounter,
    required this.lastTableEvent,
  });

  final String? currentGameName;
  final Map<String, Object?>? currentGameMeta;
  final List<LifeCounterHistoryEntry> currentGameEntries;
  final List<LifeCounterHistoryEntry> archiveEntries;
  final List<LifeCounterArchivedGame> archivedGames;
  final int archivedGameCount;
  final int gameCounter;
  final String? lastTableEvent;

  int get currentGameEventCount => currentGameEntries.length;
  int get archivedEventCount => archiveEntries.length;
  bool get hasContent =>
      (lastTableEvent?.trim().isNotEmpty ?? false) ||
      currentGameEntries.isNotEmpty ||
      archiveEntries.isNotEmpty ||
      archivedGames.isNotEmpty;

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
        archivedGames: canonicalState.archivedGames,
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
      archivedGames: canonicalState.archivedGames,
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

  static List<LifeCounterArchivedGame> _extractArchivedGames(
    Object? rawArchive,
  ) {
    if (rawArchive is! List) {
      return const [];
    }

    final games = <LifeCounterArchivedGame>[];
    for (var index = 0; index < rawArchive.length; index += 1) {
      final item = rawArchive[index];
      if (item is Map) {
        final nested = item['history'] ?? item['gameHistory'] ?? item['events'];
        if (nested is List) {
          final metadata = <String, Object?>{};
          for (final entry in item.entries) {
            final key = entry.key.toString();
            if (key == 'name' ||
                key == 'history' ||
                key == 'gameHistory' ||
                key == 'events') {
              continue;
            }
            metadata[key] = entry.value;
          }
          games.add(
            LifeCounterArchivedGame(
              name: _readString(item['name']),
              metadata: Map<String, Object?>.unmodifiable(metadata),
              entries: _extractEntries(
                nested,
                source: LifeCounterHistoryEntrySource.archive,
              ),
            ),
          );
          continue;
        }
      }

      final entries = _extractEntries([
        item,
      ], source: LifeCounterHistoryEntrySource.archive);
      games.add(
        LifeCounterArchivedGame(
          name: 'Partida arquivada #${index + 1}',
          entries: entries,
        ),
      );
    }

    return List<LifeCounterArchivedGame>.unmodifiable(games);
  }

  static List<LifeCounterHistoryEntry> _flattenArchivedGames(
    List<LifeCounterArchivedGame> games,
  ) {
    return List<LifeCounterHistoryEntry>.unmodifiable(
      games.reversed.expand((game) => game.entries),
    );
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

    final rawOccurredAt =
        rawEntry['timestamp'] ??
        rawEntry['date'] ??
        rawEntry['createdAt'] ??
        rawEntry['startDate'];
    final occurredAt = _readDateTime(rawOccurredAt);

    return LifeCounterHistoryEntry(
      message: message,
      occurredAt: occurredAt,
      rawOccurredAt: occurredAt == null ? _readString(rawOccurredAt) : null,
      source: source,
    );
  }

  static String? _compactMapMessage(Map<dynamic, dynamic> raw) {
    final player = raw['player'];
    final change = raw['change'];
    final life = raw['life'];
    if (player is num && change is num && life is num) {
      return 'player: ${player.toInt()} • change: ${change.toInt()} • life: ${life.toInt()}';
    }

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
      return DateTime.tryParse(value) ?? _parseLotusLocaleDateTime(value);
    }

    return null;
  }

  static DateTime? _parseLotusLocaleDateTime(String raw) {
    final match = RegExp(
      r'^(\d{1,2})/(\d{1,2})/(\d{4}),?\s+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(AM|PM)?$',
      caseSensitive: false,
    ).firstMatch(raw.trim());
    if (match == null) {
      return null;
    }

    final first = int.parse(match.group(1)!);
    final second = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    var hour = int.parse(match.group(4)!);
    final minute = int.parse(match.group(5)!);
    final secondOfMinute = int.tryParse(match.group(6) ?? '') ?? 0;
    final period = match.group(7)?.toUpperCase();
    final month = period == null ? second : first;
    final day = period == null ? first : second;

    if (period != null) {
      if (hour < 1 || hour > 12) {
        return null;
      }
      hour = hour % 12 + (period == 'PM' ? 12 : 0);
    }
    if (month < 1 ||
        month > 12 ||
        day < 1 ||
        day > 31 ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59 ||
        secondOfMinute < 0 ||
        secondOfMinute > 59) {
      return null;
    }

    final parsed = DateTime(year, month, day, hour, minute, secondOfMinute);
    if (parsed.year != year ||
        parsed.month != month ||
        parsed.day != day ||
        parsed.hour != hour ||
        parsed.minute != minute ||
        parsed.second != secondOfMinute) {
      return null;
    }
    return parsed;
  }

  static Map<String, Object?> _encodeEntryForLotus(
    LifeCounterHistoryEntry entry,
  ) {
    final lifeEvent = RegExp(
      r'^player: (\d+) • change: (-?\d+) • life: (-?\d+)$',
    ).firstMatch(entry.message);
    if (lifeEvent != null) {
      return <String, Object?>{
        'player': int.parse(lifeEvent.group(1)!),
        'change': int.parse(lifeEvent.group(2)!),
        'life': int.parse(lifeEvent.group(3)!),
        if (entry.occurredAt != null)
          'timestamp': entry.occurredAt!.millisecondsSinceEpoch,
        if (entry.occurredAt == null && entry.rawOccurredAt != null)
          'timestamp': entry.rawOccurredAt,
      };
    }

    return <String, Object?>{
      'message': entry.message,
      if (entry.occurredAt != null)
        'timestamp': entry.occurredAt!.millisecondsSinceEpoch,
      if (entry.occurredAt == null && entry.rawOccurredAt != null)
        'timestamp': entry.rawOccurredAt,
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
