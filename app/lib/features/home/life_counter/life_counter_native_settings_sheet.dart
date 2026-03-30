import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'life_counter_settings.dart';
import 'life_counter_settings_catalog.dart';

Future<LifeCounterSettings?> showLifeCounterNativeSettingsSheet(
  BuildContext context, {
  required LifeCounterSettings initialSettings,
}) {
  return showModalBottomSheet<LifeCounterSettings>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _LifeCounterNativeSettingsSheet(
        initialSettings: initialSettings,
      );
    },
  );
}

class _LifeCounterNativeSettingsSheet extends StatefulWidget {
  const _LifeCounterNativeSettingsSheet({
    required this.initialSettings,
  });

  final LifeCounterSettings initialSettings;

  @override
  State<_LifeCounterNativeSettingsSheet> createState() =>
      _LifeCounterNativeSettingsSheetState();
}

class _LifeCounterNativeSettingsSheetState
    extends State<_LifeCounterNativeSettingsSheet> {
  late LifeCounterSettings _settings;
  late final TextEditingController _customLongTapController;
  late final TextEditingController _whitelabelIconController;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
    _customLongTapController = TextEditingController(
      text: _settings.customLongTapValue.toString(),
    );
    _whitelabelIconController = TextEditingController(
      text: _settings.whitelabelIcon ?? '',
    );
  }

  @override
  void dispose() {
    _customLongTapController.dispose();
    _whitelabelIconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sections = buildLifeCounterSettingsCatalog(_settings);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 12,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 12,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.92,
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
                              'Life Counter Settings',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: AppTheme.fontXxl,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'ManaLoom now owns this shell surface while the Lotus tabletop stays unchanged.',
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
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    itemCount: sections.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 18),
                    itemBuilder: (context, index) {
                      final section = sections[index];
                      return _SettingsSection(
                        section: section,
                        customLongTapController: _customLongTapController,
                        whitelabelIconController: _whitelabelIconController,
                        onToggleChanged: _handleToggleChanged,
                        onNumberChanged: _handleNumberChanged,
                        onTextChanged: _handleTextChanged,
                      );
                    },
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
                          key: const Key('life-counter-native-settings-save'),
                          onPressed: () => Navigator.of(context).pop(_settings),
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
      ),
    );
  }

  void _handleToggleChanged(
    LifeCounterSettingFieldId id,
    bool value,
  ) {
    setState(() {
      switch (id) {
        case LifeCounterSettingFieldId.autoKill:
          _settings = _settings.copyWith(autoKill: value);
        case LifeCounterSettingFieldId.lifeLossOnCommanderDamage:
          _settings = _settings.copyWith(lifeLossOnCommanderDamage: value);
        case LifeCounterSettingFieldId.showCountersOnPlayerCard:
          _settings = _settings.copyWith(showCountersOnPlayerCard: value);
        case LifeCounterSettingFieldId.showRegularCounters:
          _settings = _settings.copyWith(showRegularCounters: value);
        case LifeCounterSettingFieldId.showCommanderDamageCounters:
          _settings = _settings.copyWith(showCommanderDamageCounters: value);
        case LifeCounterSettingFieldId.clickableCommanderDamageCounters:
          _settings = _settings.copyWith(
            clickableCommanderDamageCounters: value,
          );
        case LifeCounterSettingFieldId.keepZeroCountersOnPlayerCard:
          _settings = _settings.copyWith(keepZeroCountersOnPlayerCard: value);
        case LifeCounterSettingFieldId.saltyDefeatMessages:
          _settings = _settings.copyWith(saltyDefeatMessages: value);
        case LifeCounterSettingFieldId.cycleSaltyDefeatMessages:
          _settings = _settings.copyWith(cycleSaltyDefeatMessages: value);
        case LifeCounterSettingFieldId.gameTimer:
          _settings = _settings.copyWith(gameTimer: value);
        case LifeCounterSettingFieldId.gameTimerMainScreen:
          _settings = _settings.copyWith(gameTimerMainScreen: value);
        case LifeCounterSettingFieldId.showClockOnMainScreen:
          _settings = _settings.copyWith(showClockOnMainScreen: value);
        case LifeCounterSettingFieldId.randomPlayerColors:
          _settings = _settings.copyWith(randomPlayerColors: value);
        case LifeCounterSettingFieldId.preserveBackgroundImagesOnShuffle:
          _settings = _settings.copyWith(
            preserveBackgroundImagesOnShuffle: value,
          );
        case LifeCounterSettingFieldId.setLifeByTappingNumber:
          _settings = _settings.copyWith(setLifeByTappingNumber: value);
        case LifeCounterSettingFieldId.verticalTapAreas:
          _settings = _settings.copyWith(verticalTapAreas: value);
        case LifeCounterSettingFieldId.cleanLook:
          _settings = _settings.copyWith(cleanLook: value);
        case LifeCounterSettingFieldId.criticalDamageWarning:
          _settings = _settings.copyWith(criticalDamageWarning: value);
        case LifeCounterSettingFieldId.customLongTapEnabled:
          _settings = _settings.copyWith(customLongTapEnabled: value);
        case LifeCounterSettingFieldId.customLongTapValue:
        case LifeCounterSettingFieldId.whitelabelIcon:
          break;
      }
    });
  }

  void _handleNumberChanged(
    LifeCounterSettingFieldId id,
    String value,
  ) {
    final parsed = int.tryParse(value);
    if (parsed == null) {
      return;
    }

    setState(() {
      switch (id) {
        case LifeCounterSettingFieldId.customLongTapValue:
          _settings = _settings.copyWith(
            customLongTapValue: parsed.clamp(1, 999),
          );
        default:
          break;
      }
    });
  }

  void _handleTextChanged(
    LifeCounterSettingFieldId id,
    String value,
  ) {
    setState(() {
      switch (id) {
        case LifeCounterSettingFieldId.whitelabelIcon:
          _settings = _settings.copyWith(
            whitelabelIcon: value.trim().isEmpty ? null : value.trim(),
          );
        default:
          break;
      }
    });
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.section,
    required this.customLongTapController,
    required this.whitelabelIconController,
    required this.onToggleChanged,
    required this.onNumberChanged,
    required this.onTextChanged,
  });

  final LifeCounterSettingsSection section;
  final TextEditingController customLongTapController;
  final TextEditingController whitelabelIconController;
  final void Function(LifeCounterSettingFieldId id, bool value)
      onToggleChanged;
  final void Function(LifeCounterSettingFieldId id, String value)
      onNumberChanged;
  final void Function(LifeCounterSettingFieldId id, String value)
      onTextChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: const TextStyle(
                color: AppTheme.primarySoft,
                fontSize: AppTheme.fontLg,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            for (final entry in section.entries)
              _SettingEntryTile(
                entry: entry,
                customLongTapController: customLongTapController,
                whitelabelIconController: whitelabelIconController,
                onToggleChanged: onToggleChanged,
                onNumberChanged: onNumberChanged,
                onTextChanged: onTextChanged,
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingEntryTile extends StatelessWidget {
  const _SettingEntryTile({
    required this.entry,
    required this.customLongTapController,
    required this.whitelabelIconController,
    required this.onToggleChanged,
    required this.onNumberChanged,
    required this.onTextChanged,
  });

  final LifeCounterSettingEntry entry;
  final TextEditingController customLongTapController;
  final TextEditingController whitelabelIconController;
  final void Function(LifeCounterSettingFieldId id, bool value)
      onToggleChanged;
  final void Function(LifeCounterSettingFieldId id, String value)
      onNumberChanged;
  final void Function(LifeCounterSettingFieldId id, String value)
      onTextChanged;

  @override
  Widget build(BuildContext context) {
    switch (entry.kind) {
      case LifeCounterSettingValueKind.toggle:
        return SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(
            entry.label,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: AppTheme.fontMd,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            entry.description,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: AppTheme.fontSm,
              height: 1.3,
            ),
          ),
          value: entry.toggleValue ?? false,
          onChanged: (value) => onToggleChanged(entry.id, value),
        );
      case LifeCounterSettingValueKind.number:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            key: Key('life-counter-setting-${entry.id.name}'),
            controller: customLongTapController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: entry.label,
              helperText: entry.description,
            ),
            onChanged: (value) => onNumberChanged(entry.id, value),
          ),
        );
      case LifeCounterSettingValueKind.text:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            key: Key('life-counter-setting-${entry.id.name}'),
            controller: whitelabelIconController,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: entry.label,
              helperText: entry.description,
            ),
            onChanged: (value) => onTextChanged(entry.id, value),
          ),
        );
    }
  }
}
