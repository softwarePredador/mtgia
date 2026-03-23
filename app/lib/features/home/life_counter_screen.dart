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
  const LifeCounterScreen({super.key});

  @override
  State<LifeCounterScreen> createState() => _LifeCounterScreenState();
}

class _LifeCounterScreenState extends State<LifeCounterScreen> {
  static const _sessionPrefsKey = 'life_counter_session_v1';
  final Random _random = Random();

  int _playerCount = 2;
  int _startingLife = 20;
  bool _isHubExpanded = false;

  late List<int> _lives;
  late List<int> _poison;
  late List<int> _energy;
  late List<int> _experience;
  late List<int> _commanderCasts;
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
    AppTheme.manaViolet,
    AppTheme.primarySoft,
    AppTheme.mythicGold,
    AppTheme.error,
  ];

  static const _playerLabels = [
    'Jogador 1',
    'Jogador 2',
    'Jogador 3',
    'Jogador 4',
  ];

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

  void _setPlayerCount(int count) {
    setState(() {
      _playerCount = count;
      _initAll();
    });
    _persistSession();
  }

  void _setStartingLife(int life) {
    setState(() {
      _startingLife = life;
      _initAll();
    });
    _persistSession();
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'player_count': _playerCount,
      'starting_life': _startingLife,
      'lives': _lives,
      'poison': _poison,
      'energy': _energy,
      'experience': _experience,
      'commander_casts': _commanderCasts,
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
      if (playerCount == null ||
          startingLife == null ||
          playerCount < 2 ||
          playerCount > 4) {
        return;
      }

      final lives = _readIntList(payload['lives'], playerCount);
      final poison = _readIntList(payload['poison'], playerCount);
      final energy = _readIntList(payload['energy'], playerCount);
      final experience = _readIntList(payload['experience'], playerCount);
      final commanderCasts = _readIntList(
        payload['commander_casts'],
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
          commanderDamage == null) {
        return;
      }

      if (!mounted) return;
      setState(() {
        _playerCount = playerCount;
        _startingLife = startingLife;
        _lives = lives;
        _poison = poison;
        _energy = energy;
        _experience = experience;
        _commanderCasts = commanderCasts;
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

  void _showSettingsDialog() {
    if (_isHubExpanded) {
      setState(() {
        _isHubExpanded = false;
      });
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceSlate,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder:
          (ctx) => _SettingsSheet(
            playerCount: _playerCount,
            startingLife: _startingLife,
            onPlayerCountChanged: (count) {
              _setPlayerCount(count);
              Navigator.pop(ctx);
            },
            onStartingLifeChanged: (life) {
              _setStartingLife(life);
              Navigator.pop(ctx);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundAbyss,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.scaffoldGradient),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              const Positioned.fill(child: _LifeCounterBackdrop()),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 10),
                  child:
                      _playerCount <= 2
                          ? _buildTwoPlayers()
                          : _buildGridPlayers(),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: _TableEdgeAction(
                  icon: Icons.arrow_back_rounded,
                  label: 'Sair',
                  onTap: () => Navigator.of(context).maybePop(),
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
                    onToggle: () {
                      setState(() {
                        _isHubExpanded = !_isHubExpanded;
                      });
                    },
                    onSettings: _showSettingsDialog,
                    onTools: _showTableToolsSheet,
                    onUndo: _history.isNotEmpty ? _undo : null,
                    onReset: _reset,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTwoPlayers() {
    return Column(
      children: List.generate(_playerCount, (i) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _PlayerPanel(
              label: _playerLabels[i],
              life: _lives[i],
              poison: _poison[i],
              commanderTax: _commanderCasts[i] * 2,
              commanderDamageTotal: _totalCommanderDamage(i),
              isMonarch: _monarchPlayer == i,
              hasInitiative: _initiativePlayer == i,
              color: _playerColors[i],
              onIncrement: () => _changeLife(i, 1),
              onQuickIncrement: () => _changeLife(i, 5),
              onDecrement: () => _changeLife(i, -1),
              onQuickDecrement: () => _changeLife(i, -5),
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
                  padding: const EdgeInsets.fromLTRB(12, 0, 6, 6),
                  child: _PlayerPanel(
                    label: _playerLabels[0],
                    life: _lives[0],
                    poison: _poison[0],
                    commanderTax: _commanderCasts[0] * 2,
                    commanderDamageTotal: _totalCommanderDamage(0),
                    isMonarch: _monarchPlayer == 0,
                    hasInitiative: _initiativePlayer == 0,
                    color: _playerColors[0],
                    onIncrement: () => _changeLife(0, 1),
                    onQuickIncrement: () => _changeLife(0, 5),
                    onDecrement: () => _changeLife(0, -1),
                    onQuickDecrement: () => _changeLife(0, -5),
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
                  padding: const EdgeInsets.fromLTRB(6, 0, 12, 6),
                  child: _PlayerPanel(
                    label: _playerLabels[1],
                    life: _lives[1],
                    poison: _poison[1],
                    commanderTax: _commanderCasts[1] * 2,
                    commanderDamageTotal: _totalCommanderDamage(1),
                    isMonarch: _monarchPlayer == 1,
                    hasInitiative: _initiativePlayer == 1,
                    color: _playerColors[1],
                    onIncrement: () => _changeLife(1, 1),
                    onQuickIncrement: () => _changeLife(1, 5),
                    onDecrement: () => _changeLife(1, -1),
                    onQuickDecrement: () => _changeLife(1, -5),
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
                  padding: const EdgeInsets.fromLTRB(12, 6, 6, 12),
                  child: _PlayerPanel(
                    label: _playerLabels[2],
                    life: _lives[2],
                    poison: _poison[2],
                    commanderTax: _commanderCasts[2] * 2,
                    commanderDamageTotal: _totalCommanderDamage(2),
                    isMonarch: _monarchPlayer == 2,
                    hasInitiative: _initiativePlayer == 2,
                    color: _playerColors[2],
                    onIncrement: () => _changeLife(2, 1),
                    onQuickIncrement: () => _changeLife(2, 5),
                    onDecrement: () => _changeLife(2, -1),
                    onQuickDecrement: () => _changeLife(2, -5),
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
                    padding: const EdgeInsets.fromLTRB(6, 6, 12, 12),
                    child: _PlayerPanel(
                      label: _playerLabels[3],
                      life: _lives[3],
                      poison: _poison[3],
                      commanderTax: _commanderCasts[3] * 2,
                      commanderDamageTotal: _totalCommanderDamage(3),
                      isMonarch: _monarchPlayer == 3,
                      hasInitiative: _initiativePlayer == 3,
                      color: _playerColors[3],
                      onIncrement: () => _changeLife(3, 1),
                      onQuickIncrement: () => _changeLife(3, 5),
                      onDecrement: () => _changeLife(3, -1),
                      onQuickDecrement: () => _changeLife(3, -5),
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
}

// ---------------------------------------------------------------------------
// Tabletop control hub
// ---------------------------------------------------------------------------

class _LifeCounterBackdrop extends StatelessWidget {
  const _LifeCounterBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: _BackdropGlow(
              size: 220,
              color: AppTheme.manaViolet.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            top: 80,
            right: -40,
            child: _BackdropGlow(
              size: 200,
              color: AppTheme.mythicGold.withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            bottom: 110,
            left: -50,
            child: _BackdropGlow(
              size: 210,
              color: AppTheme.primarySoft.withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -30,
            child: _BackdropGlow(
              size: 240,
              color: AppTheme.error.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackdropGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _BackdropGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0, 1],
        ),
      ),
    );
  }
}

class _TableEdgeAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TableEdgeAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.backgroundAbyss.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(
              color: AppTheme.outlineMuted.withValues(alpha: 0.9),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppTheme.textPrimary, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.fontSm,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableControlHub extends StatelessWidget {
  final bool isExpanded;
  final int playerCount;
  final int startingLife;
  final bool canUndo;
  final int stormCount;
  final String? monarchLabel;
  final String? initiativeLabel;
  final String? firstPlayerLabel;
  final VoidCallback onToggle;
  final VoidCallback onSettings;
  final VoidCallback onTools;
  final VoidCallback? onUndo;
  final VoidCallback onReset;

  const _TableControlHub({
    required this.isExpanded,
    required this.playerCount,
    required this.startingLife,
    required this.canUndo,
    required this.stormCount,
    required this.monarchLabel,
    required this.initiativeLabel,
    required this.firstPlayerLabel,
    required this.onToggle,
    required this.onSettings,
    required this.onTools,
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
          if (isExpanded)
            Container(
              constraints: const BoxConstraints(maxWidth: 320),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundAbyss.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppTheme.outlineMuted.withValues(alpha: 0.9),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Mesa Commander',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: AppTheme.fontLg,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$playerCount jogadores • $startingLife de vida',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: AppTheme.fontSm,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (statusChips.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      runSpacing: 6,
                      children: statusChips,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HubSecondaryAction(
                        buttonKey: const Key('life-counter-hub-settings'),
                        icon: Icons.tune_rounded,
                        label: 'Mesa',
                        accent: AppTheme.manaViolet,
                        onTap: onSettings,
                      ),
                      const SizedBox(width: 8),
                      _HubSecondaryAction(
                        buttonKey: const Key('life-counter-hub-undo'),
                        icon: Icons.undo_rounded,
                        label: 'Undo',
                        accent: canUndo ? AppTheme.success : AppTheme.textHint,
                        onTap: onUndo,
                      ),
                      const SizedBox(width: 8),
                      _HubSecondaryAction(
                        buttonKey: const Key('life-counter-hub-tools'),
                        icon: Icons.casino_rounded,
                        label: 'Tools',
                        accent: AppTheme.mythicGold,
                        onTap: onTools,
                      ),
                      const SizedBox(width: 8),
                      _HubSecondaryAction(
                        buttonKey: const Key('life-counter-hub-reset'),
                        icon: Icons.refresh_rounded,
                        label: 'Reset',
                        accent: AppTheme.error,
                        onTap: onReset,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          _HubMedallion(isExpanded: isExpanded, onTap: onToggle),
          if (!isExpanded) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.backgroundAbyss.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                border: Border.all(
                  color: AppTheme.outlineMuted.withValues(alpha: 0.8),
                  width: 1,
                ),
              ),
              child: Text(
                '$playerCount jogadores • $startingLife vida',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.fontSm,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (statusChips.isNotEmpty) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: statusChips,
                ),
              ),
            ],
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
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: isExpanded ? 106 : 96,
              height: isExpanded ? 106 : 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.goldAccentGradient,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.24),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.mythicGold.withValues(alpha: 0.32),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            ),
            Container(
              width: isExpanded ? 82 : 74,
              height: isExpanded ? 82 : 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.surfaceElevated, AppTheme.backgroundAbyss],
                ),
                border: Border.all(
                  color: AppTheme.manaViolet.withValues(alpha: 0.45),
                  width: 1.2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isExpanded
                        ? Icons.close_rounded
                        : Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: isExpanded ? 26 : 24,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isExpanded ? 'Fechar' : 'Mesa',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: AppTheme.fontXs,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 12,
              child: _HubOrbitDot(color: AppTheme.manaViolet),
            ),
            Positioned(
              bottom: 12,
              left: 10,
              child: _HubOrbitDot(color: AppTheme.primarySoft),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubOrbitDot extends StatelessWidget {
  final Color color;

  const _HubOrbitDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 8,
            offset: const Offset(0, 0),
          ),
        ],
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
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: AppTheme.fontXs,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HubSecondaryAction extends StatelessWidget {
  final Key? buttonKey;
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback? onTap;

  const _HubSecondaryAction({
    this.buttonKey,
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Material(
      key: buttonKey,
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Ink(
          width: 62,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color:
                  enabled
                      ? accent.withValues(alpha: 0.28)
                      : AppTheme.outlineMuted,
              width: 0.8,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: enabled ? AppTheme.textPrimary : AppTheme.textHint,
                  fontSize: AppTheme.fontXs,
                  fontWeight: FontWeight.w700,
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
class _PlayerPanel extends StatelessWidget {
  final String label;
  final int life;
  final int poison;
  final int commanderTax;
  final int commanderDamageTotal;
  final bool isMonarch;
  final bool hasInitiative;
  final Color color;
  final VoidCallback onIncrement;
  final VoidCallback onQuickIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onQuickDecrement;
  final VoidCallback onCountersTap;
  final Key? quickPlusKey;
  final Key? quickMinusKey;
  final Key? countersKey;
  final int quarterTurns;
  final bool compact;

  const _PlayerPanel({
    required this.label,
    required this.life,
    required this.poison,
    required this.commanderTax,
    required this.commanderDamageTotal,
    required this.isMonarch,
    required this.hasInitiative,
    required this.color,
    required this.onIncrement,
    required this.onQuickIncrement,
    required this.onDecrement,
    required this.onQuickDecrement,
    required this.onCountersTap,
    this.quickPlusKey,
    this.quickMinusKey,
    this.countersKey,
    this.quarterTurns = 0,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final panelStart = Color.lerp(color, AppTheme.backgroundAbyss, 0.18)!;
    final panelMid = Color.lerp(color, AppTheme.surfaceSlate, 0.62)!;
    final panelEnd = Color.lerp(color, AppTheme.backgroundAbyss, 0.74)!;

    final content = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [panelStart, panelMid, panelEnd],
          stops: const [0.0, 0.52, 1.0],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -28,
            right: -18,
            child: _BackdropGlow(
              size: compact ? 120 : 150,
              color: color.withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            bottom: -36,
            left: -12,
            child: _BackdropGlow(
              size: compact ? 110 : 135,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: _SeatChip(label: label, color: color, compact: compact),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: _LifeQuickAdjustButton(
              buttonKey: quickPlusKey,
              label: '+5',
              color: color,
              compact: compact,
              onTap: onQuickIncrement,
            ),
          ),
          Positioned(
            left: 8,
            bottom: 8,
            child: _LifeQuickAdjustButton(
              buttonKey: quickMinusKey,
              label: '-5',
              color: AppTheme.error,
              compact: compact,
              onTap: onQuickDecrement,
            ),
          ),
          // Main life controls
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // + button (top area)
              Expanded(
                child: InkWell(
                  onTap: onIncrement,
                  child: Center(
                    child: Icon(
                      Icons.add,
                      color: Colors.white.withValues(alpha: 0.72),
                      size: compact ? 30 : 42,
                    ),
                  ),
                ),
              ),

              // Life total + label
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$life',
                      style: TextStyle(
                        color: life <= 0 ? AppTheme.error : Colors.white,
                        fontSize: compact ? 52 : 72,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -1.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    // Badges row: poison + commander damage
                    _buildBadgesRow(),
                  ],
                ),
              ),

              // - button (bottom area)
              Expanded(
                child: InkWell(
                  onTap: onDecrement,
                  child: Center(
                    child: Icon(
                      Icons.remove,
                      color: Colors.white.withValues(alpha: 0.72),
                      size: compact ? 30 : 42,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Counters button (bottom-right corner)
          Positioned(
            right: 4,
            bottom: 4,
            child: _CountersButton(
              buttonKey: countersKey,
              onTap: onCountersTap,
              compact: compact,
            ),
          ),
        ],
      ),
    );

    if (quarterTurns != 0) {
      return RotatedBox(quarterTurns: quarterTurns, child: content);
    }
    return content;
  }

  Widget _buildBadgesRow() {
    final badges = <Widget>[];

    if (poison > 0) {
      badges.add(
        _BadgeChip(
          icon: Icons.coronavirus,
          value: poison,
          color: AppTheme.success,
          isLethal: poison >= 10,
          compact: compact,
        ),
      );
    }

    if (commanderTax > 0) {
      badges.add(
        _TextBadgeChip(
          label: 'Tax +$commanderTax',
          color: AppTheme.warning,
          compact: compact,
        ),
      );
    }

    if (isMonarch) {
      badges.add(
        _TextBadgeChip(
          label: 'Monarca',
          color: AppTheme.mythicGold,
          compact: compact,
        ),
      );
    }

    if (hasInitiative) {
      badges.add(
        _TextBadgeChip(
          label: 'Iniciativa',
          color: AppTheme.success,
          compact: compact,
        ),
      );
    }

    if (commanderDamageTotal > 0) {
      badges.add(
        _BadgeChip(
          icon: Icons.shield,
          value: commanderDamageTotal,
          color: AppTheme.mythicGold,
          isLethal: commanderDamageTotal >= 21,
          compact: compact,
        ),
      );
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: badges,
      ),
    );
  }
}

class _SeatChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool compact;

  const _SeatChip({
    required this.label,
    required this.color,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundAbyss.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: color.withValues(alpha: 0.36), width: 1),
      ),
      child: Text(
        label.replaceFirst('Jogador ', 'P'),
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? AppTheme.fontXs : AppTheme.fontSm,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _LifeQuickAdjustButton extends StatelessWidget {
  final Key? buttonKey;
  final String label;
  final Color color;
  final bool compact;
  final VoidCallback onTap;

  const _LifeQuickAdjustButton({
    this.buttonKey,
    required this.label,
    required this.color,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? 50 : 56,
      height: compact ? 36 : 40,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: buttonKey,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: AppTheme.backgroundAbyss.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              border: Border.all(
                color: color.withValues(alpha: 0.34),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: compact ? AppTheme.fontXs : AppTheme.fontSm,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Badge Chip (poison/commander indicators on player panel)
// ---------------------------------------------------------------------------
class _BadgeChip extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;
  final bool isLethal;
  final bool compact;

  const _BadgeChip({
    required this.icon,
    required this.value,
    required this.color,
    required this.isLethal,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isLethal ? AppTheme.error : color.withValues(alpha: 0.2);
    final fgColor = isLethal ? Colors.white : color;
    final sz = compact ? 10.0 : 12.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
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
  final String label;
  final Color color;
  final bool compact;

  const _TextBadgeChip({
    required this.label,
    required this.color,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
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
          width: compact ? 48 : 56,
          height: compact ? 48 : 56,
          decoration: BoxDecoration(
            color: AppTheme.backgroundAbyss.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: AppTheme.primarySoft.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.dashboard_customize,
            color: Colors.white.withValues(alpha: 0.86),
            size: compact ? 22 : 24,
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
  final ValueChanged<int> onStormChanged;
  final VoidCallback onStormReset;
  final ValueChanged<int?> onMonarchChanged;
  final ValueChanged<int?> onInitiativeChanged;
  final ValueChanged<int?> onFirstPlayerChanged;
  final String Function() onRollCoinFlip;
  final String Function() onRollD20;
  final int Function() onRollFirstPlayer;

  const _TableToolsSheet({
    required this.playerCount,
    required this.playerLabels,
    required this.stormCount,
    required this.monarchPlayer,
    required this.initiativePlayer,
    required this.firstPlayerIndex,
    required this.lastTableEvent,
    required this.onStormChanged,
    required this.onStormReset,
    required this.onMonarchChanged,
    required this.onInitiativeChanged,
    required this.onFirstPlayerChanged,
    required this.onRollCoinFlip,
    required this.onRollD20,
    required this.onRollFirstPlayer,
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

  @override
  void initState() {
    super.initState();
    _stormCount = widget.stormCount;
    _monarchPlayer = widget.monarchPlayer;
    _initiativePlayer = widget.initiativePlayer;
    _firstPlayerIndex = widget.firstPlayerIndex;
    _lastTableEvent = widget.lastTableEvent;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.9,
      expand: false,
      builder:
          (ctx, scrollController) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: ListView(
              controller: scrollController,
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
                  'Ferramentas de Mesa',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ajustes rápidos para Commander sem sair da partida.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textHint,
                  ),
                ),
                const SizedBox(height: 20),
                _CounterRow(
                  rowKey: const Key('life-counter-storm-row'),
                  icon: Icons.flash_on_rounded,
                  label: 'Storm',
                  sublabel:
                      _stormCount == 0
                          ? 'Sem mágicas encadeadas agora'
                          : 'Contagem atual da pilha',
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
                    label: const Text('Resetar storm'),
                  ),
                ),
                const SizedBox(height: 16),
                _PlayerSelectionCard(
                  title: 'Monarch',
                  subtitle: 'Define quem está com a coroa agora.',
                  chipPrefix: 'Monarca',
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
                  subtitle: 'Marca quem está com a iniciativa.',
                  chipPrefix: 'Inic.',
                  color: AppTheme.success,
                  playerCount: widget.playerCount,
                  playerLabels: widget.playerLabels,
                  selectedPlayer: _initiativePlayer,
                  clearKey: const Key('life-counter-clear-initiative'),
                  onSelected: _selectInitiative,
                ),
                const SizedBox(height: 12),
                _PlayerSelectionCard(
                  title: 'Primeiro jogador',
                  subtitle: 'Deixe salvo quem começou a partida.',
                  chipPrefix: '1º',
                  color: AppTheme.primarySoft,
                  playerCount: widget.playerCount,
                  playerLabels: widget.playerLabels,
                  selectedPlayer: _firstPlayerIndex,
                  clearKey: const Key('life-counter-clear-first-player'),
                  onSelected: _selectFirstPlayer,
                ),
                const SizedBox(height: 16),
                Text(
                  'Utilidades rápidas',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ToolActionButton(
                      buttonKey: const Key('life-counter-tool-coin'),
                      icon: Icons.flip_camera_android_rounded,
                      label: 'Moeda',
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
                      label: 'Sortear 1º',
                      onTap: _runFirstPlayerRoll,
                    ),
                  ],
                ),
                if (_lastTableEvent != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    key: const Key('life-counter-table-event'),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: AppTheme.outlineMuted,
                        width: 0.8,
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
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
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
    return FilledButton.tonalIcon(
      key: buttonKey,
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.surfaceElevated,
        foregroundColor: AppTheme.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

// ---------------------------------------------------------------------------
// Counter Row (reusable +/- row for any counter type)
// ---------------------------------------------------------------------------
class _CounterRow extends StatelessWidget {
  final Key? rowKey;
  final Key? sublabelKey;
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
          _RoundButton(icon: Icons.add, color: color, onTap: onIncrement),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Round + / - button for counter rows
// ---------------------------------------------------------------------------
class _RoundButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _RoundButton({required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
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
// Settings Sheet
// ---------------------------------------------------------------------------

/// Bottom sheet para configurar número de jogadores e vida inicial.
class _SettingsSheet extends StatelessWidget {
  final int playerCount;
  final int startingLife;
  final ValueChanged<int> onPlayerCountChanged;
  final ValueChanged<int> onStartingLifeChanged;

  const _SettingsSheet({
    required this.playerCount,
    required this.startingLife,
    required this.onPlayerCountChanged,
    required this.onStartingLifeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configurações',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Player count
          Text(
            'Jogadores',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children:
                [2, 3, 4].map((count) {
                  final isSelected = count == playerCount;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text('$count'),
                        selected: isSelected,
                        onSelected: (_) => onPlayerCountChanged(count),
                        selectedColor: AppTheme.manaViolet,
                        labelStyle: TextStyle(
                          color:
                              isSelected
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 20),

          // Starting life
          Text(
            'Vida Inicial',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [20, 25, 30, 40].map((life) {
                  final isSelected = life == startingLife;
                  return ChoiceChip(
                    label: Text('$life'),
                    selected: isSelected,
                    onSelected: (_) => onStartingLifeChanged(life),
                    selectedColor: AppTheme.manaViolet,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            '20 = Standard/Modern • 25 = Brawl\n30 = Oathbreaker • 40 = Commander',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textHint,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
