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
}

enum LifeCounterHistoryEntrySource { currentGame, archive, fallback }

@immutable
class LifeCounterHistorySnapshot {
  const LifeCounterHistorySnapshot({
    required this.currentGameName,
    required this.currentGameEntries,
    required this.archiveEntries,
    required this.archivedGameCount,
    required this.lastTableEvent,
  });

  final String? currentGameName;
  final List<LifeCounterHistoryEntry> currentGameEntries;
  final List<LifeCounterHistoryEntry> archiveEntries;
  final int archivedGameCount;
  final String? lastTableEvent;

  int get currentGameEventCount => currentGameEntries.length;
  int get archivedEventCount => archiveEntries.length;
  bool get hasContent =>
      (lastTableEvent?.trim().isNotEmpty ?? false) ||
      currentGameEntries.isNotEmpty ||
      archiveEntries.isNotEmpty;

  factory LifeCounterHistorySnapshot.fromSources({
    LifeCounterSession? session,
    LotusStorageSnapshot? snapshot,
  }) {
    final currentGameMeta = _decodeSnapshotJson(
      snapshot?.values[_currentGameMetaKey],
    );
    final currentGameEntries = _extractEntries(
      _decodeSnapshotJson(snapshot?.values[_gameHistoryKey]),
      source: LifeCounterHistoryEntrySource.currentGame,
    );
    final archiveEntries = _extractArchiveEntries(
      _decodeSnapshotJson(snapshot?.values[_allGamesHistoryKey]),
    );
    final currentGameName = switch (currentGameMeta) {
      Map<dynamic, dynamic> meta => _readString(meta['name']),
      _ => null,
    };
    final lastTableEvent =
        session?.lastTableEvent?.trim().isEmpty ?? true
            ? null
            : session?.lastTableEvent?.trim();

    if (currentGameEntries.isEmpty && lastTableEvent != null) {
      return LifeCounterHistorySnapshot(
        currentGameName: currentGameName,
        currentGameEntries: [
          LifeCounterHistoryEntry(
            message: lastTableEvent,
            source: LifeCounterHistoryEntrySource.fallback,
          ),
        ],
        archiveEntries: archiveEntries,
        archivedGameCount: _countArchivedGames(
          _decodeSnapshotJson(snapshot?.values[_allGamesHistoryKey]),
        ),
        lastTableEvent: lastTableEvent,
      );
    }

    return LifeCounterHistorySnapshot(
      currentGameName: currentGameName,
      currentGameEntries: currentGameEntries,
      archiveEntries: archiveEntries,
      archivedGameCount: _countArchivedGames(
        _decodeSnapshotJson(snapshot?.values[_allGamesHistoryKey]),
      ),
      lastTableEvent: lastTableEvent,
    );
  }

  static const String _gameHistoryKey = 'gameHistory';
  static const String _allGamesHistoryKey = 'allGamesHistory';
  static const String _currentGameMetaKey = 'currentGameMeta';

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
}
