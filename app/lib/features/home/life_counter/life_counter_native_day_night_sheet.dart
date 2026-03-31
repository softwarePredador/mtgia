import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'life_counter_day_night_state.dart';

Future<LifeCounterDayNightState?> showLifeCounterNativeDayNightSheet(
  BuildContext context, {
  required LifeCounterDayNightState initialState,
}) {
  return showModalBottomSheet<LifeCounterDayNightState>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _LifeCounterNativeDayNightSheet(initialState: initialState);
    },
  );
}

class _LifeCounterNativeDayNightSheet extends StatefulWidget {
  const _LifeCounterNativeDayNightSheet({required this.initialState});

  final LifeCounterDayNightState initialState;

  @override
  State<_LifeCounterNativeDayNightSheet> createState() =>
      _LifeCounterNativeDayNightSheetState();
}

class _LifeCounterNativeDayNightSheetState
    extends State<_LifeCounterNativeDayNightSheet> {
  late bool _isNight;

  @override
  void initState() {
    super.initState();
    _isNight = widget.initialState.isNight;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.backgroundAbyss,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.outlineMuted),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 28,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Day / Night',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: AppTheme.fontXxl,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'ManaLoom now owns the tabletop day-night state without changing the Lotus layout.',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: AppTheme.fontMd,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: AppTheme.textSecondary,
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.outlineMuted),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('Day'),
                          icon: Icon(Icons.wb_sunny_outlined),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('Night'),
                          icon: Icon(Icons.nightlight_round),
                        ),
                      ],
                      selected: <bool>{_isNight},
                      onSelectionChanged: (selection) {
                        setState(() {
                          _isNight = selection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isNight
                          ? 'Night is active on the tabletop.'
                          : 'Day is active on the tabletop.',
                      key: const Key(
                        'life-counter-native-day-night-current-label',
                      ),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: AppTheme.fontMd,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.outlineMuted),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          side: const BorderSide(color: AppTheme.outlineMuted),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        key: const Key('life-counter-native-day-night-apply'),
                        onPressed:
                            () => Navigator.of(
                              context,
                            ).pop(LifeCounterDayNightState(isNight: _isNight)),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.manaViolet,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
