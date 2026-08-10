import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

typedef HorizontalDiscoveryRailBuilder =
    Widget Function(BuildContext context, ScrollController controller);

/// Makes a horizontal collection discoverable without covering card artwork.
///
/// The rail owns its controller, announces the interaction to assistive
/// technology and exposes one 48 px directional control outside the content.
/// This keeps full-card images untouched while making overflow explicit on
/// touch and pointer layouts.
class HorizontalDiscoveryRail extends StatefulWidget {
  const HorizontalDiscoveryRail({
    super.key,
    required this.builder,
    required this.semanticLabel,
    required this.hintText,
    required this.forwardSemanticLabel,
    required this.backwardSemanticLabel,
    this.backwardHintText = 'Volte para comparar os itens anteriores.',
    this.hintKey,
    this.forwardButtonKey,
    this.backwardButtonKey,
  });

  final HorizontalDiscoveryRailBuilder builder;
  final String semanticLabel;
  final String hintText;
  final String backwardHintText;
  final String forwardSemanticLabel;
  final String backwardSemanticLabel;
  final Key? hintKey;
  final Key? forwardButtonKey;
  final Key? backwardButtonKey;

  @override
  State<HorizontalDiscoveryRail> createState() =>
      _HorizontalDiscoveryRailState();
}

class _HorizontalDiscoveryRailState extends State<HorizontalDiscoveryRail> {
  static const _scrollTolerance = 1.0;

  late final ScrollController _controller;
  bool _hasOverflow = false;
  bool _canScrollBackward = false;
  bool _canScrollForward = false;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController()..addListener(_refreshMetrics);
    _scheduleMetricsRefresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleMetricsRefresh();
  }

  @override
  void didUpdateWidget(covariant HorizontalDiscoveryRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleMetricsRefresh();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refreshMetrics)
      ..dispose();
    super.dispose();
  }

  void _scheduleMetricsRefresh() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshMetrics();
    });
  }

  void _refreshMetrics() {
    if (!mounted) return;
    if (!_controller.hasClients) {
      _setMetrics(hasOverflow: false, canGoBack: false, canGoForward: false);
      return;
    }

    final position = _controller.position;
    final hasOverflow = position.maxScrollExtent > _scrollTolerance;
    _setMetrics(
      hasOverflow: hasOverflow,
      canGoBack: hasOverflow && position.pixels > _scrollTolerance,
      canGoForward:
          hasOverflow &&
          position.pixels < position.maxScrollExtent - _scrollTolerance,
    );
  }

  void _setMetrics({
    required bool hasOverflow,
    required bool canGoBack,
    required bool canGoForward,
  }) {
    if (_hasOverflow == hasOverflow &&
        _canScrollBackward == canGoBack &&
        _canScrollForward == canGoForward) {
      return;
    }
    setState(() {
      _hasOverflow = hasOverflow;
      _canScrollBackward = canGoBack;
      _canScrollForward = canGoForward;
    });
  }

  Future<void> _move({required bool forward}) async {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final delta = math.max(120.0, position.viewportDimension * 0.72);
    final target = (position.pixels + (forward ? delta : -delta)).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller.jumpTo(target);
      return;
    }
    await _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rail = Expanded(
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: (_) {
          _scheduleMetricsRefresh();
          return false;
        },
        child: widget.builder(context, _controller),
      ),
    );
    final showBackwardControl =
        _hasOverflow && !_canScrollForward && _canScrollBackward;

    return Semantics(
      container: true,
      label: widget.semanticLabel,
      hint: _hasOverflow ? widget.hintText : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              rail,
              if (_hasOverflow) ...[
                const SizedBox(width: AppTheme.space8),
                if (showBackwardControl)
                  _RailDirectionButton(
                    key: widget.backwardButtonKey,
                    icon: Icons.chevron_left_rounded,
                    semanticLabel: widget.backwardSemanticLabel,
                    onPressed: () => _move(forward: false),
                  )
                else
                  _RailDirectionButton(
                    key: widget.forwardButtonKey,
                    icon: Icons.chevron_right_rounded,
                    semanticLabel: widget.forwardSemanticLabel,
                    onPressed: () => _move(forward: true),
                  ),
              ],
            ],
          ),
          if (_hasOverflow) ...[
            const SizedBox(height: AppTheme.space5),
            Semantics(
              label: showBackwardControl
                  ? widget.backwardHintText
                  : widget.hintText,
              child: ExcludeSemantics(
                child: Row(
                  key: widget.hintKey,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      showBackwardControl
                          ? Icons.swipe_right_rounded
                          : Icons.swipe_left_rounded,
                      size: 16,
                      color: AppTheme.frost400,
                    ),
                    const SizedBox(width: AppTheme.space5),
                    Flexible(
                      child: Text(
                        showBackwardControl
                            ? widget.backwardHintText
                            : widget.hintText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textSecondary,
                          height: AppTheme.lineHeightCompact,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RailDirectionButton extends StatelessWidget {
  const _RailDirectionButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Tooltip(
        message: semanticLabel,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.square(AppTheme.touchTargetMin),
            maximumSize: const Size.square(AppTheme.touchTargetMin),
            padding: EdgeInsets.zero,
            foregroundColor: AppTheme.frost400,
            backgroundColor: AppTheme.backgroundAbyss.withValues(alpha: 0.48),
            side: BorderSide(color: AppTheme.frost400.withValues(alpha: 0.46)),
            shape: const CircleBorder(),
          ),
          child: Icon(icon, size: 22),
        ),
      ),
    );
  }
}
