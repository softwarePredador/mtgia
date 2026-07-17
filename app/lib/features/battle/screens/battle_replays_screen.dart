import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cached_card_image.dart';
import '../../../core/widgets/app_state_panel.dart';
import '../../../core/widgets/mana_symbols.dart';
import '../models/battle_replay.dart';
import '../services/battle_replay_service.dart';

enum _ReplayDetailView { timeline, decisions, raw }

class BattleReplaysScreen extends StatefulWidget {
  const BattleReplaysScreen({super.key, required this.deckId, this.gateway});

  final String deckId;
  final BattleReplayGateway? gateway;

  @override
  State<BattleReplaysScreen> createState() => _BattleReplaysScreenState();
}

class _BattleReplaysScreenState extends State<BattleReplaysScreen> {
  late final BattleReplayGateway _gateway;
  final TextEditingController _opponentController = TextEditingController();

  bool _isLoading = true;
  bool _isRunning = false;
  String? _error;
  List<BattleReplaySummary> _replays = const <BattleReplaySummary>[];
  BattleReplayDetail? _selectedReplay;
  _ReplayDetailView _detailView = _ReplayDetailView.timeline;

  @override
  void initState() {
    super.initState();
    _gateway = widget.gateway ?? BattleReplayService();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReplays());
  }

  @override
  void dispose() {
    _opponentController.dispose();
    super.dispose();
  }

  Future<void> _loadReplays({bool quiet = false}) async {
    if (!quiet) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final replays = await _gateway.listReplays(widget.deckId);
      if (!mounted) return;
      setState(() {
        _replays = replays;
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = _friendlyError(error);
      });
    }
  }

  Future<void> _openReplay(BattleReplaySummary summary) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final detail = await _gateway.fetchReplay(
        deckId: widget.deckId,
        replayId: summary.id,
      );
      if (!mounted) return;
      setState(() {
        _selectedReplay = detail;
        _detailView = _ReplayDetailView.timeline;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = _friendlyError(error);
      });
    }
  }

  Future<void> _runGoldfish() async {
    await _runSimulation(
      () => _gateway.runGoldfishSimulation(deckId: widget.deckId),
    );
  }

  Future<void> _runBattle() async {
    final opponentDeckId = await _askOpponentDeckId();
    if (opponentDeckId == null || opponentDeckId.trim().isEmpty) return;
    await _runSimulation(
      () => _gateway.runBattleSimulation(
        deckId: widget.deckId,
        opponentDeckId: opponentDeckId.trim(),
      ),
    );
  }

  Future<void> _runSimulation(
    Future<BattleReplayDetail> Function() runner,
  ) async {
    setState(() {
      _isRunning = true;
      _error = null;
    });

    try {
      final detail = await runner();
      if (!mounted) return;
      setState(() {
        _selectedReplay = detail;
        _detailView = _ReplayDetailView.timeline;
        _isRunning = false;
      });
      await _loadReplays(quiet: true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isRunning = false;
        _error = _friendlyError(error);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(error)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<String?> _askOpponentDeckId() async {
    _opponentController.clear();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Battle experimental'),
          content: TextField(
            key: const Key('battle-opponent-deck-id-field'),
            controller: _opponentController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Deck adversario',
              hintText: 'Cole o opponent_deck_id',
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed:
                  () => Navigator.of(context).pop(_opponentController.text),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Rodar'),
            ),
          ],
        );
      },
    );
  }

  String _friendlyError(Object error) {
    if (error is BattleReplayException) return error.message;
    return 'Nao foi possivel carregar as simulacoes.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('battle-replays-screen'),
      appBar: AppBar(
        title: const Text('Battle & replays'),
        actions: [
          IconButton(
            key: const Key('battle-replays-refresh-button'),
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isRunning ? null : () => _loadReplays(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          key: const Key('battle-replays-workspace'),
          constraints: const BoxConstraints(maxWidth: AppTheme.contentMaxWidth),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Column(
              children: [
                _BattleReplayActions(
                  isRunning: _isRunning,
                  onRunGoldfish: _runGoldfish,
                  onRunBattle: _runBattle,
                ),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AppStatePanel(
        key: Key('battle-replays-loading-state'),
        icon: Icons.psychology_alt_outlined,
        title: 'Carregando replays',
        message: 'Buscando simulacoes salvas e trilhas de decisao do deck.',
        accent: AppTheme.frost400,
      );
    }

    if (_error != null) {
      return AppStatePanel(
        key: const Key('battle-replays-error-state'),
        icon: Icons.error_outline_rounded,
        title: 'Nao foi possivel carregar battle',
        message: _error,
        accent: Theme.of(context).colorScheme.error,
        actionLabel: 'Tentar novamente',
        onAction: _loadReplays,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppTheme.breakpointExpanded;
        final selectedReplay = _selectedReplay;

        if (isDesktop && (_replays.isNotEmpty || selectedReplay != null)) {
          return _buildMasterDetail(selectedReplay);
        }

        if (selectedReplay != null) {
          return _buildDetailPane(selectedReplay);
        }

        if (_replays.isEmpty) return _buildEmptyState();
        return _buildReplayList();
      },
    );
  }

  Widget _buildMasterDetail(BattleReplayDetail? selectedReplay) {
    return Row(
      key: const Key('battle-replays-master-detail'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          key: const Key('battle-replays-history-pane'),
          width: 344,
          child:
              _replays.isEmpty
                  ? _buildEmptyState()
                  : _buildReplayList(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  ),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: AppTheme.outlineMuted.withValues(alpha: 0.52),
        ),
        const SizedBox(width: AppTheme.paneGap),
        Expanded(
          child:
              selectedReplay == null
                  ? const _ReplaySelectionEmpty()
                  : _buildDetailPane(selectedReplay, showBack: false),
        ),
      ],
    );
  }

  Widget _buildDetailPane(BattleReplayDetail detail, {bool showBack = true}) {
    return _BattleReplayDetailPane(
      detail: detail,
      view: _detailView,
      onViewChanged: (view) => setState(() => _detailView = view),
      onBack: () => setState(() => _selectedReplay = null),
      showBack: showBack,
    );
  }

  Widget _buildEmptyState() {
    return AppStatePanel(
      key: const Key('battle-replays-empty-state'),
      icon: Icons.history_toggle_off_rounded,
      title: 'Nenhum replay salvo',
      message:
          'Rode uma simulacao para criar historico. Cada replay informa o motor e o contrato de execucao usados.',
      accent: AppTheme.brass400,
      actionLabel: 'Rodar goldfish',
      onAction: _runGoldfish,
    );
  }

  Widget _buildReplayList({
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(16, 12, 16, 24),
  }) {
    return RefreshIndicator(
      onRefresh: _loadReplays,
      child: ListView.separated(
        key: const Key('battle-replays-history-list'),
        padding: padding,
        itemCount: _replays.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final replay = _replays[index];
          return _BattleReplaySummaryTile(
            replay: replay,
            selected: replay.id == _selectedReplay?.summary.id,
            onTap: () => _openReplay(replay),
          );
        },
      ),
    );
  }
}

class _BattleReplayActions extends StatelessWidget {
  const _BattleReplayActions({
    required this.isRunning,
    required this.onRunGoldfish,
    required this.onRunBattle,
  });

  final bool isRunning;
  final VoidCallback onRunGoldfish;
  final VoidCallback onRunBattle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.outlineMuted.withValues(alpha: 0.58),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Simulacoes do deck',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isRunning)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Use como leitura experimental: nao substitui regra oficial, legalidade ou validacao de troca.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.32,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                key: const Key('battle-run-goldfish-button'),
                onPressed: isRunning ? null : onRunGoldfish,
                icon: const Icon(Icons.speed_rounded),
                label: const Text('Goldfish'),
              ),
              OutlinedButton.icon(
                key: const Key('battle-run-battle-button'),
                onPressed: isRunning ? null : onRunBattle,
                icon: const Icon(Icons.sports_martial_arts_rounded),
                label: const Text('Battle'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BattleReplaySummaryTile extends StatelessWidget {
  const _BattleReplaySummaryTile({
    required this.replay,
    required this.onTap,
    this.selected = false,
  });

  final BattleReplaySummary replay;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color:
          selected
              ? AppTheme.frost400.withValues(alpha: 0.08)
              : AppTheme.surfaceElevated,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        key: Key('battle-replay-summary-${replay.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color:
                  selected
                      ? AppTheme.frost400.withValues(alpha: 0.48)
                      : AppTheme.outlineMuted.withValues(alpha: 0.62),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.frost400.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(
                      Icons.psychology_alt_outlined,
                      color: AppTheme.frost400,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          replay.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          replay.resultLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textHint,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ReplayMetaChip(label: replay.statusLabel),
                  _ReplayMetaChip(label: replay.turnLabel),
                  _ReplayMetaChip(label: replay.eventLabel),
                  if (replay.createdAt != null)
                    _ReplayMetaChip(label: _formatDate(replay.createdAt!)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReplaySelectionEmpty extends StatelessWidget {
  const _ReplaySelectionEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      key: const Key('battle-replays-selection-empty'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.sports_esports_outlined,
                size: 36,
                color: AppTheme.frost400,
              ),
              const SizedBox(height: 14),
              Text(
                'Selecione um replay',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'O historico permanece visivel enquanto voce percorre a partida.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BattleReplayDetailPane extends StatelessWidget {
  const _BattleReplayDetailPane({
    required this.detail,
    required this.view,
    required this.onViewChanged,
    required this.onBack,
    this.showBack = true,
  });

  final BattleReplayDetail detail;
  final _ReplayDetailView view;
  final ValueChanged<_ReplayDetailView> onViewChanged;
  final VoidCallback onBack;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = detail.summary;
    return ListView(
      key: const Key('battle-replay-detail-pane'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (showBack)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Replays'),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: AppTheme.outlineMuted.withValues(alpha: 0.62),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summary.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${summary.resultLabel} · ${summary.turnLabel} · ${summary.sourceLabel}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.32,
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<_ReplayDetailView>(
                segments: const [
                  ButtonSegment(
                    value: _ReplayDetailView.timeline,
                    icon: Icon(Icons.table_chart_outlined),
                    label: Text('Replay'),
                  ),
                  ButtonSegment(
                    value: _ReplayDetailView.decisions,
                    icon: Icon(Icons.account_tree_outlined),
                    label: Text('Decisoes'),
                  ),
                  ButtonSegment(
                    value: _ReplayDetailView.raw,
                    icon: Icon(Icons.data_object_rounded),
                    label: Text('Dados'),
                  ),
                ],
                selected: {view},
                onSelectionChanged: (selection) {
                  onViewChanged(selection.first);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        switch (view) {
          _ReplayDetailView.timeline => _ReplayTimeline(detail: detail),
          _ReplayDetailView.decisions => _ReplayDecisions(detail: detail),
          _ReplayDetailView.raw => _ReplayRaw(detail: detail),
        },
      ],
    );
  }
}

class _ReplayTimeline extends StatelessWidget {
  const _ReplayTimeline({required this.detail});

  final BattleReplayDetail detail;

  @override
  Widget build(BuildContext context) {
    if (detail.visualSnapshots.isNotEmpty) {
      return _ReplayVisualViewer(detail: detail);
    }

    if (detail.events.isEmpty) {
      final text = detail.replayText?.trim();
      if (text != null && text.isNotEmpty) {
        return _ReplayTextBlock(text: text);
      }
      return const _InlineEmptyPanel(
        key: Key('battle-replay-no-events-state'),
        icon: Icons.timeline_outlined,
        title: 'Replay sem jogadas registradas',
        message: 'Ainda nao ha relato suficiente para exibir esta partida.',
      );
    }

    return Column(
      children: detail.events
          .map((event) => _ReplayEventTile(event: event))
          .toList(growable: false),
    );
  }
}

class _ReplayDecisions extends StatelessWidget {
  const _ReplayDecisions({required this.detail});

  final BattleReplayDetail detail;

  @override
  Widget build(BuildContext context) {
    if (detail.decisions.isEmpty) {
      return const _InlineEmptyPanel(
        key: Key('battle-replay-no-decisions-state'),
        icon: Icons.account_tree_outlined,
        title: 'Sem decisoes registradas',
        message:
            'Quando a simulacao explicar escolhas importantes, elas aparecem aqui.',
      );
    }

    return Column(
      children: detail.decisions
          .map((decision) => _ReplayDecisionTile(decision: decision))
          .toList(growable: false),
    );
  }
}

class _ReplayRaw extends StatelessWidget {
  const _ReplayRaw({required this.detail});

  final BattleReplayDetail detail;

  @override
  Widget build(BuildContext context) {
    final text = const JsonEncoder.withIndent('  ').convert(detail.raw);
    return _ReplayTextBlock(text: text);
  }
}

class _ReplayVisualViewer extends StatefulWidget {
  const _ReplayVisualViewer({required this.detail});

  final BattleReplayDetail detail;

  @override
  State<_ReplayVisualViewer> createState() => _ReplayVisualViewerState();
}

class _ReplayVisualViewerState extends State<_ReplayVisualViewer> {
  int _index = 0;

  @override
  void didUpdateWidget(covariant _ReplayVisualViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.detail.visualSnapshots.length) {
      _index = widget.detail.visualSnapshots.length - 1;
    }
  }

  void _move(int delta) {
    final next = (_index + delta).clamp(
      0,
      widget.detail.visualSnapshots.length - 1,
    );
    if (next == _index) return;
    setState(() => _index = next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snapshots = widget.detail.visualSnapshots;
    final snapshot = snapshots[_index];
    final canMoveBack = _index > 0;
    final canMoveForward = _index < snapshots.length - 1;

    return Container(
      key: const Key('battle-replay-visual-viewer'),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.58),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReplayStepBadge(label: snapshot.turnLabel),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        snapshot.phaseLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppTheme.frost400,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        snapshot.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          height: 1.32,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (snapshot.activePlayer != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Ativo: ${snapshot.activePlayer}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('battle-visual-prev-button'),
                  tooltip: 'Anterior',
                  onPressed: canMoveBack ? () => _move(-1) : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                IconButton(
                  key: const Key('battle-visual-next-button'),
                  tooltip: 'Proximo',
                  onPressed: canMoveForward ? () => _move(1) : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
          if (snapshots.length > 1)
            Slider(
              key: const Key('battle-visual-turn-slider'),
              value: _index.toDouble(),
              min: 0,
              max: (snapshots.length - 1).toDouble(),
              divisions: snapshots.length - 1,
              label: '${_index + 1}/${snapshots.length}',
              semanticFormatterCallback:
                  (value) =>
                      'Jogada ${value.round() + 1} de ${snapshots.length}',
              onChanged: (value) => setState(() => _index = value.round()),
            ),
          _VisualPlayerBoards(
            players: snapshot.players,
            activePlayer: snapshot.activePlayer,
          ),
        ],
      ),
    );
  }
}

class _VisualPlayerBoards extends StatelessWidget {
  const _VisualPlayerBoards({
    required this.players,
    required this.activePlayer,
  });

  final List<BattleReplayPlayerSnapshot> players;
  final String? activePlayer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth >= 760 && players.length == 2;
        if (!sideBySide) {
          return Column(
            children: [
              for (final player in players)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: _VisualPlayerBoard(
                    player: player,
                    isActive: player.name == activePlayer,
                  ),
                ),
            ],
          );
        }

        return Padding(
          key: const Key('battle-visual-player-grid'),
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < players.length; index++) ...[
                if (index > 0) const SizedBox(width: 10),
                Expanded(
                  child: _VisualPlayerBoard(
                    player: players[index],
                    isActive: players[index].name == activePlayer,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _VisualPlayerBoard extends StatelessWidget {
  const _VisualPlayerBoard({required this.player, required this.isActive});

  final BattleReplayPlayerSnapshot player;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: Key('battle-visual-player-${player.name}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isActive
                ? AppTheme.frost400.withValues(alpha: 0.08)
                : AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color:
              isActive
                  ? AppTheme.frost400.withValues(alpha: 0.44)
                  : AppTheme.outlineMuted.withValues(alpha: 0.54),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _ReplayMetaChip(label: '${player.life} vida'),
              const SizedBox(width: 6),
              _ReplayMetaChip(label: '${player.mana} mana'),
            ],
          ),
          const SizedBox(height: 10),
          _VisualCardZone(
            key: Key('battle-visual-zone-battlefield-${player.name}'),
            title: 'Campo',
            cards: player.battlefield,
            fallbackCount: player.lands,
            fallbackLabel: 'terrenos',
          ),
          const SizedBox(height: 10),
          _VisualCardZone(
            key: Key('battle-visual-zone-hand-${player.name}'),
            title: 'Mao',
            cards: player.hand,
            fallbackCount: player.handSize,
            fallbackLabel: 'cartas',
          ),
          const SizedBox(height: 10),
          _VisualCardZone(
            key: Key('battle-visual-zone-graveyard-${player.name}'),
            title: 'Cemiterio',
            cards: player.graveyard,
            fallbackCount: player.graveyardSize,
            fallbackLabel: 'cartas',
            compact: true,
          ),
          const SizedBox(height: 8),
          Text(
            'Biblioteca: ${player.librarySize}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.textHint,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualCardZone extends StatelessWidget {
  const _VisualCardZone({
    super.key,
    required this.title,
    required this.cards,
    required this.fallbackCount,
    required this.fallbackLabel,
    this.compact = false,
  });

  final String title;
  final List<BattleReplayVisualCard> cards;
  final int fallbackCount;
  final String fallbackLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              cards.isNotEmpty
                  ? '${cards.length}'
                  : '$fallbackCount $fallbackLabel',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.textHint,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (cards.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSlate.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(
                color: AppTheme.outlineMuted.withValues(alpha: 0.44),
              ),
            ),
            child: Text(
              fallbackCount > 0
                  ? '$fallbackCount $fallbackLabel sem imagem neste replay'
                  : 'Sem cartas nesta zona',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textHint,
              ),
            ),
          )
        else
          _BattleVisualCardCarousel(
            key: Key('battle-visual-card-carousel-${_safeReplayKey(title)}'),
            cards: cards,
            compact: compact,
          ),
      ],
    );
  }
}

class _BattleVisualCardCarousel extends StatefulWidget {
  const _BattleVisualCardCarousel({
    super.key,
    required this.cards,
    required this.compact,
  });

  final List<BattleReplayVisualCard> cards;
  final bool compact;

  @override
  State<_BattleVisualCardCarousel> createState() =>
      _BattleVisualCardCarouselState();
}

class _BattleVisualCardCarouselState extends State<_BattleVisualCardCarousel> {
  PageController? _controller;
  double? _viewportFraction;
  int _index = 0;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  PageController _ensureController(double viewportFraction) {
    if (_controller == null || _viewportFraction != viewportFraction) {
      _controller?.dispose();
      _viewportFraction = viewportFraction;
      _controller = PageController(
        viewportFraction: viewportFraction,
        initialPage: _index.clamp(0, widget.cards.length - 1).toInt(),
      );
    }
    return _controller!;
  }

  void _move(int delta) {
    if (widget.cards.isEmpty) return;
    final next = (_index + delta).clamp(0, widget.cards.length - 1);
    if (next == _index) return;
    _controller?.animateToPage(
      next,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
    setState(() => _index = next);
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.compact ? 112.0 : 132.0;
    final cardExtent = widget.compact ? 76.0 : 92.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
        final viewportFraction =
            (cardExtent / width).clamp(0.08, 0.44).toDouble();
        final controller = _ensureController(viewportFraction);

        return SizedBox(
          height: height,
          child: Stack(
            children: [
              PageView.builder(
                key: const Key('battle-visual-card-carousel'),
                controller: controller,
                padEnds: false,
                physics: const BouncingScrollPhysics(),
                itemCount: widget.cards.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) {
                  final card = widget.cards[index];
                  final isActive = index == _index;
                  return AnimatedScale(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    scale: isActive ? 1 : 0.94,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: isActive ? 1 : 0.78,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _VisualCardTile(
                            card: card,
                            compact: widget.compact,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (widget.cards.length > 1) ...[
                Positioned(
                  left: 0,
                  top: 18,
                  child: _BattleCarouselNavButton(
                    tooltip: 'Carta anterior',
                    icon: Icons.chevron_left_rounded,
                    onPressed: _index > 0 ? () => _move(-1) : null,
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 18,
                  child: _BattleCarouselNavButton(
                    tooltip: 'Proxima carta',
                    icon: Icons.chevron_right_rounded,
                    onPressed:
                        _index < widget.cards.length - 1
                            ? () => _move(1)
                            : null,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _VisualCardTile extends StatelessWidget {
  const _VisualCardTile({required this.card, required this.compact});

  final BattleReplayVisualCard card;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 54.0 : 66.0;
    final height = compact ? 76.0 : 92.0;
    final theme = Theme.of(context);
    final imageUrl = _battleCardImageUrl(card);

    return Semantics(
      key: Key('battle-visual-card-${card.name}'),
      button: true,
      label: 'Ver ${card.name}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          onTap: () => _showReplayCardPreview(context, card),
          child: SizedBox(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CachedCardImage(
                      key: Key('battle-visual-card-image-${card.name}'),
                      imageUrl: imageUrl,
                      width: width,
                      height: height,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                    ),
                    if (card.isTapped)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppTheme.overlayBlack40,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusXs,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.rotate_90_degrees_ccw_rounded,
                              color: AppTheme.textPrimary,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  card.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    height: 1.08,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (card.powerToughnessLabel != null)
                  Text(
                    card.powerToughnessLabel!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.textHint,
                      height: 1.08,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BattleCarouselNavButton extends StatelessWidget {
  const _BattleCarouselNavButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceElevated.withValues(alpha: 0.86),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
      ),
    );
  }
}

void _showReplayCardPreview(BuildContext context, BattleReplayVisualCard card) {
  showDialog<void>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      final imageUrl = _battleCardImageUrl(card, version: 'normal');
      return Dialog(
        insetPadding: const EdgeInsets.all(20),
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        card.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: CachedCardImage(
                    imageUrl: imageUrl,
                    width: 220,
                    height: 306,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                ),
                const SizedBox(height: 12),
                if (card.typeLine != null && card.typeLine!.trim().isNotEmpty)
                  Text(
                    card.typeLine!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (card.manaCost != null &&
                        card.manaCost!.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceSlate,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusPill,
                          ),
                          border: Border.all(
                            color: AppTheme.outlineMuted.withValues(alpha: 0.6),
                          ),
                        ),
                        child: ManaCostRow(cost: card.manaCost, symbolSize: 17),
                      ),
                    if (card.powerToughnessLabel != null)
                      _ReplayMetaChip(label: card.powerToughnessLabel!),
                    if (card.isTapped) const _ReplayMetaChip(label: 'Virada'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ReplayEventTile extends StatelessWidget {
  const _ReplayEventTile({required this.event});

  final BattleReplayEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.58),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReplayStepBadge(label: event.turnLabel),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.phaseLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.frost400,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    height: 1.32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplayDecisionTile extends StatelessWidget {
  const _ReplayDecisionTile({required this.decision});

  final BattleReplayDecision decision;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.58),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReplayStepBadge(label: decision.turnLabel),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  decision.choice,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  decision.reason,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.34,
                  ),
                ),
                if (decision.score != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Avaliacao ${decision.score!.toStringAsFixed(2)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.textHint,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplayMetaChip extends StatelessWidget {
  const _ReplayMetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.54),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: AppTheme.fontSm,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReplayStepBadge extends StatelessWidget {
  const _ReplayStepBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.brass500.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.brass500.withValues(alpha: 0.32)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.brass400,
          fontSize: AppTheme.fontSm,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ReplayTextBlock extends StatelessWidget {
  const _ReplayTextBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.58),
        ),
      ),
      child: SelectableText(
        text,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: AppTheme.fontSm,
          height: 1.38,
        ),
      ),
    );
  }
}

String _battleCardImageUrl(
  BattleReplayVisualCard card, {
  String version = 'small',
}) {
  final provided = card.imageUrl?.trim();
  if (provided != null && provided.isNotEmpty) {
    if (version == 'small') return provided.replaceFirst('/normal/', '/small/');
    if (version == 'normal') {
      return provided.replaceFirst('/small/', '/normal/');
    }
    return provided;
  }
  final encoded = Uri.encodeComponent(card.name.trim());
  return 'https://api.scryfall.com/cards/named?exact=$encoded&format=image&version=$version';
}

String _safeReplayKey(String value) {
  final sanitized = value
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  return sanitized.isEmpty ? 'cards' : sanitized;
}

class _InlineEmptyPanel extends StatelessWidget {
  const _InlineEmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.58),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.frost400, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month $hour:$minute';
}
