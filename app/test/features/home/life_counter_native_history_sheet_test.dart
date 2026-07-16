import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_history.dart';
import 'package:manaloom/features/home/life_counter/life_counter_history_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_native_history_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Host extends StatelessWidget {
  const _Host({
    required this.history,
    required this.onImportSubmitted,
    this.navigatorObservers = const <NavigatorObserver>[],
  });

  final LifeCounterHistorySnapshot history;
  final Future<bool> Function(String rawPayload) onImportSubmitted;
  final List<NavigatorObserver> navigatorObservers;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: navigatorObservers,
      home: Scaffold(
        body: Builder(
          builder:
              (context) => Center(
                child: ElevatedButton(
                  onPressed:
                      () => showLifeCounterNativeHistorySheet(
                        context,
                        history: history,
                        onImportSubmitted: onImportSubmitted,
                      ),
                  child: const Text('Open'),
                ),
              ),
        ),
      ),
    );
  }
}

class _PopCountingNavigatorObserver extends NavigatorObserver {
  int popCount = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popCount += 1;
    super.didPop(route, previousRoute);
  }
}

void main() {
  group('LifeCounterNativeHistorySheet', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets(
      'confirms destructive import and refreshes the open sheet after success',
      (tester) async {
        var importCalls = 0;
        const initialHistory = LifeCounterHistorySnapshot(
          currentGameName: 'Existing Game',
          currentGameMeta: null,
          currentGameEntries: [
            LifeCounterHistoryEntry(message: 'Existing event'),
          ],
          archiveEntries: [],
          archivedGameCount: 0,
          gameCounter: 1,
          lastTableEvent: 'Existing event',
        );

        await tester.pumpWidget(
          _Host(
            history: initialHistory,
            onImportSubmitted: (rawPayload) async {
              importCalls += 1;
              expect(rawPayload, 'replacement payload');
              await LifeCounterHistoryStore().save(
                const LifeCounterHistoryState(
                  currentGameName: 'Imported Game',
                  currentGameEntries: [
                    LifeCounterHistoryEntry(message: 'Imported event one'),
                    LifeCounterHistoryEntry(message: 'Imported event two'),
                  ],
                  archiveEntries: [
                    LifeCounterHistoryEntry(
                      message: 'Archived imported event',
                      source: LifeCounterHistoryEntrySource.archive,
                    ),
                  ],
                  archivedGames: [
                    LifeCounterArchivedGame(
                      name: 'Imported Archive',
                      entries: [
                        LifeCounterHistoryEntry(
                          message: 'Archived imported event',
                          source: LifeCounterHistoryEntrySource.archive,
                        ),
                      ],
                    ),
                  ],
                  archivedGameCount: 1,
                  lastTableEvent: 'Imported event two',
                ),
              );
              return true;
            },
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('Current game: Existing Game'), findsOneWidget);

        await tester.tap(
          find.byKey(const Key('life-counter-native-history-import')),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('life-counter-native-history-import-input')),
          'replacement payload',
        );
        await tester.tap(
          find.byKey(const Key('life-counter-native-history-import-confirm')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Replace existing history?'), findsOneWidget);
        await tester.tap(
          find.byKey(const Key('life-counter-native-history-replace-cancel')),
        );
        await tester.pumpAndSettle();
        expect(importCalls, 0);
        expect(
          find.byKey(const Key('life-counter-native-history-import-input')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const Key('life-counter-native-history-import-confirm')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('life-counter-native-history-replace-confirm')),
        );
        await tester.pumpAndSettle();

        expect(importCalls, 1);
        expect(find.text('Current game: Imported Game'), findsOneWidget);
        expect(find.text('Imported event one'), findsOneWidget);
        expect(find.text('Imported event two'), findsWidgets);
        expect(find.text('Existing event'), findsNothing);
      },
    );

    testWidgets('submits and closes the async import dialog only once', (
      tester,
    ) async {
      final result = Completer<bool>();
      final navigatorObserver = _PopCountingNavigatorObserver();
      var importCalls = 0;
      const emptyHistory = LifeCounterHistorySnapshot(
        currentGameName: null,
        currentGameMeta: null,
        currentGameEntries: [],
        archiveEntries: [],
        archivedGameCount: 0,
        gameCounter: 1,
        lastTableEvent: null,
      );

      await tester.pumpWidget(
        _Host(
          history: emptyHistory,
          navigatorObservers: [navigatorObserver],
          onImportSubmitted: (rawPayload) {
            importCalls += 1;
            expect(rawPayload, 'one payload');
            return result.future;
          },
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('life-counter-native-history-import')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('life-counter-native-history-import-input')),
        'one payload',
      );

      final confirm = find.byKey(
        const Key('life-counter-native-history-import-confirm'),
      );
      await tester.tap(confirm);
      await tester.tap(confirm);
      await tester.pump();

      expect(importCalls, 1);
      expect(navigatorObserver.popCount, 0);
      expect(
        find.byKey(const Key('life-counter-native-history-import-progress')),
        findsOneWidget,
      );
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

      result.complete(true);
      await tester.pumpAndSettle();

      expect(importCalls, 1);
      expect(navigatorObserver.popCount, 1);
      expect(confirm, findsNothing);
      expect(find.text('Life Counter History'), findsOneWidget);
    });
  });
}
