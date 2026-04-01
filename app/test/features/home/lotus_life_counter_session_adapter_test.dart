import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/lotus/lotus_life_counter_session_adapter.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot.dart';

void main() {
  group('LotusLifeCounterSessionAdapter', () {
    test('derives a canonical session from a compatible Lotus snapshot', () {
      final snapshot = LotusStorageSnapshot(
        values: {
          'playerCount': '4',
          'startingLife2P': '20',
          'startingLifeMP': '40',
          'layoutType': jsonEncode('portrait-portrait-portrait-portrait'),
          '__manaloom_player_special_states': jsonEncode([
            'none',
            'none',
            'decked_out',
            'answer_left',
          ]),
          '__manaloom_table_state': jsonEncode({
            'stormCount': 6,
            'monarchPlayer': 1,
            'initiativePlayer': 3,
            'lastPlayerRolls': [12, null, 4, 18],
            'lastHighRolls': [17, 8, null, 19],
            'firstPlayerIndex': 2,
          }),
          'turnTracker': jsonEncode({
            'isActive': true,
            'ongoingGame': true,
            'autoHighroll': true,
            'currentPlayerIndex': 3,
            'startingPlayerIndex': 1,
            'currentTurn': 7,
            'turnTimer': {'isActive': true, 'duration': 93, 'countDown': []},
          }),
          'players': jsonEncode([
            {
              'name': 'Player 1',
              'nickname': 'Archenemy',
              'life': 38,
              'background': '#123456',
              'backgroundImage': 'indexeddb://imageDatabase/images/10',
              'backgroundImagePartner': false,
              'alive': true,
              'partnerCommander': false,
              'counters': {
                'poison': 1,
                'energy': 5,
                'xp': 2,
                'tax-1': 4,
                'charge': 3,
              },
              'commanderDamage': [
                {
                  'player': 'Player 2',
                  'damage': {'commander1': 7},
                },
              ],
            },
            {
              'name': 'Player 2',
              'nickname': '',
              'life': 31,
              'background': '#654321',
              'backgroundImage': false,
              'backgroundImagePartner': 'indexeddb://imageDatabase/images/11',
              'alive': true,
              'partnerCommander': true,
              'counters': {
                'poison': 0,
                'energy': 1,
                'xp': 0,
                'tax-1': 2,
                'tax-2': 6,
                'rad': 1,
              },
              'commanderDamage': [],
            },
            {
              'name': 'Player 3',
              'life': 15,
              'alive': false,
              'partnerCommander': false,
              'counters': {'poison': 4, 'energy': 0, 'xp': 3},
              'commanderDamage': [
                {
                  'player': 'Player 4',
                  'damage': {'commander1': 3, 'commander2': 2},
                },
              ],
            },
            {
              'name': 'Player 4',
              'life': 22,
              'alive': false,
              'partnerCommander': false,
              'counters': {},
              'commanderDamage': [],
            },
          ]),
        },
      );

      final session = LotusLifeCounterSessionAdapter.tryBuildSession(snapshot);

      expect(session, isNotNull);
      expect(session!.playerCount, 4);
      expect(session.startingLifeTwoPlayer, 20);
      expect(session.startingLifeMultiPlayer, 40);
      expect(session.lives, const [38, 31, 15, 22]);
      expect(session.poison, const [1, 0, 4, 0]);
      expect(session.energy, const [5, 1, 0, 0]);
      expect(session.experience, const [2, 0, 3, 0]);
      expect(session.commanderCasts, const [2, 3, 0, 0]);
      expect(session.resolvedCommanderCastDetails, const [
        LifeCounterCommanderCastDetail(
          commanderOneCasts: 2,
          commanderTwoCasts: 0,
        ),
        LifeCounterCommanderCastDetail(
          commanderOneCasts: 1,
          commanderTwoCasts: 3,
        ),
        LifeCounterCommanderCastDetail.zero,
        LifeCounterCommanderCastDetail.zero,
      ]);
      expect(session.playerExtraCounters, const [
        {'charge': 3},
        {'rad': 1},
        {},
        {},
      ]);
      expect(session.resolvedPlayerAppearances[0], const LifeCounterPlayerAppearance(
        background: '#123456',
        nickname: 'Archenemy',
        backgroundImage: 'indexeddb://imageDatabase/images/10',
      ));
      expect(session.resolvedPlayerAppearances[1], const LifeCounterPlayerAppearance(
        background: '#654321',
        nickname: '',
        backgroundImagePartner: 'indexeddb://imageDatabase/images/11',
      ));
      expect(session.partnerCommanders, const [false, true, false, false]);
      expect(session.playerSpecialStates, const [
        LifeCounterPlayerSpecialState.none,
        LifeCounterPlayerSpecialState.none,
        LifeCounterPlayerSpecialState.deckedOut,
        LifeCounterPlayerSpecialState.answerLeft,
      ]);
      expect(session.commanderDamage[0][1], 7);
      expect(session.commanderDamage[2][3], 5);
      expect(
        session.resolvedCommanderDamageDetails[2][3],
        const LifeCounterCommanderDamageDetail(
          commanderOneDamage: 3,
          commanderTwoDamage: 2,
        ),
      );
      expect(session.firstPlayerIndex, 2);
      expect(session.turnTrackerActive, isTrue);
      expect(session.turnTrackerOngoingGame, isTrue);
      expect(session.turnTrackerAutoHighRoll, isTrue);
      expect(session.currentTurnPlayerIndex, 1);
      expect(session.currentTurnNumber, 7);
      expect(session.turnTimerActive, isTrue);
      expect(session.turnTimerSeconds, 93);
      expect(session.stormCount, 6);
      expect(session.monarchPlayer, 1);
      expect(session.initiativePlayer, 3);
      expect(session.lastPlayerRolls, const [12, null, 4, 18]);
      expect(session.lastHighRolls, const [17, 8, null, 19]);
    });

    test('returns null for snapshots without players payload', () {
      const snapshot = LotusStorageSnapshot(values: {'playerCount': '4'});

      final session = LotusLifeCounterSessionAdapter.tryBuildSession(snapshot);

      expect(session, isNull);
    });

    test('serializes canonical session back into Lotus-compatible storage', () {
      final values = LotusLifeCounterSessionAdapter.buildSnapshotValues(
        const LifeCounterSession(
          playerCount: 4,
          startingLifeTwoPlayer: 20,
          startingLifeMultiPlayer: 40,
          lives: [40, 31, 1, 23],
          poison: [0, 1, 2, 10],
          energy: [0, 5, 0, 1],
          experience: [0, 0, 4, 1],
          commanderCasts: [0, 2, 0, 1],
          commanderCastDetails: [
            LifeCounterCommanderCastDetail.zero,
            LifeCounterCommanderCastDetail(
              commanderOneCasts: 1,
              commanderTwoCasts: 3,
            ),
            LifeCounterCommanderCastDetail.zero,
            LifeCounterCommanderCastDetail(
              commanderOneCasts: 0,
              commanderTwoCasts: 1,
            ),
          ],
          playerExtraCounters: [
            {'charge': 3},
            {'rad': 1},
            {},
            {'tickets': 2},
          ],
          playerAppearances: [
            LifeCounterPlayerAppearance(
              background: '#123456',
              nickname: 'Archenemy',
              backgroundImage: 'indexeddb://imageDatabase/images/10',
            ),
            LifeCounterPlayerAppearance(
              background: '#654321',
              nickname: 'Two-Headed',
              backgroundImagePartner: 'indexeddb://imageDatabase/images/11',
            ),
            LifeCounterPlayerAppearance(background: '#111111'),
            LifeCounterPlayerAppearance(background: '#222222'),
          ],
          partnerCommanders: [false, true, false, false],
          playerSpecialStates: [
            LifeCounterPlayerSpecialState.none,
            LifeCounterPlayerSpecialState.none,
            LifeCounterPlayerSpecialState.deckedOut,
            LifeCounterPlayerSpecialState.answerLeft,
          ],
          lastPlayerRolls: [null, null, null, null],
          lastHighRolls: [null, null, null, null],
          commanderDamage: [
            [0, 7, 0, 0],
            [0, 0, 5, 0],
            [0, 0, 0, 3],
            [1, 0, 0, 0],
          ],
          commanderDamageDetails: [
            [
              LifeCounterCommanderDamageDetail.zero,
              LifeCounterCommanderDamageDetail(
                commanderOneDamage: 4,
                commanderTwoDamage: 3,
              ),
              LifeCounterCommanderDamageDetail.zero,
              LifeCounterCommanderDamageDetail.zero,
            ],
            [
              LifeCounterCommanderDamageDetail.zero,
              LifeCounterCommanderDamageDetail.zero,
              LifeCounterCommanderDamageDetail(
                commanderOneDamage: 5,
                commanderTwoDamage: 0,
              ),
              LifeCounterCommanderDamageDetail.zero,
            ],
            [
              LifeCounterCommanderDamageDetail.zero,
              LifeCounterCommanderDamageDetail.zero,
              LifeCounterCommanderDamageDetail.zero,
              LifeCounterCommanderDamageDetail(
                commanderOneDamage: 1,
                commanderTwoDamage: 2,
              ),
            ],
            [
              LifeCounterCommanderDamageDetail(
                commanderOneDamage: 1,
                commanderTwoDamage: 0,
              ),
              LifeCounterCommanderDamageDetail.zero,
              LifeCounterCommanderDamageDetail.zero,
              LifeCounterCommanderDamageDetail.zero,
            ],
          ],
          stormCount: 0,
          monarchPlayer: 2,
          initiativePlayer: 3,
          firstPlayerIndex: 1,
          turnTrackerActive: true,
          turnTrackerOngoingGame: true,
          turnTrackerAutoHighRoll: true,
          currentTurnPlayerIndex: 3,
          currentTurnNumber: 6,
          turnTimerActive: true,
          turnTimerSeconds: 45,
          lastTableEvent: null,
        ),
      );

      final players = jsonDecode(values['players']!) as List<dynamic>;
      final turnTracker =
          jsonDecode(values['turnTracker']!) as Map<String, dynamic>;

      expect(jsonDecode(values['playerCount']!), 4);
      expect(
        jsonDecode(values['layoutType']!),
        'portrait-portrait-portrait-portrait',
      );
      expect(players, hasLength(4));
      expect((players[1] as Map<String, dynamic>)['life'], 31);
      expect((players[0] as Map<String, dynamic>)['nickname'], 'Archenemy');
      expect((players[0] as Map<String, dynamic>)['background'], '#123456');
      expect(
        (players[0] as Map<String, dynamic>)['backgroundImage'],
        'indexeddb://imageDatabase/images/10',
      );
      expect(
        (players[1] as Map<String, dynamic>)['backgroundImagePartner'],
        'indexeddb://imageDatabase/images/11',
      );
      expect(
        ((players[1] as Map<String, dynamic>)['counters']
            as Map<String, dynamic>)['tax-1'],
        2,
      );
      expect(
        ((players[1] as Map<String, dynamic>)['counters']
            as Map<String, dynamic>)['tax-2'],
        6,
      );
      expect(
        ((players[0] as Map<String, dynamic>)['counters']
            as Map<String, dynamic>)['charge'],
        3,
      );
      expect(
        ((players[3] as Map<String, dynamic>)['counters']
            as Map<String, dynamic>)['tickets'],
        2,
      );
      expect((players[2] as Map<String, dynamic>)['alive'], isFalse);
      expect((players[1] as Map<String, dynamic>)['partnerCommander'], isTrue);
      expect(
        ((players[0] as Map<String, dynamic>)['commanderDamage'] as List)
            .firstWhere(
              (entry) =>
                  (entry as Map<String, dynamic>)['player'] == 'Player 2',
            )['damage'],
        {'commander1': 4, 'commander2': 3},
      );
      expect(turnTracker['isActive'], isTrue);
      expect(turnTracker['ongoingGame'], isTrue);
      expect(turnTracker['autoHighroll'], isTrue);
      expect(turnTracker['currentPlayerIndex'], 2);
      expect(turnTracker['startingPlayerIndex'], 3);
      expect(turnTracker['currentTurn'], 6);
      expect(
        (turnTracker['turnTimer'] as Map<String, dynamic>)['isActive'],
        isTrue,
      );
      expect(
        (turnTracker['turnTimer'] as Map<String, dynamic>)['duration'],
        45,
      );
      expect(jsonDecode(values['__manaloom_player_special_states']!), [
        'none',
        'none',
        'decked_out',
        'answer_left',
      ]);
      expect(jsonDecode(values['__manaloom_table_state']!), {
        'stormCount': 0,
        'monarchPlayer': 2,
        'initiativePlayer': 3,
        'lastPlayerRolls': [null, null, null, null],
        'lastHighRolls': [null, null, null, null],
        'firstPlayerIndex': 1,
      });
    });

    test('uses Lotus-compatible layout keys for different player counts', () {
      final twoPlayerValues =
          LotusLifeCounterSessionAdapter.buildSnapshotValues(
            LifeCounterSession.initial(playerCount: 2),
          );
      final fivePlayerValues =
          LotusLifeCounterSessionAdapter.buildSnapshotValues(
            LifeCounterSession.initial(playerCount: 5),
          );
      final sixPlayerValues =
          LotusLifeCounterSessionAdapter.buildSnapshotValues(
            LifeCounterSession.initial(playerCount: 6),
          );

      expect(jsonDecode(twoPlayerValues['layoutType']!), 'portrait-portrait');
      expect(
        jsonDecode(fivePlayerValues['layoutType']!),
        'portrait-portrait-portrait-portrait-landscape',
      );
      expect(
        jsonDecode(sixPlayerValues['layoutType']!),
        'portrait-portrait-portrait-portrait-portrait-portrait',
      );
    });

    test('normalizes turn tracker bootstrap to the next alive player', () {
      final values = LotusLifeCounterSessionAdapter.buildSnapshotValues(
        const LifeCounterSession(
          playerCount: 4,
          startingLifeTwoPlayer: 20,
          startingLifeMultiPlayer: 40,
          lives: [40, 31, 1, 23],
          poison: [0, 1, 2, 10],
          energy: [0, 5, 0, 1],
          experience: [0, 0, 4, 1],
          commanderCasts: [0, 2, 0, 1],
          partnerCommanders: [false, false, false, false],
          playerSpecialStates: [
            LifeCounterPlayerSpecialState.none,
            LifeCounterPlayerSpecialState.deckedOut,
            LifeCounterPlayerSpecialState.answerLeft,
            LifeCounterPlayerSpecialState.none,
          ],
          lastPlayerRolls: [null, null, null, null],
          lastHighRolls: [null, null, null, null],
          commanderDamage: [
            [0, 7, 0, 0],
            [0, 0, 5, 0],
            [0, 0, 0, 3],
            [1, 0, 0, 0],
          ],
          stormCount: 0,
          monarchPlayer: null,
          initiativePlayer: null,
          firstPlayerIndex: 1,
          turnTrackerActive: true,
          turnTrackerOngoingGame: true,
          turnTrackerAutoHighRoll: false,
          currentTurnPlayerIndex: 1,
          currentTurnNumber: 4,
          turnTimerActive: true,
          turnTimerSeconds: 12,
          lastTableEvent: null,
        ),
      );

      final turnTracker =
          jsonDecode(values['turnTracker']!) as Map<String, dynamic>;

      expect(turnTracker['startingPlayerIndex'], 3);
      expect(turnTracker['currentPlayerIndex'], 2);
    });

    test('skips lethal players when serializing turn tracker payloads', () {
      final values = LotusLifeCounterSessionAdapter.buildTurnTrackerSnapshotValues(
        const LifeCounterSession(
          playerCount: 4,
          startingLifeTwoPlayer: 20,
          startingLifeMultiPlayer: 40,
          lives: [0, 40, 40, 40],
          poison: [0, 0, 0, 0],
          energy: [0, 0, 0, 0],
          experience: [0, 0, 0, 0],
          commanderCasts: [0, 0, 0, 0],
          partnerCommanders: [false, false, false, false],
          playerSpecialStates: [
            LifeCounterPlayerSpecialState.none,
            LifeCounterPlayerSpecialState.none,
            LifeCounterPlayerSpecialState.none,
            LifeCounterPlayerSpecialState.none,
          ],
          lastPlayerRolls: [null, null, null, null],
          lastHighRolls: [null, null, null, null],
          commanderDamage: [
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
          ],
          stormCount: 0,
          monarchPlayer: null,
          initiativePlayer: null,
          firstPlayerIndex: 0,
          turnTrackerActive: true,
          turnTrackerOngoingGame: true,
          turnTrackerAutoHighRoll: false,
          currentTurnPlayerIndex: 0,
          currentTurnNumber: 1,
          turnTimerActive: false,
          turnTimerSeconds: 0,
          lastTableEvent: null,
        ),
      );

      final turnTracker =
          jsonDecode(values['turnTracker']!) as Map<String, dynamic>;

      expect(turnTracker['startingPlayerIndex'], 2);
      expect(turnTracker['currentPlayerIndex'], 3);
    });

    test('falls back to answer-left when Lotus only exposes alive false', () {
      final snapshot = LotusStorageSnapshot(
        values: {
          'playerCount': '2',
          'startingLife2P': '20',
          'startingLifeMP': '40',
          'layoutType': jsonEncode('portrait-portrait'),
          'players': jsonEncode([
            {
              'name': 'Player 1',
              'life': 17,
              'alive': true,
              'partnerCommander': false,
              'counters': <String, Object?>{},
              'commanderDamage': <Object?>[],
            },
            {
              'name': 'Player 2',
              'life': 0,
              'alive': false,
              'partnerCommander': false,
              'counters': <String, Object?>{},
              'commanderDamage': <Object?>[],
            },
          ]),
        },
      );

      final session = LotusLifeCounterSessionAdapter.tryBuildSession(snapshot);

      expect(session, isNotNull);
      expect(session!.playerSpecialStates, const [
        LifeCounterPlayerSpecialState.none,
        LifeCounterPlayerSpecialState.answerLeft,
      ]);
    });
  });
}
