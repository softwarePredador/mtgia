import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class DialogTitleBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accent;

  const DialogTitleBlock({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class DialogSectionCard extends StatelessWidget {
  final String title;
  final Color accent;
  final IconData? icon;
  final Widget child;

  const DialogSectionCard({
    super.key,
    required this.title,
    required this.accent,
    this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: accent.withValues(alpha: 0.2), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: accent),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class DeckMetaChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback? onTap;

  const DeckMetaChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 0.7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: AppTheme.fontSm,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: content,
    );
  }
}

class FlowLoadingDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Color accent;
  final IconData icon;
  final double? progress;
  final int? stepNumber;
  final int? totalSteps;
  final List<String> tips;

  const FlowLoadingDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.accent,
    required this.icon,
    this.progress,
    this.stepNumber,
    this.totalSteps,
    this.tips = const [],
  });

  @override
  State<FlowLoadingDialog> createState() => _FlowLoadingDialogState();
}

class _FlowLoadingDialogState extends State<FlowLoadingDialog> {
  Timer? _tipTimer;
  int _tipIndex = 0;

  @override
  void initState() {
    super.initState();
    _configureTipRotation();
  }

  @override
  void didUpdateWidget(covariant FlowLoadingDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tips != widget.tips) {
      _tipIndex = 0;
      _configureTipRotation();
    }
  }

  void _configureTipRotation() {
    _tipTimer?.cancel();
    if (widget.tips.length <= 1) return;
    _tipTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        _tipIndex = (_tipIndex + 1) % widget.tips.length;
      });
    });
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTip =
        widget.tips.isEmpty
            ? null
            : widget.tips[_tipIndex % widget.tips.length];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: widget.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Icon(widget.icon, color: widget.accent, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (widget.stepNumber != null && widget.totalSteps != null) ...[
              const SizedBox(height: 10),
              DeckMetaChip(
                label: 'Etapa ${widget.stepNumber} de ${widget.totalSteps}',
                color: widget.accent,
                icon: Icons.timelapse_rounded,
              ),
            ],
            if (widget.subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                widget.subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 16),
            LinearProgressIndicator(value: widget.progress),
            if (currentTip != null) ...[
              const SizedBox(height: 14),
              Container(
                width: 320,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSlate,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: widget.accent.withValues(alpha: 0.16),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 18,
                      color: widget.accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Text(
                          currentTip,
                          key: ValueKey(currentTip),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            height: 1.35,
                          ),
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
