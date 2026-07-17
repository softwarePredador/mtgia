import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'life_counter_player_appearance_profile_store.dart';
import 'life_counter_session.dart';

Future<LifeCounterSession?> showLifeCounterNativePlayerAppearanceSheet(
  BuildContext context, {
  required LifeCounterSession initialSession,
  required int initialTargetPlayerIndex,
  List<LifeCounterPlayerAppearanceProfile> initialProfiles =
      const <LifeCounterPlayerAppearanceProfile>[],
  Future<void> Function(
    LifeCounterSession currentSession,
    int targetPlayerIndex,
  )?
  onExportPressed,
  Future<LifeCounterSession?> Function(
    String rawPayload,
    LifeCounterSession currentSession,
    int targetPlayerIndex,
  )?
  onImportSubmitted,
  Future<List<LifeCounterPlayerAppearanceProfile>> Function(
    String name,
    LifeCounterPlayerAppearance appearance,
  )?
  onSaveProfilePressed,
  Future<List<LifeCounterPlayerAppearanceProfile>> Function(String profileId)?
  onDeleteProfilePressed,
  void Function(
    LifeCounterPlayerAppearanceProfile profile,
    int targetPlayerIndex,
  )?
  onApplyProfilePressed,
}) {
  return showModalBottomSheet<LifeCounterSession>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.transparent,
    builder: (context) {
      return _LifeCounterNativePlayerAppearanceSheet(
        initialSession: initialSession,
        initialTargetPlayerIndex: initialTargetPlayerIndex,
        initialProfiles: initialProfiles,
        onExportPressed: onExportPressed,
        onImportSubmitted: onImportSubmitted,
        onSaveProfilePressed: onSaveProfilePressed,
        onDeleteProfilePressed: onDeleteProfilePressed,
        onApplyProfilePressed: onApplyProfilePressed,
      );
    },
  );
}

class _LifeCounterNativePlayerAppearanceSheet extends StatefulWidget {
  const _LifeCounterNativePlayerAppearanceSheet({
    required this.initialSession,
    required this.initialTargetPlayerIndex,
    required this.initialProfiles,
    this.onExportPressed,
    this.onImportSubmitted,
    this.onSaveProfilePressed,
    this.onDeleteProfilePressed,
    this.onApplyProfilePressed,
  });

  final LifeCounterSession initialSession;
  final int initialTargetPlayerIndex;
  final List<LifeCounterPlayerAppearanceProfile> initialProfiles;
  final Future<void> Function(
    LifeCounterSession currentSession,
    int targetPlayerIndex,
  )?
  onExportPressed;
  final Future<LifeCounterSession?> Function(
    String rawPayload,
    LifeCounterSession currentSession,
    int targetPlayerIndex,
  )?
  onImportSubmitted;
  final Future<List<LifeCounterPlayerAppearanceProfile>> Function(
    String name,
    LifeCounterPlayerAppearance appearance,
  )?
  onSaveProfilePressed;
  final Future<List<LifeCounterPlayerAppearanceProfile>> Function(
    String profileId,
  )?
  onDeleteProfilePressed;
  final void Function(
    LifeCounterPlayerAppearanceProfile profile,
    int targetPlayerIndex,
  )?
  onApplyProfilePressed;

  @override
  State<_LifeCounterNativePlayerAppearanceSheet> createState() =>
      _LifeCounterNativePlayerAppearanceSheetState();
}

class _LifeCounterNativePlayerAppearanceSheetState
    extends State<_LifeCounterNativePlayerAppearanceSheet> {
  late int _targetPlayerIndex;
  late TextEditingController _nicknameController;
  late TextEditingController _customBackgroundController;
  late TextEditingController _profileNameController;
  late LifeCounterPlayerAppearance _appearance;
  late List<LifeCounterPlayerAppearance> _draftAppearances;
  late List<LifeCounterPlayerAppearanceProfile> _profiles;
  String? _backgroundError;
  String? _profileError;

  LifeCounterPlayerAppearance get _draftAppearance => _appearance.copyWith(
    nickname: _nicknameController.text.trim(),
    background:
        _normalizeHexColor(_customBackgroundController.text) ??
        _appearance.background,
  );

  LifeCounterSession get _draftSession {
    final playerAppearances = List<LifeCounterPlayerAppearance>.from(
      _draftAppearances,
    );
    playerAppearances[_targetPlayerIndex] = _draftAppearance;

    return widget.initialSession.copyWith(playerAppearances: playerAppearances);
  }

  @override
  void initState() {
    super.initState();
    _targetPlayerIndex = widget.initialTargetPlayerIndex.clamp(
      0,
      widget.initialSession.playerCount - 1,
    );
    _nicknameController = TextEditingController();
    _customBackgroundController = TextEditingController();
    _profileNameController = TextEditingController();
    _draftAppearances = List<LifeCounterPlayerAppearance>.from(
      widget.initialSession.resolvedPlayerAppearances,
    );
    _profiles = List<LifeCounterPlayerAppearanceProfile>.from(
      widget.initialProfiles,
    );
    _syncFromTarget();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _customBackgroundController.dispose();
    _profileNameController.dispose();
    super.dispose();
  }

  void _syncFromTarget() {
    _appearance = _draftAppearances[_targetPlayerIndex];
    _nicknameController.text = _appearance.nickname;
    _customBackgroundController.text = _appearance.background;
    _backgroundError = null;
    _profileError = null;
  }

  void _changeTarget(int playerIndex) {
    setState(() {
      _draftAppearances[_targetPlayerIndex] = _draftAppearance;
      _targetPlayerIndex = playerIndex;
      _syncFromTarget();
    });
  }

  void _selectBackground(String value) {
    setState(() {
      _appearance = _appearance.copyWith(background: value);
      _customBackgroundController.text = value;
      _backgroundError = null;
    });
  }

  void _clearMainImage() {
    setState(() {
      _appearance = _appearance.copyWith(clearBackgroundImage: true);
    });
  }

  void _clearPartnerImage() {
    setState(() {
      _appearance = _appearance.copyWith(clearBackgroundImagePartner: true);
    });
  }

  bool _applyCustomBackground() {
    final normalized = _normalizeHexColor(_customBackgroundController.text);
    if (normalized == null) {
      setState(() {
        _backgroundError = 'Use uma cor hexadecimal, como #FFB51E.';
      });
      return false;
    }

    _selectBackground(normalized);
    return true;
  }

  LifeCounterSession _buildUpdatedSession() {
    return _draftSession;
  }

  Future<void> _handleExportPressed() async {
    final onExportPressed = widget.onExportPressed;
    if (onExportPressed == null) {
      return;
    }

    await onExportPressed(_draftSession, _targetPlayerIndex);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('A aparência do jogador foi copiada.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _handleImportPressed() async {
    final onImportSubmitted = widget.onImportSubmitted;
    if (onImportSubmitted == null) {
      return;
    }

    final importedSession = await _showPlayerAppearanceImportDialog(
      context,
      (rawPayload) =>
          onImportSubmitted(rawPayload, _draftSession, _targetPlayerIndex),
    );
    if (!mounted || importedSession == null) {
      return;
    }

    setState(() {
      _draftAppearances = List<LifeCounterPlayerAppearance>.from(
        importedSession.resolvedPlayerAppearances,
      );
      _appearance = _draftAppearances[_targetPlayerIndex];
      _nicknameController.text = _appearance.nickname;
      _customBackgroundController.text = _appearance.background;
      _backgroundError = null;
    });

    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('A aparência do jogador foi importada.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _handleSaveProfilePressed() async {
    final onSaveProfilePressed = widget.onSaveProfilePressed;
    if (onSaveProfilePressed == null) {
      return;
    }

    final profileName = _profileNameController.text.trim();
    if (profileName.isEmpty) {
      setState(() {
        _profileError = 'Informe um nome para o perfil antes de salvar.';
      });
      return;
    }

    final profiles = await onSaveProfilePressed(profileName, _draftAppearance);
    if (!mounted) {
      return;
    }

    setState(() {
      _profiles = List<LifeCounterPlayerAppearanceProfile>.from(profiles);
      _profileError = null;
    });

    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Perfil de aparência "$profileName" salvo.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _handleDeleteProfilePressed(String profileId) async {
    final onDeleteProfilePressed = widget.onDeleteProfilePressed;
    if (onDeleteProfilePressed == null) {
      return;
    }

    final profiles = await onDeleteProfilePressed(profileId);
    if (!mounted) {
      return;
    }

    setState(() {
      _profiles = List<LifeCounterPlayerAppearanceProfile>.from(profiles);
    });
  }

  void _applyProfile(LifeCounterPlayerAppearanceProfile profile) {
    widget.onApplyProfilePressed?.call(profile, _targetPlayerIndex);
    setState(() {
      _appearance = profile.appearance;
      _nicknameController.text = _appearance.nickname;
      _customBackgroundController.text = _appearance.background;
      _profileNameController.text = profile.name;
      _backgroundError = null;
      _profileError = null;
    });
  }

  bool get _supportsTransfer =>
      widget.onExportPressed != null || widget.onImportSubmitted != null;

  bool get _supportsProfiles =>
      widget.onSaveProfilePressed != null ||
      widget.onDeleteProfilePressed != null;

  bool get _hasPartnerImage =>
      widget.initialSession.partnerCommanders[_targetPlayerIndex] &&
      _appearance.backgroundImagePartner != null;

  Widget _buildTransferActions() {
    return Row(
      children: [
        if (widget.onExportPressed != null)
          TextButton.icon(
            key: const Key('life-counter-native-player-appearance-export'),
            onPressed: _handleExportPressed,
            icon: const Icon(Icons.ios_share_rounded, size: 18),
            label: const Text('Exportar'),
          ),
        if (widget.onImportSubmitted != null)
          TextButton.icon(
            key: const Key('life-counter-native-player-appearance-import'),
            onPressed: _handleImportPressed,
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Importar'),
          ),
      ],
    );
  }

  Widget _buildProfilesSection() {
    return _SectionCard(
      title: 'Perfis',
      subtitle: 'Salve esta aparência para reutilizá-la em outras partidas.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  key: const Key(
                    'life-counter-native-player-appearance-profile-name',
                  ),
                  controller: _profileNameController,
                  decoration: InputDecoration(
                    labelText: 'Nome do perfil',
                    hintText: 'Grupo de Commander / perfil do jogador',
                    errorText: _profileError,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonal(
                key: const Key(
                  'life-counter-native-player-appearance-save-profile',
                ),
                onPressed: _handleSaveProfilePressed,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                ),
                child: const Text('Salvar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_profiles.isEmpty)
            const Text(
              'Nenhum perfil de aparência salvo.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontSm,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Column(
              children: _profiles
                  .map(
                    (profile) => _AppearanceProfileTile(
                      profile: profile,
                      onApply: () => _applyProfile(profile),
                      onDelete:
                          widget.onDeleteProfilePressed == null
                              ? null
                              : () => _handleDeleteProfilePressed(profile.id),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerLabel = 'Jogador ${_targetPlayerIndex + 1}';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          12,
          12,
          12 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.84,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.backgroundAbyss,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.outlineMuted),
              boxShadow: const [
                BoxShadow(
                  color: AppTheme.overlayBlack40,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Aparência do jogador',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: AppTheme.fontXxl,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Personalize nomes e fundos de cada jogador.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: AppTheme.fontMd,
                                height: AppTheme.lineHeightCompact,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: AppTheme.textSecondary,
                        tooltip: 'Fechar',
                      ),
                    ],
                  ),
                ),
                if (_supportsTransfer)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: _buildTransferActions(),
                  ),
                const Divider(height: 1, color: AppTheme.outlineMuted),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    children: [
                      _SectionCard(
                        title: 'Jogador alvo',
                        subtitle:
                            'Escolha qual aparência de jogador deseja editar.',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List<Widget>.generate(
                            widget.initialSession.playerCount,
                            (index) => ChoiceChip(
                              key: Key(
                                'life-counter-native-player-appearance-target-$index',
                              ),
                              label: Text('Jogador ${index + 1}'),
                              selected: _targetPlayerIndex == index,
                              onSelected: (_) => _changeTarget(index),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SectionCard(
                        title: 'Apelido',
                        subtitle: 'Defina um nome opcional para este jogador.',
                        child: TextField(
                          key: const Key(
                            'life-counter-native-player-appearance-nickname',
                          ),
                          controller: _nicknameController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Apelido',
                            hintText: 'Nome opcional do jogador',
                          ),
                        ),
                      ),
                      if (_supportsProfiles) ...[
                        const SizedBox(height: 18),
                        _buildProfilesSection(),
                      ],
                      const SizedBox(height: 18),
                      _SectionCard(
                        title: 'Fundo',
                        subtitle:
                            '$playerLabel: escolha uma cor pronta ou personalizada.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _BackgroundPreview(
                              background: _appearance.background,
                              nickname: _nicknameController.text.trim(),
                              hasMainImage: _appearance.backgroundImage != null,
                              hasPartnerImage: _hasPartnerImage,
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: List<Widget>.generate(
                                lifeCounterDefaultPlayerBackgrounds.length,
                                (index) {
                                  final colorValue =
                                      lifeCounterDefaultPlayerBackgrounds[index];
                                  return _BackgroundChip(
                                    key: Key(
                                      'life-counter-native-player-appearance-preset-$index',
                                    ),
                                    colorValue: colorValue,
                                    selected:
                                        _appearance.background.toUpperCase() ==
                                        colorValue.toUpperCase(),
                                    onTap: () => _selectBackground(colorValue),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextField(
                                    key: const Key(
                                      'life-counter-native-player-appearance-custom-background',
                                    ),
                                    controller: _customBackgroundController,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    decoration: InputDecoration(
                                      labelText:
                                          'Cor hexadecimal personalizada',
                                      hintText: '#FFB51E',
                                      errorText: _backgroundError,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                FilledButton.tonal(
                                  key: const Key(
                                    'life-counter-native-player-appearance-apply-background',
                                  ),
                                  onPressed: _applyCustomBackground,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 18,
                                    ),
                                  ),
                                  child: const Text('Usar'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SectionCard(
                        title: 'Imagens de fundo',
                        subtitle:
                            'Confira ou remova as imagens definidas para este jogador.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ImageStatusRow(
                              title: 'Imagem de fundo principal',
                              hasValue: _appearance.backgroundImage != null,
                              onClear:
                                  _appearance.backgroundImage == null
                                      ? null
                                      : _clearMainImage,
                              clearKey: const Key(
                                'life-counter-native-player-appearance-clear-main-image',
                              ),
                            ),
                            const SizedBox(height: 12),
                            _ImageStatusRow(
                              title: 'Imagem de fundo do parceiro',
                              hasValue: _hasPartnerImage,
                              onClear:
                                  _hasPartnerImage ? _clearPartnerImage : null,
                              clearKey: const Key(
                                'life-counter-native-player-appearance-clear-partner-image',
                              ),
                            ),
                          ],
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
                            side: const BorderSide(
                              color: AppTheme.outlineMuted,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          key: const Key(
                            'life-counter-native-player-appearance-apply',
                          ),
                          onPressed: () {
                            if (!_applyCustomBackground()) {
                              return;
                            }
                            Navigator.of(context).pop(_buildUpdatedSession());
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.brass500,
                            foregroundColor: AppTheme.backgroundAbyss,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Aplicar'),
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
}

Future<LifeCounterSession?> _showPlayerAppearanceImportDialog(
  BuildContext context,
  Future<LifeCounterSession?> Function(String rawPayload) onImportSubmitted,
) {
  final controller = TextEditingController();
  return showDialog<LifeCounterSession?>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text(
          'Importar aparência do jogador',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          key: const Key('life-counter-native-player-appearance-import-input'),
          controller: controller,
          maxLines: 10,
          minLines: 6,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Cole aqui uma aparência de jogador exportada',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key(
              'life-counter-native-player-appearance-import-confirm',
            ),
            onPressed: () async {
              final importedSession = await onImportSubmitted(controller.text);
              if (!dialogContext.mounted) {
                return;
              }
              Navigator.of(dialogContext).pop(importedSession);
            },
            child: const Text('Importar'),
          ),
        ],
      );
    },
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: AppTheme.fontLg,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontSm,
                height: AppTheme.lineHeightComfortable,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _BackgroundPreview extends StatelessWidget {
  const _BackgroundPreview({
    required this.background,
    required this.nickname,
    required this.hasMainImage,
    required this.hasPartnerImage,
  });

  final String background;
  final String nickname;
  final bool hasMainImage;
  final bool hasPartnerImage;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(background);
    final foreground =
        color.computeLuminance() > 0.55
            ? AppTheme.lifeCounterBlack
            : AppTheme.lifeCounterWhite;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nickname.isEmpty ? 'Prévia' : nickname,
            key: const Key(
              'life-counter-native-player-appearance-preview-nickname',
            ),
            style: TextStyle(
              color: foreground,
              fontSize: AppTheme.fontXxl,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PreviewBadge(
                label: background.toUpperCase(),
                foreground: foreground,
              ),
              if (hasMainImage)
                _PreviewBadge(
                  label: 'Imagem principal mantida',
                  foreground: foreground,
                ),
              if (hasPartnerImage)
                _PreviewBadge(
                  label: 'Imagem do parceiro mantida',
                  foreground: foreground,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewBadge extends StatelessWidget {
  const _PreviewBadge({required this.label, required this.foreground});

  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontSize: AppTheme.fontSm,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _BackgroundChip extends StatelessWidget {
  const _BackgroundChip({
    super.key,
    required this.colorValue,
    required this.selected,
    required this.onTap,
  });

  final String colorValue;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(colorValue);
    final foreground =
        color.computeLuminance() > 0.55
            ? AppTheme.lifeCounterBlack
            : AppTheme.lifeCounterWhite;

    final semanticLabel = 'Selecionar cor $colorValue';
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: Tooltip(
        message: semanticLabel,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: selected ? AppTheme.textPrimary : AppTheme.transparent,
                width: AppTheme.strokeStrong,
              ),
              boxShadow:
                  selected
                      ? const [
                        BoxShadow(
                          color: AppTheme.overlayBlack20,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ]
                      : null,
            ),
            child: Center(
              child: Text(
                colorValue.replaceFirst('#', ''),
                style: TextStyle(
                  color: foreground,
                  fontSize: AppTheme.fontSm,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppearanceProfileTile extends StatelessWidget {
  const _AppearanceProfileTile({
    required this.profile,
    required this.onApply,
    this.onDelete,
  });

  final LifeCounterPlayerAppearanceProfile profile;
  final VoidCallback onApply;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.surfaceSlate,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.outlineMuted),
        ),
        child: ListTile(
          key: Key(
            'life-counter-native-player-appearance-profile-${profile.id}',
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 4,
          ),
          title: Text(
            profile.name,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            profile.appearance.nickname.isEmpty
                ? profile.appearance.background.toUpperCase()
                : '${profile.appearance.nickname} · ${profile.appearance.background.toUpperCase()}',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: AppTheme.fontSm,
            ),
          ),
          trailing: Wrap(
            spacing: 6,
            children: [
              TextButton(
                key: Key(
                  'life-counter-native-player-appearance-apply-profile-${profile.id}',
                ),
                onPressed: onApply,
                child: const Text('Usar'),
              ),
              if (onDelete != null)
                IconButton(
                  key: Key(
                    'life-counter-native-player-appearance-delete-profile-${profile.id}',
                  ),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: AppTheme.textSecondary,
                  tooltip: 'Excluir perfil',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageStatusRow extends StatelessWidget {
  const _ImageStatusRow({
    required this.title,
    required this.hasValue,
    required this.onClear,
    required this.clearKey,
  });

  final String title;
  final bool hasValue;
  final VoidCallback? onClear;
  final Key clearKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasValue ? 'Imagem mantida' : 'Nenhuma imagem salva',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: AppTheme.fontSm,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          key: clearKey,
          onPressed: onClear,
          child: const Text('Limpar'),
        ),
      ],
    );
  }
}

String? _normalizeHexColor(String raw) {
  final normalized = raw.trim().toUpperCase();
  if (normalized.isEmpty) {
    return null;
  }

  final withHash = normalized.startsWith('#') ? normalized : '#$normalized';
  final isValid = RegExp(r'^#[0-9A-F]{6}$').hasMatch(withHash);
  return isValid ? withHash : null;
}

Color _parseColor(String value) {
  final normalized = _normalizeHexColor(value);
  if (normalized == null) {
    return AppTheme.surfaceSlate;
  }

  return Color(int.parse(normalized.substring(1), radix: 16) + 0xFF000000);
}
