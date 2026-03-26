import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../cards/providers/card_provider.dart';
import '../cards/screens/card_detail_screen.dart';
import '../decks/models/deck_card_item.dart';

/// Snapshot of all player state for undo support.
class _GameSnapshot {
  final List<int> lives;
  final List<int> poison;
  final List<int> energy;
  final List<int> experience;
  final List<int> commanderCasts;
  final List<_PlayerSpecialState> playerSpecialStates;
  final List<int?> lastPlayerRolls;
  final List<int?> lastHighRolls;
  final List<List<int>> commanderDamage;
  final int stormCount;
  final int? monarchPlayer;
  final int? initiativePlayer;
  final int? firstPlayerIndex;
  final String? lastTableEvent;

  _GameSnapshot({
    required this.lives,
    required this.poison,
    required this.energy,
    required this.experience,
    required this.commanderCasts,
    required this.playerSpecialStates,
    required this.lastPlayerRolls,
    required this.lastHighRolls,
    required this.commanderDamage,
    required this.stormCount,
    required this.monarchPlayer,
    required this.initiativePlayer,
    required this.firstPlayerIndex,
    required this.lastTableEvent,
  });
}

enum _PlayerSpecialState { none, deckedOut, answerLeft }

/// Contador de vida completo para partidas de Magic: The Gathering.
///
/// Suporta 2 a 6 jogadores, com:
/// - Vida (life total)
/// - Veneno / Poison counters (10 = derrota)
/// - Dano de Comandante por oponente (21 = derrota)
/// - Energy e Experience counters
/// - HistÃ³rico com undo
class LifeCounterScreen extends StatefulWidget {
  final Random? randomOverride;
  final bool initialHubExpanded;

  const LifeCounterScreen({
    super.key,
    this.randomOverride,
    this.initialHubExpanded = false,
  });

  @override
  State<LifeCounterScreen> createState() => _LifeCounterScreenState();
}

class _LifeCounterScreenState extends State<LifeCounterScreen> {
  static const _sessionPrefsKey = 'life_counter_session_v1';
  static const double _tableGutter = 3;
  final Random _runtimeRandom = Random();

  int _playerCount = 2;
  int _startingLifeTwoPlayer = 20;
  int _startingLifeMultiPlayer = 40;
  bool _isHubExpanded = false;

  late List<int> _lives;
  late List<int> _poison;
  late List<int> _energy;
  late List<int> _experience;
  late List<int> _commanderCasts;
  late List<_PlayerSpecialState> _playerSpecialStates;
  late List<int?> _lastPlayerRolls;
  late List<int?> _lastHighRolls;
  Set<int> _highRollWinners = const <int>{};
  // _commanderDamage[target][source] = damage dealt by source's commander to target
  late List<List<int>> _commanderDamage;
  int _stormCount = 0;
  int? _monarchPlayer;
  int? _initiativePlayer;
  int? _firstPlayerIndex;
  String? _lastTableEvent;

  final List<_GameSnapshot> _history = [];
  static const int _maxHistory = 50;

  static const _playerColors = [
    Color(0xFFFFB51E),
    Color(0xFFFF0A5B),
    Color(0xFFCF7AEF),
    Color(0xFF4B57FF),
    Color(0xFF44E063),
    Color(0xFF40B9FF),
  ];

  static const _playerLabels = [
    'Jogador 1',
    'Jogador 2',
    'Jogador 3',
    'Jogador 4',
    'Jogador 5',
    'Jogador 6',
  ];

  Random get _random => widget.randomOverride ?? _runtimeRandom;
  int get _startingLife =>
      _playerCount == 2 ? _startingLifeTwoPlayer : _startingLifeMultiPlayer;

  @override
  void initState() {
    super.initState();
    _isHubExpanded = widget.initialHubExpanded;
    _initAll();
    _restorePersistedSession();
  }

  void _initAll() {
    _lives = List.generate(_playerCount, (_) => _startingLife);
    _poison = List.generate(_playerCount, (_) => 0);
    _energy = List.generate(_playerCount, (_) => 0);
    _experience = List.generate(_playerCount, (_) => 0);
    _commanderCasts = List.generate(_playerCount, (_) => 0);
    _playerSpecialStates = List.generate(
      _playerCount,
      (_) => _PlayerSpecialState.none,
    );
    _lastPlayerRolls = List.generate(_playerCount, (_) => null);
    _lastHighRolls = List.generate(_playerCount, (_) => null);
    _highRollWinners = const <int>{};
    _commanderDamage = List.generate(
      _playerCount,
      (_) => List.generate(_playerCount, (_) => 0),
    );
    _stormCount = 0;
    _monarchPlayer = null;
    _initiativePlayer = null;
    _firstPlayerIndex = null;
    _lastTableEvent = null;
    _history.clear();
  }

  void _saveSnapshot() {
    _history.add(
      _GameSnapshot(
        lives: List.of(_lives),
        poison: List.of(_poison),
        energy: List.of(_energy),
        experience: List.of(_experience),
        commanderCasts: List.of(_commanderCasts),
        playerSpecialStates: List.of(_playerSpecialStates),
        lastPlayerRolls: List.of(_lastPlayerRolls),
        lastHighRolls: List.of(_lastHighRolls),
        commanderDamage: _commanderDamage.map((row) => List.of(row)).toList(),
        stormCount: _stormCount,
        monarchPlayer: _monarchPlayer,
        initiativePlayer: _initiativePlayer,
        firstPlayerIndex: _firstPlayerIndex,
        lastTableEvent: _lastTableEvent,
      ),
    );
    if (_history.length > _maxHistory) {
      _history.removeAt(0);
    }
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _saveSnapshot();
    setState(() {
      _initAll();
    });
    _persistSession();
  }

  void _changeLife(int player, int delta) {
    HapticFeedback.selectionClick();
    _saveSnapshot();
    setState(() {
      _lives[player] += delta;
    });
    _persistSession();
  }

  void _setLifeTotal(int player, int life) {
    final normalizedLife = life.clamp(0, 999);
    HapticFeedback.mediumImpact();
    _saveSnapshot();
    setState(() {
      _lives[player] = normalizedLife;
      _lastTableEvent =
          '${_playerLabels[player]} ajustado para $normalizedLife de vida';
    });
    _persistSession();
  }

  void _changePoison(int player, int delta) {
    HapticFeedback.selectionClick();
    _saveSnapshot();
    setState(() {
      _poison[player] = (_poison[player] + delta).clamp(0, 99);
    });
    _persistSession();
  }

  void _changeEnergy(int player, int delta) {
    HapticFeedback.selectionClick();
    _saveSnapshot();
    setState(() {
      _energy[player] = (_energy[player] + delta).clamp(0, 999);
    });
    _persistSession();
  }

  void _changeExperience(int player, int delta) {
    HapticFeedback.selectionClick();
    _saveSnapshot();
    setState(() {
      _experience[player] = (_experience[player] + delta).clamp(0, 999);
    });
    _persistSession();
  }

  void _changeCommanderCasts(int player, int delta) {
    HapticFeedback.selectionClick();
    _saveSnapshot();
    setState(() {
      _commanderCasts[player] = (_commanderCasts[player] + delta).clamp(0, 21);
    });
    _persistSession();
  }

  void _changeCommanderDamage(int target, int source, int delta) {
    HapticFeedback.selectionClick();
    _saveSnapshot();
    setState(() {
      _commanderDamage[target][source] =
          (_commanderDamage[target][source] + delta).clamp(0, 99);
    });
    _persistSession();
  }

  void _changeStorm(int delta) {
    HapticFeedback.selectionClick();
    _saveSnapshot();
    setState(() {
      _stormCount = (_stormCount + delta).clamp(0, 999);
    });
    _persistSession();
  }

  void _resetStorm() {
    HapticFeedback.selectionClick();
    _saveSnapshot();
    setState(() {
      _stormCount = 0;
    });
    _persistSession();
  }

  void _setMonarchPlayer(int? playerIndex) {
    HapticFeedback.selectionClick();
    _saveSnapshot();
    setState(() {
      _monarchPlayer = playerIndex;
    });
    _persistSession();
  }

  void _setInitiativePlayer(int? playerIndex) {
    HapticFeedback.selectionClick();
    _saveSnapshot();
    setState(() {
      _initiativePlayer = playerIndex;
    });
    _persistSession();
  }

  void _setFirstPlayerIndex(int? playerIndex) {
    HapticFeedback.selectionClick();
    _saveSnapshot();
    setState(() {
      _firstPlayerIndex = playerIndex;
      if (playerIndex != null) {
        _lastTableEvent = 'Primeiro jogador: ${_playerLabels[playerIndex]}';
      }
    });
    _persistSession();
  }

  String _rollCoinFlip() {
    HapticFeedback.mediumImpact();
    late final String result;
    _saveSnapshot();
    setState(() {
      result = 'Moeda: ${_random.nextBool() ? 'Cara' : 'Coroa'}';
      _lastTableEvent = result;
    });
    _persistSession();
    return result;
  }

  String _rollD20() {
    HapticFeedback.mediumImpact();
    late final String result;
    _saveSnapshot();
    setState(() {
      result = 'D20: ${_random.nextInt(20) + 1}';
      _lastTableEvent = result;
    });
    _persistSession();
    return result;
  }

  String _rollPlayerD20(int player) {
    HapticFeedback.mediumImpact();
    late final String result;
    late final int value;
    _saveSnapshot();
    setState(() {
      value = _random.nextInt(20) + 1;
      _lastPlayerRolls[player] = value;
      result = '${_playerLabels[player]} rolou D20: $value';
      _lastTableEvent = result;
    });
    _persistSession();
    return result;
  }

  Set<int> _deriveHighRollWinners(List<int?> values) {
    final available = values.whereType<int>().toList();
    if (available.isEmpty) return const <int>{};
    final highest = available.reduce(max);
    return {
      for (int i = 0; i < values.length; i++)
        if (values[i] != null && values[i] == highest) i,
    };
  }

  Map<int, int> _runHighRoll({
    Set<int>? participants,
    bool tieBreaker = false,
  }) {
    HapticFeedback.mediumImpact();
    final activePlayers = participants ?? {
      for (int i = 0; i < _playerCount; i++) i,
    };
    final results = <int, int>{
      for (final player in activePlayers) player: _random.nextInt(20) + 1,
    };
    final winners = _deriveHighRollWinners(
      List<int?>.generate(
        _playerCount,
        (i) => activePlayers.contains(i) ? results[i] : null,
      ),
    );

    _saveSnapshot();
    setState(() {
      _lastHighRolls = List<int?>.generate(
        _playerCount,
        (i) => activePlayers.contains(i) ? results[i] : null,
      );
      _highRollWinners = winners;
      if (winners.length == 1) {
        final winner = winners.first;
        _firstPlayerIndex = winner;
        _lastTableEvent =
            '${tieBreaker ? 'Desempate do High Roll' : 'High Roll'}: ${_playerLabels[winner]} venceu com ${results[winner]}';
      } else {
        final highest = winners
            .map((index) => results[index]!)
            .fold<int>(0, max);
        _lastTableEvent =
            '${tieBreaker ? 'Desempate do High Roll' : 'High Roll'} empatado em $highest entre ${winners.map((i) => _playerLabels[i]).join(', ')}';
      }
    });
    _persistSession();
    return results;
  }

  Map<int, int> _runOrRerollHighRoll() {
    if (_highRollWinners.length > 1) {
      return _runHighRoll(
        participants: Set<int>.from(_highRollWinners),
        tieBreaker: true,
      );
    }
    return _runHighRoll();
  }

  int _rollFirstPlayer() {
    HapticFeedback.mediumImpact();
    final chosen = _random.nextInt(_playerCount);
    _saveSnapshot();
    setState(() {
      _firstPlayerIndex = chosen;
      _lastTableEvent = 'Primeiro jogador: ${_playerLabels[chosen]}';
    });
    _persistSession();
    return chosen;
  }

  void _togglePlayerDefeated(int player) {
    if (_playerHasTakeoverState(player)) {
      _revivePlayer(player);
      return;
    }
    _markPlayerKnockedOut(player);
  }

  bool _playerHasTakeoverState(int player) {
    return _playerSpecialStates[player] != _PlayerSpecialState.none ||
        _lives[player] <= 0 ||
        _poison[player] >= 10 ||
        _commanderDamage[player].any((damage) => damage >= 21);
  }

  void _markPlayerKnockedOut(int player) {
    HapticFeedback.mediumImpact();
    _saveSnapshot();
    setState(() {
      _playerSpecialStates[player] = _PlayerSpecialState.none;
      _lives[player] = 0;
      _lastTableEvent = '${_playerLabels[player]} foi nocauteado';
    });
    _persistSession();
  }

  void _markPlayerDeckedOut(int player) {
    HapticFeedback.mediumImpact();
    _saveSnapshot();
    setState(() {
      _playerSpecialStates[player] = _PlayerSpecialState.deckedOut;
      _lastTableEvent = '${_playerLabels[player]} ficou sem grimorio';
    });
    _persistSession();
  }

  void _markPlayerAnswerLeft(int player) {
    HapticFeedback.mediumImpact();
    _saveSnapshot();
    setState(() {
      _playerSpecialStates[player] = _PlayerSpecialState.answerLeft;
      _lastTableEvent = '${_playerLabels[player]} deixou a mesa';
    });
    _persistSession();
  }

  void _revivePlayer(int player) {
    HapticFeedback.mediumImpact();
    _saveSnapshot();
    setState(() {
      _playerSpecialStates[player] = _PlayerSpecialState.none;
      _lives[player] = _startingLife;
      _poison[player] = 0;
      _commanderDamage[player] = List<int>.filled(_playerCount, 0);
      _lastTableEvent =
          '${_playerLabels[player]} voltou com $_startingLife de vida';
    });
    _persistSession();
  }

  void _setPlayerCount(int count) {
    setState(() {
      _playerCount = count;
      _initAll();
    });
    _persistSession();
  }

  void _setTwoPlayerStartingLife(int life) {
    setState(() {
      _startingLifeTwoPlayer = life;
      _initAll();
    });
    _persistSession();
  }

  void _setMultiPlayerStartingLife(int life) {
    setState(() {
      _startingLifeMultiPlayer = life;
      _initAll();
    });
    _persistSession();
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'player_count': _playerCount,
      'starting_life': _startingLife,
      'starting_life_two_player': _startingLifeTwoPlayer,
      'starting_life_multi_player': _startingLifeMultiPlayer,
      'lives': _lives,
      'poison': _poison,
      'energy': _energy,
      'experience': _experience,
      'commander_casts': _commanderCasts,
      'player_special_states':
          _playerSpecialStates.map(_encodePlayerSpecialState).toList(),
      'last_player_rolls': _lastPlayerRolls,
      'last_high_rolls': _lastHighRolls,
      'commander_damage': _commanderDamage,
      'storm_count': _stormCount,
      'monarch_player': _monarchPlayer,
      'initiative_player': _initiativePlayer,
      'first_player_index': _firstPlayerIndex,
      'last_table_event': _lastTableEvent,
    };
    await prefs.setString(_sessionPrefsKey, jsonEncode(payload));
  }

  Future<void> _restorePersistedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionPrefsKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final payload = decoded.cast<String, dynamic>();
      final playerCount = (payload['player_count'] as num?)?.toInt();
      final startingLife = (payload['starting_life'] as num?)?.toInt();
      final startingLifeTwoPlayer =
          (payload['starting_life_two_player'] as num?)?.toInt();
      final startingLifeMultiPlayer =
          (payload['starting_life_multi_player'] as num?)?.toInt();
      if (playerCount == null || playerCount < 2 || playerCount > 6) {
        return;
      }
      final restoredTwoPlayerLife =
          startingLifeTwoPlayer ??
          (playerCount == 2 ? (startingLife ?? 20) : 20);
      final restoredMultiPlayerLife =
          startingLifeMultiPlayer ??
          (playerCount > 2 ? (startingLife ?? 40) : 40);

      final lives = _readIntList(payload['lives'], playerCount);
      final poison = _readIntList(payload['poison'], playerCount);
      final energy = _readIntList(payload['energy'], playerCount);
      final experience = _readIntList(payload['experience'], playerCount);
      final commanderCasts = _readIntList(
        payload['commander_casts'],
        playerCount,
      );
      final playerSpecialStates = _readPlayerSpecialStateList(
        payload['player_special_states'],
        playerCount,
      );
      final lastPlayerRolls = _readNullableIntList(
        payload['last_player_rolls'],
        playerCount,
      );
      final lastHighRolls = _readNullableIntList(
        payload['last_high_rolls'],
        playerCount,
      );
      final commanderDamage = _readMatrix(
        payload['commander_damage'],
        playerCount,
      );
      final stormCount = (payload['storm_count'] as num?)?.toInt() ?? 0;
      final monarchPlayer = _readOptionalPlayerIndex(
        payload['monarch_player'],
        playerCount,
      );
      final initiativePlayer = _readOptionalPlayerIndex(
        payload['initiative_player'],
        playerCount,
      );
      final firstPlayerIndex = _readOptionalPlayerIndex(
        payload['first_player_index'],
        playerCount,
      );
      final lastTableEvent = payload['last_table_event'] as String?;
      if (lives == null ||
          poison == null ||
          energy == null ||
          experience == null ||
          commanderCasts == null ||
          playerSpecialStates == null ||
          lastPlayerRolls == null ||
          lastHighRolls == null ||
          commanderDamage == null) {
        return;
      }

      if (!mounted) return;
      setState(() {
        _playerCount = playerCount;
        _startingLifeTwoPlayer = restoredTwoPlayerLife;
        _startingLifeMultiPlayer = restoredMultiPlayerLife;
        _lives = lives;
        _poison = poison;
        _energy = energy;
        _experience = experience;
        _commanderCasts = commanderCasts;
        _playerSpecialStates = playerSpecialStates;
        _lastPlayerRolls = lastPlayerRolls;
        _lastHighRolls = lastHighRolls;
        _highRollWinners = _deriveHighRollWinners(lastHighRolls);
        _commanderDamage = commanderDamage;
        _stormCount = stormCount.clamp(0, 999);
        _monarchPlayer = monarchPlayer;
        _initiativePlayer = initiativePlayer;
        _firstPlayerIndex = firstPlayerIndex;
        _lastTableEvent = lastTableEvent;
        _history.clear();
      });
    } catch (_) {
      // Ignora sessÃ£o invÃ¡lida sem travar a tela.
    }
  }

  List<int>? _readIntList(dynamic value, int expectedLength) {
    if (value is! List || value.length != expectedLength) return null;
    final parsed = value.map((item) => (item as num?)?.toInt()).toList();
    if (parsed.any((item) => item == null)) return null;
    return parsed.cast<int>();
  }

  List<int?>? _readNullableIntList(dynamic value, int expectedLength) {
    if (value == null) {
      return List<int?>.generate(expectedLength, (_) => null);
    }
    if (value is! List || value.length != expectedLength) return null;
    return value.map((item) => (item as num?)?.toInt()).toList();
  }

  List<List<int>>? _readMatrix(dynamic value, int expectedLength) {
    if (value is! List || value.length != expectedLength) return null;
    final rows = <List<int>>[];
    for (final row in value) {
      final parsed = _readIntList(row, expectedLength);
      if (parsed == null) return null;
      rows.add(parsed);
    }
    return rows;
  }

  int? _readOptionalPlayerIndex(dynamic value, int playerCount) {
    if (value == null) return null;
    final parsed = (value as num?)?.toInt();
    if (parsed == null || parsed < 0 || parsed >= playerCount) return null;
    return parsed;
  }

  Future<void> _showTableOverlayDialog({
    required String barrierLabel,
    required WidgetBuilder builder,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: barrierLabel,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      pageBuilder: (ctx, _, __) => builder(ctx),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        final opacity = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final scale = Tween<double>(
          begin: 0.94,
          end: 1,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );
        return FadeTransition(
          opacity: opacity,
          child: SlideTransition(
            position: slide,
            child: ScaleTransition(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
    );
  }

  void _showSettingsDialog() {
    if (_isHubExpanded) {
      setState(() {
        _isHubExpanded = false;
      });
    }
    _showTableOverlayDialog(
      barrierLabel: 'Fechar configuraÃ§Ãµes',
        builder:
          (ctx) => _SettingsSheet(
            twoPlayerStartingLife: _startingLifeTwoPlayer,
            multiPlayerStartingLife: _startingLifeMultiPlayer,
            onTwoPlayerStartingLifeChanged: (life) {
              _setTwoPlayerStartingLife(life);
            },
            onMultiPlayerStartingLifeChanged: (life) {
              _setMultiPlayerStartingLife(life);
            },
          ),
    );
  }

  void _showPlayersDialog() {
    if (_isHubExpanded) {
      setState(() {
        _isHubExpanded = false;
      });
    }
    _showTableOverlayDialog(
      barrierLabel: 'Fechar seleÃ§Ã£o de jogadores',
      builder:
          (ctx) => _PlayersOverlay(
            selectedPlayerCount: _playerCount,
            onSelected: (count) {
              _setPlayerCount(count);
              Navigator.of(ctx).pop();
            },
          ),
    );
  }

  void _showHistoryDialog() {
    _showTableOverlayDialog(
      barrierLabel: 'Fechar histÃ³rico',
      builder:
          (ctx) => _HistoryOverlay(
            lastTableEvent: _lastTableEvent,
            snapshotCount: _history.length,
          ),
    );
  }

  void _showCardSearchDialog() {
    _showTableOverlayDialog(
      barrierLabel: 'Fechar busca de cartas',
      builder: (ctx) => const _CardSearchOverlay(),
    );
  }

  void _showDiceDialog() {
    if (_isHubExpanded) {
      setState(() {
        _isHubExpanded = false;
      });
    }
    _showTableOverlayDialog(
      barrierLabel: 'Fechar dice',
      builder:
          (ctx) => _DiceOverlay(
            hasPendingHighRollTie: _highRollWinners.length > 1,
            lastTableEvent: _lastTableEvent,
            onRollCoin: () {
              _rollCoinFlip();
            },
            onRollD20: () {
              _rollD20();
            },
            onRollFirstPlayer: () {
              _rollFirstPlayer();
            },
            onHighRoll: () {
              _runOrRerollHighRoll();
            },
          ),
    );
  }

  void _showTableToolsSheet() {
    if (_isHubExpanded) {
      setState(() {
        _isHubExpanded = false;
      });
    }
    _showTableOverlayDialog(
      barrierLabel: 'Fechar ferramentas da mesa',
      builder:
          (ctx) => _TableToolsSheet(
            playerCount: _playerCount,
            playerLabels: _playerLabels,
            stormCount: _stormCount,
            monarchPlayer: _monarchPlayer,
            initiativePlayer: _initiativePlayer,
            firstPlayerIndex: _firstPlayerIndex,
            lastTableEvent: _lastTableEvent,
            onStormChanged: _changeStorm,
            onStormReset: _resetStorm,
            onMonarchChanged: _setMonarchPlayer,
            onInitiativeChanged: _setInitiativePlayer,
            onFirstPlayerChanged: _setFirstPlayerIndex,
            onRollCoinFlip: _rollCoinFlip,
            onRollD20: _rollD20,
            onRollFirstPlayer: _rollFirstPlayer,
            initialHighRollResults: {
              for (int i = 0; i < _playerCount; i++)
                if (_lastHighRolls[i] != null) i: _lastHighRolls[i]!,
            },
            initialHighRollWinners: _highRollWinners,
            onRunHighRoll: _runOrRerollHighRoll,
          ),
    );
  }

  void _showCountersDialog(int playerIndex) {
    _showTableOverlayDialog(
      barrierLabel: 'Fechar contadores',
      builder:
          (ctx) => _CountersOverlay(
            playerIndex: playerIndex,
            playerCount: _playerCount,
            playerColor: _playerColors[playerIndex],
            playerLabel: _playerLabels[playerIndex],
            initialPoison: _poison[playerIndex],
            initialEnergy: _energy[playerIndex],
            initialExperience: _experience[playerIndex],
            initialCommanderCasts: _commanderCasts[playerIndex],
            initialCommanderDamage: List.of(_commanderDamage[playerIndex]),
            playerColors: _playerColors,
            playerLabels: _playerLabels,
            onPoisonChanged: (delta) => _changePoison(playerIndex, delta),
            onEnergyChanged: (delta) => _changeEnergy(playerIndex, delta),
            onExperienceChanged:
                (delta) => _changeExperience(playerIndex, delta),
            onCommanderCastsChanged:
                (delta) => _changeCommanderCasts(playerIndex, delta),
            onCommanderDamageChanged:
                (source, delta) =>
                    _changeCommanderDamage(playerIndex, source, delta),
          ),
    );
  }

  List<_PlayerSpecialState>? _readPlayerSpecialStateList(
    dynamic value,
    int expectedLength,
  ) {
    if (value == null) {
      return List<_PlayerSpecialState>.generate(
        expectedLength,
        (_) => _PlayerSpecialState.none,
      );
    }
    if (value is! List || value.length != expectedLength) return null;
    final parsed = <_PlayerSpecialState>[];
    for (final item in value) {
      if (item is! String) return null;
      parsed.add(_decodePlayerSpecialState(item));
    }
    return parsed;
  }

  String _encodePlayerSpecialState(_PlayerSpecialState state) {
    switch (state) {
      case _PlayerSpecialState.none:
        return 'none';
      case _PlayerSpecialState.deckedOut:
        return 'decked_out';
      case _PlayerSpecialState.answerLeft:
        return 'answer_left';
    }
  }

  _PlayerSpecialState _decodePlayerSpecialState(String value) {
    switch (value) {
      case 'decked_out':
        return _PlayerSpecialState.deckedOut;
      case 'answer_left':
        return _PlayerSpecialState.answerLeft;
      default:
        return _PlayerSpecialState.none;
    }
  }

  void _showCommanderDamageQuickDialog(int playerIndex) {
    _showTableOverlayDialog(
      barrierLabel: 'Fechar dano de comandante rapido',
      builder:
          (ctx) => _CommanderDamageQuickOverlay(
            playerIndex: playerIndex,
            playerCount: _playerCount,
            playerLabel: _playerLabels[playerIndex],
            initialCommanderDamage: List.of(_commanderDamage[playerIndex]),
            playerColors: _playerColors,
            playerLabels: _playerLabels,
            onCommanderDamageChanged:
                (source, delta) =>
                    _changeCommanderDamage(playerIndex, source, delta),
          ),
    );
  }

  void _showSetLifeDialog(int playerIndex) {
    _showTableOverlayDialog(
      barrierLabel: 'Fechar set life',
      builder:
          (ctx) => _BenchmarkSetLifeOverlay(
            playerLabel: _playerLabels[playerIndex],
            initialLife: _lives[playerIndex],
            onApply: (life) {
              _setLifeTotal(playerIndex, life);
              Navigator.of(ctx).pop();
            },
          ),
    );
  }

  int _quarterTurnsForSeat(int playerIndex) {
    if (_playerCount == 2) {
      return playerIndex == 0 ? 2 : 0;
    }
    if (_playerCount == 5) {
      switch (playerIndex) {
        case 0:
          return 2;
        case 1:
        case 3:
          return 1;
        default:
          return 3;
      }
    }
    if (_playerCount == 6) {
      switch (playerIndex) {
        case 0:
          return 2;
        case 5:
          return 0;
        case 1:
        case 3:
          return 1;
        default:
          return 3;
      }
    }
    return playerIndex.isEven ? 1 : 3;
  }

  Alignment get _hubAlignmentForLayout {
    switch (_playerCount) {
      case 5:
        return const Alignment(0, 0.12);
      case 6:
        return const Alignment(0, 0.04);
      default:
        return Alignment.center;
    }
  }

  double get _hubScaleFactorForLayout {
    switch (_playerCount) {
      case 5:
        return 0.9;
      case 6:
        return 0.82;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(2, 2, 2, 4),
                  child: _buildTablePlayers(),
                ),
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: _hubAlignmentForLayout,
                child: _TableControlHub(
                  scaleFactor: _hubScaleFactorForLayout,
                  isExpanded: _isHubExpanded,
                  lastTableEvent: _lastTableEvent,
                  onToggle: () {
                    setState(() {
                      _isHubExpanded = !_isHubExpanded;
                    });
                  },
                  onPlayers: _showPlayersDialog,
                  onSettings: _showSettingsDialog,
                  onTools: _showTableToolsSheet,
                  hasPendingHighRollTie: _highRollWinners.length > 1,
                  onQuickHighRoll: _runOrRerollHighRoll,
                  onReset: _reset,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: IgnorePointer(
                ignoring: !_isHubExpanded,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  offset: _isHubExpanded ? Offset.zero : const Offset(0, 0.2),
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    scale: _isHubExpanded ? 1 : 0.94,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: _isHubExpanded ? 1 : 0,
                      child: Center(
                        child: _TableBottomRail(
                          onDice: _showDiceDialog,
                          onHistory: _showHistoryDialog,
                          onCardSearch: _showCardSearchDialog,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablePlayers() {
    switch (_playerCount) {
      case 2:
        return _buildTwoPlayers();
      case 3:
        return _buildThreePlayers();
      case 5:
        return _buildFivePlayers();
      case 6:
        return _buildSixPlayers();
      default:
        return _buildFourPlayers();
    }
  }

  Widget _buildTwoPlayers() {
    return Column(
      children: [
        Expanded(child: _buildPlayerSlot(0, quarterTurns: _quarterTurnsForSeat(0))),
        const SizedBox(height: _tableGutter),
        Expanded(child: _buildPlayerSlot(1)),
      ],
    );
  }

  Widget _buildThreePlayers() {
    return Column(
      children: [
        Expanded(
          flex: 44,
          child: Row(
            children: [
              Expanded(
                child: _buildPlayerSlot(
                  0,
                  compact: true,
                  dense: true,
                  quarterTurns: _quarterTurnsForSeat(0),
                ),
              ),
              const SizedBox(width: _tableGutter),
              Expanded(
                child: _buildPlayerSlot(
                  1,
                  compact: true,
                  dense: true,
                  quarterTurns: _quarterTurnsForSeat(1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: _tableGutter),
        Expanded(
          flex: 56,
          child: _buildPlayerSlot(2, quarterTurns: _quarterTurnsForSeat(2)),
        ),
      ],
    );
  }

  Widget _buildFourPlayers() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildPlayerSlot(
                  0,
                  compact: true,
                  quarterTurns: _quarterTurnsForSeat(0),
                ),
              ),
              const SizedBox(width: _tableGutter),
              Expanded(
                child: _buildPlayerSlot(
                  1,
                  compact: true,
                  quarterTurns: _quarterTurnsForSeat(1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: _tableGutter),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildPlayerSlot(
                  2,
                  compact: true,
                  dense: true,
                  quarterTurns: _quarterTurnsForSeat(2),
                ),
              ),
              const SizedBox(width: _tableGutter),
              Expanded(
                child: _buildPlayerSlot(
                  3,
                  compact: true,
                  dense: true,
                  quarterTurns: _quarterTurnsForSeat(3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFivePlayers() {
    return _buildRingPlayers(
      topCenterPlayer: 0,
      upperLeftPlayer: 1,
      upperRightPlayer: 2,
      lowerLeftPlayer: 3,
      lowerRightPlayer: 4,
    );
  }

  Widget _buildSixPlayers() {
    return _buildRingPlayers(
      topCenterPlayer: 0,
      upperLeftPlayer: 1,
      upperRightPlayer: 2,
      lowerLeftPlayer: 3,
      lowerRightPlayer: 4,
      bottomCenterPlayer: 5,
    );
  }

  Widget _buildRingPlayers({
    int? topCenterPlayer,
    int? bottomCenterPlayer,
    required int upperLeftPlayer,
    required int upperRightPlayer,
    required int lowerLeftPlayer,
    required int lowerRightPlayer,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final centerWell =
            (min(width * 0.38, height * 0.24)).clamp(150.0, 184.0).toDouble();
        final sideWidth = (width - centerWell - (_tableGutter * 2)) / 2;
        final bandHeight = (height - centerWell - (_tableGutter * 2)) / 2;
        final centerX = sideWidth + _tableGutter;
        final rightX = width - sideWidth;
        final lowerY = height - bandHeight;

        return Stack(
          children: [
            if (topCenterPlayer != null)
              Positioned(
                left: centerX,
                top: 0,
                width: centerWell,
                height: bandHeight,
                child: _buildPlayerSlot(
                  topCenterPlayer,
                  compact: true,
                  dense: true,
                  quarterTurns: _quarterTurnsForSeat(topCenterPlayer),
                ),
              ),
            Positioned(
              left: 0,
              top: 0,
              width: sideWidth,
              height: bandHeight,
              child: _buildPlayerSlot(
                upperLeftPlayer,
                compact: true,
                dense: true,
                quarterTurns: _quarterTurnsForSeat(upperLeftPlayer),
              ),
            ),
            Positioned(
              left: rightX,
              top: 0,
              width: sideWidth,
              height: bandHeight,
              child: _buildPlayerSlot(
                upperRightPlayer,
                compact: true,
                dense: true,
                quarterTurns: _quarterTurnsForSeat(upperRightPlayer),
              ),
            ),
            Positioned(
              left: 0,
              top: lowerY,
              width: sideWidth,
              height: bandHeight,
              child: _buildPlayerSlot(
                lowerLeftPlayer,
                compact: true,
                dense: true,
                quarterTurns: _quarterTurnsForSeat(lowerLeftPlayer),
              ),
            ),
            Positioned(
              left: rightX,
              top: lowerY,
              width: sideWidth,
              height: bandHeight,
              child: _buildPlayerSlot(
                lowerRightPlayer,
                compact: true,
                dense: true,
                quarterTurns: _quarterTurnsForSeat(lowerRightPlayer),
              ),
            ),
            if (bottomCenterPlayer != null)
              Positioned(
                left: centerX,
                top: lowerY,
                width: centerWell,
                height: bandHeight,
                child: _buildPlayerSlot(
                  bottomCenterPlayer,
                  compact: true,
                  dense: true,
                  quarterTurns: _quarterTurnsForSeat(bottomCenterPlayer),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPlayerSlot(
    int playerIndex, {
    bool compact = false,
    bool dense = false,
    int quarterTurns = 0,
  }) {
    return KeyedSubtree(
      key: Key('life-counter-player-slot-$playerIndex'),
      child: _PlayerPanel(
        panelIndex: playerIndex,
        label: _playerLabels[playerIndex],
        life: _lives[playerIndex],
        poison: _poison[playerIndex],
        commanderTax: _commanderCasts[playerIndex] * 2,
        commanderDamageTotal: _totalCommanderDamage(playerIndex),
        commanderDamageLeadSourceLabel:
            _commanderDamageLeadSourceLabel(playerIndex),
        commanderDamageLeadSourceValue:
            _commanderDamageLeadSourceValue(playerIndex),
        lastPlayerRoll: _lastPlayerRolls[playerIndex],
        highRollValue: _lastHighRolls[playerIndex],
        specialState: _playerSpecialStates[playerIndex],
        isHighRollWinner: _highRollWinners.contains(playerIndex),
        isHighRollTie:
            _highRollWinners.length > 1 &&
            _highRollWinners.contains(playerIndex),
        isMonarch: _monarchPlayer == playerIndex,
        hasInitiative: _initiativePlayer == playerIndex,
        color: _playerColors[playerIndex],
        onIncrement: () => _changeLife(playerIndex, 1),
        onQuickIncrement: () => _changeLife(playerIndex, 5),
        onDecrement: () => _changeLife(playerIndex, -1),
        onQuickDecrement: () => _changeLife(playerIndex, -5),
        onPoisonIncrement: () => _changePoison(playerIndex, 1),
        onPoisonDecrement: () => _changePoison(playerIndex, -1),
        onCommanderTaxIncrement: () => _changeCommanderCasts(playerIndex, 1),
        onCommanderTaxDecrement: () => _changeCommanderCasts(playerIndex, -1),
        onOpenCommanderDamageQuick:
            () => _showCommanderDamageQuickDialog(playerIndex),
        onOpenSetLife: () => _showSetLifeDialog(playerIndex),
        onPlayerRollD20: () => _rollPlayerD20(playerIndex),
        onToggleDefeated: () => _togglePlayerDefeated(playerIndex),
        onMarkDeckedOut: () => _markPlayerDeckedOut(playerIndex),
        onMarkAnswerLeft: () => _markPlayerAnswerLeft(playerIndex),
        onCountersTap: () => _showCountersDialog(playerIndex),
        quickPlusKey: Key('life-counter-quick-plus-$playerIndex'),
        quickMinusKey: Key('life-counter-quick-minus-$playerIndex'),
        countersKey: Key('life-counter-counters-$playerIndex'),
        quarterTurns: quarterTurns,
        compact: compact,
        dense: dense,
      ),
    );
  }

  int _totalCommanderDamage(int player) {
    int total = 0;
    for (int i = 0; i < _playerCount; i++) {
      total += _commanderDamage[player][i];
    }
    return total;
  }

  int? _commanderDamageLeadSource(int player) {
    int? source;
    int highest = 0;
    for (int i = 0; i < _playerCount; i++) {
      if (i == player) continue;
      final damage = _commanderDamage[player][i];
      if (damage > highest) {
        highest = damage;
        source = i;
      }
    }
    return source;
  }

  String? _commanderDamageLeadSourceLabel(int player) {
    final source = _commanderDamageLeadSource(player);
    if (source == null) return null;
    return 'de P${source + 1}';
  }

  int? _commanderDamageLeadSourceValue(int player) {
    final source = _commanderDamageLeadSource(player);
    if (source == null) return null;
    final damage = _commanderDamage[player][source];
    return damage > 0 ? damage : null;
  }
}

class _TableControlHub extends StatelessWidget {
  final double scaleFactor;
  final bool isExpanded;
  final bool hasPendingHighRollTie;
  final String? lastTableEvent;
  final VoidCallback onToggle;
  final VoidCallback onPlayers;
  final VoidCallback onSettings;
  final VoidCallback onTools;
  final VoidCallback onQuickHighRoll;
  final VoidCallback onReset;

  const _TableControlHub({
    required this.scaleFactor,
    required this.isExpanded,
    required this.hasPendingHighRollTie,
    required this.lastTableEvent,
    required this.onToggle,
    required this.onPlayers,
    required this.onSettings,
    required this.onTools,
    required this.onQuickHighRoll,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final petalSpecs = [
      _HubPetalSpec(
        key: Key('life-counter-hub-players'),
        label: 'PLAYERS',
        color: Color(0xFF44E063),
        offset: Offset(-76, 2) * scaleFactor,
        rotation: -pi / 2,
      ),
      _HubPetalSpec(
        key: Key('life-counter-hub-reset'),
        label: 'RESTART',
        color: Color(0xFFFFE277),
        offset: Offset(-16, -58) * scaleFactor,
        rotation: -0.72,
      ),
      _HubPetalSpec(
        key: Key('life-counter-hub-quick-high-roll'),
        label: '',
        color: Color(0xFF40B9FF),
        offset: Offset(34, -56) * scaleFactor,
        rotation: 0.68,
      ),
      _HubPetalSpec(
        key: Key('life-counter-hub-settings'),
        label: 'SETTINGS',
        color: Color(0xFFB9B4FF),
        offset: Offset(76, 4) * scaleFactor,
        rotation: pi / 2,
      ),
      _HubPetalSpec(
        key: Key('life-counter-hub-tools'),
        label: 'HELP',
        color: Color(0xFFFF2C77),
        offset: Offset(0, 70) * scaleFactor,
        rotation: pi,
      ),
    ];

    final hubSize = (isExpanded ? 236 : 68) * scaleFactor;
    final lastEventMaxWidth = 224 * scaleFactor;
    final lastEventTopGap = 2 * scaleFactor;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: Column(
        key: const Key('life-counter-control-hub'),
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: hubSize,
            height: hubSize,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                _HubOrbitPetal(
                  scaleFactor: scaleFactor,
                  isExpanded: isExpanded,
                  spec: petalSpecs[0],
                  onTap: onPlayers,
                ),
                _HubOrbitPetal(
                  scaleFactor: scaleFactor,
                  isExpanded: isExpanded,
                  spec: petalSpecs[1],
                  onTap: onReset,
                ),
                _HubOrbitPetal(
                  scaleFactor: scaleFactor,
                  isExpanded: isExpanded,
                  spec: petalSpecs[2].copyWith(
                    label:
                        hasPendingHighRollTie ? 'DESMP' : 'HIGH ROLL',
                  ),
                  onTap: onQuickHighRoll,
                ),
                _HubOrbitPetal(
                  scaleFactor: scaleFactor,
                  isExpanded: isExpanded,
                  spec: petalSpecs[3],
                  onTap: onSettings,
                ),
                _HubOrbitPetal(
                  scaleFactor: scaleFactor,
                  isExpanded: isExpanded,
                  spec: petalSpecs[4],
                  onTap: onTools,
                ),
                _HubMedallion(
                  scaleFactor: scaleFactor,
                  isExpanded: isExpanded,
                  onTap: onToggle,
                ),
              ],
            ),
          ),
          if (isExpanded && lastTableEvent != null) ...[
            SizedBox(height: lastEventTopGap),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.08),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: ConstrainedBox(
                key: ValueKey(lastTableEvent),
                constraints: BoxConstraints(maxWidth: lastEventMaxWidth),
                child: Text(
                  key: const Key('life-counter-hub-last-event'),
                  lastTableEvent!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.76),
                    fontSize: AppTheme.fontSm,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.45,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HubMedallion extends StatelessWidget {
  final double scaleFactor;
  final bool isExpanded;
  final VoidCallback onTap;

  const _HubMedallion({
    required this.scaleFactor,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final outerSize = (isExpanded ? 76 : 66) * scaleFactor;
    final middleSize = (isExpanded ? 68 : 58) * scaleFactor;
    final innerSize = (isExpanded ? 56 : 48) * scaleFactor;
    final iconSize = (isExpanded ? 26 : 23) * scaleFactor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('life-counter-hub-toggle'),
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: SizedBox(
          width: outerSize,
          height: outerSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: outerSize,
                height: outerSize,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: isExpanded ? 12 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipPath(
                  clipper: const _HexagonClipper(),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: middleSize,
                height: middleSize,
                child: ClipPath(
                  clipper: const _HexagonClipper(),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E0E0E),
                    ),
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: innerSize,
                height: innerSize,
                child: ClipPath(
                  clipper: const _HexagonClipper(),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFFFE7F6).withValues(alpha: 0.98),
                          const Color(0xFFD6F4FF).withValues(alpha: 0.96),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
              Icon(
                isExpanded ? Icons.close_rounded : Icons.menu_rounded,
                color: Colors.black,
                size: iconSize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubPetalAction extends StatelessWidget {
  final Key? buttonKey;
  final String label;
  final Color color;
  final double scaleFactor;
  final VoidCallback? onTap;

  const _HubPetalAction({
    this.buttonKey,
    required this.label,
    required this.color,
    required this.scaleFactor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Material(
      key: buttonKey,
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          width: 90 * scaleFactor,
          height: 34 * scaleFactor,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.12),
              width: 0.6,
            ),
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10 * scaleFactor),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color:
                        enabled
                            ? Colors.black.withValues(alpha: 0.9)
                            : Colors.black.withValues(alpha: 0.35),
                    fontSize: 9.6 * scaleFactor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.65,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayersOverlay extends StatelessWidget {
  final int selectedPlayerCount;
  final ValueChanged<int> onSelected;

  const _PlayersOverlay({
    required this.selectedPlayerCount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _TableOverlayFrame(
      frameKey: const Key('life-counter-players-overlay'),
      title: 'PLAYERS',
      subtitle: 'Pick the board layout before the round starts.',
      width: 292,
      maxHeight: 540,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final count in const [2, 3, 4, 5, 6]) ...[
            _PlayerLayoutPreview(
              previewKey: Key('life-counter-players-option-$count'),
              playerCount: count,
              selected: selectedPlayerCount == count,
              onTap: () => onSelected(count),
            ),
            if (count != 6) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _TableOverlayFrame extends StatelessWidget {
  final Key? frameKey;
  final String title;
  final String? subtitle;
  final Widget child;
  final double width;
  final double maxHeight;

  const _TableOverlayFrame({
    this.frameKey,
    required this.title,
    this.subtitle,
    required this.child,
    this.width = 330,
    this.maxHeight = 560,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width, maxHeight: maxHeight),
              child: Stack(
                children: [
                  Container(
                    key: frameKey,
                    width: width,
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.98),
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.66),
                              fontSize: AppTheme.fontSm,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                              letterSpacing: 0.15,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Flexible(
                          child: SingleChildScrollView(
                            child: child,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => Navigator.of(context).pop(),
                        child: Ink(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF2C77),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlaySectionHeading extends StatelessWidget {
  final String label;

  const _OverlaySectionHeading(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.86),
        fontSize: AppTheme.fontSm,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
      ),
    );
  }
}

class _PlayerLayoutPreview extends StatelessWidget {
  final Key? previewKey;
  final int playerCount;
  final bool selected;
  final VoidCallback onTap;

  const _PlayerLayoutPreview({
    this.previewKey,
    required this.playerCount,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      key: previewKey,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          width: 176,
          height: 72,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFF2C77) : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color:
                  selected
                      ? const Color(0xFFFF2C77)
                      : Colors.white.withValues(alpha: 0.9),
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: _PlayerLayoutGlyph(playerCount: playerCount),
          ),
        ),
      ),
    );
  }
}

class _PlayerLayoutGlyph extends StatelessWidget {
  final int playerCount;

  const _PlayerLayoutGlyph({required this.playerCount});

  @override
  Widget build(BuildContext context) {
    final tileColor = playerCount >= 4 ? Colors.black : Colors.white;
    final tileAlt =
        playerCount >= 4
            ? Colors.black.withValues(alpha: 0.82)
            : Colors.white.withValues(alpha: 0.9);

    Widget tile({Color? color}) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: color ?? tileColor,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    if (playerCount == 2) {
      return Row(children: [tile(color: tileAlt), tile(color: tileAlt)]);
    }

    if (playerCount == 3) {
      return Column(
        children: [
          Expanded(child: Row(children: [tile(color: tileAlt), tile(color: tileAlt)])),
          Expanded(
            child: Row(
              children: [
                tile(color: tileAlt),
                Expanded(child: Container()),
              ],
            ),
          ),
        ],
      );
    }

    if (playerCount == 5 || playerCount == 6) {
      Widget strip() {
        return Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: tileAlt,
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }

      return Stack(
        children: [
          Align(
            alignment: const Alignment(0, -0.82),
            child: SizedBox(width: 54, height: 16, child: strip()),
          ),
          Align(
            alignment: const Alignment(-0.72, -0.36),
            child: SizedBox(width: 48, height: 24, child: strip()),
          ),
          Align(
            alignment: const Alignment(0.72, -0.36),
            child: SizedBox(width: 48, height: 24, child: strip()),
          ),
          Align(
            alignment: const Alignment(-0.72, 0.46),
            child: SizedBox(width: 48, height: 24, child: strip()),
          ),
          Align(
            alignment: const Alignment(0.72, 0.46),
            child: SizedBox(width: 48, height: 24, child: strip()),
          ),
          if (playerCount == 6)
            Align(
              alignment: const Alignment(0, 0.88),
              child: SizedBox(width: 54, height: 16, child: strip()),
            ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(child: Row(children: [tile(), tile()])),
        Expanded(child: Row(children: [tile(), tile()])),
      ],
    );
  }
}

class _HistoryOverlay extends StatelessWidget {
  final String? lastTableEvent;
  final int snapshotCount;

  const _HistoryOverlay({
    required this.lastTableEvent,
    required this.snapshotCount,
  });

  @override
  Widget build(BuildContext context) {
    return _TableOverlayFrame(
      frameKey: const Key('life-counter-history-overlay'),
      title: 'HISTORY',
      width: 304,
      maxHeight: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _OverlaySectionHeading('LAST EVENT'),
          const SizedBox(height: 10),
          Text(
            lastTableEvent == null ? 'NO TABLE EVENT.' : lastTableEvent!,
            key: const Key('life-counter-history-last-event'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: AppTheme.fontMd,
              height: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          const _OverlaySectionHeading('SNAPSHOTS'),
          const SizedBox(height: 10),
          Text(
            '$snapshotCount SAVED',
            key: const Key('life-counter-history-snapshot-count'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayPlainText extends StatelessWidget {
  final String body;

  const _OverlayPlainText({required this.body});

  @override
  Widget build(BuildContext context) {
    return Text(
      body,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.86),
        fontSize: AppTheme.fontMd,
        height: 1.35,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _CardSearchOverlay extends StatefulWidget {
  const _CardSearchOverlay();

  @override
  State<_CardSearchOverlay> createState() => _CardSearchOverlayState();
}

class _CardSearchOverlayState extends State<_CardSearchOverlay> {
  static const _suggestions = [
    'Sol Ring',
    'Command Tower',
    'Cyclonic Rift',
    'Swords to Plowshares',
  ];

  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runSearch(BuildContext context, String query) {
    context.read<CardProvider>().searchCards(query.trim());
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CardProvider(),
      child: Builder(
        builder: (context) {
          return _TableOverlayFrame(
            frameKey: const Key('life-counter-card-search-overlay'),
            title: 'CARD SEARCH',
            width: 348,
            maxHeight: 620,
            child: Consumer<CardProvider>(
              builder: (context, provider, _) {
                final hasQuery = _controller.text.trim().length >= 3;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      key: const Key('life-counter-card-search-input'),
                      controller: _controller,
                      textInputAction: TextInputAction.search,
                      onChanged: (value) {
                        setState(() {});
                        if (value.trim().length >= 3) {
                          _runSearch(context, value);
                        } else {
                          provider.clearSearch();
                        }
                      },
                      onSubmitted: (value) => _runSearch(context, value),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.96),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                      decoration: InputDecoration(
                        hintText: 'SEARCH CARDS',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.34),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                        suffixIcon:
                            _controller.text.isEmpty
                                ? null
                                : IconButton(
                                  key: const Key(
                                    'life-counter-card-search-clear',
                                  ),
                                  onPressed: () {
                                    _controller.clear();
                                    provider.clearSearch();
                                    setState(() {});
                                  },
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white.withValues(alpha: 0.82),
                                  ),
                                ),
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.28),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Colors.white,
                            width: 1.8,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.94),
                            width: 1.8,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF40B9FF),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final suggestion in _suggestions)
                          _CardSearchSuggestionChip(
                            chipKey: Key(
                              'life-counter-card-search-suggestion-${suggestion.toLowerCase().replaceAll(' ', '-')}',
                            ),
                            label: suggestion,
                            onTap: () {
                              _controller.text = suggestion;
                              setState(() {});
                              _runSearch(context, suggestion);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (!hasQuery)
                      const _OverlayPlainText(
                        body: 'TYPE 3 LETTERS OR USE A TABLE SHORTCUT.',
                      )
                    else if (provider.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (provider.errorMessage != null)
                      Text(
                        provider.errorMessage!,
                        key: const Key('life-counter-card-search-error'),
                        style: TextStyle(
                          color: AppTheme.error.withValues(alpha: 0.92),
                          fontSize: AppTheme.fontSm,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      )
                    else if (provider.searchResults.isEmpty)
                      _OverlayPlainText(
                        body:
                            'NO CARD FOUND FOR "${_controller.text.trim().toUpperCase()}".',
                      )
                    else
                      Column(
                        key: const Key('life-counter-card-search-results'),
                        children: [
                          for (int i = 0;
                              i < provider.searchResults.length && i < 8;
                              i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _CardSearchResultTile(
                                tileKey: Key(
                                  'life-counter-card-search-result-$i',
                                ),
                                card: provider.searchResults[i],
                              ),
                            ),
                        ],
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CardSearchSuggestionChip extends StatelessWidget {
  final Key chipKey;
  final String label;
  final VoidCallback onTap;

  const _CardSearchSuggestionChip({
    required this.chipKey,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      key: chipKey,
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.94),
              width: 1.5,
            ),
          ),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: AppTheme.fontXs,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardSearchResultTile extends StatelessWidget {
  final Key tileKey;
  final DeckCardItem card;

  const _CardSearchResultTile({
    required this.tileKey,
    required this.card,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      key: tileKey,
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CardDetailScreen(card: card),
            ),
          );
        },
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.94),
              width: 1.3,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.style_rounded,
                  color: Colors.white.withValues(alpha: 0.72),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.96),
                        fontSize: AppTheme.fontMd,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (card.typeLine.trim().isNotEmpty) card.typeLine,
                        if (card.setCode.trim().isNotEmpty)
                          card.setCode.toUpperCase(),
                      ].join('  â€¢  '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontSize: AppTheme.fontSm,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.open_in_new_rounded,
                color: Colors.white.withValues(alpha: 0.72),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableBottomRail extends StatelessWidget {
  final VoidCallback onDice;
  final VoidCallback onHistory;
  final VoidCallback onCardSearch;

  const _TableBottomRail({
    required this.onDice,
    required this.onHistory,
    required this.onCardSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('life-counter-bottom-rail'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4EC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BottomRailPill(
            pillKey: const Key('life-counter-rail-dice'),
            icon: Icons.casino_outlined,
            label: 'DICE',
            onTap: onDice,
          ),
          const SizedBox(width: 8),
          _BottomRailPill(
            pillKey: const Key('life-counter-rail-history'),
            icon: Icons.history_rounded,
            label: 'HISTORY',
            onTap: onHistory,
          ),
          const SizedBox(width: 8),
          _BottomRailPill(
            pillKey: const Key('life-counter-rail-card-search'),
            icon: Icons.search_rounded,
            label: 'CARD SEARCH',
            onTap: onCardSearch,
          ),
        ],
      ),
    );
  }
}

class _BottomRailPill extends StatelessWidget {
  final Key pillKey;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomRailPill({
    required this.pillKey,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      key: pillKey,
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppTheme.fontSm,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.55,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubOrbitPetal extends StatelessWidget {
  final double scaleFactor;
  final bool isExpanded;
  final _HubPetalSpec spec;
  final VoidCallback onTap;

  const _HubOrbitPetal({
    required this.scaleFactor,
    required this.isExpanded,
    required this.spec,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !isExpanded,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: isExpanded ? 1 : 0),
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            final easedOpacity = Curves.easeOut.transform(value.clamp(0, 1));
            final offset = Offset.lerp(Offset.zero, spec.offset, value)!;
            return Align(
              alignment: Alignment.center,
              child: Transform.translate(
                offset: offset,
                child: Transform.rotate(
                  angle: spec.rotation * value,
                  child: Opacity(
                    opacity: easedOpacity,
                    child: Transform.scale(
                      scale: 0.78 + (0.22 * value),
                      child: child,
                    ),
                  ),
                ),
              ),
            );
          },
          child: _HubPetalAction(
            buttonKey: spec.key,
            label: spec.label,
            color: spec.color,
            scaleFactor: scaleFactor,
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}

class _HubPetalSpec {
  final Key key;
  final String label;
  final Color color;
  final Offset offset;
  final double rotation;

  const _HubPetalSpec({
    required this.key,
    required this.label,
    required this.color,
    required this.offset,
    required this.rotation,
  });

  _HubPetalSpec copyWith({
    Key? key,
    String? label,
    Color? color,
    Offset? offset,
    double? rotation,
  }) {
    return _HubPetalSpec(
      key: key ?? this.key,
      label: label ?? this.label,
      color: color ?? this.color,
      offset: offset ?? this.offset,
      rotation: rotation ?? this.rotation,
    );
  }
}

class _HexagonClipper extends CustomClipper<Path> {
  const _HexagonClipper();

  @override
  Path getClip(Size size) {
    final width = size.width;
    final height = size.height;

    return Path()
      ..moveTo(width * 0.26, 0)
      ..lineTo(width * 0.74, 0)
      ..lineTo(width, height * 0.5)
      ..lineTo(width * 0.74, height)
      ..lineTo(width * 0.26, height)
      ..lineTo(0, height * 0.5)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ---------------------------------------------------------------------------
// Player Panel
// ---------------------------------------------------------------------------

/// Painel de um jogador individual com vida, indicadores de poison/commander,
/// e botÃ£o para abrir contadores extras.
class _PlayerPanel extends StatefulWidget {
  final int panelIndex;
  final String label;
  final int life;
  final int poison;
  final int commanderTax;
  final int commanderDamageTotal;
  final String? commanderDamageLeadSourceLabel;
  final int? commanderDamageLeadSourceValue;
  final int? lastPlayerRoll;
  final int? highRollValue;
  final _PlayerSpecialState specialState;
  final bool isHighRollWinner;
  final bool isHighRollTie;
  final bool isMonarch;
  final bool hasInitiative;
  final Color color;
  final VoidCallback onIncrement;
  final VoidCallback onQuickIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onQuickDecrement;
  final VoidCallback onPoisonIncrement;
  final VoidCallback onPoisonDecrement;
  final VoidCallback onCommanderTaxIncrement;
  final VoidCallback onCommanderTaxDecrement;
  final VoidCallback onOpenCommanderDamageQuick;
  final VoidCallback onOpenSetLife;
  final VoidCallback onPlayerRollD20;
  final VoidCallback onToggleDefeated;
  final VoidCallback onMarkDeckedOut;
  final VoidCallback onMarkAnswerLeft;
  final VoidCallback onCountersTap;
  final Key? quickPlusKey;
  final Key? quickMinusKey;
  final Key? countersKey;
  final int quarterTurns;
  final bool compact;
  final bool dense;

  const _PlayerPanel({
    required this.panelIndex,
    required this.label,
    required this.life,
    required this.poison,
    required this.commanderTax,
    required this.commanderDamageTotal,
    required this.commanderDamageLeadSourceLabel,
    required this.commanderDamageLeadSourceValue,
    required this.lastPlayerRoll,
    required this.highRollValue,
    required this.specialState,
    required this.isHighRollWinner,
    required this.isHighRollTie,
    required this.isMonarch,
    required this.hasInitiative,
    required this.color,
    required this.onIncrement,
    required this.onQuickIncrement,
    required this.onDecrement,
    required this.onQuickDecrement,
    required this.onPoisonIncrement,
    required this.onPoisonDecrement,
    required this.onCommanderTaxIncrement,
    required this.onCommanderTaxDecrement,
    required this.onOpenCommanderDamageQuick,
    required this.onOpenSetLife,
    required this.onPlayerRollD20,
    required this.onToggleDefeated,
    required this.onMarkDeckedOut,
    required this.onMarkAnswerLeft,
    required this.onCountersTap,
    this.quickPlusKey,
    this.quickMinusKey,
    this.countersKey,
    this.quarterTurns = 0,
    this.compact = false,
    this.dense = false,
  });

  @override
  State<_PlayerPanel> createState() => _PlayerPanelState();
}

class _PlayerPanelState extends State<_PlayerPanel> {
  bool _showLifeActions = false;

  bool get _isDenseCompact => widget.compact && widget.dense;

  double get _coreStageWidth => _isDenseCompact ? 132 : widget.compact ? 156 : 214;
  double get _coreStageHeight => _isDenseCompact ? 108 : widget.compact ? 126 : 176;

  Alignment get _normalCoreAlignment {
    final horizontal =
        widget.quarterTurns == 1
            ? (_isDenseCompact ? 0.04 : widget.compact ? 0.05 : 0.035)
            : widget.quarterTurns == 3
            ? (_isDenseCompact ? -0.04 : widget.compact ? -0.05 : -0.035)
            : 0.0;
    final vertical = _isDenseCompact ? -0.04 : widget.compact ? -0.055 : -0.038;
    return Alignment(horizontal, vertical);
  }

  Alignment get _actionsCoreAlignment {
    final horizontal =
        widget.quarterTurns == 1
            ? (_isDenseCompact ? 0.022 : widget.compact ? 0.03 : 0.02)
            : widget.quarterTurns == 3
            ? (_isDenseCompact ? -0.022 : widget.compact ? -0.03 : -0.02)
            : 0.0;
    final vertical = _isDenseCompact ? -0.018 : widget.compact ? -0.03 : -0.02;
    return Alignment(horizontal, vertical);
  }

  Alignment get _eventTakeoverAlignment {
    final horizontal =
        widget.quarterTurns == 1
            ? (_isDenseCompact ? 0.014 : widget.compact ? 0.02 : 0.015)
            : widget.quarterTurns == 3
            ? (_isDenseCompact ? -0.014 : widget.compact ? -0.02 : -0.015)
            : 0.0;
    return Alignment(horizontal, 0.0);
  }

  Alignment get _specialTakeoverAlignment {
    final horizontal =
        widget.quarterTurns == 1
            ? (_isDenseCompact ? 0.008 : widget.compact ? 0.012 : 0.008)
            : widget.quarterTurns == 3
            ? (_isDenseCompact ? -0.008 : widget.compact ? -0.012 : -0.008)
            : 0.0;
    return Alignment(horizontal, 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDeckedOut = widget.specialState == _PlayerSpecialState.deckedOut;
    final hasAnswerLeft = widget.specialState == _PlayerSpecialState.answerLeft;
    final isDefeated = widget.life <= 0 && !isDeckedOut && !hasAnswerLeft;
    final isCommanderLethal =
        !isDeckedOut && !hasAnswerLeft && widget.commanderDamageTotal >= 21;
    final isPoisonLethal =
        !isDeckedOut && !hasAnswerLeft && widget.poison >= 10;
    final hasPanelTakeoverState =
        isDefeated ||
        isDeckedOut ||
        hasAnswerLeft ||
        isCommanderLethal ||
        isPoisonLethal;
    final hasHighRoll = widget.highRollValue != null;
    final hasPlayerRoll = widget.lastPlayerRoll != null && !hasHighRoll;
    final hasEventTakeover =
        (hasHighRoll || hasPlayerRoll) &&
        !_showLifeActions &&
        !hasPanelTakeoverState;
    final eventValue =
        hasHighRoll
            ? widget.highRollValue!.toString()
            : hasPlayerRoll
            ? widget.lastPlayerRoll!.toString()
            : null;
    final eventLabel =
        hasHighRoll
            ? (widget.isHighRollTie ? 'EMPATE' : 'HIGH ROLL')
            : hasPlayerRoll
            ? 'D20'
            : null;
    final baseColor =
        isDeckedOut
            ? const Color(0xFF4A3A12)
            : hasAnswerLeft
            ? const Color(0xFF1D1D1D)
            : isDefeated
            ? const Color(0xFF5B3A6C)
            : isCommanderLethal
            ? const Color(0xFF341217)
            : isPoisonLethal
            ? const Color(0xFF122A18)
            : widget.color;
    final highRollAccent =
        widget.isHighRollTie ? AppTheme.warning : AppTheme.primarySoft;
    final isLightPanel =
        ThemeData.estimateBrightnessForColor(baseColor) == Brightness.light;
    final dominantValueColor =
        isLightPanel ? Colors.black : Colors.white.withValues(alpha: 0.98);
    final supportingColor =
        isLightPanel
            ? Colors.black.withValues(alpha: 0.46)
            : Colors.white.withValues(alpha: 0.38);
    final quickActions = <Widget>[
      _PlayerInlineAction(
        actionKey: Key('life-counter-player-roll-d20-${widget.panelIndex}'),
        icon: Icons.casino_outlined,
        label: 'D20',
        compact: widget.compact,
        dense: widget.dense,
        onTap: () {
          widget.onPlayerRollD20();
          setState(() {
            _showLifeActions = false;
          });
        },
      ),
      _PlayerInlineAction(
        actionKey: Key('life-counter-player-poison-plus-${widget.panelIndex}'),
        icon: Icons.coronavirus_outlined,
        label: 'TOX +',
        compact: widget.compact,
        dense: widget.dense,
        onTap: () {
          widget.onPoisonIncrement();
          setState(() {
            _showLifeActions = false;
          });
        },
      ),
      _PlayerInlineAction(
        actionKey: Key('life-counter-player-poison-minus-${widget.panelIndex}'),
        icon: Icons.remove_circle_outline_rounded,
        label: 'TOX -',
        compact: widget.compact,
        dense: widget.dense,
        onTap: () {
          widget.onPoisonDecrement();
          setState(() {
            _showLifeActions = false;
          });
        },
      ),
      _PlayerInlineAction(
        actionKey: Key('life-counter-player-tax-plus-${widget.panelIndex}'),
        icon: Icons.add_circle_outline_rounded,
        label: 'TAX +',
        compact: widget.compact,
        dense: widget.dense,
        onTap: () {
          widget.onCommanderTaxIncrement();
          setState(() {
            _showLifeActions = false;
          });
        },
      ),
      _PlayerInlineAction(
        actionKey: Key('life-counter-player-tax-minus-${widget.panelIndex}'),
        icon: Icons.remove_circle_outline_rounded,
        label: 'TAX -',
        compact: widget.compact,
        dense: widget.dense,
        onTap: () {
          widget.onCommanderTaxDecrement();
          setState(() {
            _showLifeActions = false;
          });
        },
      ),
      _PlayerInlineAction(
        actionKey: Key(
          'life-counter-player-commander-damage-${widget.panelIndex}',
        ),
        icon: Icons.shield_outlined,
        label: 'MARKS',
        compact: widget.compact,
        dense: widget.dense,
        onTap: () {
          widget.onOpenCommanderDamageQuick();
          setState(() {
            _showLifeActions = false;
          });
        },
      ),
      _PlayerInlineAction(
        actionKey: widget.countersKey,
        icon: Icons.dashboard_customize_outlined,
        label: 'TRACK',
        compact: widget.compact,
        dense: widget.dense,
        onTap: () {
          widget.onCountersTap();
          setState(() {
            _showLifeActions = false;
          });
        },
      ),
      _PlayerInlineAction(
        actionKey: Key(
          'life-counter-player-toggle-dead-${widget.panelIndex}',
        ),
        icon:
            hasPanelTakeoverState
                ? Icons.favorite_rounded
                : Icons.dangerous_rounded,
        label: hasPanelTakeoverState ? 'REVIVE' : 'KO\'D!',
        compact: widget.compact,
        dense: widget.dense,
        destructive: !hasPanelTakeoverState,
        onTap: () {
          widget.onToggleDefeated();
          setState(() {
            _showLifeActions = false;
          });
        },
      ),
      if (!hasPanelTakeoverState)
        _PlayerInlineAction(
          actionKey: Key(
            'life-counter-player-mark-decked-${widget.panelIndex}',
          ),
          icon: Icons.auto_stories_rounded,
          label: 'DECKED',
          compact: widget.compact,
          dense: widget.dense,
          destructive: true,
          onTap: () {
            widget.onMarkDeckedOut();
            setState(() {
              _showLifeActions = false;
            });
          },
        ),
      if (!hasPanelTakeoverState)
        _PlayerInlineAction(
          actionKey: Key(
            'life-counter-player-mark-left-${widget.panelIndex}',
          ),
          icon: Icons.exit_to_app_rounded,
          label: 'LEFT',
          compact: widget.compact,
          dense: widget.dense,
          destructive: true,
          onTap: () {
            widget.onMarkAnswerLeft();
            setState(() {
              _showLifeActions = false;
            });
          },
        ),
    ];
    final quickActionsRowChildren = <Widget>[];
    for (int i = 0; i < quickActions.length; i++) {
      if (i > 0) {
        quickActionsRowChildren.add(const SizedBox(width: 8));
      }
      quickActionsRowChildren.add(quickActions[i]);
    }
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isCommanderLethal
                  ? AppTheme.error
                  : Colors.black,
          width: isCommanderLethal ? 3 : 3,
        ),
        boxShadow: const [],
      ),
      child: Stack(
        children: [
          if (hasEventTakeover)
            Positioned.fill(
              child: IgnorePointer(
                child: _PanelEventTakeoverOverlay(
                  overlayKey: Key(
                    hasHighRoll
                        ? 'life-counter-player-high-roll-event-${widget.panelIndex}'
                        : 'life-counter-player-roll-event-${widget.panelIndex}',
                  ),
                  compact: widget.compact,
                  dense: widget.dense,
                  contentAlignment: _eventTakeoverAlignment,
                  color: baseColor,
                  accent: highRollAccent,
                  value: eventValue!,
                  kind: hasHighRoll ? 'high_roll' : 'd20',
                  isWinner: widget.isHighRollWinner,
                  isTie: widget.isHighRollTie,
                ),
              ),
            ),
          if (!_showLifeActions && !hasPanelTakeoverState)
            Positioned(
              top: _isDenseCompact ? 12 : widget.compact ? 18 : 20,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.center,
                child: _LifeQuickAdjustButton(
                  buttonKey: widget.quickPlusKey,
                  label: '+',
                  semanticLabel: '+5',
                  color: supportingColor,
                  compact: widget.compact,
                  dense: widget.dense,
                  onTap: widget.onQuickIncrement,
                ),
              ),
            ),
          if (!_showLifeActions && !hasPanelTakeoverState)
            Positioned(
              bottom: _isDenseCompact ? 4 : 8,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.center,
                child: _LifeQuickAdjustButton(
                  buttonKey: widget.quickMinusKey,
                  label: '-',
                  semanticLabel: '-5',
                  color: supportingColor,
                  compact: widget.compact,
                  dense: widget.dense,
                  onTap: widget.onQuickDecrement,
                ),
              ),
            ),
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: widget.onIncrement,
                    child: const SizedBox.expand(),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: widget.onDecrement,
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment:
                _showLifeActions ? _actionsCoreAlignment : _normalCoreAlignment,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    key: Key('life-counter-life-core-${widget.panelIndex}'),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    onTap: widget.onOpenSetLife,
                    onLongPress: () {
                      setState(() {
                        _showLifeActions = !_showLifeActions;
                      });
                    },
                    child: SizedBox(
                      width: _coreStageWidth,
                      height: _coreStageHeight,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 360),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            final fade = CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOut,
                            );
                            final scale = Tween<double>(
                              begin: 0.82,
                              end: 1,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutBack,
                              ),
                            );
                            final slide = Tween<Offset>(
                              begin: const Offset(0, 0.05),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            );
                            return FadeTransition(
                              opacity: fade,
                              child: SlideTransition(
                                position: slide,
                                child: ScaleTransition(
                                  scale: scale,
                                  child: child,
                                ),
                              ),
                            );
                          },
                          child: _buildLifeCoreContent(
                            isDefeated: isDefeated,
                            isDeckedOut: isDeckedOut,
                            hasAnswerLeft: hasAnswerLeft,
                            isCommanderLethal: isCommanderLethal,
                            isPoisonLethal: isPoisonLethal,
                            hasHighRoll: hasHighRoll,
                            dominantValueColor: dominantValueColor,
                            supportingColor: supportingColor,
                            eventLabel: eventLabel,
                            eventValue: eventValue,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_showLifeActions)
                    _isDenseCompact
                        ? SizedBox(
                          height: 78,
                          child: SingleChildScrollView(
                            key: Key(
                              'life-counter-player-quick-actions-${widget.panelIndex}',
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _PlayerCounterConsoleStrip(
                                  poison: widget.poison,
                                  commanderTax: widget.commanderTax,
                                  commanderDamageTotal:
                                      widget.commanderDamageTotal,
                                  compact: widget.compact,
                                  dense: widget.dense,
                                ),
                                const SizedBox(height: 6),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: _coreStageWidth + 72,
                                  ),
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: quickActions,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        : Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _PlayerCounterConsoleStrip(
                                poison: widget.poison,
                                commanderTax: widget.commanderTax,
                                commanderDamageTotal:
                                    widget.commanderDamageTotal,
                                compact: widget.compact,
                                dense: widget.dense,
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: widget.compact ? 42 : 48,
                                child: SingleChildScrollView(
                                  key: Key(
                                    'life-counter-player-quick-actions-${widget.panelIndex}',
                                  ),
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: quickActionsRowChildren,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ],
              ),
            ),
          ),
          if (hasPanelTakeoverState)
            Positioned.fill(
              child: IgnorePointer(
                child: _PanelTakeoverOverlay(
                  overlayKey: Key(
                    isDeckedOut
                        ? 'life-counter-player-decked-out-${widget.panelIndex}'
                        : hasAnswerLeft
                        ? 'life-counter-player-answer-left-${widget.panelIndex}'
                        : isDefeated
                        ? 'life-counter-player-defeated-${widget.panelIndex}'
                        : isCommanderLethal
                        ? 'life-counter-player-commander-lethal-${widget.panelIndex}'
                        : 'life-counter-player-poison-lethal-${widget.panelIndex}',
                  ),
                  compact: widget.compact,
                  dense: widget.dense,
                  contentAlignment: _specialTakeoverAlignment,
                  color:
                      isDeckedOut
                          ? const Color(0xFF2F2407)
                          : hasAnswerLeft
                          ? const Color(0xFF121212)
                          : isDefeated
                          ? const Color(0xFF1D1025)
                          : isCommanderLethal
                          ? const Color(0xFF2B090F)
                          : const Color(0xFF0C2414),
                  accent:
                      isDeckedOut
                          ? const Color(0xFFFFD36A)
                          : hasAnswerLeft
                          ? const Color(0xFFEDEDED)
                          : isDefeated
                          ? const Color(0xFFFF5AA9)
                          : isCommanderLethal
                          ? const Color(0xFFFF5B61)
                          : const Color(0xFF6BFF8D),
                  title:
                      isDeckedOut
                          ? 'DECKED OUT.'
                          : hasAnswerLeft
                          ? 'ANSWER LEFT.'
                          : isDefeated
                          ? 'KO\'D!'
                          : isCommanderLethal
                          ? 'COMMANDER DOWN.'
                          : 'TOXIC OUT.',
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.quarterTurns != 0) {
      return RotatedBox(quarterTurns: widget.quarterTurns, child: content);
    }
    return content;
  }

  Widget _buildLifeCoreContent({
    required bool isDefeated,
    required bool isDeckedOut,
    required bool hasAnswerLeft,
    required bool isCommanderLethal,
    required bool isPoisonLethal,
    required bool hasHighRoll,
    required Color dominantValueColor,
    required Color supportingColor,
    required String? eventLabel,
    required String? eventValue,
  }) {
    if (
      isDefeated ||
      isDeckedOut ||
      hasAnswerLeft ||
      isCommanderLethal ||
      isPoisonLethal
    ) {
      return SizedBox(
        key: ValueKey(
          'life-core-special-${widget.panelIndex}-$isDefeated-$isDeckedOut-$hasAnswerLeft-$isCommanderLethal-$isPoisonLethal',
        ),
        width: _coreStageWidth,
        height: _coreStageHeight,
      );
    }

    if (hasHighRoll || eventLabel != null) {
      return SizedBox(
        key: ValueKey(
          'life-core-event-${widget.panelIndex}-$eventLabel-$eventValue',
        ),
        width: _coreStageWidth,
        height: _coreStageHeight,
      );
    }

    if (_showLifeActions) {
      return SizedBox(
        key: ValueKey('life-core-actions-${widget.panelIndex}'),
        width: _coreStageWidth,
        height: _coreStageHeight,
        child: Center(
          child: Text(
            'SET LIFE',
            style: TextStyle(
              color: supportingColor,
              fontSize:
                  _isDenseCompact
                      ? AppTheme.fontXs
                      : widget.compact
                      ? AppTheme.fontSm
                      : AppTheme.fontMd,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      key: ValueKey(
        'life-core-${widget.panelIndex}-$eventLabel-$eventValue-${widget.life}-${widget.isHighRollWinner}-${widget.isHighRollTie}',
      ),
      width: _coreStageWidth,
      height: _coreStageHeight,
      child: Center(
        child: Text(
          '${widget.life}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: dominantValueColor,
            fontSize: _isDenseCompact ? 96 : widget.compact ? 112 : 164,
            fontWeight: FontWeight.w900,
            height: 0.88,
            letterSpacing: _isDenseCompact ? -4.6 : widget.compact ? -5.4 : -6.8,
          ),
        ),
      ),
    );
  }
}

class _PlayerInlineAction extends StatelessWidget {
  final Key? actionKey;
  final IconData icon;
  final String label;
  final bool compact;
  final bool dense;
  final bool destructive;
  final VoidCallback onTap;

  const _PlayerInlineAction({
    this.actionKey,
    required this.icon,
    required this.label,
    required this.compact,
    this.dense = false,
    this.destructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? AppTheme.error : AppTheme.textPrimary;
    final isDenseCompact = compact && dense;

    return Material(
      key: actionKey,
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        onTap: onTap,
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: isDenseCompact ? 8 : compact ? 10 : 12,
            vertical: isDenseCompact ? 6 : compact ? 8 : 9,
          ),
          decoration: BoxDecoration(
            color: AppTheme.backgroundAbyss.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(
              color: accent.withValues(alpha: destructive ? 0.3 : 0.18),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: isDenseCompact ? 12 : compact ? 14 : 16, color: accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontSize:
                      isDenseCompact
                          ? AppTheme.fontXs - 1
                          : compact
                          ? AppTheme.fontXs
                          : AppTheme.fontSm,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerCounterConsoleStrip extends StatelessWidget {
  final int poison;
  final int commanderTax;
  final int commanderDamageTotal;
  final bool compact;
  final bool dense;

  const _PlayerCounterConsoleStrip({
    required this.poison,
    required this.commanderTax,
    required this.commanderDamageTotal,
    required this.compact,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDenseCompact = compact && dense;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: isDenseCompact ? 6 : 8,
      runSpacing: 6,
      children: [
        _PlayerCounterConsoleStat(
          label: 'TOX',
          value: '$poison',
          compact: compact,
          dense: dense,
          accent: const Color(0xFF6BFF8D),
          isActive: poison > 0,
        ),
        _PlayerCounterConsoleStat(
          label: 'TAX',
          value: '+$commanderTax',
          compact: compact,
          dense: dense,
          accent: AppTheme.primarySoft,
          isActive: commanderTax > 0,
        ),
        _PlayerCounterConsoleStat(
          label: 'MARKS',
          value: '$commanderDamageTotal',
          compact: compact,
          dense: dense,
          accent:
              commanderDamageTotal >= 21
                  ? AppTheme.error
                  : const Color(0xFFFFB3A8),
          isActive: commanderDamageTotal > 0,
        ),
      ],
    );
  }
}

class _PlayerCounterConsoleStat extends StatelessWidget {
  final String label;
  final String value;
  final bool compact;
  final bool dense;
  final Color accent;
  final bool isActive;

  const _PlayerCounterConsoleStat({
    required this.label,
    required this.value,
    required this.compact,
    this.dense = false,
    required this.accent,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final isDenseCompact = compact && dense;
    final baseColor =
        isActive
            ? accent.withValues(alpha: 0.18)
            : Colors.black.withValues(alpha: 0.34);
    final borderColor =
        isActive
            ? accent.withValues(alpha: 0.42)
            : Colors.white.withValues(alpha: 0.12);
    final labelColor =
        isActive
            ? accent.withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.5);
    final valueColor =
        isActive
            ? Colors.white.withValues(alpha: 0.96)
            : Colors.white.withValues(alpha: 0.7);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor, width: 0.9),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isDenseCompact ? 8 : compact ? 10 : 12,
          vertical: isDenseCompact ? 4 : compact ? 5 : 6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize:
                    isDenseCompact
                        ? AppTheme.fontXs - 2
                        : compact
                        ? AppTheme.fontXs - 1
                        : AppTheme.fontXs,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize:
                    isDenseCompact
                        ? AppTheme.fontXs
                        : compact
                        ? AppTheme.fontSm
                        : AppTheme.fontMd,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LifeQuickAdjustButton extends StatelessWidget {
  final Key? buttonKey;
  final String label;
  final String? semanticLabel;
  final Color color;
  final bool compact;
  final bool dense;
  final VoidCallback onTap;

  const _LifeQuickAdjustButton({
    this.buttonKey,
    required this.label,
    this.semanticLabel,
    required this.color,
    required this.compact,
    this.dense = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDenseCompact = compact && dense;
    return SizedBox(
      width: isDenseCompact ? 44 : compact ? 54 : 60,
      height: isDenseCompact ? 30 : compact ? 38 : 42,
      child: Semantics(
        label: semanticLabel ?? label,
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: buttonKey,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: isDenseCompact ? 22 : compact ? 26 : 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelTakeoverOverlay extends StatelessWidget {
  final Key overlayKey;
  final bool compact;
  final bool dense;
  final Alignment contentAlignment;
  final Color color;
  final Color accent;
  final String title;

  const _PanelTakeoverOverlay({
    required this.overlayKey,
    required this.compact,
    required this.dense,
    required this.contentAlignment,
    required this.color,
    required this.accent,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isDenseCompact = compact && dense;
    return TweenAnimationBuilder<double>(
      key: overlayKey,
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.95),
                  color.withValues(alpha: 0.88),
                ],
              ),
              border: Border.all(
                color: accent.withValues(alpha: 0.92),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.22 * value),
                  blurRadius: isDenseCompact ? 16 : compact ? 22 : 32,
                  spreadRadius: isDenseCompact ? 0.6 : compact ? 1 : 2,
                ),
              ],
            ),
            child: Align(
              alignment: contentAlignment,
              child: Transform.scale(
                scale: 0.92 + (0.08 * value),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.98),
                          fontSize: isDenseCompact ? 26 : compact ? 34 : 44,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.8,
                          height: 0.95,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PanelEventTakeoverOverlay extends StatelessWidget {
  final Key overlayKey;
  final bool compact;
  final bool dense;
  final Alignment contentAlignment;
  final Color color;
  final Color accent;
  final String value;
  final String kind;
  final bool isWinner;
  final bool isTie;

  const _PanelEventTakeoverOverlay({
    required this.overlayKey,
    required this.compact,
    required this.dense,
    required this.contentAlignment,
    required this.color,
    required this.accent,
    required this.value,
    required this.kind,
    required this.isWinner,
    required this.isTie,
  });

  @override
  Widget build(BuildContext context) {
    final isDenseCompact = compact && dense;
    final valueColor = Colors.black.withValues(alpha: 0.96);
    final eventLabel = kind == 'd20' ? 'D20' : 'HIGH ROLL';
    final resultLabel =
        kind == 'd20'
            ? null
            : isTie
            ? 'TIE'
            : isWinner
            ? 'WINNER'
            : null;

    final background =
        isWinner
            ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF9CD1),
                Color(0xFFFFF5A3),
                Color(0xFFB7FFBE),
                Color(0xFFB5C8FF),
              ],
            )
            : isTie
            ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFC55A),
                Color(0xFFFFE596),
                Color(0xFFFFB764),
              ],
            )
            : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomCenter,
              colors: [
                Color.alphaBlend(Colors.white.withValues(alpha: 0.08), color),
                Color.alphaBlend(Colors.black.withValues(alpha: 0.18), color),
                color,
              ],
            );

    return TweenAnimationBuilder<double>(
      key: overlayKey,
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) {
        return Opacity(
          opacity: progress,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: background,
              border: Border.all(
                color:
                    isWinner
                        ? Colors.white.withValues(alpha: 0.42)
                        : isTie
                        ? Colors.black.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.08),
                width: isWinner ? 2 : 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(
                    alpha:
                        isWinner
                            ? 0.28 * progress
                            : isTie
                            ? 0.2 * progress
                            : 0.12 * progress,
                  ),
                  blurRadius:
                      isDenseCompact
                          ? isWinner
                              ? 24
                              : isTie
                              ? 18
                              : 12
                          : isWinner
                          ? 34
                          : isTie
                          ? 26
                          : 18,
                  spreadRadius:
                      isDenseCompact
                          ? isWinner
                              ? 1.5
                              : isTie
                              ? 0.6
                              : 0
                          : isWinner
                          ? 3
                          : isTie
                          ? 1
                          : 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                if (isWinner)
                  ..._buildConfetti(progress),
                if (isTie)
                  ..._buildTieMarkers(progress),
                Positioned(
                  top: isDenseCompact ? 8 : compact ? 12 : 16,
                  left: 0,
                  right: 0,
                  child: Transform.translate(
                    offset: Offset(0, 8 * (1 - progress)),
                    child: Opacity(
                      opacity: Curves.easeOut.transform(progress),
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDenseCompact ? 8 : compact ? 10 : 12,
                            vertical: isDenseCompact ? 4 : compact ? 5 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(
                              alpha: kind == 'd20' ? 0.16 : 0.72,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            eventLabel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  kind == 'd20'
                                      ? valueColor.withValues(alpha: 0.8)
                                      : Colors.white.withValues(alpha: 0.94),
                              fontSize:
                                  isDenseCompact
                                      ? AppTheme.fontXs - 1
                                      : compact
                                      ? AppTheme.fontXs
                                      : AppTheme.fontSm,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: contentAlignment,
                  child: Transform.scale(
                    scale: 0.88 + (0.12 * progress),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDenseCompact ? 8 : compact ? 10 : 14,
                        vertical: isDenseCompact ? 12 : compact ? 18 : 24,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(
                                      alpha:
                                          isWinner
                                              ? 0.26 * progress
                                              : isTie
                                              ? 0.18 * progress
                                              : 0.06 * progress,
                                    ),
                                    blurRadius: isDenseCompact ? 22 : compact ? 34 : 46,
                                    spreadRadius: isDenseCompact ? 1 : compact ? 2 : 3,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: Text(
                                  value,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: valueColor,
                                    fontSize: isDenseCompact ? 120 : compact ? 156 : 228,
                                    fontWeight: FontWeight.w900,
                                    height: 0.78,
                                    letterSpacing: isDenseCompact ? -6.5 : -9,
                                  ),
                                ),
                              ),
                            ),
                            if (resultLabel != null)
                              Padding(
                                padding: EdgeInsets.only(
                                  top: isDenseCompact ? 0 : compact ? 2 : 6,
                                ),
                                child: Transform.translate(
                                  offset: Offset(0, 8 * (1 - progress)),
                                  child: Opacity(
                                    opacity: Curves.easeOut.transform(progress),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal:
                                            isDenseCompact ? 8 : compact ? 10 : 14,
                                        vertical:
                                            isDenseCompact ? 4 : compact ? 5 : 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: isTie ? 0.82 : 0.76,
                                        ),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: isTie ? 0.14 : 0.18,
                                          ),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        resultLabel,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.96,
                                          ),
                                          fontSize:
                                              isDenseCompact
                                                  ? AppTheme.fontXs - 1
                                                  : compact
                                                  ? AppTheme.fontXs
                                                  : AppTheme.fontSm,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildConfetti(double progress) {
    const colors = [
      Color(0xFFFF4C7D),
      Color(0xFF4A5BFF),
      Color(0xFFFFC552),
      Color(0xFF5BDF79),
      Color(0xFFFFFFFF),
    ];
    const positions = [
      (-0.78, -0.82, 18.0),
      (-0.46, -0.58, 14.0),
      (0.48, -0.76, 20.0),
      (0.78, -0.36, 16.0),
      (-0.74, 0.42, 14.0),
      (-0.40, 0.82, 18.0),
      (0.34, 0.62, 16.0),
      (0.74, 0.30, 20.0),
      (0.02, -0.84, 14.0),
      (0.12, 0.92, 14.0),
    ];

    return [
      for (int i = 0; i < positions.length; i++)
        Align(
          alignment: Alignment(positions[i].$1, positions[i].$2),
          child: Transform.rotate(
            angle: i.isEven ? pi / 12 : -pi / 10,
            child: Opacity(
              opacity: 0.78 * progress,
              child: Icon(
                Icons.star_rounded,
                color: colors[i % colors.length].withValues(alpha: 0.9),
                size: positions[i].$3,
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> _buildTieMarkers(double progress) {
    const positions = [
      (-0.78, -0.72),
      (0.78, -0.72),
      (-0.82, 0.68),
      (0.82, 0.68),
    ];

    return [
      for (final position in positions)
        Align(
          alignment: Alignment(position.$1, position.$2),
          child: Opacity(
            opacity: 0.62 * progress,
            child: Transform.rotate(
              angle: pi / 4,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.12),
                    width: 0.8,
                  ),
                ),
              ),
            ),
          ),
        ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Table tools sheet
// ---------------------------------------------------------------------------
class _TableToolsSheet extends StatefulWidget {
  final int playerCount;
  final List<String> playerLabels;
  final int stormCount;
  final int? monarchPlayer;
  final int? initiativePlayer;
  final int? firstPlayerIndex;
  final String? lastTableEvent;
  final Map<int, int> initialHighRollResults;
  final Set<int> initialHighRollWinners;
  final ValueChanged<int> onStormChanged;
  final VoidCallback onStormReset;
  final ValueChanged<int?> onMonarchChanged;
  final ValueChanged<int?> onInitiativeChanged;
  final ValueChanged<int?> onFirstPlayerChanged;
  final String Function() onRollCoinFlip;
  final String Function() onRollD20;
  final int Function() onRollFirstPlayer;
  final Map<int, int> Function() onRunHighRoll;

  const _TableToolsSheet({
    required this.playerCount,
    required this.playerLabels,
    required this.stormCount,
    required this.monarchPlayer,
    required this.initiativePlayer,
    required this.firstPlayerIndex,
    required this.lastTableEvent,
    required this.initialHighRollResults,
    required this.initialHighRollWinners,
    required this.onStormChanged,
    required this.onStormReset,
    required this.onMonarchChanged,
    required this.onInitiativeChanged,
    required this.onFirstPlayerChanged,
    required this.onRollCoinFlip,
    required this.onRollD20,
    required this.onRollFirstPlayer,
    required this.onRunHighRoll,
  });

  @override
  State<_TableToolsSheet> createState() => _TableToolsSheetState();
}

class _TableToolsSheetState extends State<_TableToolsSheet> {
  late int _stormCount;
  late int? _monarchPlayer;
  late int? _initiativePlayer;
  late int? _firstPlayerIndex;
  late String? _lastTableEvent;
  Map<int, int>? _rollOffResults;
  Set<int> _rollOffWinners = const <int>{};

  @override
  void initState() {
    super.initState();
    _stormCount = widget.stormCount;
    _monarchPlayer = widget.monarchPlayer;
    _initiativePlayer = widget.initiativePlayer;
    _firstPlayerIndex = widget.firstPlayerIndex;
    _lastTableEvent = widget.lastTableEvent;
    _rollOffResults =
        widget.initialHighRollResults.isEmpty
            ? null
            : Map<int, int>.from(widget.initialHighRollResults);
    _rollOffWinners = Set<int>.from(widget.initialHighRollWinners);
  }

  void _updateStorm(int delta) {
    setState(() {
      _stormCount = (_stormCount + delta).clamp(0, 999);
    });
    widget.onStormChanged(delta);
  }

  void _resetStorm() {
    setState(() {
      _stormCount = 0;
    });
    widget.onStormReset();
  }

  void _selectMonarch(int? playerIndex) {
    setState(() {
      _monarchPlayer = playerIndex;
    });
    widget.onMonarchChanged(playerIndex);
  }

  void _selectInitiative(int? playerIndex) {
    setState(() {
      _initiativePlayer = playerIndex;
    });
    widget.onInitiativeChanged(playerIndex);
  }

  void _selectFirstPlayer(int? playerIndex) {
    setState(() {
      _firstPlayerIndex = playerIndex;
      if (playerIndex != null) {
        _lastTableEvent =
            'Primeiro jogador: ${widget.playerLabels[playerIndex]}';
      }
    });
    widget.onFirstPlayerChanged(playerIndex);
  }

  void _runCoinFlip() {
    final result = widget.onRollCoinFlip();
    setState(() {
      _lastTableEvent = result;
    });
  }

  void _runD20() {
    final result = widget.onRollD20();
    setState(() {
      _lastTableEvent = result;
    });
  }

  void _runFirstPlayerRoll() {
    final chosen = widget.onRollFirstPlayer();
    setState(() {
      _firstPlayerIndex = chosen;
      _lastTableEvent = 'Primeiro jogador: ${widget.playerLabels[chosen]}';
    });
  }

  void _runRollOff() {
    final wasTieBreaker = _rollOffWinners.length > 1;
    final results = widget.onRunHighRoll();
    final highest = results.values.reduce(max);
    final winners =
        results.entries
            .where((entry) => entry.value == highest)
            .map((entry) => entry.key)
            .toSet();

    setState(() {
      _rollOffResults = results;
      _rollOffWinners = winners;
      if (winners.length == 1) {
        final winner = winners.first;
        _firstPlayerIndex = winner;
        _lastTableEvent =
            '${wasTieBreaker ? 'Desempate do High Roll' : 'Maior resultado'}: ${widget.playerLabels[winner]} com $highest';
      } else {
        _lastTableEvent =
            '${wasTieBreaker ? 'Desempate do High Roll' : 'Empate'} em $highest entre ${winners.map((i) => widget.playerLabels[i]).join(', ')}';
      }
    });

    if (winners.length == 1) {
      widget.onFirstPlayerChanged(winners.first);
    }
  }

  void _rerollTiedPlayers() {
    if (_rollOffWinners.length <= 1) return;
    _runRollOff();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _TableOverlayFrame(
      frameKey: const Key('life-counter-tools-overlay'),
      title: 'TABLE TOOLS',
      subtitle: 'LIVE STATE AND STARTER TOOLS.',
      width: 348,
      maxHeight: 620,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _OverlaySectionHeading('TABLE STATE'),
          const SizedBox(height: 10),
          _CounterRow(
            rowKey: const Key('life-counter-storm-row'),
            icon: Icons.flash_on_rounded,
            label: 'Storm',
            sublabel:
                _stormCount == 0
                    ? 'No spells chained right now'
                    : 'Current stack count',
            value: _stormCount,
            color: AppTheme.warning,
            onIncrement: () => _updateStorm(1),
            onDecrement: () => _updateStorm(-1),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const Key('life-counter-storm-reset'),
              onPressed: _stormCount > 0 ? _resetStorm : null,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('RESET STORM'),
            ),
          ),
          const SizedBox(height: 14),
          _PlayerSelectionCard(
            title: 'Monarch',
            subtitle: 'Who currently holds the crown.',
            chipPrefix: 'MON',
            color: AppTheme.mythicGold,
            playerCount: widget.playerCount,
            playerLabels: widget.playerLabels,
            selectedPlayer: _monarchPlayer,
            clearKey: const Key('life-counter-clear-monarch'),
            onSelected: _selectMonarch,
          ),
          const SizedBox(height: 12),
          _PlayerSelectionCard(
            title: 'Initiative',
            subtitle: 'Who currently has the initiative.',
            chipPrefix: 'INIT',
            color: AppTheme.success,
            playerCount: widget.playerCount,
            playerLabels: widget.playerLabels,
            selectedPlayer: _initiativePlayer,
            clearKey: const Key('life-counter-clear-initiative'),
            onSelected: _selectInitiative,
          ),
          const SizedBox(height: 12),
          _PlayerSelectionCard(
            title: 'First Player',
            subtitle: 'Persist who started the game.',
            chipPrefix: '1ST',
            color: AppTheme.primarySoft,
            playerCount: widget.playerCount,
            playerLabels: widget.playerLabels,
            selectedPlayer: _firstPlayerIndex,
            clearKey: const Key('life-counter-clear-first-player'),
            onSelected: _selectFirstPlayer,
          ),
          const SizedBox(height: 18),
          const _OverlaySectionHeading('QUICK TOOLS'),
          const SizedBox(height: 10),
          _DiceActionRow(
            buttonKey: const Key('life-counter-tool-rolloff'),
            label: _rollOffWinners.length > 1 ? 'TIEBREAK' : 'HIGH ROLL',
            detail:
                _rollOffWinners.length > 1
                    ? 'REROLL TIED PLAYERS'
                    : 'ROLL EVERY PLAYER',
            accent: const Color(0xFF40B9FF),
            emphasized: true,
            onTap: _runRollOff,
          ),
          const SizedBox(height: 10),
          _DiceActionRow(
            buttonKey: const Key('life-counter-tool-d20'),
            label: 'D20',
            detail: 'TABLE DIE',
            onTap: _runD20,
          ),
          const SizedBox(height: 10),
          _DiceActionRow(
            buttonKey: const Key('life-counter-tool-coin'),
            label: 'COIN',
            detail: 'HEADS OR TAILS',
            onTap: _runCoinFlip,
          ),
          const SizedBox(height: 10),
          _DiceActionRow(
            buttonKey: const Key('life-counter-tool-first-player'),
            label: 'ROLL 1ST',
            detail: 'SET STARTING PLAYER',
            onTap: _runFirstPlayerRoll,
          ),
          if (_rollOffResults != null) ...[
            const SizedBox(height: 18),
            Column(
              key: const Key('life-counter-rolloff-results'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _OverlaySectionHeading('HIGH ROLL'),
                const SizedBox(height: 6),
                Text(
                  _rollOffWinners.length == 1
                      ? 'WINNER HIGHLIGHTED BELOW.'
                      : 'TIE DETECTED. REROLL TIED PLAYERS.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (int i = 0; i < widget.playerCount; i++)
                      _RollOffPlayerResult(
                        resultKey: Key('life-counter-rolloff-player-$i'),
                        label: widget.playerLabels[i],
                        value: _rollOffResults![i]!,
                        isWinner: _rollOffWinners.contains(i),
                      ),
                  ],
                ),
                if (_rollOffWinners.length > 1) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      key: const Key('life-counter-rolloff-reroll-ties'),
                      onPressed: _rerollTiedPlayers,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('REROLL TIES'),
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (_lastTableEvent != null) ...[
            const SizedBox(height: 18),
            const _OverlaySectionHeading('LAST EVENT'),
            const SizedBox(height: 8),
            Text(
              key: const Key('life-counter-table-event'),
              _lastTableEvent!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DiceOverlay extends StatelessWidget {
  final bool hasPendingHighRollTie;
  final String? lastTableEvent;
  final VoidCallback onRollCoin;
  final VoidCallback onRollD20;
  final VoidCallback onRollFirstPlayer;
  final VoidCallback onHighRoll;

  const _DiceOverlay({
    required this.hasPendingHighRollTie,
    required this.lastTableEvent,
    required this.onRollCoin,
    required this.onRollD20,
    required this.onRollFirstPlayer,
    required this.onHighRoll,
  });

  @override
  Widget build(BuildContext context) {
    return _TableOverlayFrame(
      frameKey: const Key('life-counter-dice-overlay'),
      title: 'DICE',
      width: 320,
      maxHeight: 440,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _OverlaySectionHeading('PRIMARY'),
          const SizedBox(height: 10),
          _DiceActionRow(
            buttonKey: const Key('life-counter-dice-roll-high-roll'),
            label: hasPendingHighRollTie ? 'TIEBREAK' : 'HIGH ROLL',
            detail:
                hasPendingHighRollTie
                    ? 'REROLL ONLY TIED PLAYERS'
                    : 'ROLL ALL PLAYERS',
            accent: const Color(0xFF40B9FF),
            emphasized: true,
            onTap: () {
              onHighRoll();
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 18),
          const _OverlaySectionHeading('QUICK ROLLS'),
          const SizedBox(height: 10),
          _DiceActionRow(
            buttonKey: const Key('life-counter-dice-roll-d20'),
            label: 'D20',
            detail: 'TABLE DIE',
            onTap: () {
              onRollD20();
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 10),
          _DiceActionRow(
            buttonKey: const Key('life-counter-dice-roll-coin'),
            label: 'COIN',
            detail: 'HEADS OR TAILS',
            onTap: () {
              onRollCoin();
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 10),
          _DiceActionRow(
            buttonKey: const Key('life-counter-dice-roll-first-player'),
            label: 'ROLL 1ST',
            detail: 'CHOOSE STARTING PLAYER',
            onTap: () {
              onRollFirstPlayer();
              Navigator.of(context).pop();
            },
          ),
          if (lastTableEvent != null) ...[
            const SizedBox(height: 18),
            const _OverlaySectionHeading('LAST EVENT'),
            const SizedBox(height: 10),
            Text(
              key: const Key('life-counter-dice-last-event'),
              lastTableEvent!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.86),
                fontSize: AppTheme.fontMd,
                fontWeight: FontWeight.w800,
                height: 1.35,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DiceActionRow extends StatelessWidget {
  final Key buttonKey;
  final String label;
  final String detail;
  final Color? accent;
  final bool emphasized;
  final VoidCallback onTap;

  const _DiceActionRow({
    required this.buttonKey,
    required this.label,
    required this.detail,
    this.accent,
    this.emphasized = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = accent ?? Colors.white;
    return Material(
      key: buttonKey,
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(emphasized ? 22 : 16),
        onTap: onTap,
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: emphasized ? 18 : 16,
            vertical: emphasized ? 18 : 14,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: emphasized ? 0.56 : 0.32),
            borderRadius: BorderRadius.circular(emphasized ? 22 : 16),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: emphasized ? 26 : 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: emphasized ? 0.8 : 0.5,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      detail,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.68),
                        fontSize: AppTheme.fontXs,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: borderColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: borderColor.withValues(alpha: 0.7),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  emphasized ? 'RUN' : 'GO',
                  style: TextStyle(
                    color: borderColor,
                    fontSize: AppTheme.fontXs,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RollOffPlayerResult extends StatelessWidget {
  final Key? resultKey;
  final String label;
  final int value;
  final bool isWinner;

  const _RollOffPlayerResult({
    this.resultKey,
    required this.label,
    required this.value,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: resultKey,
      width: 132,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:
            isWinner
                ? AppTheme.primarySoft.withValues(alpha: 0.12)
                : AppTheme.backgroundAbyss.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color:
              isWinner
                  ? AppTheme.primarySoft.withValues(alpha: 0.28)
                  : AppTheme.outlineMuted.withValues(alpha: 0.75),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: AppTheme.fontSm,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.fontXxl,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (isWinner) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.emoji_events_rounded,
                  size: 16,
                  color: AppTheme.primarySoft,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SetLifeOverlay extends StatefulWidget {
  final String playerLabel;
  final int initialLife;
  final ValueChanged<int> onApply;

  const _SetLifeOverlay({
    required this.playerLabel,
    required this.initialLife,
    required this.onApply,
  });

  @override
  State<_SetLifeOverlay> createState() => _SetLifeOverlayState();
}

class _SetLifeOverlayState extends State<_SetLifeOverlay> {
  late String _buffer;

  @override
  void initState() {
    super.initState();
    _buffer = widget.initialLife.toString();
  }

  void _appendDigit(String digit) {
    setState(() {
      if (_buffer == '0') {
        _buffer = digit;
      } else if (_buffer.length < 3) {
        _buffer += digit;
      }
    });
  }

  void _clear() {
    setState(() {
      _buffer = '0';
    });
  }

  void _backspace() {
    setState(() {
      if (_buffer.length <= 1) {
        _buffer = '0';
      } else {
        _buffer = _buffer.substring(0, _buffer.length - 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayValue = _buffer.isEmpty ? '0' : _buffer;
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.74),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 330),
                child: Column(
                  key: const Key('life-counter-set-life-overlay'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.playerLabel.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.28),
                        fontSize: AppTheme.fontSm,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      key: const Key('life-counter-set-life-display'),
                      height: 72,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            displayValue,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 72,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -3,
                              height: 0.9,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 250,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          for (final digit in [
                            '1',
                            '2',
                            '3',
                            '4',
                            '5',
                            '6',
                            '7',
                            '8',
                            '9',
                          ])
                            _SetLifeKeypadButton(
                              buttonKey: Key('life-counter-set-life-digit-$digit'),
                              label: digit,
                              onTap: () => _appendDigit(digit),
                            ),
                          _SetLifeKeypadButton(
                            buttonKey: const Key('life-counter-set-life-clear'),
                            label: 'C',
                            onTap: _clear,
                            destructive: true,
                          ),
                          _SetLifeKeypadButton(
                            buttonKey: const Key('life-counter-set-life-digit-0'),
                            label: '0',
                            onTap: () => _appendDigit('0'),
                          ),
                          _SetLifeKeypadButton(
                            buttonKey: const Key('life-counter-set-life-backspace'),
                            label: 'âŒ«',
                            onTap: _backspace,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'CANCEL',
                            style: TextStyle(
                              color: Color(0xFFFF2C77),
                              fontSize: AppTheme.fontMd,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        TextButton(
                          key: const Key('life-counter-set-life-apply'),
                          onPressed:
                              () => widget.onApply(
                                int.tryParse(displayValue) ?? 0,
                              ),
                          child: Text(
                            'SET LIFE',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.56),
                              fontSize: AppTheme.fontMd,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetLifeKeypadButton extends StatelessWidget {
  final Key buttonKey;
  final String label;
  final bool destructive;
  final VoidCallback onTap;

  const _SetLifeKeypadButton({
    required this.buttonKey,
    required this.label,
    this.destructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      key: buttonKey,
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFF454257),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color:
                    destructive
                        ? const Color(0xFFFF2C77)
                        : Colors.white.withValues(alpha: 0.96),
                fontSize: label == 'âŒ«' ? 22 : 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BenchmarkSetLifeOverlay extends StatefulWidget {
  final String playerLabel;
  final int initialLife;
  final ValueChanged<int> onApply;

  const _BenchmarkSetLifeOverlay({
    required this.playerLabel,
    required this.initialLife,
    required this.onApply,
  });

  @override
  State<_BenchmarkSetLifeOverlay> createState() =>
      _BenchmarkSetLifeOverlayState();
}

class _BenchmarkSetLifeOverlayState extends State<_BenchmarkSetLifeOverlay> {
  late String _buffer;

  @override
  void initState() {
    super.initState();
    _buffer = widget.initialLife.toString();
  }

  void _appendDigit(String digit) {
    setState(() {
      if (_buffer == '0') {
        _buffer = digit;
      } else if (_buffer.length < 3) {
        _buffer += digit;
      }
    });
  }

  void _clear() {
    setState(() {
      _buffer = '0';
    });
  }

  void _backspace() {
    setState(() {
      if (_buffer.length <= 1) {
        _buffer = '0';
      } else {
        _buffer = _buffer.substring(0, _buffer.length - 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayValue = _buffer.isEmpty ? '0' : _buffer;
    final parsedValue = int.tryParse(displayValue) ?? 0;
    final hasChanges = parsedValue != widget.initialLife;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.76),
                ),
              ),
            ),
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                builder: (context, progress, child) {
                  return Opacity(
                    opacity: progress,
                    child: Transform.translate(
                      offset: Offset(0, 18 * (1 - progress)),
                      child: Transform.scale(
                        scale: 0.96 + (0.04 * progress),
                        child: child,
                      ),
                    ),
                  );
                },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 338),
                  child: Column(
                    key: const Key('life-counter-set-life-overlay'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.playerLabel.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.28),
                          fontSize: AppTheme.fontSm,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        key: const Key('life-counter-set-life-shell'),
                        padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.34),
                              blurRadius: 36,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              key: const Key('life-counter-set-life-display'),
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  transitionBuilder: (child, animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.08),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    displayValue,
                                    key: ValueKey(displayValue),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 76,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -3.4,
                                      height: 0.88,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: 270,
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 14,
                                runSpacing: 14,
                                children: [
                                  for (final digit in [
                                    '1',
                                    '2',
                                    '3',
                                    '4',
                                    '5',
                                    '6',
                                    '7',
                                    '8',
                                    '9',
                                  ])
                                    _BenchmarkSetLifeKeypadButton(
                                      buttonKey: Key(
                                        'life-counter-set-life-digit-$digit',
                                      ),
                                      label: digit,
                                      onTap: () => _appendDigit(digit),
                                    ),
                                  _BenchmarkSetLifeKeypadButton(
                                    buttonKey: const Key(
                                      'life-counter-set-life-clear',
                                    ),
                                    label: 'C',
                                    onTap: _clear,
                                    destructive: true,
                                  ),
                                  _BenchmarkSetLifeKeypadButton(
                                    buttonKey: const Key(
                                      'life-counter-set-life-digit-0',
                                    ),
                                    label: '0',
                                    onTap: () => _appendDigit('0'),
                                  ),
                                  _BenchmarkSetLifeKeypadButton(
                                    buttonKey: const Key(
                                      'life-counter-set-life-backspace',
                                    ),
                                    label: 'DEL',
                                    onTap: _backspace,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text(
                                    'CANCEL',
                                    style: TextStyle(
                                      color: Color(0xFFFF2C77),
                                      fontSize: AppTheme.fontMd,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 26),
                                TextButton(
                                  key: const Key('life-counter-set-life-apply'),
                                  onPressed: () => widget.onApply(parsedValue),
                                  child: Text(
                                    'SET LIFE',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: hasChanges ? 0.72 : 0.38,
                                      ),
                                      fontSize: AppTheme.fontMd,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenchmarkSetLifeKeypadButton extends StatelessWidget {
  final Key buttonKey;
  final String label;
  final bool destructive;
  final VoidCallback onTap;

  const _BenchmarkSetLifeKeypadButton({
    required this.buttonKey,
    required this.label,
    this.destructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      key: buttonKey,
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: const Color(0xFF171717),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: destructive ? 0.06 : 0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color:
                    destructive
                        ? const Color(0xFFFF2C77)
                        : Colors.white.withValues(alpha: 0.96),
                fontSize: label == 'DEL' ? 17 : 30,
                fontWeight: FontWeight.w900,
                letterSpacing: label == 'DEL' ? 1.2 : 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerSelectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String chipPrefix;
  final Color color;
  final int playerCount;
  final List<String> playerLabels;
  final int? selectedPlayer;
  final Key clearKey;
  final ValueChanged<int?> onSelected;

  const _PlayerSelectionCard({
    required this.title,
    required this.subtitle,
    required this.chipPrefix,
    required this.color,
    required this.playerCount,
    required this.playerLabels,
    required this.selectedPlayer,
    required this.clearKey,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textHint,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < playerCount; i++)
                ChoiceChip(
                  key: Key('life-counter-${title.toLowerCase()}-$i'),
                  label: Text('$chipPrefix ${playerLabels[i]}'),
                  selected: selectedPlayer == i,
                  onSelected: (_) => onSelected(i),
                  selectedColor: color,
                  labelStyle: TextStyle(
                    color:
                        selectedPlayer == i
                            ? Colors.white
                            : AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ActionChip(
                key: clearKey,
                label: const Text('Limpar'),
                onPressed: () => onSelected(null),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Counters Overlay (poison, commander damage, energy, experience)
// ---------------------------------------------------------------------------
class _CountersOverlay extends StatefulWidget {
  final int playerIndex;
  final int playerCount;
  final Color playerColor;
  final String playerLabel;
  final int initialPoison;
  final int initialEnergy;
  final int initialExperience;
  final int initialCommanderCasts;
  final List<int> initialCommanderDamage;
  final List<Color> playerColors;
  final List<String> playerLabels;
  final ValueChanged<int> onPoisonChanged;
  final ValueChanged<int> onEnergyChanged;
  final ValueChanged<int> onExperienceChanged;
  final ValueChanged<int> onCommanderCastsChanged;
  final Function(int source, int delta) onCommanderDamageChanged;

  const _CountersOverlay({
    required this.playerIndex,
    required this.playerCount,
    required this.playerColor,
    required this.playerLabel,
    required this.initialPoison,
    required this.initialEnergy,
    required this.initialExperience,
    required this.initialCommanderCasts,
    required this.initialCommanderDamage,
    required this.playerColors,
    required this.playerLabels,
    required this.onPoisonChanged,
    required this.onEnergyChanged,
    required this.onExperienceChanged,
    required this.onCommanderCastsChanged,
    required this.onCommanderDamageChanged,
  });

  @override
  State<_CountersOverlay> createState() => _CountersOverlayState();
}

class _CountersOverlayState extends State<_CountersOverlay> {
  late int _poison;
  late int _energy;
  late int _experience;
  late int _commanderCasts;
  late List<int> _cmdDamage;

  @override
  void initState() {
    super.initState();
    _poison = widget.initialPoison;
    _energy = widget.initialEnergy;
    _experience = widget.initialExperience;
    _commanderCasts = widget.initialCommanderCasts;
    _cmdDamage = List.of(widget.initialCommanderDamage);
  }

  void _updatePoison(int delta) {
    setState(() {
      _poison = (_poison + delta).clamp(0, 99);
    });
    widget.onPoisonChanged(delta);
  }

  void _updateEnergy(int delta) {
    setState(() {
      _energy = (_energy + delta).clamp(0, 999);
    });
    widget.onEnergyChanged(delta);
  }

  void _updateExperience(int delta) {
    setState(() {
      _experience = (_experience + delta).clamp(0, 999);
    });
    widget.onExperienceChanged(delta);
  }

  void _updateCommanderCasts(int delta) {
    setState(() {
      _commanderCasts = (_commanderCasts + delta).clamp(0, 21);
    });
    widget.onCommanderCastsChanged(delta);
  }

  void _updateCmdDamage(int source, int delta) {
    setState(() {
      _cmdDamage[source] = (_cmdDamage[source] + delta).clamp(0, 99);
    });
    widget.onCommanderDamageChanged(source, delta);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _TableOverlayFrame(
      frameKey: const Key('life-counter-counters-overlay'),
      title: 'TRACKERS',
      subtitle: 'Mesa-first trackers for ${widget.playerLabel}.',
      width: 356,
      maxHeight: 640,
      child: Column(
        key: const Key('life-counter-counters-sheet'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OverlaySectionHeading(
            widget.playerLabel.toUpperCase(),
          ),
          const SizedBox(height: 12),
          _CounterRow(
            rowKey: const Key('life-counter-poison-row'),
            valueKey: const Key('life-counter-poison-value'),
            icon: Icons.coronavirus,
            label: 'TOXIC',
            sublabel: _poison >= 10 ? 'â˜  LETAL (â‰¥10)' : '10 = derrota',
            value: _poison,
            color: AppTheme.success,
            isLethal: _poison >= 10,
            onIncrement: () => _updatePoison(1),
            onDecrement: () => _updatePoison(-1),
          ),
          const SizedBox(height: 12),
          _CounterRow(
            rowKey: const Key('life-counter-commander-casts-row'),
            sublabelKey: const Key(
              'life-counter-commander-casts-sublabel',
            ),
            valueKey: const Key('life-counter-commander-casts-value'),
            icon: Icons.local_fire_department_outlined,
            label: 'CAST TAX',
            sublabel:
                _commanderCasts == 0
                    ? 'Current tax: 0 mana'
                    : 'Current tax: +${_commanderCasts * 2} mana',
            value: _commanderCasts,
            color: AppTheme.warning,
            onIncrement: () => _updateCommanderCasts(1),
            onDecrement: () => _updateCommanderCasts(-1),
          ),
          const SizedBox(height: 18),
          const _OverlaySectionHeading('COMMANDER DAMAGE'),
          const SizedBox(height: 6),
          Text(
            '21 de uma mesma fonte = derrota',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(widget.playerCount, (sourceIdx) {
            if (sourceIdx == widget.playerIndex) {
              return const SizedBox.shrink();
            }
            final dmg = _cmdDamage[sourceIdx];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _CounterRow(
                icon: Icons.shield,
                label: 'De ${widget.playerLabels[sourceIdx]}',
                sublabel: dmg >= 21 ? 'â˜  LETAL (â‰¥21)' : null,
                value: dmg,
                color: widget.playerColors[sourceIdx],
                isLethal: dmg >= 21,
                onIncrement: () => _updateCmdDamage(sourceIdx, 1),
                onDecrement: () => _updateCmdDamage(sourceIdx, -1),
              ),
            );
          }),
          const SizedBox(height: 10),
          _CounterRow(
            icon: Icons.bolt,
            label: 'ENERGY',
            value: _energy,
            color: AppTheme.mythicGold,
            onIncrement: () => _updateEnergy(1),
            onDecrement: () => _updateEnergy(-1),
          ),
          const SizedBox(height: 12),
          _CounterRow(
            icon: Icons.star,
            label: 'XP',
            value: _experience,
            color: AppTheme.primarySoft,
            onIncrement: () => _updateExperience(1),
            onDecrement: () => _updateExperience(-1),
          ),
        ],
      ),
    );
  }
}

class _CommanderDamageQuickOverlay extends StatefulWidget {
  final int playerIndex;
  final int playerCount;
  final String playerLabel;
  final List<int> initialCommanderDamage;
  final List<Color> playerColors;
  final List<String> playerLabels;
  final Function(int source, int delta) onCommanderDamageChanged;

  const _CommanderDamageQuickOverlay({
    required this.playerIndex,
    required this.playerCount,
    required this.playerLabel,
    required this.initialCommanderDamage,
    required this.playerColors,
    required this.playerLabels,
    required this.onCommanderDamageChanged,
  });

  @override
  State<_CommanderDamageQuickOverlay> createState() =>
      _CommanderDamageQuickOverlayState();
}

class _CommanderDamageQuickOverlayState
    extends State<_CommanderDamageQuickOverlay> {
  late List<int> _cmdDamage;

  @override
  void initState() {
    super.initState();
    _cmdDamage = List.of(widget.initialCommanderDamage);
  }

  void _updateCmdDamage(int source, int delta) {
    setState(() {
      _cmdDamage[source] = (_cmdDamage[source] + delta).clamp(0, 99);
    });
    widget.onCommanderDamageChanged(source, delta);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lethalSources = <int>[
      for (int i = 0; i < widget.playerCount; i++)
        if (i != widget.playerIndex && _cmdDamage[i] >= 21) i,
    ];

    return _TableOverlayFrame(
      frameKey: const Key('life-counter-commander-damage-quick-overlay'),
      title: 'COMMANDER DAMAGE',
      subtitle: 'MARKS BY SOURCE FOR ${widget.playerLabel.toUpperCase()}.',
      width: 332,
      maxHeight: 560,
      child: Column(
        key: const Key('life-counter-commander-damage-quick-sheet'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lethalSources.isNotEmpty) ...[
            Container(
              key: const Key(
                'life-counter-quick-commander-damage-lethal-summary',
              ),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppTheme.error.withValues(alpha: 0.28),
                  width: 1,
                ),
              ),
              child: Text(
                lethalSources.length == 1
                    ? 'LETAL por dano de comandante de ${widget.playerLabels[lethalSources.first]}.'
                    : 'LETAL por dano de comandante de ${lethalSources.map((i) => widget.playerLabels[i]).join(', ')}.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          ...List.generate(widget.playerCount, (sourceIdx) {
            if (sourceIdx == widget.playerIndex) {
              return const SizedBox.shrink();
            }
            final dmg = _cmdDamage[sourceIdx];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _CommanderDamageQuickRow(
                rowKey: Key(
                  'life-counter-quick-commander-damage-row-$sourceIdx',
                ),
                decrementKey: Key(
                  'life-counter-quick-commander-damage-minus-$sourceIdx',
                ),
                incrementKey: Key(
                  'life-counter-quick-commander-damage-plus-$sourceIdx',
                ),
                valueKey: Key(
                  'life-counter-quick-commander-damage-value-$sourceIdx',
                ),
                label: widget.playerLabels[sourceIdx],
                value: dmg,
                color: widget.playerColors[sourceIdx],
                isLethal: dmg >= 21,
                onIncrement: () => _updateCmdDamage(sourceIdx, 1),
                onDecrement: () => _updateCmdDamage(sourceIdx, -1),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CommanderDamageQuickRow extends StatelessWidget {
  final Key rowKey;
  final Key decrementKey;
  final Key incrementKey;
  final Key valueKey;
  final String label;
  final int value;
  final Color color;
  final bool isLethal;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _CommanderDamageQuickRow({
    required this.rowKey,
    required this.decrementKey,
    required this.incrementKey,
    required this.valueKey,
    required this.label,
    required this.value,
    required this.color,
    required this.isLethal,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isLethal ? AppTheme.error : color;
    return Container(
      key: rowKey,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:
            isLethal
                ? AppTheme.error.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isLethal
                  ? AppTheme.error.withValues(alpha: 0.34)
                  : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: AppTheme.fontSm,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isLethal ? 'COMMANDER LETHAL' : 'MARKS FROM THIS SOURCE',
                  style: TextStyle(
                    color:
                        isLethal
                            ? AppTheme.error.withValues(alpha: 0.92)
                            : AppTheme.textSecondary,
                    fontSize: AppTheme.fontXs,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          _RoundButton(
            buttonKey: decrementKey,
            icon: Icons.remove,
            color: accent,
            onTap: value > 0 ? onDecrement : null,
          ),
          SizedBox(
            width: 44,
            child: Center(
              child: Text(
                key: valueKey,
                '$value',
                style: TextStyle(
                  color: isLethal ? AppTheme.error : AppTheme.textPrimary,
                  fontSize: AppTheme.fontXl,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          _RoundButton(
            buttonKey: incrementKey,
            icon: Icons.add,
            color: accent,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Counter Row (reusable +/- row for any counter type)
// ---------------------------------------------------------------------------
class _CounterRow extends StatelessWidget {
  final Key? rowKey;
  final Key? sublabelKey;
  final Key? valueKey;
  final IconData icon;
  final String label;
  final String? sublabel;
  final int value;
  final Color color;
  final bool isLethal;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _CounterRow({
    this.rowKey,
    this.sublabelKey,
    this.valueKey,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onIncrement,
    required this.onDecrement,
    this.sublabel,
    this.isLethal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: rowKey,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:
            isLethal
                ? AppTheme.error.withValues(alpha: 0.15)
                : AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color:
              isLethal
                  ? AppTheme.error.withValues(alpha: 0.5)
                  : color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: isLethal ? AppTheme.error : color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: AppTheme.fontMd,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (sublabel != null)
                  Text(
                    key: sublabelKey,
                    sublabel!,
                    style: TextStyle(
                      color: isLethal ? AppTheme.error : AppTheme.textHint,
                      fontSize: AppTheme.fontXs,
                    ),
                  ),
              ],
            ),
          ),
          // Minus button
          _RoundButton(
            icon: Icons.remove,
            color: color,
            onTap: value > 0 ? onDecrement : null,
          ),
          // Value
          SizedBox(
            width: 40,
            child: Center(
              child: Text(
                key: valueKey,
                '$value',
                style: TextStyle(
                  color: isLethal ? AppTheme.error : color,
                  fontSize: AppTheme.fontXl,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Plus button
          _RoundButton(
            icon: Icons.add,
            color: color,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Round + / - button for counter rows
// ---------------------------------------------------------------------------
class _RoundButton extends StatelessWidget {
  final Key? buttonKey;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _RoundButton({
    this.buttonKey,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: buttonKey,
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                enabled
                    ? color.withValues(alpha: 0.15)
                    : AppTheme.outlineMuted.withValues(alpha: 0.3),
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? color : AppTheme.textHint,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Settings Overlay
// ---------------------------------------------------------------------------

/// Overlay de mesa para configurar nÃºmero de jogadores e vida inicial.
class _SettingsSheet extends StatelessWidget {
  final int twoPlayerStartingLife;
  final int multiPlayerStartingLife;
  final ValueChanged<int> onTwoPlayerStartingLifeChanged;
  final ValueChanged<int> onMultiPlayerStartingLifeChanged;

  const _SettingsSheet({
    required this.twoPlayerStartingLife,
    required this.multiPlayerStartingLife,
    required this.onTwoPlayerStartingLifeChanged,
    required this.onMultiPlayerStartingLifeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _TableOverlayFrame(
      frameKey: const Key('life-counter-settings-overlay'),
      title: 'SETTINGS',
      width: 336,
      maxHeight: 560,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _OverlaySectionHeading('MULTI-PLAYER STARTING LIFE'),
          const SizedBox(height: 10),
          _StartingLifePresetRow(
            prefix: 'life-counter-settings-multi',
            selectedLife: multiPlayerStartingLife,
            onSelected: onMultiPlayerStartingLifeChanged,
          ),
          const SizedBox(height: 24),
          const _OverlaySectionHeading('TWO-PLAYER STARTING LIFE'),
          const SizedBox(height: 10),
          _StartingLifePresetRow(
            prefix: 'life-counter-settings-two-player',
            selectedLife: twoPlayerStartingLife,
            onSelected: onTwoPlayerStartingLifeChanged,
          ),
          const SizedBox(height: 28),
          const _OverlaySectionHeading('GAME MODES'),
          const SizedBox(height: 12),
          const _SettingsToggleRow(
            rowKey: Key('life-counter-settings-mode-planechase'),
            label: 'ENABLE PLANECHASE',
          ),
          const SizedBox(height: 10),
          const _SettingsToggleRow(
            rowKey: Key('life-counter-settings-mode-archenemy'),
            label: 'ENABLE ARCHENEMY',
          ),
          const SizedBox(height: 10),
          const _SettingsToggleRow(
            rowKey: Key('life-counter-settings-mode-bounty'),
            label: 'ENABLE BOUNTY',
          ),
          const SizedBox(height: 28),
          const _OverlaySectionHeading('GAMEPLAY'),
          const SizedBox(height: 12),
          const _SettingsToggleRow(
            rowKey: Key('life-counter-settings-gameplay-turn-tracker'),
            label: 'ENABLE TURN TRACKER',
          ),
          const SizedBox(height: 10),
          const _SettingsToggleRow(
            rowKey: Key('life-counter-settings-gameplay-high-roll'),
            label: 'HIGH-ROLL AT GAME START',
          ),
          const SizedBox(height: 10),
          const _SettingsToggleRow(
            rowKey: Key('life-counter-settings-gameplay-game-timer'),
            label: 'ENABLE GAME TIMER',
          ),
          const SizedBox(height: 10),
          const _SettingsToggleRow(
            rowKey: Key('life-counter-settings-gameplay-auto-kill'),
            label: 'AUTO-KILL',
            subtitle: 'Kill player from life, poison, or commander damage',
            selected: true,
          ),
        ],
      ),
    );
  }
}

class _StartingLifePresetRow extends StatelessWidget {
  final String prefix;
  final int selectedLife;
  final ValueChanged<int> onSelected;

  const _StartingLifePresetRow({
    required this.prefix,
    required this.selectedLife,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final life in const [40, 30, 20]) ...[
          _StartingLifePresetButton(
            buttonKey: Key('$prefix-$life'),
            life: life,
            selected: selectedLife == life,
            onTap: () => onSelected(life),
          ),
          if (life != 20) const SizedBox(width: 10),
        ],
        const SizedBox(width: 10),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
        ),
      ],
    );
  }
}

class _StartingLifePresetButton extends StatelessWidget {
  final Key buttonKey;
  final int life;
  final bool selected;
  final VoidCallback onTap;

  const _StartingLifePresetButton({
    required this.buttonKey,
    required this.life,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      key: buttonKey,
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFC81E) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFFFFC81E) : Colors.white,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '$life',
              style: TextStyle(
                color: selected ? Colors.black : Colors.white,
                fontSize: AppTheme.fontLg,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  final Key rowKey;
  final String label;
  final String? subtitle;
  final bool selected;

  const _SettingsToggleRow({
    required this.rowKey,
    required this.label,
    this.subtitle,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      key: rowKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? const Color(0xFF1C78FF) : Colors.white,
              width: 2.2,
            ),
            color: selected ? const Color(0xFF1C78FF) : Colors.transparent,
          ),
          child:
              selected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                  : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppTheme.fontMd,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.48),
                    fontSize: AppTheme.fontXs,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: 0.3,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
