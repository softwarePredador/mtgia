import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_state_panel.dart';
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
      body: Column(
        children: [
          _BattleReplayActions(
            isRunning: _isRunning,
            onRunGoldfish: _runGoldfish,
            onRunBattle: _runBattle,
          ),
          Expanded(child: _buildBody()),
        ],
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

    final selectedReplay = _selectedReplay;
    if (selectedReplay != null) {
      return _BattleReplayDetailPane(
        detail: selectedReplay,
        view: _detailView,
        onViewChanged: (view) => setState(() => _detailView = view),
        onBack: () => setState(() => _selectedReplay = null),
      );
    }

    if (_replays.isEmpty) {
      return AppStatePanel(
        key: const Key('battle-replays-empty-state'),
        icon: Icons.history_toggle_off_rounded,
        title: 'Nenhum replay salvo',
        message:
            'Rode uma simulacao para criar historico. Battle usa o simulador experimental do backend e deve ser lido como evidencia advisory.',
        accent: AppTheme.brass400,
        actionLabel: 'Rodar goldfish',
        onAction: _runGoldfish,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReplays,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _replays.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final replay = _replays[index];
          return _BattleReplaySummaryTile(
            replay: replay,
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
  const _BattleReplaySummaryTile({required this.replay, required this.onTap});

  final BattleReplaySummary replay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppTheme.surfaceElevated,
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
              color: AppTheme.outlineMuted.withValues(alpha: 0.62),
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

class _BattleReplayDetailPane extends StatelessWidget {
  const _BattleReplayDetailPane({
    required this.detail,
    required this.view,
    required this.onViewChanged,
    required this.onBack,
  });

  final BattleReplayDetail detail;
  final _ReplayDetailView view;
  final ValueChanged<_ReplayDetailView> onViewChanged;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = detail.summary;
    return ListView(
      key: const Key('battle-replay-detail-pane'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
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
                    icon: Icon(Icons.timeline_outlined),
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
                    label: Text('Raw'),
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
    if (detail.events.isEmpty) {
      final text = detail.replayText?.trim();
      if (text != null && text.isNotEmpty) {
        return _ReplayTextBlock(text: text);
      }
      return const _InlineEmptyPanel(
        key: Key('battle-replay-no-events-state'),
        icon: Icons.timeline_outlined,
        title: 'Replay sem eventos estruturados',
        message: 'O backend ainda nao retornou timeline ou texto de replay.',
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
        title: 'Sem decision trace',
        message: 'Quando o runner expuser decisoes, elas aparecem aqui.',
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
                    'Score ${decision.score!.toStringAsFixed(2)}',
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
          fontFamily: 'monospace',
          fontSize: AppTheme.fontSm,
          height: 1.38,
        ),
      ),
    );
  }
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
