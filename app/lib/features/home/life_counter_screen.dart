import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';

/// Snapshot of all player state for undo support.
class _GameSnapshot {
  final List<int> lives;
  final List<int> poison;
  final List<int> energy;
  final List<int> experience;
  final List<int> commanderCasts;
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

/// Contador de vida completo para partidas de Magic: The Gathering.
///
/// Suporta 2, 3 ou 4 jogadores, com:
/// - Vida (life total)
/// - Veneno / Poison counters (10 = derrota)
/// - Dano de Comandante por oponente (21 = derrota)
/// - Energy e Experience counters
/// - Histórico com undo
class LifeCounterScreen extends StatefulWidget {
  final Random? randomOverride;

  const LifeCounterScreen({super.key, this.randomOverride});

  @override
  State<LifeCounterScreen> createState() => _LifeCounterScreenState();
}

class _LifeCounterScreenState extends State<LifeCounterScreen> {
  static const _sessionPrefsKey = 'life_counter_session_v1';
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
  ];

  static const _playerLabels = [
    'Jogador 1',
    'Jogador 2',
    'Jogador 3',
    'Jogador 4',
  ];

  Random get _random => widget.randomOverride ?? _runtimeRandom;
  int get _startingLife =>
      _playerCount == 2 ? _startingLifeTwoPlayer : _startingLifeMultiPlayer;

  @override
  void initState() {
    super.initState();
    _initAll();
    _restorePersistedSession();
  }

  void _initAll() {
    _lives = List.generate(_playerCount, (_) => _startingLife);
    _poison = List.generate(_playerCount, (_) => 0);
    _energy = List.generate(_playerCount, (_) => 0);
    _experience = List.generate(_playerCount, (_) => 0);
    _commanderCasts = List.generate(_playerCount, (_) => 0);
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

  void _undo() {
    if (_history.isEmpty) return;
    HapticFeedback.selectionClick();
    final snap = _history.removeLast();
    setState(() {
      _lives = snap.lives;
      _poison = snap.poison;
      _energy = snap.energy;
      _experience = snap.experience;
      _commanderCasts = snap.commanderCasts;
      _lastPlayerRolls = snap.lastPlayerRolls;
      _lastHighRolls = snap.lastHighRolls;
      _highRollWinners = _deriveHighRollWinners(snap.lastHighRolls);
      _commanderDamage = snap.commanderDamage;
      _stormCount = snap.stormCount;
      _monarchPlayer = snap.monarchPlayer;
      _initiativePlayer = snap.initiativePlayer;
      _firstPlayerIndex = snap.firstPlayerIndex;
      _lastTableEvent = snap.lastTableEvent;
    });
    _persistSession();
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
    HapticFeedback.mediumImpact();
    _saveSnapshot();
    setState(() {
      if (_lives[player] > 0) {
        _lives[player] = 0;
        _lastTableEvent = '${_playerLabels[player]} marcado como morto';
      } else {
        _lives[player] = _startingLife;
        _lastTableEvent =
            '${_playerLabels[player]} voltou com $_startingLife de vida';
      }
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
      if (playerCount == null || playerCount < 2 || playerCount > 4) {
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
      // Ignora sessão inválida sem travar a tela.
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
      barrierLabel: 'Fechar configurações',
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
      barrierLabel: 'Fechar seleção de jogadores',
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
      barrierLabel: 'Fechar histórico',
      builder:
          (ctx) => _SimpleTableOverlay(
            title: 'HISTORY',
            body:
                _lastTableEvent == null
                    ? 'Nenhum evento de mesa registrado ainda.'
                    : 'Último evento: $_lastTableEvent\n\nSnapshots salvos: ${_history.length}',
          ),
    );
  }

  void _showCardSearchDialog() {
    _showTableOverlayDialog(
      barrierLabel: 'Fechar busca de cartas',
      builder:
          (ctx) => const _SimpleTableOverlay(
            title: 'CARD SEARCH',
            body:
                'Entrada reservada para a adaptação MTG dentro da shell clonada. Nesta fase, o foco é convergir a mesa ao benchmark.',
          ),
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

  void _showCountersSheet(int playerIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceSlate,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder:
          (ctx) => _CountersSheet(
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

  void _showCommanderDamageQuickSheet(int playerIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceSlate,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder:
          (ctx) => _CommanderDamageQuickSheet(
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
          (ctx) => _SetLifeOverlay(
            playerLabel: _playerLabels[playerIndex],
            initialLife: _lives[playerIndex],
            onApply: (life) {
              _setLifeTotal(playerIndex, life);
              Navigator.of(ctx).pop();
            },
          ),
    );
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
                  padding: const EdgeInsets.fromLTRB(3, 3, 3, 6),
                  child:
                      _playerCount <= 2
                          ? _buildTwoPlayers()
                          : _buildGridPlayers(),
                ),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: _TableControlHub(
                  isExpanded: _isHubExpanded,
                  playerCount: _playerCount,
                  startingLife: _startingLife,
                  canUndo: _history.isNotEmpty,
                  stormCount: _stormCount,
                  monarchLabel:
                      _monarchPlayer == null
                          ? null
                          : 'Monarca ${_playerLabels[_monarchPlayer!]}',
                  initiativeLabel:
                      _initiativePlayer == null
                          ? null
                          : 'Iniciativa ${_playerLabels[_initiativePlayer!]}',
                  firstPlayerLabel:
                      _firstPlayerIndex == null
                          ? null
                          : '1º ${_playerLabels[_firstPlayerIndex!]}',
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
                  onQuickCoin: _rollCoinFlip,
                  onQuickD20: _rollD20,
                  onQuickFirstPlayer: _rollFirstPlayer,
                  onUndo: _history.isNotEmpty ? _undo : null,
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
          ],
        ),
      ),
    );
  }

  Widget _buildTwoPlayers() {
    return Column(
      children: List.generate(_playerCount, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(3, i == 0 ? 0 : 3, 3, 3),
            child: _PlayerPanel(
              panelIndex: i,
              label: _playerLabels[i],
              life: _lives[i],
              poison: _poison[i],
              commanderTax: _commanderCasts[i] * 2,
              commanderDamageTotal: _totalCommanderDamage(i),
              commanderDamageLeadSourceLabel: _commanderDamageLeadSourceLabel(i),
              commanderDamageLeadSourceValue: _commanderDamageLeadSourceValue(i),
              lastPlayerRoll: _lastPlayerRolls[i],
              highRollValue: _lastHighRolls[i],
              isHighRollWinner: _highRollWinners.contains(i),
              isHighRollTie:
                  _highRollWinners.length > 1 && _highRollWinners.contains(i),
              isMonarch: _monarchPlayer == i,
              hasInitiative: _initiativePlayer == i,
              color: _playerColors[i],
              onIncrement: () => _changeLife(i, 1),
              onQuickIncrement: () => _changeLife(i, 5),
              onDecrement: () => _changeLife(i, -1),
              onQuickDecrement: () => _changeLife(i, -5),
              onPoisonIncrement: () => _changePoison(i, 1),
              onPoisonDecrement: () => _changePoison(i, -1),
              onCommanderTaxIncrement: () => _changeCommanderCasts(i, 1),
              onCommanderTaxDecrement: () => _changeCommanderCasts(i, -1),
              onOpenCommanderDamageQuick:
                  () => _showCommanderDamageQuickSheet(i),
              onOpenSetLife: () => _showSetLifeDialog(i),
              onPlayerRollD20: () => _rollPlayerD20(i),
              onToggleDefeated: () => _togglePlayerDefeated(i),
              onCountersTap: () => _showCountersSheet(i),
              quickPlusKey: Key('life-counter-quick-plus-$i'),
              quickMinusKey: Key('life-counter-quick-minus-$i'),
              countersKey: Key('life-counter-counters-$i'),
              quarterTurns: i == 0 && _playerCount == 2 ? 2 : 0,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGridPlayers() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 3, 3),
                  child: _PlayerPanel(
                    panelIndex: 0,
                    label: _playerLabels[0],
                    life: _lives[0],
                    poison: _poison[0],
                    commanderTax: _commanderCasts[0] * 2,
                    commanderDamageTotal: _totalCommanderDamage(0),
                    commanderDamageLeadSourceLabel:
                        _commanderDamageLeadSourceLabel(0),
                    commanderDamageLeadSourceValue:
                        _commanderDamageLeadSourceValue(0),
                    lastPlayerRoll: _lastPlayerRolls[0],
                    highRollValue: _lastHighRolls[0],
                    isHighRollWinner: _highRollWinners.contains(0),
                    isHighRollTie:
                        _highRollWinners.length > 1 &&
                        _highRollWinners.contains(0),
                    isMonarch: _monarchPlayer == 0,
                    hasInitiative: _initiativePlayer == 0,
                    color: _playerColors[0],
                    onIncrement: () => _changeLife(0, 1),
                    onQuickIncrement: () => _changeLife(0, 5),
                    onDecrement: () => _changeLife(0, -1),
                    onQuickDecrement: () => _changeLife(0, -5),
                    onPoisonIncrement: () => _changePoison(0, 1),
                    onPoisonDecrement: () => _changePoison(0, -1),
                    onCommanderTaxIncrement: () => _changeCommanderCasts(0, 1),
                    onCommanderTaxDecrement: () => _changeCommanderCasts(0, -1),
                    onOpenCommanderDamageQuick:
                        () => _showCommanderDamageQuickSheet(0),
                    onOpenSetLife: () => _showSetLifeDialog(0),
                    onPlayerRollD20: () => _rollPlayerD20(0),
                    onToggleDefeated: () => _togglePlayerDefeated(0),
                    onCountersTap: () => _showCountersSheet(0),
                    quickPlusKey: const Key('life-counter-quick-plus-0'),
                    quickMinusKey: const Key('life-counter-quick-minus-0'),
                    countersKey: const Key('life-counter-counters-0'),
                    compact: true,
                    quarterTurns: 2,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(3, 0, 0, 3),
                  child: _PlayerPanel(
                    panelIndex: 1,
                    label: _playerLabels[1],
                    life: _lives[1],
                    poison: _poison[1],
                    commanderTax: _commanderCasts[1] * 2,
                    commanderDamageTotal: _totalCommanderDamage(1),
                    commanderDamageLeadSourceLabel:
                        _commanderDamageLeadSourceLabel(1),
                    commanderDamageLeadSourceValue:
                        _commanderDamageLeadSourceValue(1),
                    lastPlayerRoll: _lastPlayerRolls[1],
                    highRollValue: _lastHighRolls[1],
                    isHighRollWinner: _highRollWinners.contains(1),
                    isHighRollTie:
                        _highRollWinners.length > 1 &&
                        _highRollWinners.contains(1),
                    isMonarch: _monarchPlayer == 1,
                    hasInitiative: _initiativePlayer == 1,
                    color: _playerColors[1],
                    onIncrement: () => _changeLife(1, 1),
                    onQuickIncrement: () => _changeLife(1, 5),
                    onDecrement: () => _changeLife(1, -1),
                    onQuickDecrement: () => _changeLife(1, -5),
                    onPoisonIncrement: () => _changePoison(1, 1),
                    onPoisonDecrement: () => _changePoison(1, -1),
                    onCommanderTaxIncrement: () => _changeCommanderCasts(1, 1),
                    onCommanderTaxDecrement: () => _changeCommanderCasts(1, -1),
                    onOpenCommanderDamageQuick:
                        () => _showCommanderDamageQuickSheet(1),
                    onOpenSetLife: () => _showSetLifeDialog(1),
                    onPlayerRollD20: () => _rollPlayerD20(1),
                    onToggleDefeated: () => _togglePlayerDefeated(1),
                    onCountersTap: () => _showCountersSheet(1),
                    quickPlusKey: const Key('life-counter-quick-plus-1'),
                    quickMinusKey: const Key('life-counter-quick-minus-1'),
                    countersKey: const Key('life-counter-counters-1'),
                    compact: true,
                    quarterTurns: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 3, 3, 0),
                  child: _PlayerPanel(
                    panelIndex: 2,
                    label: _playerLabels[2],
                    life: _lives[2],
                    poison: _poison[2],
                    commanderTax: _commanderCasts[2] * 2,
                    commanderDamageTotal: _totalCommanderDamage(2),
                    commanderDamageLeadSourceLabel:
                        _commanderDamageLeadSourceLabel(2),
                    commanderDamageLeadSourceValue:
                        _commanderDamageLeadSourceValue(2),
                    lastPlayerRoll: _lastPlayerRolls[2],
                    highRollValue: _lastHighRolls[2],
                    isHighRollWinner: _highRollWinners.contains(2),
                    isHighRollTie:
                        _highRollWinners.length > 1 &&
                        _highRollWinners.contains(2),
                    isMonarch: _monarchPlayer == 2,
                    hasInitiative: _initiativePlayer == 2,
                    color: _playerColors[2],
                    onIncrement: () => _changeLife(2, 1),
                    onQuickIncrement: () => _changeLife(2, 5),
                    onDecrement: () => _changeLife(2, -1),
                    onQuickDecrement: () => _changeLife(2, -5),
                    onPoisonIncrement: () => _changePoison(2, 1),
                    onPoisonDecrement: () => _changePoison(2, -1),
                    onCommanderTaxIncrement: () => _changeCommanderCasts(2, 1),
                    onCommanderTaxDecrement: () => _changeCommanderCasts(2, -1),
                    onOpenCommanderDamageQuick:
                        () => _showCommanderDamageQuickSheet(2),
                    onOpenSetLife: () => _showSetLifeDialog(2),
                    onPlayerRollD20: () => _rollPlayerD20(2),
                    onToggleDefeated: () => _togglePlayerDefeated(2),
                    onCountersTap: () => _showCountersSheet(2),
                    quickPlusKey: const Key('life-counter-quick-plus-2'),
                    quickMinusKey: const Key('life-counter-quick-minus-2'),
                    countersKey: const Key('life-counter-counters-2'),
                    compact: true,
                    quarterTurns: 0,
                  ),
                ),
              ),
              if (_playerCount >= 4)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(3, 3, 0, 0),
                    child: _PlayerPanel(
                      panelIndex: 3,
                      label: _playerLabels[3],
                      life: _lives[3],
                      poison: _poison[3],
                      commanderTax: _commanderCasts[3] * 2,
                      commanderDamageTotal: _totalCommanderDamage(3),
                      commanderDamageLeadSourceLabel:
                          _commanderDamageLeadSourceLabel(3),
                      commanderDamageLeadSourceValue:
                          _commanderDamageLeadSourceValue(3),
                      lastPlayerRoll: _lastPlayerRolls[3],
                      highRollValue: _lastHighRolls[3],
                      isHighRollWinner: _highRollWinners.contains(3),
                      isHighRollTie:
                          _highRollWinners.length > 1 &&
                          _highRollWinners.contains(3),
                      isMonarch: _monarchPlayer == 3,
                      hasInitiative: _initiativePlayer == 3,
                      color: _playerColors[3],
                      onIncrement: () => _changeLife(3, 1),
                      onQuickIncrement: () => _changeLife(3, 5),
                      onDecrement: () => _changeLife(3, -1),
                      onQuickDecrement: () => _changeLife(3, -5),
                      onPoisonIncrement: () => _changePoison(3, 1),
                      onPoisonDecrement: () => _changePoison(3, -1),
                      onCommanderTaxIncrement: () => _changeCommanderCasts(3, 1),
                      onCommanderTaxDecrement: () => _changeCommanderCasts(3, -1),
                      onOpenCommanderDamageQuick:
                          () => _showCommanderDamageQuickSheet(3),
                      onOpenSetLife: () => _showSetLifeDialog(3),
                      onPlayerRollD20: () => _rollPlayerD20(3),
                      onToggleDefeated: () => _togglePlayerDefeated(3),
                      onCountersTap: () => _showCountersSheet(3),
                      quickPlusKey: const Key('life-counter-quick-plus-3'),
                      quickMinusKey: const Key('life-counter-quick-minus-3'),
                      countersKey: const Key('life-counter-counters-3'),
                      compact: true,
                      quarterTurns: 0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
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
  final bool isExpanded;
  final bool hasPendingHighRollTie;
  final int playerCount;
  final int startingLife;
  final bool canUndo;
  final int stormCount;
  final String? monarchLabel;
  final String? initiativeLabel;
  final String? firstPlayerLabel;
  final String? lastTableEvent;
  final VoidCallback onToggle;
  final VoidCallback onPlayers;
  final VoidCallback onSettings;
  final VoidCallback onTools;
  final VoidCallback onQuickHighRoll;
  final VoidCallback onQuickCoin;
  final VoidCallback onQuickD20;
  final VoidCallback onQuickFirstPlayer;
  final VoidCallback? onUndo;
  final VoidCallback onReset;

  const _TableControlHub({
    required this.isExpanded,
    required this.hasPendingHighRollTie,
    required this.playerCount,
    required this.startingLife,
    required this.canUndo,
    required this.stormCount,
    required this.monarchLabel,
    required this.initiativeLabel,
    required this.firstPlayerLabel,
    required this.lastTableEvent,
    required this.onToggle,
    required this.onPlayers,
    required this.onSettings,
    required this.onTools,
    required this.onQuickHighRoll,
    required this.onQuickCoin,
    required this.onQuickD20,
    required this.onQuickFirstPlayer,
    required this.onUndo,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final statusChips = <Widget>[
      if (stormCount > 0)
        _HubStatusChip(
          chipKey: const Key('life-counter-hub-status-storm'),
          label: 'Storm $stormCount',
          color: AppTheme.warning,
        ),
      if (monarchLabel != null)
        _HubStatusChip(
          chipKey: const Key('life-counter-hub-status-monarch'),
          label: monarchLabel!,
          color: AppTheme.mythicGold,
        ),
      if (initiativeLabel != null)
        _HubStatusChip(
          chipKey: const Key('life-counter-hub-status-initiative'),
          label: initiativeLabel!,
          color: AppTheme.success,
        ),
      if (firstPlayerLabel != null)
        _HubStatusChip(
          chipKey: const Key('life-counter-hub-status-first-player'),
          label: firstPlayerLabel!,
          color: AppTheme.primarySoft,
        ),
    ];

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: Column(
        key: const Key('life-counter-control-hub'),
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isExpanded && statusChips.isNotEmpty) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: statusChips,
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: isExpanded ? 300 : 80,
            height: isExpanded ? 230 : 80,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (isExpanded) ...[
                  Positioned(
                    left: 30,
                    top: 70,
                    child: Transform.rotate(
                      angle: -pi / 2.6,
                      child: _HubPetalAction(
                        buttonKey: const Key('life-counter-hub-players'),
                        label: 'PLAYERS',
                        color: const Color(0xFF44E063),
                        onTap: onPlayers,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 26,
                    child: Transform.rotate(
                      angle: -0.34,
                      child: _HubPetalAction(
                        buttonKey: const Key('life-counter-hub-reset'),
                        label: 'RESTART',
                        color: const Color(0xFFFFE277),
                        onTap: onReset,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 24,
                    top: 68,
                    child: Transform.rotate(
                      angle: 0.28,
                      child: _HubPetalAction(
                        buttonKey: const Key('life-counter-hub-quick-high-roll'),
                        label:
                            hasPendingHighRollTie
                                ? 'DESMP'
                                : 'HIGH ROLL',
                        color: const Color(0xFF40B9FF),
                        onTap: onQuickHighRoll,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 50,
                    bottom: 54,
                    child: Transform.rotate(
                      angle: pi / 2.2,
                      child: _HubPetalAction(
                        buttonKey: const Key('life-counter-hub-settings'),
                        label: 'SETTINGS',
                        color: const Color(0xFFB9B4FF),
                        onTap: onSettings,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 92,
                    bottom: 24,
                    child: Transform.rotate(
                      angle: pi,
                      child: _HubPetalAction(
                        buttonKey: const Key('life-counter-hub-tools'),
                        label: 'HELP',
                        color: const Color(0xFFFF2C77),
                        onTap: onTools,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -4,
                    left: 18,
                    right: 18,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _HubMiniUtility(
                          buttonKey: const Key('life-counter-hub-quick-d20'),
                          label: 'D20',
                          onTap: onQuickD20,
                        ),
                        const SizedBox(width: 6),
                        _HubMiniUtility(
                          buttonKey: const Key('life-counter-hub-quick-coin'),
                          label: 'COIN',
                          onTap: onQuickCoin,
                        ),
                        const SizedBox(width: 6),
                        _HubMiniUtility(
                          buttonKey: const Key(
                            'life-counter-hub-quick-first-player',
                          ),
                          label: '1ST',
                          onTap: onQuickFirstPlayer,
                        ),
                        const SizedBox(width: 6),
                        _HubMiniUtility(
                          buttonKey: const Key('life-counter-hub-undo'),
                          label: 'UNDO',
                          enabled: canUndo,
                          onTap: onUndo,
                        ),
                      ],
                    ),
                  ),
                ],
                _HubMedallion(isExpanded: isExpanded, onTap: onToggle),
              ],
            ),
          ),
          if (isExpanded && lastTableEvent != null) ...[
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Container(
                key: const Key('life-counter-hub-last-event'),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  lastTableEvent!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: AppTheme.fontSm,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
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
  final bool isExpanded;
  final VoidCallback onTap;

  const _HubMedallion({required this.isExpanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('life-counter-hub-toggle'),
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox(
          width: isExpanded ? 76 : 68,
          height: isExpanded ? 76 : 68,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: pi / 4,
                child: Container(
                  width: isExpanded ? 58 : 52,
                  height: isExpanded ? 58 : 52,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.92),
                      width: 2.2,
                    ),
                  ),
                ),
              ),
              Transform.rotate(
                angle: pi / 4,
                child: Container(
                  width: isExpanded ? 44 : 40,
                  height: isExpanded ? 44 : 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFF7CBFF),
                        Color(0xFFB4F1FF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Icon(
                isExpanded ? Icons.close_rounded : Icons.menu_rounded,
                color: Colors.black,
                size: isExpanded ? 30 : 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubStatusChip extends StatelessWidget {
  final Key? chipKey;
  final String label;
  final Color color;

  const _HubStatusChip({
    this.chipKey,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: chipKey,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.92),
          fontSize: AppTheme.fontXs,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HubPetalAction extends StatelessWidget {
  final Key? buttonKey;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _HubPetalAction({
    this.buttonKey,
    required this.label,
    required this.color,
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              color:
                  enabled
                      ? Colors.black.withValues(alpha: 0.9)
                      : Colors.black.withValues(alpha: 0.35),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
        ),
      ),
    );
  }
}

class _HubMiniUtility extends StatelessWidget {
  final Key? buttonKey;
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  const _HubMiniUtility({
    this.buttonKey,
    required this.label,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      key: buttonKey,
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        onTap: enabled ? onTap : null,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 0.8,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color:
                  enabled
                      ? Colors.white.withValues(alpha: 0.92)
                      : Colors.white.withValues(alpha: 0.3),
              fontSize: AppTheme.fontXs,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
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
      width: 284,
      maxHeight: 460,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final count in const [2, 3, 4]) ...[
            _PlayerLayoutPreview(
              previewKey: Key('life-counter-players-option-$count'),
              playerCount: count,
              selected: selectedPlayerCount == count,
              onTap: () => onSelected(count),
            ),
            if (count != 4) const SizedBox(height: 18),
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
          width: 180,
          height: 88,
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
            padding: const EdgeInsets.all(10),
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
    final tileColor = playerCount == 4 ? Colors.black : Colors.white;
    final tileAlt =
        playerCount == 4
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

    return Column(
      children: [
        Expanded(child: Row(children: [tile(), tile()])),
        Expanded(child: Row(children: [tile(), tile()])),
      ],
    );
  }
}

class _SimpleTableOverlay extends StatelessWidget {
  final String title;
  final String body;

  const _SimpleTableOverlay({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return _TableOverlayFrame(
      title: title,
      subtitle: 'Overlay direto sobre a mesa, sem sair da partida.',
      width: 304,
      maxHeight: 320,
      child: Text(
        body,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.84),
          fontSize: AppTheme.fontSm,
          height: 1.45,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppTheme.fontSm,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Player Panel
// ---------------------------------------------------------------------------

/// Painel de um jogador individual com vida, indicadores de poison/commander,
/// e botão para abrir contadores extras.
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
  final VoidCallback onCountersTap;
  final Key? quickPlusKey;
  final Key? quickMinusKey;
  final Key? countersKey;
  final int quarterTurns;
  final bool compact;

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
    required this.onCountersTap,
    this.quickPlusKey,
    this.quickMinusKey,
    this.countersKey,
    this.quarterTurns = 0,
    this.compact = false,
  });

  @override
  State<_PlayerPanel> createState() => _PlayerPanelState();
}

class _PlayerPanelState extends State<_PlayerPanel> {
  bool _showLifeActions = false;

  @override
  Widget build(BuildContext context) {
    final isDefeated = widget.life <= 0;
    final isCommanderLethal = widget.commanderDamageTotal >= 21;
    final isPoisonLethal = widget.poison >= 10;
    final hasPanelTakeoverState =
        isDefeated || isCommanderLethal || isPoisonLethal;
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
        isDefeated
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
              top: widget.compact ? 18 : 20,
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
                  onTap: widget.onQuickIncrement,
                ),
              ),
            ),
          if (!_showLifeActions && !hasPanelTakeoverState)
            Positioned(
              bottom: 8,
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
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: FittedBox(
                fit: BoxFit.scaleDown,
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
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
                            begin: const Offset(0, 0.06),
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
                  if (_showLifeActions)
                    SizedBox(
                      height: widget.compact ? 42 : 48,
                      child: SingleChildScrollView(
                        key: Key(
                          'life-counter-player-quick-actions-${widget.panelIndex}',
                        ),
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _PlayerInlineAction(
                              actionKey: Key(
                                'life-counter-player-roll-d20-${widget.panelIndex}',
                              ),
                              icon: Icons.casino_outlined,
                              label: 'D20',
                              compact: widget.compact,
                              onTap: () {
                                widget.onPlayerRollD20();
                                setState(() {
                                  _showLifeActions = false;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _PlayerInlineAction(
                              actionKey: Key(
                                'life-counter-player-poison-plus-${widget.panelIndex}',
                              ),
                              icon: Icons.coronavirus_outlined,
                              label: 'Poison +',
                              compact: widget.compact,
                              onTap: () {
                                widget.onPoisonIncrement();
                                setState(() {
                                  _showLifeActions = false;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _PlayerInlineAction(
                              actionKey: Key(
                                'life-counter-player-poison-minus-${widget.panelIndex}',
                              ),
                              icon: Icons.remove_circle_outline_rounded,
                              label: 'Poison -',
                              compact: widget.compact,
                              onTap: () {
                                widget.onPoisonDecrement();
                                setState(() {
                                  _showLifeActions = false;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _PlayerInlineAction(
                              actionKey: Key(
                                'life-counter-player-tax-plus-${widget.panelIndex}',
                              ),
                              icon: Icons.add_circle_outline_rounded,
                              label: 'Tax +',
                              compact: widget.compact,
                              onTap: () {
                                widget.onCommanderTaxIncrement();
                                setState(() {
                                  _showLifeActions = false;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _PlayerInlineAction(
                              actionKey: Key(
                                'life-counter-player-tax-minus-${widget.panelIndex}',
                              ),
                              icon: Icons.remove_circle_outline_rounded,
                              label: 'Tax -',
                              compact: widget.compact,
                              onTap: () {
                                widget.onCommanderTaxDecrement();
                                setState(() {
                                  _showLifeActions = false;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _PlayerInlineAction(
                              actionKey: Key(
                                'life-counter-player-commander-damage-${widget.panelIndex}',
                              ),
                              icon: Icons.shield_outlined,
                              label: 'Cmd dmg',
                              compact: widget.compact,
                              onTap: () {
                                widget.onOpenCommanderDamageQuick();
                                setState(() {
                                  _showLifeActions = false;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _PlayerInlineAction(
                              actionKey: Key(
                                'life-counter-player-toggle-dead-${widget.panelIndex}',
                              ),
                              icon:
                                  isDefeated
                                      ? Icons.favorite_rounded
                                      : Icons.dangerous_rounded,
                              label: isDefeated ? 'Reviver' : 'Morto',
                              compact: widget.compact,
                              destructive: !isDefeated,
                              onTap: () {
                                widget.onToggleDefeated();
                                setState(() {
                                  _showLifeActions = false;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!_showLifeActions &&
                      !hasPanelTakeoverState &&
                      !hasEventTakeover)
                    _buildBadgesRow(isCommanderLethal: isCommanderLethal),
                  ],
                ),
              ),
            ),
          ),
          if (!_showLifeActions && !hasPanelTakeoverState && !hasEventTakeover)
            Positioned(
              right: 6,
              bottom: 6,
              child: _CountersButton(
                buttonKey: widget.countersKey,
                onTap: widget.onCountersTap,
                compact: widget.compact,
              ),
            ),
          if (hasPanelTakeoverState)
            Positioned.fill(
              child: IgnorePointer(
                child: _PanelTakeoverOverlay(
                  overlayKey: Key(
                    isDefeated
                        ? 'life-counter-player-defeated-${widget.panelIndex}'
                        : isCommanderLethal
                        ? 'life-counter-player-commander-lethal-${widget.panelIndex}'
                        : 'life-counter-player-poison-lethal-${widget.panelIndex}',
                  ),
                  compact: widget.compact,
                  color:
                      isDefeated
                          ? const Color(0xFF1D1025)
                          : isCommanderLethal
                          ? const Color(0xFF2B090F)
                          : const Color(0xFF0C2414),
                  accent:
                      isDefeated
                          ? const Color(0xFFFF5AA9)
                          : isCommanderLethal
                          ? const Color(0xFFFF5B61)
                          : const Color(0xFF6BFF8D),
                  title:
                      isDefeated
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
    required bool isCommanderLethal,
    required bool isPoisonLethal,
    required bool hasHighRoll,
    required Color dominantValueColor,
    required Color supportingColor,
    required String? eventLabel,
    required String? eventValue,
  }) {
    if (isDefeated || isCommanderLethal || isPoisonLethal) {
      return SizedBox(
        key: ValueKey(
          'life-core-special-${widget.panelIndex}-$isDefeated-$isCommanderLethal-$isPoisonLethal',
        ),
        width: widget.compact ? 90 : 110,
        height: widget.compact ? 90 : 110,
      );
    }

    if (hasHighRoll || eventLabel != null) {
      return SizedBox(
        key: ValueKey(
          'life-core-event-${widget.panelIndex}-$eventLabel-$eventValue',
        ),
        width: widget.compact ? 90 : 110,
        height: widget.compact ? 90 : 110,
      );
    }

    if (_showLifeActions) {
      return Text(
        key: ValueKey('life-core-actions-${widget.panelIndex}'),
        'SET LIFE',
        style: TextStyle(
          color: supportingColor,
          fontSize: widget.compact ? AppTheme.fontSm : AppTheme.fontMd,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
        ),
      );
    }

    return Column(
      key: ValueKey(
        'life-core-${widget.panelIndex}-$eventLabel-$eventValue-${widget.life}-${widget.isHighRollWinner}-${widget.isHighRollTie}',
      ),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${widget.life}',
          style: TextStyle(
            color: dominantValueColor,
            fontSize: widget.compact ? 96 : 144,
            fontWeight: FontWeight.w900,
            height: 0.92,
            letterSpacing: -5,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesRow({required bool isCommanderLethal}) {
    final badges = <Widget>[];

    if (widget.lastPlayerRoll != null) {
      badges.add(
        _TextBadgeChip(
          chipKey: Key('life-counter-player-roll-badge-${widget.panelIndex}'),
          label: 'D20 ${widget.lastPlayerRoll}',
          color: AppTheme.primarySoft,
          compact: widget.compact,
        ),
      );
    }

    if (widget.highRollValue != null) {
      badges.add(
        _TextBadgeChip(
          chipKey: Key(
            'life-counter-player-high-roll-badge-${widget.panelIndex}',
          ),
          label: 'HIGH ${widget.highRollValue}',
          color: widget.isHighRollTie ? AppTheme.warning : AppTheme.primarySoft,
          compact: widget.compact,
        ),
      );
      if (widget.isHighRollWinner) {
        badges.add(
          _TextBadgeChip(
            chipKey: Key(
              'life-counter-player-high-roll-status-${widget.panelIndex}',
            ),
            label: widget.isHighRollTie ? 'EMPATE' : 'VENCEU',
            color: widget.isHighRollTie ? AppTheme.warning : AppTheme.primarySoft,
            compact: widget.compact,
          ),
        );
      }
    }

    if (widget.poison > 0) {
      badges.add(
        _BadgeChip(
          chipKey: Key('life-counter-player-poison-badge-${widget.panelIndex}'),
          icon: Icons.coronavirus,
          value: widget.poison,
          color: AppTheme.success,
          isLethal: widget.poison >= 10,
          compact: widget.compact,
        ),
      );
    }

    if (widget.commanderTax > 0) {
      badges.add(
        _TextBadgeChip(
          chipKey: Key('life-counter-player-tax-badge-${widget.panelIndex}'),
          label: 'Tax +${widget.commanderTax}',
          color: AppTheme.warning,
          compact: widget.compact,
        ),
      );
    }

    if (widget.isMonarch) {
      badges.add(
        _TextBadgeChip(
          label: 'Monarca',
          color: AppTheme.mythicGold,
          compact: widget.compact,
        ),
      );
    }

    if (widget.hasInitiative) {
      badges.add(
        _TextBadgeChip(
          label: 'Iniciativa',
          color: AppTheme.success,
          compact: widget.compact,
        ),
      );
    }

    if (widget.commanderDamageTotal > 0) {
      badges.add(
        _BadgeChip(
          chipKey: Key(
            'life-counter-player-commander-damage-badge-${widget.panelIndex}',
          ),
          icon: Icons.shield,
          value: widget.commanderDamageTotal,
          color: AppTheme.mythicGold,
          isLethal: widget.commanderDamageTotal >= 21,
          compact: widget.compact,
        ),
      );
      if (widget.commanderDamageLeadSourceLabel != null &&
          widget.commanderDamageLeadSourceValue != null) {
        badges.add(
          _TextBadgeChip(
            chipKey: Key(
              'life-counter-player-commander-source-badge-${widget.panelIndex}',
            ),
            label:
                '${widget.commanderDamageLeadSourceLabel} ${widget.commanderDamageLeadSourceValue}',
            color:
                widget.commanderDamageLeadSourceValue! >= 21
                    ? AppTheme.error
                    : AppTheme.mythicGold,
            compact: widget.compact,
          ),
        );
      }
      if (!isCommanderLethal && widget.commanderDamageTotal >= 21) {
        badges.add(
          _TextBadgeChip(
            chipKey: Key(
              'life-counter-player-commander-lethal-badge-${widget.panelIndex}',
            ),
            label: 'CMD LETAL',
            color: AppTheme.error,
            compact: widget.compact,
          ),
        );
      }
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: Wrap(
          key: ValueKey(
            'life-counter-badges-${widget.panelIndex}-${widget.poison}-${widget.commanderTax}-${widget.commanderDamageTotal}-${widget.lastPlayerRoll}-${widget.highRollValue}-${widget.isHighRollWinner}-${widget.isHighRollTie}-${widget.isMonarch}-${widget.hasInitiative}',
          ),
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: badges,
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
  final bool destructive;
  final VoidCallback onTap;

  const _PlayerInlineAction({
    this.actionKey,
    required this.icon,
    required this.label,
    required this.compact,
    this.destructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? AppTheme.error : AppTheme.textPrimary;

    return Material(
      key: actionKey,
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        onTap: onTap,
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 8 : 9,
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
              Icon(icon, size: compact ? 14 : 16, color: accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontSize: compact ? AppTheme.fontXs : AppTheme.fontSm,
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

class _LifeQuickAdjustButton extends StatelessWidget {
  final Key? buttonKey;
  final String label;
  final String? semanticLabel;
  final Color color;
  final bool compact;
  final VoidCallback onTap;

  const _LifeQuickAdjustButton({
    this.buttonKey,
    required this.label,
    this.semanticLabel,
    required this.color,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? 54 : 60,
      height: compact ? 38 : 42,
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
                    fontSize: compact ? 26 : 30,
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
  final Color color;
  final Color accent;
  final String title;

  const _PanelTakeoverOverlay({
    required this.overlayKey,
    required this.compact,
    required this.color,
    required this.accent,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
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
                  blurRadius: compact ? 22 : 32,
                  spreadRadius: compact ? 1 : 2,
                ),
              ],
            ),
            child: Center(
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
                          fontSize: compact ? 34 : 44,
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
  final Color color;
  final Color accent;
  final String value;
  final String kind;
  final bool isWinner;
  final bool isTie;

  const _PanelEventTakeoverOverlay({
    required this.overlayKey,
    required this.compact,
    required this.color,
    required this.accent,
    required this.value,
    required this.kind,
    required this.isWinner,
    required this.isTie,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = Colors.black.withValues(alpha: 0.96);
    final caption =
        kind == 'd20'
            ? 'D20'
            : isTie
            ? 'TIE'
            : isWinner
            ? 'WINNER'
            : '';

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
            : LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.alphaBlend(Colors.white.withValues(alpha: 0.18), color),
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
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: isWinner ? 0.24 * progress : 0.14 * progress),
                  blurRadius: isWinner ? 30 : 18,
                  spreadRadius: isWinner ? 2 : 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                if (isWinner)
                  ..._buildConfetti(progress),
                Center(
                  child: Transform.scale(
                    scale: 0.9 + (0.1 * progress),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 10 : 14,
                        vertical: compact ? 18 : 24,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              value,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: valueColor,
                                fontSize: compact ? 150 : 220,
                                fontWeight: FontWeight.w900,
                                height: 0.78,
                                letterSpacing: -8,
                              ),
                            ),
                            if (caption.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  caption,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: valueColor.withValues(alpha: 0.72),
                                    fontSize: compact ? AppTheme.fontSm : AppTheme.fontMd,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.6,
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
}

// ---------------------------------------------------------------------------
// Badge Chip (poison/commander indicators on player panel)
// ---------------------------------------------------------------------------
class _BadgeChip extends StatelessWidget {
  final Key? chipKey;
  final IconData icon;
  final int value;
  final Color color;
  final bool isLethal;
  final bool compact;

  const _BadgeChip({
    this.chipKey,
    required this.icon,
    required this.value,
    required this.color,
    required this.isLethal,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isLethal
            ? AppTheme.error.withValues(alpha: 0.2)
            : AppTheme.backgroundAbyss.withValues(alpha: 0.42);
    final fgColor =
        isLethal ? AppTheme.textPrimary : color.withValues(alpha: 0.92);
    final sz = compact ? 10.0 : 12.0;

    return Container(
      key: chipKey,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color:
              isLethal
                  ? AppTheme.error.withValues(alpha: 0.3)
                  : color.withValues(alpha: 0.22),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: sz, color: fgColor),
          const SizedBox(width: 3),
          Text(
            '$value',
            style: TextStyle(
              color: fgColor,
              fontSize: sz,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TextBadgeChip extends StatelessWidget {
  final Key? chipKey;
  final String label;
  final Color color;
  final bool compact;

  const _TextBadgeChip({
    this.chipKey,
    required this.label,
    required this.color,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = color.withValues(alpha: 0.92);
    return Container(
      key: chipKey,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundAbyss.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fgColor,
          fontSize: compact ? AppTheme.fontXs : AppTheme.fontSm,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Counters button (opens the counters bottom sheet)
// ---------------------------------------------------------------------------
class _CountersButton extends StatelessWidget {
  final Key? buttonKey;
  final VoidCallback onTap;
  final bool compact;

  const _CountersButton({
    this.buttonKey,
    required this.onTap,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: buttonKey,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        onTap: onTap,
        child: Container(
          width: compact ? 38 : 40,
          height: compact ? 38 : 40,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 0.8,
            ),
          ),
          child: Icon(
            Icons.dashboard_customize,
            color: Colors.white.withValues(alpha: 0.86),
            size: compact ? 18 : 19,
          ),
        ),
      ),
    );
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
      subtitle: 'Mesa-first controls layered over the battlefield.',
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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ToolActionButton(
                buttonKey: const Key('life-counter-tool-coin'),
                icon: Icons.flip_camera_android_rounded,
                label: 'COIN',
                onTap: _runCoinFlip,
              ),
              _ToolActionButton(
                buttonKey: const Key('life-counter-tool-d20'),
                icon: Icons.casino_outlined,
                label: 'D20',
                onTap: _runD20,
              ),
              _ToolActionButton(
                buttonKey: const Key('life-counter-tool-first-player'),
                icon: Icons.person_search_rounded,
                label: 'ROLL 1ST',
                onTap: _runFirstPlayerRoll,
              ),
              _ToolActionButton(
                buttonKey: const Key('life-counter-tool-rolloff'),
                icon: Icons.casino_rounded,
                label: _rollOffWinners.length > 1 ? 'TIEBREAK' : 'HIGH ROLL',
                onTap: _runRollOff,
              ),
            ],
          ),
          if (_rollOffResults != null) ...[
            const SizedBox(height: 18),
            Container(
              key: const Key('life-counter-rolloff-results'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HIGH ROLL',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _rollOffWinners.length == 1
                        ? 'Winning result is highlighted below.'
                        : 'Tie detected. Reroll only tied players.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
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
            ),
          ],
          if (_lastTableEvent != null) ...[
            const SizedBox(height: 18),
            Container(
              key: const Key('life-counter-table-event'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _lastTableEvent!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
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
      subtitle: 'Quick random tools without leaving the table.',
      width: 320,
      maxHeight: 420,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ToolActionButton(
                buttonKey: const Key('life-counter-dice-roll-d20'),
                icon: Icons.casino_outlined,
                label: 'D20',
                onTap: () {
                  onRollD20();
                  Navigator.of(context).pop();
                },
              ),
              _ToolActionButton(
                buttonKey: const Key('life-counter-dice-roll-coin'),
                icon: Icons.flip_camera_android_rounded,
                label: 'COIN',
                onTap: () {
                  onRollCoin();
                  Navigator.of(context).pop();
                },
              ),
              _ToolActionButton(
                buttonKey: const Key('life-counter-dice-roll-first-player'),
                icon: Icons.person_search_rounded,
                label: 'ROLL 1ST',
                onTap: () {
                  onRollFirstPlayer();
                  Navigator.of(context).pop();
                },
              ),
              _ToolActionButton(
                buttonKey: const Key('life-counter-dice-roll-high-roll'),
                icon: Icons.casino_rounded,
                label: hasPendingHighRollTie ? 'TIEBREAK' : 'HIGH ROLL',
                onTap: () {
                  onHighRoll();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          if (lastTableEvent != null) ...[
            const SizedBox(height: 18),
            Container(
              key: const Key('life-counter-dice-last-event'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Text(
                lastTableEvent!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.86),
                  fontSize: AppTheme.fontSm,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ],
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
                            label: '⌫',
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
                fontSize: label == '⌫' ? 22 : 30,
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

class _ToolActionButton extends StatelessWidget {
  final Key? buttonKey;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolActionButton({
    this.buttonKey,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      key: buttonKey,
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.44),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppTheme.fontMd,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Counters Bottom Sheet (poison, commander damage, energy, experience)
// ---------------------------------------------------------------------------
class _CountersSheet extends StatefulWidget {
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

  const _CountersSheet({
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
  State<_CountersSheet> createState() => _CountersSheetState();
}

class _CountersSheetState extends State<_CountersSheet> {
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

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder:
          (ctx, scrollController) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: ListView(
              controller: scrollController,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.outlineMuted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Contadores — ${widget.playerLabel}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: widget.playerColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Poison ──
                _CounterRow(
                  icon: Icons.coronavirus,
                  label: 'Veneno (Poison)',
                  sublabel: _poison >= 10 ? '☠ LETAL (≥10)' : '10 = derrota',
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
                  icon: Icons.local_fire_department_outlined,
                  label: 'Commander casts',
                  sublabel:
                      _commanderCasts == 0
                          ? 'Taxa atual: 0 mana'
                          : 'Taxa atual: +${_commanderCasts * 2} mana',
                  value: _commanderCasts,
                  color: AppTheme.warning,
                  onIncrement: () => _updateCommanderCasts(1),
                  onDecrement: () => _updateCommanderCasts(-1),
                ),
                const SizedBox(height: 12),

                // ── Commander Damage ──
                Text(
                  '⚔ Dano de Comandante',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mythicGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '21 de uma mesma fonte = derrota',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textHint,
                  ),
                ),
                const SizedBox(height: 8),
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
                      sublabel: dmg >= 21 ? '☠ LETAL (≥21)' : null,
                      value: dmg,
                      color: widget.playerColors[sourceIdx],
                      isLethal: dmg >= 21,
                      onIncrement: () => _updateCmdDamage(sourceIdx, 1),
                      onDecrement: () => _updateCmdDamage(sourceIdx, -1),
                    ),
                  );
                }),
                const SizedBox(height: 12),

                // ── Energy ──
                _CounterRow(
                  icon: Icons.bolt,
                  label: 'Energia (Energy)',
                  value: _energy,
                  color: AppTheme.mythicGold,
                  onIncrement: () => _updateEnergy(1),
                  onDecrement: () => _updateEnergy(-1),
                ),
                const SizedBox(height: 12),

                // ── Experience ──
                _CounterRow(
                  icon: Icons.star,
                  label: 'Experiência (Experience)',
                  value: _experience,
                  color: AppTheme.primarySoft,
                  onIncrement: () => _updateExperience(1),
                  onDecrement: () => _updateExperience(-1),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
    );
  }
}

class _CommanderDamageQuickSheet extends StatefulWidget {
  final int playerIndex;
  final int playerCount;
  final String playerLabel;
  final List<int> initialCommanderDamage;
  final List<Color> playerColors;
  final List<String> playerLabels;
  final Function(int source, int delta) onCommanderDamageChanged;

  const _CommanderDamageQuickSheet({
    required this.playerIndex,
    required this.playerCount,
    required this.playerLabel,
    required this.initialCommanderDamage,
    required this.playerColors,
    required this.playerLabels,
    required this.onCommanderDamageChanged,
  });

  @override
  State<_CommanderDamageQuickSheet> createState() =>
      _CommanderDamageQuickSheetState();
}

class _CommanderDamageQuickSheetState extends State<_CommanderDamageQuickSheet> {
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

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          key: const Key('life-counter-commander-damage-quick-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.outlineMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Dano de comandante rapido',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ajuste o dano recebido por ${widget.playerLabel} sem abrir a sheet completa.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textHint,
              ),
            ),
            if (lethalSources.isNotEmpty) ...[
              const SizedBox(height: 12),
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
                  color: AppTheme.error.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: AppTheme.error.withValues(alpha: 0.34),
                    width: 0.9,
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
            ],
            const SizedBox(height: 16),
            ...List.generate(widget.playerCount, (sourceIdx) {
              if (sourceIdx == widget.playerIndex) {
                return const SizedBox.shrink();
              }
              final dmg = _cmdDamage[sourceIdx];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CounterRow(
                  rowKey: Key(
                    'life-counter-quick-commander-damage-row-$sourceIdx',
                  ),
                  icon: Icons.shield_rounded,
                  label: 'De ${widget.playerLabels[sourceIdx]}',
                  sublabel:
                      dmg >= 21
                          ? '☠ LETAL (≥21)'
                          : 'Commander damage por fonte',
                  value: dmg,
                  color: widget.playerColors[sourceIdx],
                  isLethal: dmg >= 21,
                  decrementKey: Key(
                    'life-counter-quick-commander-damage-minus-$sourceIdx',
                  ),
                  incrementKey: Key(
                    'life-counter-quick-commander-damage-plus-$sourceIdx',
                  ),
                  valueKey: Key(
                    'life-counter-quick-commander-damage-value-$sourceIdx',
                  ),
                  onIncrement: () => _updateCmdDamage(sourceIdx, 1),
                  onDecrement: () => _updateCmdDamage(sourceIdx, -1),
                ),
              );
            }),
          ],
        ),
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
  final Key? incrementKey;
  final Key? decrementKey;
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
    this.incrementKey,
    this.decrementKey,
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
            buttonKey: decrementKey,
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
            buttonKey: incrementKey,
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

/// Overlay de mesa para configurar número de jogadores e vida inicial.
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
