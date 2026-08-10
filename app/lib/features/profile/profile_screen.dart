import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/widgets/shell_app_bar_actions.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/manaloom_theme_motif.dart';
import '../../core/widgets/player_identity_name.dart';
import '../../core/widgets/responsive_page_frame.dart';
import '../auth/models/user.dart';
import '../auth/password_policy.dart';
import '../auth/providers/auth_provider.dart';
import '../commercial/widgets/ai_usage_meter.dart';
import '../social/providers/social_provider.dart';
import 'account_privacy_service.dart';

typedef AccountDataShare = Future<void> Function(String content);

enum _ProfileSaveFeedback { success, error }

class _ProfileDraft {
  const _ProfileDraft({
    required this.displayName,
    required this.avatarUrl,
    required this.locationState,
    required this.locationCity,
    required this.tradeNotes,
    required this.profileVisibility,
    required this.binderVisibility,
    required this.locationVisibility,
    required this.messageVisibility,
    required this.tradeVisibility,
    required this.tradeNotesVisibility,
  });

  factory _ProfileDraft.fromUser(User user) => _ProfileDraft(
    displayName: _normalized(user.displayName),
    avatarUrl: _normalized(user.avatarUrl),
    locationState: _normalized(user.locationState),
    locationCity: _normalized(user.locationCity),
    tradeNotes: _normalized(user.tradeNotes),
    profileVisibility: user.profileVisibility,
    binderVisibility: user.binderVisibility,
    locationVisibility: user.locationVisibility,
    messageVisibility: user.messageVisibility,
    tradeVisibility: user.tradeVisibility,
    tradeNotesVisibility: user.tradeNotesVisibility,
  );

  final String displayName;
  final String avatarUrl;
  final String locationState;
  final String locationCity;
  final String tradeNotes;
  final String profileVisibility;
  final String binderVisibility;
  final String locationVisibility;
  final String messageVisibility;
  final String tradeVisibility;
  final String tradeNotesVisibility;

  static String _normalized(String? value) => value?.trim() ?? '';

  @override
  bool operator ==(Object other) =>
      other is _ProfileDraft &&
      other.displayName == displayName &&
      other.avatarUrl == avatarUrl &&
      other.locationState == locationState &&
      other.locationCity == locationCity &&
      other.tradeNotes == tradeNotes &&
      other.profileVisibility == profileVisibility &&
      other.binderVisibility == binderVisibility &&
      other.locationVisibility == locationVisibility &&
      other.messageVisibility == messageVisibility &&
      other.tradeVisibility == tradeVisibility &&
      other.tradeNotesVisibility == tradeNotesVisibility;

  @override
  int get hashCode => Object.hash(
    displayName,
    avatarUrl,
    locationState,
    locationCity,
    tradeNotes,
    profileVisibility,
    binderVisibility,
    locationVisibility,
    messageVisibility,
    tradeVisibility,
    tradeNotesVisibility,
  );
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.apiClient, this.shareData});

  final ApiClient? apiClient;
  final AccountDataShare? shareData;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _deleteConfirmation = 'EXCLUIR MINHA CONTA';

  final _displayNameController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  final _cityController = TextEditingController();
  final _tradeNotesController = TextEditingController();
  String? _selectedState;
  String _profileVisibility = 'public';
  String _binderVisibility = 'public';
  String _locationVisibility = 'private';
  String _messageVisibility = 'everyone';
  String _tradeVisibility = 'everyone';
  String _tradeNotesVisibility = 'private';
  bool _isSaving = false;
  bool _isExporting = false;
  bool _isDeleting = false;
  bool _isSecuring = false;
  String? _securityMessage;
  bool _securityMessageIsError = false;
  bool _isHydrating = false;
  _ProfileDraft? _baselineDraft;
  _ProfileSaveFeedback? _saveFeedback;
  String? _saveMessage;
  late final AccountPrivacyService _privacyService;

  static const _brazilStates = [
    'AC',
    'AL',
    'AM',
    'AP',
    'BA',
    'CE',
    'DF',
    'ES',
    'GO',
    'MA',
    'MG',
    'MS',
    'MT',
    'PA',
    'PB',
    'PE',
    'PI',
    'PR',
    'RJ',
    'RN',
    'RO',
    'RR',
    'RS',
    'SC',
    'SE',
    'SP',
    'TO',
  ];

  @override
  void initState() {
    super.initState();
    _privacyService = AccountPrivacyService(apiClient: widget.apiClient);
    for (final controller in _draftControllers) {
      controller.addListener(_handleDraftChanged);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      await auth.refreshProfile();
      final user = auth.user;
      if (!mounted || user == null) return;
      _hydrateFromUser(user);
    });
  }

  List<TextEditingController> get _draftControllers => [
    _displayNameController,
    _avatarUrlController,
    _cityController,
    _tradeNotesController,
  ];

  _ProfileDraft get _currentDraft => _ProfileDraft(
    displayName: _displayNameController.text.trim(),
    avatarUrl: _avatarUrlController.text.trim(),
    locationState: _selectedState?.trim() ?? '',
    locationCity: _cityController.text.trim(),
    tradeNotes: _tradeNotesController.text.trim(),
    profileVisibility: _profileVisibility,
    binderVisibility: _binderVisibility,
    locationVisibility: _locationVisibility,
    messageVisibility: _messageVisibility,
    tradeVisibility: _tradeVisibility,
    tradeNotesVisibility: _tradeNotesVisibility,
  );

  bool get _isDirty =>
      _baselineDraft != null && _currentDraft != _baselineDraft;

  void _hydrateFromUser(User user) {
    _isHydrating = true;
    _displayNameController.text = user.displayName ?? '';
    _avatarUrlController.text = user.avatarUrl ?? '';
    _cityController.text = user.locationCity ?? '';
    _tradeNotesController.text = user.tradeNotes ?? '';
    _selectedState = user.locationState;
    _profileVisibility = user.profileVisibility;
    _binderVisibility = user.binderVisibility;
    _locationVisibility = user.locationVisibility;
    _messageVisibility = user.messageVisibility;
    _tradeVisibility = user.tradeVisibility;
    _tradeNotesVisibility = user.tradeNotesVisibility;
    _baselineDraft = _ProfileDraft.fromUser(user);
    _saveFeedback = null;
    _saveMessage = null;
    _isHydrating = false;
    if (mounted) setState(() {});
  }

  void _handleDraftChanged() {
    if (!mounted || _isHydrating) return;
    setState(() {
      _saveFeedback = null;
      _saveMessage = null;
    });
  }

  void _mutateDraft(VoidCallback mutation) {
    setState(() {
      mutation();
      _saveFeedback = null;
      _saveMessage = null;
    });
  }

  @override
  void dispose() {
    for (final controller in _draftControllers) {
      controller.removeListener(_handleDraftChanged);
    }
    _displayNameController.dispose();
    _avatarUrlController.dispose();
    _cityController.dispose();
    _tradeNotesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || !_isDirty) return;
    setState(() {
      _isSaving = true;
      _saveFeedback = null;
      _saveMessage = null;
    });
    final auth = context.read<AuthProvider>();
    final avatarText = _avatarUrlController.text.trim();
    final cityText = _cityController.text.trim();
    final tradeNotesText = _tradeNotesController.text.trim();
    final ok = await auth.updateProfile(
      displayName: _displayNameController.text.trim(),
      avatarUrl: avatarText.isEmpty ? null : avatarText,
      locationState: _selectedState,
      locationCity: cityText.isEmpty ? null : cityText,
      tradeNotes: tradeNotesText.isEmpty ? null : tradeNotesText,
      profileVisibility: _profileVisibility,
      binderVisibility: _binderVisibility,
      locationVisibility: _locationVisibility,
      messageVisibility: _messageVisibility,
      tradeVisibility: _tradeVisibility,
      tradeNotesVisibility: _tradeNotesVisibility,
    );
    if (!mounted) return;
    if (ok) {
      setState(() {
        _isSaving = false;
        _baselineDraft = _currentDraft;
        _saveFeedback = _ProfileSaveFeedback.success;
        _saveMessage = 'Alterações salvas';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Perfil atualizado')));
    } else {
      final message = auth.errorMessage ?? 'Falha ao atualizar perfil';
      setState(() {
        _isSaving = false;
        _saveFeedback = _ProfileSaveFeedback.error;
        _saveMessage = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _exportData() async {
    if (_isExporting || _isDeleting) return;
    setState(() => _isExporting = true);
    try {
      final portableData = await _privacyService.exportPortableData();
      await (widget.shareData ?? _sharePortableData)(portableData);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exportação preparada. Escolha onde deseja salvar.'),
        ),
      );
    } on AccountPrivacyException catch (error) {
      if (!mounted) return;
      _showPrivacyError(error.message);
    } catch (_) {
      if (!mounted) return;
      _showPrivacyError(
        'Não foi possível exportar seus dados. Tente novamente.',
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _sharePortableData(String content) async {
    final file = XFile.fromData(
      Uint8List.fromList(utf8.encode(content)),
      mimeType: 'application/json',
    );
    await Share.shareXFiles(
      [file],
      subject: 'Meus dados do ManaLoom',
      text: 'Exportação portátil da conta ManaLoom.',
      fileNameOverrides: const ['manaloom-user-data.json'],
    );
  }

  Future<void> _deleteAccount() async {
    if (_isDeleting || _isExporting) return;
    final credentials = await _showDeleteAccountDialog();
    if (credentials == null || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await _privacyService.deleteAccount(
        confirmation: credentials.confirmation,
        password: credentials.password,
      );
      if (!mounted) return;
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta excluída e dados pessoais removidos.'),
        ),
      );
      context.go('/login');
    } on AccountPrivacyException catch (error) {
      if (!mounted) return;
      _showPrivacyError(error.message);
    } catch (_) {
      if (!mounted) return;
      _showPrivacyError('Não foi possível excluir sua conta. Tente novamente.');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<_DeletionCredentials?> _showDeleteAccountDialog() {
    return showDialog<_DeletionCredentials>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const _DeleteAccountDialog(confirmationPhrase: _deleteConfirmation),
    );
  }

  Future<void> _changePassword() async {
    if (_isSecuring) return;
    final credentials = await showDialog<_PasswordChangeCredentials>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ChangePasswordDialog(),
    );
    if (credentials == null || !mounted) return;
    setState(() {
      _isSecuring = true;
      _securityMessage = null;
      _securityMessageIsError = false;
    });
    final auth = context.read<AuthProvider>();
    final ok = await auth.changePassword(
      currentPassword: credentials.currentPassword,
      newPassword: credentials.newPassword,
    );
    if (!mounted) return;
    final message = ok
        ? 'Senha alterada e outras sessões encerradas.'
        : auth.errorMessage ?? 'Não foi possível alterar a senha.';
    setState(() {
      _isSecuring = false;
      _securityMessage = message;
      _securityMessageIsError = !ok;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ok ? null : Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _revokeSessions() async {
    if (_isSecuring) return;
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _RevokeSessionsDialog(),
    );
    if (password == null || !mounted) return;
    setState(() {
      _isSecuring = true;
      _securityMessage = null;
      _securityMessageIsError = false;
    });
    final auth = context.read<AuthProvider>();
    final ok = await auth.revokeOtherSessions(currentPassword: password);
    if (!mounted) return;
    final message = ok
        ? 'Outras sessões foram encerradas.'
        : auth.errorMessage ?? 'Não foi possível encerrar as sessões.';
    setState(() {
      _isSecuring = false;
      _securityMessage = message;
      _securityMessageIsError = !ok;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ok ? null : Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showPrivacyError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _showBlockedUsers() async {
    final provider = context.read<SocialProvider>();
    unawaited(provider.fetchBlockedUsers());
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('profile-blocked-users-dialog'),
        title: const Text('Contas bloqueadas'),
        content: SizedBox(
          width: 480,
          child: Consumer<SocialProvider>(
            builder: (context, social, _) {
              if (social.isLoadingBlockedUsers) {
                return SizedBox(
                  width: 480,
                  height: 152,
                  child: Semantics(
                    liveRegion: true,
                    label: 'Carregando contas bloqueadas',
                    child: const Center(
                      child: CircularProgressIndicator(
                        key: Key('profile-blocked-users-loading'),
                      ),
                    ),
                  ),
                );
              }
              if (social.blockedUsersError != null) {
                return SizedBox(
                  width: 480,
                  child: Semantics(
                    liveRegion: true,
                    container: true,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.space20,
                      ),
                      child: Column(
                        key: const Key('profile-blocked-users-error'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            social.blockedUsersError!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppTheme.space8),
                          TextButton.icon(
                            key: const Key('profile-blocked-users-retry'),
                            onPressed: social.isLoadingBlockedUsers
                                ? null
                                : social.fetchBlockedUsers,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              if (social.blockedUsers.isEmpty) {
                return const SizedBox(
                  width: 480,
                  height: 112,
                  child: Center(
                    key: Key('profile-blocked-users-empty'),
                    child: Text('Nenhuma conta bloqueada.'),
                  ),
                );
              }
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  key: const Key('profile-blocked-users-list'),
                  shrinkWrap: true,
                  itemCount: social.blockedUsers.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = social.blockedUsers[index];
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final unblockButton = TextButton(
                          key: Key('profile-unblock-${user.id}'),
                          onPressed: () => _confirmUnblock(dialogContext, user),
                          child: const Text('Desbloquear'),
                        );
                        final username = Text(
                          '@${user.username}',
                          key: Key('profile-blocked-username-${user.id}'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                        if (constraints.maxWidth < 360) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.space8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  user.displayLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppTheme.space4),
                                username,
                                const SizedBox(height: AppTheme.space4),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: unblockButton,
                                ),
                              ],
                            ),
                          );
                        }
                        return ListTile(
                          title: Text(
                            user.displayLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: username,
                          trailing: unblockButton,
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            key: const Key('profile-blocked-users-close'),
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmUnblock(
    BuildContext dialogContext,
    BlockedUser user,
  ) async {
    final confirmed = await showDialog<bool>(
      context: dialogContext,
      barrierDismissible: false,
      builder: (confirmationContext) => AlertDialog(
        key: const Key('profile-unblock-confirmation-dialog'),
        title: const Text('Desbloquear jogador?'),
        content: Text(
          '${user.displayLabel} poderá voltar a encontrar seu conteúdo '
          'público e iniciar interações permitidas.',
        ),
        actions: [
          TextButton(
            key: const Key('profile-unblock-cancel-button'),
            onPressed: () => Navigator.pop(confirmationContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('profile-unblock-confirm-button'),
            onPressed: () => Navigator.pop(confirmationContext, true),
            child: const Text('Desbloquear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await context.read<SocialProvider>().unblockUser(user.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Jogador desbloqueado.' : 'Não foi possível desbloquear.',
        ),
        backgroundColor: ok ? null : AppTheme.error,
      ),
    );
  }

  Future<void> _showAvatarDialog(BuildContext context) async {
    final result = await showDialog<_AvatarDialogResult>(
      context: context,
      builder: (_) => _AvatarUrlDialog(initialUrl: _avatarUrlController.text),
    );
    if (result == null || !mounted) return;
    _avatarUrlController.text = result.url ?? '';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.select<AuthProvider, User?>(
      (provider) => provider.user,
    );
    final compact =
        MediaQuery.sizeOf(context).width < AppTheme.breakpointCompact;

    return Scaffold(
      backgroundColor: AppTheme.backgroundAbyss,
      bottomNavigationBar: user == null ? null : _buildSaveDock(compact),
      appBar: AppBar(
        toolbarHeight: 54,
        title: const Text('Perfil'),
        centerTitle: true,
        backgroundColor: AppTheme.backgroundAbyss,
        surfaceTintColor: AppTheme.transparent,
        titleTextStyle: theme.textTheme.titleMedium?.copyWith(
          color: AppTheme.textPrimary,
          fontFamily: AppTheme.displayFontFamily,
          fontSize: AppTheme.fontLg + 1,
          fontWeight: FontWeight.w700,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/login');
            },
          ),
          const ShellAppBarActions(),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.scaffoldGradient,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
                child: ResponsivePageFrame(
                  maxWidth: 1280,
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? AppTheme.space16 : AppTheme.space24,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final useWorkbench = constraints.maxWidth >= 1040;
                      final identity = _buildIdentityRail(
                        user,
                        theme,
                        compact: !useWorkbench,
                      );
                      final workspace = _buildProfileWorkspace(user, theme);

                      return KeyedSubtree(
                        key: const Key('profile-content'),
                        child: useWorkbench
                            ? Row(
                                key: const Key('profile-wide-workbench'),
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: AppTheme.identityRailWidth,
                                    child: identity,
                                  ),
                                  const SizedBox(width: AppTheme.space32),
                                  Expanded(child: workspace),
                                ],
                              )
                            : Column(
                                key: const Key('profile-stacked-workbench'),
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  identity,
                                  const SizedBox(height: AppTheme.space24),
                                  workspace,
                                ],
                              ),
                      );
                    },
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSaveDock(bool compact) {
    final theme = Theme.of(context);
    final dirty = _isDirty;
    final status = _isSaving
        ? 'Salvando alterações'
        : _saveMessage ?? (dirty ? 'Alterações não salvas' : 'Tudo salvo');
    final statusColor = switch (_saveFeedback) {
      _ProfileSaveFeedback.success => AppTheme.success,
      _ProfileSaveFeedback.error => AppTheme.error,
      null => dirty ? AppTheme.brass400 : AppTheme.textSecondary,
    };
    final statusIcon = _isSaving
        ? Icons.sync
        : switch (_saveFeedback) {
            _ProfileSaveFeedback.success => Icons.check_circle_outline,
            _ProfileSaveFeedback.error => Icons.error_outline,
            null =>
              dirty ? Icons.edit_note_outlined : Icons.cloud_done_outlined,
          };

    final statusWidget = Semantics(
      key: const Key('profile-save-status'),
      liveRegion: true,
      label: status,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 18, color: statusColor),
          const SizedBox(width: AppTheme.space8),
          Flexible(
            child: Text(
              status,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    final saveButton = SizedBox(
      width: compact ? double.infinity : 220,
      child: FilledButton.icon(
        key: const Key('profile-save-button'),
        onPressed: _isSaving || !dirty ? null : _save,
        icon: _isSaving
            ? const SizedBox(
                width: AppTheme.space18,
                height: AppTheme.space18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save_outlined),
        label: Text(_isSaving ? 'Salvando' : 'Salvar alterações'),
      ),
    );

    return Material(
      color: AppTheme.surfaceSlate,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(
                color: AppTheme.outlineMuted,
                width: AppTheme.strokeHairline,
              ),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppTheme.space16 : AppTheme.space24,
            vertical: AppTheme.space10,
          ),
          child: Align(
            alignment: Alignment.center,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        statusWidget,
                        const SizedBox(height: AppTheme.space8),
                        saveButton,
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: statusWidget),
                        const SizedBox(width: AppTheme.space24),
                        saveButton,
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdentityRail(
    User user,
    ThemeData theme, {
    required bool compact,
  }) {
    final draftName = _displayNameController.text.trim();
    final displayName = draftName.isNotEmpty
        ? draftName
        : (user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : user.username);
    final location = [
      _cityController.text.trim(),
      _selectedState ?? '',
    ].where((part) => part.isNotEmpty).join(', ');

    final identity = compact
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildEditableAvatar(user, theme, radius: 38),
              const SizedBox(width: AppTheme.space16),
              Expanded(child: _buildIdentityCopy(user, theme, displayName)),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEditableAvatar(user, theme, radius: 48),
              const SizedBox(height: AppTheme.space18),
              _buildIdentityCopy(user, theme, displayName),
            ],
          );

    return ManaLoomThemeMotif(
      variant: ManaLoomMotifVariant.cardWeave,
      intensity: 0.72,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        key: const Key('profile-identity-rail'),
        padding: const EdgeInsets.all(AppTheme.space20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceSlate.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.brass400.withValues(alpha: 0.24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'IDENTIDADE DE JOGADOR',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.brass400,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            identity,
            const SizedBox(height: AppTheme.space16),
            Wrap(
              spacing: AppTheme.space8,
              runSpacing: AppTheme.space8,
              children: [
                _IdentityBadge(
                  icon: _profileVisibility == 'public'
                      ? Icons.public
                      : Icons.lock_outline,
                  label: _profileVisibility == 'public'
                      ? 'Perfil público'
                      : 'Perfil privado',
                ),
                _IdentityBadge(
                  icon: user.emailVerified
                      ? Icons.verified_outlined
                      : Icons.mark_email_unread_outlined,
                  label: user.emailVerified
                      ? 'Email verificado'
                      : 'Email pendente',
                ),
                if (location.isNotEmpty)
                  _IdentityBadge(
                    icon: Icons.location_on_outlined,
                    label: location,
                  ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppTheme.space20),
              child: Divider(height: 1),
            ),
            const AiUsageMeter(compact: true),
            const SizedBox(height: AppTheme.space16),
            Text(
              'ATALHOS DO SEU ESPAÇO',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: AppTheme.space10),
            _IdentityDestination(
              buttonKey: const Key('profile-open-binder-button'),
              icon: Icons.collections_bookmark_outlined,
              label: 'Meu Fichário',
              onPressed: () => context.push('/collection?tab=0'),
            ),
            _IdentityDestination(
              buttonKey: const Key('profile-open-marketplace-button'),
              icon: Icons.storefront_outlined,
              label: 'Marketplace',
              onPressed: () => context.push('/collection?tab=1'),
            ),
            _IdentityDestination(
              buttonKey: const Key('profile-open-plans-button'),
              icon: Icons.tune_outlined,
              label: 'Planos e limites',
              onPressed: () => context.push('/plans'),
            ),
            _IdentityDestination(
              buttonKey: const Key('profile-open-legal-button'),
              icon: Icons.policy_outlined,
              label: 'Legal e privacidade',
              onPressed: () => context.push('/legal'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableAvatar(
    User user,
    ThemeData theme, {
    required double radius,
  }) {
    final avatarUrl = _avatarUrlController.text.trim();
    final identity = _displayNameController.text.trim().isNotEmpty
        ? _displayNameController.text.trim()
        : (user.displayName ?? user.username).trim();
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: AppTheme.brass500.withValues(alpha: 0.16),
          backgroundImage: avatarUrl.isNotEmpty
              ? CachedNetworkImageProvider(avatarUrl)
              : null,
          child: avatarUrl.isEmpty
              ? Text(
                  identity.isNotEmpty
                      ? identity.characters.first.toUpperCase()
                      : '?',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppTheme.brass400,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Material(
            color: AppTheme.brass400,
            shape: const CircleBorder(),
            child: Semantics(
              button: true,
              label: 'Alterar foto de perfil',
              child: Tooltip(
                message: 'Alterar foto de perfil',
                child: InkWell(
                  key: const Key('profile-avatar-edit-button'),
                  customBorder: const CircleBorder(),
                  onTap: () => _showAvatarDialog(context),
                  child: const Padding(
                    padding: EdgeInsets.all(AppTheme.space6),
                    child: Icon(
                      Icons.camera_alt,
                      size: 15,
                      color: AppTheme.backgroundAbyss,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdentityCopy(User user, ThemeData theme, String displayName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        PlayerIdentityName(
          key: const Key('profile-identity-name'),
          name: displayName,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppTheme.textPrimary,
            fontFamily: AppTheme.displayFontFamily,
            fontWeight: FontWeight.w900,
            height: 1.02,
          ),
        ),
        const SizedBox(height: AppTheme.space5),
        Text(
          '@${user.username}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.frost400,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTheme.space3),
        Text(
          user.email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileWorkspace(User user, ThemeData theme) {
    return Column(
      key: const Key('profile-settings-workspace'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Seu espaço de jogador',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontFamily: AppTheme.displayFontFamily,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppTheme.space6),
        Text(
          'Defina como outros jogadores reconhecem você e quais portas ficam abertas para comunidade e trocas.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: AppTheme.space24),
        _ProfileSectionPanel(
          title: 'Como você aparece',
          subtitle: 'Identidade visível na busca, nos decks e nas trocas.',
          icon: Icons.badge_outlined,
          child: TextField(
            key: const Key('profile-display-name-field'),
            controller: _displayNameController,
            decoration: const InputDecoration(
              labelText: 'Nick / Apelido',
              hintText: 'Ex: Planeswalker42',
              prefixIcon: Icon(Icons.face_outlined),
            ),
          ),
        ),
        _ProfileSectionPanel(
          title: 'Contexto para trocas',
          subtitle:
              'Localização e observações só aparecem conforme sua regra de privacidade.',
          icon: Icons.location_on_outlined,
          child: _buildLocationFields(),
        ),
        _ProfileSectionPanel(
          title: 'Quem pode encontrar e chamar você',
          subtitle:
              'Controle separadamente perfil, fichário, localização, mensagens e propostas.',
          icon: Icons.visibility_outlined,
          child: _buildVisibilityGrid(),
        ),
        _ProfileSectionPanel(
          title: 'Acesso e sessões',
          subtitle:
              'Segurança da conta fica separada da sua identidade pública.',
          icon: Icons.lock_outline,
          child: _buildSecurityActions(user),
        ),
        _ProfileSectionPanel(
          title: 'Dados e controle da conta',
          subtitle:
              'Revise bloqueios, gere uma cópia portátil ou encerre a conta.',
          icon: Icons.shield_outlined,
          child: _buildAccountActions(),
        ),
        const SizedBox(height: AppTheme.space112),
      ],
    );
  }

  Widget _buildLocationFields() {
    final stateField = DropdownButtonFormField<String>(
      key: const Key('profile-state-field'),
      initialValue: _selectedState,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Estado'),
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('—')),
        ..._brazilStates.map(
          (state) => DropdownMenuItem(value: state, child: Text(state)),
        ),
      ],
      onChanged: (value) => _mutateDraft(() => _selectedState = value),
    );
    final cityField = TextField(
      key: const Key('profile-city-field'),
      controller: _cityController,
      decoration: const InputDecoration(
        labelText: 'Cidade',
        hintText: 'Ex: São Paulo',
        prefixIcon: Icon(Icons.location_city_outlined, size: 20),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth < 520
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    stateField,
                    const SizedBox(height: AppTheme.space12),
                    cityField,
                  ],
                )
              : Row(
                  children: [
                    SizedBox(
                      width: AppTheme.compactFieldWidth,
                      child: stateField,
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(child: cityField),
                  ],
                ),
        ),
        const SizedBox(height: AppTheme.space16),
        TextField(
          key: const Key('profile-trade-notes-field'),
          controller: _tradeNotesController,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'Observação para trocas',
            hintText: 'Ex: entrego em mãos em SP ou deixo na loja combinada.',
            prefixIcon: Icon(Icons.info_outline, size: 20),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildVisibilityGrid() {
    final fields = <Widget>[
      _VisibilityField(
        fieldKey: const Key('profile-profile-visibility-field'),
        label: 'Visibilidade do perfil',
        value: _profileVisibility,
        options: const {'public': 'Público', 'private': 'Privado'},
        onChanged: (value) => _mutateDraft(() => _profileVisibility = value),
      ),
      _VisibilityField(
        fieldKey: const Key('profile-binder-visibility-field'),
        label: 'Fichário',
        value: _binderVisibility,
        options: const {'public': 'Público', 'private': 'Privado'},
        onChanged: (value) => _mutateDraft(() => _binderVisibility = value),
      ),
      _VisibilityField(
        fieldKey: const Key('profile-location-visibility-field'),
        label: 'Localização',
        value: _locationVisibility,
        options: const {
          'public': 'Pública',
          'trade_only': 'Somente em trades',
          'private': 'Privada',
        },
        onChanged: (value) => _mutateDraft(() => _locationVisibility = value),
      ),
      _VisibilityField(
        fieldKey: const Key('profile-message-visibility-field'),
        label: 'Mensagens',
        value: _messageVisibility,
        options: const {
          'everyone': 'Todos',
          'followers': 'Seguidores',
          'none': 'Ninguém',
        },
        onChanged: (value) => _mutateDraft(() => _messageVisibility = value),
      ),
      _VisibilityField(
        fieldKey: const Key('profile-trade-visibility-field'),
        label: 'Novas propostas',
        value: _tradeVisibility,
        options: const {
          'everyone': 'Todos',
          'followers': 'Seguidores',
          'none': 'Ninguém',
        },
        onChanged: (value) => _mutateDraft(() => _tradeVisibility = value),
      ),
      _VisibilityField(
        fieldKey: const Key('profile-trade-notes-visibility-field'),
        label: 'Notas de troca',
        value: _tradeNotesVisibility,
        options: const {
          'trade_only': 'Somente em trades',
          'private': 'Privadas',
        },
        onChanged: (value) => _mutateDraft(() => _tradeNotesVisibility = value),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 680;
        final fieldWidth = twoColumns
            ? (constraints.maxWidth - AppTheme.space12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: AppTheme.space12,
          runSpacing: AppTheme.space12,
          children: [
            for (final field in fields)
              SizedBox(width: fieldWidth, child: field),
          ],
        );
      },
    );
  }

  Widget _buildSecurityActions(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!user.emailVerified) ...[
          _InlineAccountNotice(
            icon: Icons.mark_email_unread_outlined,
            title: 'Seu email ainda precisa ser verificado',
            action: FilledButton(
              key: const Key('profile-verify-email-button'),
              onPressed: () => context.push('/verify-email'),
              child: const Text('Verificar email'),
            ),
          ),
          const SizedBox(height: AppTheme.space14),
        ],
        Wrap(
          spacing: AppTheme.space12,
          runSpacing: AppTheme.space8,
          children: [
            OutlinedButton.icon(
              key: const Key('profile-change-password-button'),
              onPressed: _isSecuring ? null : _changePassword,
              icon: const Icon(Icons.password_outlined),
              label: const Text('Trocar senha'),
            ),
            TextButton.icon(
              key: const Key('profile-revoke-sessions-button'),
              onPressed: _isSecuring ? null : _revokeSessions,
              icon: const Icon(Icons.phonelink_erase_outlined),
              label: const Text('Encerrar outras sessões'),
            ),
          ],
        ),
        if (_isSecuring || _securityMessage != null) ...[
          const SizedBox(height: AppTheme.space10),
          Semantics(
            liveRegion: true,
            container: true,
            child: Container(
              key: Key(
                _isSecuring
                    ? 'profile-security-action-progress'
                    : _securityMessageIsError
                    ? 'profile-security-action-error'
                    : 'profile-security-action-success',
              ),
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.space10),
              decoration: BoxDecoration(
                color:
                    (_securityMessageIsError
                            ? AppTheme.error
                            : AppTheme.success)
                        .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color:
                      (_securityMessageIsError
                              ? AppTheme.error
                              : AppTheme.success)
                          .withValues(alpha: 0.55),
                ),
              ),
              child: Row(
                children: [
                  if (_isSecuring)
                    const SizedBox(
                      width: AppTheme.space18,
                      height: AppTheme.space18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      _securityMessageIsError
                          ? Icons.error_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      color: _securityMessageIsError
                          ? AppTheme.error
                          : AppTheme.success,
                    ),
                  const SizedBox(width: AppTheme.space8),
                  Expanded(
                    child: Text(
                      _isSecuring
                          ? 'Atualizando a segurança da conta…'
                          : _securityMessage!,
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAccountActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppTheme.space12,
          runSpacing: AppTheme.space8,
          children: [
            OutlinedButton.icon(
              key: const Key('profile-blocked-users-button'),
              onPressed: _showBlockedUsers,
              icon: const Icon(Icons.block_outlined),
              label: const Text('Contas bloqueadas'),
            ),
            OutlinedButton.icon(
              key: const Key('profile-export-data-button'),
              onPressed: _isExporting || _isDeleting ? null : _exportData,
              icon: _isExporting
                  ? const SizedBox(
                      width: AppTheme.space18,
                      height: AppTheme.space18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined),
              label: Text(
                _isExporting ? 'Preparando exportação' : 'Exportar meus dados',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('profile-delete-account-button'),
            onPressed: _isExporting || _isDeleting ? null : _deleteAccount,
            icon: _isDeleting
                ? const SizedBox(
                    width: AppTheme.space18,
                    height: AppTheme.space18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_forever_outlined),
            label: Text(
              _isDeleting ? 'Excluindo conta' : 'Excluir minha conta',
            ),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
          ),
        ),
      ],
    );
  }
}

class _IdentityBadge extends StatelessWidget {
  const _IdentityBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space8,
        vertical: AppTheme.space5,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.72),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.frost400),
          const SizedBox(width: AppTheme.space5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityDestination extends StatelessWidget {
  const _IdentityDestination({
    required this.buttonKey,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final Key buttonKey;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        key: buttonKey,
        onPressed: onPressed,
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          foregroundColor: AppTheme.textPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space8,
            vertical: AppTheme.space10,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 19, color: AppTheme.frost400),
            const SizedBox(width: AppTheme.space10),
            Expanded(child: Text(label)),
            const Icon(Icons.arrow_forward, size: 16),
          ],
        ),
      ),
    );
  }
}

class _InlineAccountNotice extends StatelessWidget {
  const _InlineAccountNotice({
    required this.icon,
    required this.title,
    required this.action,
  });

  final IconData icon;
  final String title;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final message = Row(
          children: [
            Icon(icon, color: AppTheme.brass400),
            const SizedBox(width: AppTheme.space10),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
        return Container(
          padding: const EdgeInsets.all(AppTheme.space14),
          decoration: BoxDecoration(
            color: AppTheme.brass500.withValues(alpha: 0.08),
            border: Border(
              left: BorderSide(color: AppTheme.brass400, width: 3),
            ),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    message,
                    const SizedBox(height: AppTheme.space12),
                    action,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: message),
                    const SizedBox(width: AppTheme.space16),
                    action,
                  ],
                ),
        );
      },
    );
  }
}

class _VisibilityField extends StatelessWidget {
  const _VisibilityField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final Key fieldKey;
  final String label;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: fieldKey,
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.visibility_outlined),
      ),
      items: options.entries
          .map(
            (entry) =>
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
          )
          .toList(growable: false),
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }
}

class _DeletionCredentials {
  const _DeletionCredentials({
    required this.confirmation,
    required this.password,
  });

  final String confirmation;
  final String password;
}

class _AvatarDialogResult {
  const _AvatarDialogResult(this.url);

  final String? url;
}

String? _validatePublicAvatarUrl(String? value) {
  final normalized = value?.trim() ?? '';
  if (normalized.isEmpty) return 'Informe uma URL HTTPS.';

  final uri = Uri.tryParse(normalized);
  if (uri == null ||
      uri.scheme.toLowerCase() != 'https' ||
      !uri.hasAuthority ||
      uri.host.trim().isEmpty ||
      uri.userInfo.isNotEmpty) {
    return 'Use uma URL HTTPS válida, sem usuário ou senha no endereço.';
  }

  final host = uri.host.toLowerCase();
  if (_isPrivateAvatarHost(host)) {
    return 'Use um endereço público; links locais ou de rede privada não são aceitos.';
  }
  return null;
}

bool _isPrivateAvatarHost(String host) {
  if (host == 'localhost' ||
      host.endsWith('.localhost') ||
      host.endsWith('.local') ||
      host == '::1' ||
      host.startsWith('fe80:') ||
      host.startsWith('fc') ||
      host.startsWith('fd')) {
    return true;
  }

  final octets = host.split('.').map(int.tryParse).toList(growable: false);
  if (octets.length != 4 || octets.any((octet) => octet == null)) return false;
  final first = octets[0]!;
  final second = octets[1]!;
  return first == 0 ||
      first == 10 ||
      first == 127 ||
      (first == 169 && second == 254) ||
      (first == 172 && second >= 16 && second <= 31) ||
      (first == 192 && second == 168);
}

class _AvatarUrlDialog extends StatefulWidget {
  const _AvatarUrlDialog({required this.initialUrl});

  final String initialUrl;

  @override
  State<_AvatarUrlDialog> createState() => _AvatarUrlDialogState();
}

class _AvatarUrlDialogState extends State<_AvatarUrlDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _EscapeDismissibleDialog(
    child: AlertDialog(
      key: const Key('profile-avatar-dialog'),
      title: const Text('Alterar foto de perfil'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cole o endereço público HTTPS de uma imagem estável.',
                style: TextStyle(
                  fontSize: AppTheme.fontMd,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppTheme.space12),
              TextFormField(
                key: const Key('profile-avatar-url-field'),
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'URL da imagem',
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.link),
                  errorMaxLines: 3,
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
                validator: _validatePublicAvatarUrl,
              ),
              const SizedBox(height: AppTheme.space12),
              const _InlineSecurityHint(
                key: Key('profile-avatar-privacy-notice'),
                icon: Icons.privacy_tip_outlined,
                text:
                    'A imagem é carregada diretamente do provedor. Evite links privados, temporários ou que revelem dados pessoais.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('profile-avatar-cancel-button'),
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        if (widget.initialUrl.trim().isNotEmpty)
          TextButton(
            key: const Key('profile-avatar-remove-button'),
            onPressed: () =>
                Navigator.pop(context, const _AvatarDialogResult(null)),
            child: const Text(
              'Remover foto',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ElevatedButton(
          key: const Key('profile-avatar-apply-button'),
          onPressed: () {
            if (_formKey.currentState?.validate() != true) return;
            Navigator.pop(
              context,
              _AvatarDialogResult(_controller.text.trim()),
            );
          },
          child: const Text('Aplicar'),
        ),
      ],
    ),
  );
}

class _PasswordChangeCredentials {
  const _PasswordChangeCredentials({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmationPassword = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _EscapeDismissibleDialog(
    child: AlertDialog(
      key: const Key('profile-change-password-dialog'),
      title: const Text('Trocar senha'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('profile-current-password-field'),
                controller: _currentController,
                obscureText: !_showCurrentPassword,
                decoration: InputDecoration(
                  labelText: 'Senha atual',
                  suffixIcon: _PasswordVisibilityButton(
                    key: const Key('profile-current-password-visibility'),
                    visible: _showCurrentPassword,
                    onPressed: () => setState(
                      () => _showCurrentPassword = !_showCurrentPassword,
                    ),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Informe sua senha atual.'
                    : null,
              ),
              const SizedBox(height: AppTheme.space12),
              const _InlineSecurityHint(
                key: Key('profile-password-requirements'),
                icon: Icons.shield_outlined,
                text:
                    'Use de 12 a 256 caracteres, sem espaços no início ou fim. Evite sequências, senhas comuns e dados da conta.',
              ),
              const SizedBox(height: AppTheme.space12),
              TextFormField(
                key: const Key('profile-new-password-field'),
                controller: _newController,
                obscureText: !_showNewPassword,
                decoration: InputDecoration(
                  labelText: 'Nova senha',
                  suffixIcon: _PasswordVisibilityButton(
                    key: const Key('profile-new-password-visibility'),
                    visible: _showNewPassword,
                    onPressed: () =>
                        setState(() => _showNewPassword = !_showNewPassword),
                  ),
                ),
                validator: validateRegistrationPassword,
              ),
              const SizedBox(height: AppTheme.space12),
              TextFormField(
                key: const Key('profile-confirm-password-field'),
                controller: _confirmationController,
                obscureText: !_showConfirmationPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmar senha',
                  suffixIcon: _PasswordVisibilityButton(
                    key: const Key('profile-confirm-password-visibility'),
                    visible: _showConfirmationPassword,
                    onPressed: () => setState(
                      () => _showConfirmationPassword =
                          !_showConfirmationPassword,
                    ),
                  ),
                ),
                validator: (value) => value != _newController.text
                    ? 'Senhas não correspondem'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('profile-change-password-cancel-button'),
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('profile-change-password-confirm-button'),
          onPressed: () {
            if (_formKey.currentState?.validate() != true) return;
            Navigator.pop(
              context,
              _PasswordChangeCredentials(
                currentPassword: _currentController.text,
                newPassword: _newController.text,
              ),
            );
          },
          child: const Text('Alterar senha'),
        ),
      ],
    ),
  );
}

class _RevokeSessionsDialog extends StatefulWidget {
  const _RevokeSessionsDialog();

  @override
  State<_RevokeSessionsDialog> createState() => _RevokeSessionsDialogState();
}

class _RevokeSessionsDialogState extends State<_RevokeSessionsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _EscapeDismissibleDialog(
    child: AlertDialog(
      key: const Key('profile-revoke-sessions-dialog'),
      title: const Text('Encerrar outras sessões?'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const Key('profile-revoke-password-field'),
          controller: _passwordController,
          obscureText: !_showPassword,
          decoration: InputDecoration(
            labelText: 'Senha atual',
            suffixIcon: _PasswordVisibilityButton(
              key: const Key('profile-revoke-password-visibility'),
              visible: _showPassword,
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
          validator: (value) => value == null || value.isEmpty
              ? 'Informe sua senha atual.'
              : null,
        ),
      ),
      actions: [
        TextButton(
          key: const Key('profile-revoke-sessions-cancel-button'),
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('profile-revoke-sessions-confirm-button'),
          onPressed: () {
            if (_formKey.currentState?.validate() != true) return;
            Navigator.pop(context, _passwordController.text);
          },
          child: const Text('Encerrar sessões'),
        ),
      ],
    ),
  );
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.confirmationPhrase});

  final String confirmationPhrase;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _confirmationController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _confirmationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _EscapeDismissibleDialog(
      child: AlertDialog(
        key: const Key('profile-delete-account-dialog'),
        title: const Text('Excluir conta definitivamente?'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Seus dados pessoais, decks, fichário e preferências serão removidos. Registros mínimos de trades e moderação podem ser mantidos anonimizados para integridade e segurança.',
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('profile-delete-privacy-link'),
                      onPressed: () {
                        final router = GoRouter.maybeOf(context);
                        Navigator.pop(context);
                        router?.push('/legal?section=privacy');
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Ler a Política de privacidade'),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space16),
                  Text(
                    'Para confirmar, digite ${widget.confirmationPhrase} e informe sua senha.',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppTheme.space12),
                  TextFormField(
                    key: const Key('profile-delete-confirmation-field'),
                    controller: _confirmationController,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Frase de confirmação',
                      errorMaxLines: 2,
                    ),
                    validator: (value) =>
                        value?.trim() == widget.confirmationPhrase
                        ? null
                        : 'Digite a frase exatamente como exibida.',
                  ),
                  const SizedBox(height: AppTheme.space12),
                  TextFormField(
                    key: const Key('profile-delete-password-field'),
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      suffixIcon: _PasswordVisibilityButton(
                        key: const Key('profile-delete-password-visibility'),
                        visible: _showPassword,
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Informe sua senha.'
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            key: const Key('profile-delete-cancel-button'),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('profile-delete-confirm-button'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: AppTheme.textPrimary,
            ),
            onPressed: () {
              if (_formKey.currentState?.validate() != true) return;
              Navigator.pop(
                context,
                _DeletionCredentials(
                  confirmation: _confirmationController.text.trim(),
                  password: _passwordController.text,
                ),
              );
            },
            child: const Text('Excluir definitivamente'),
          ),
        ],
      ),
    );
  }
}

class _PasswordVisibilityButton extends StatelessWidget {
  const _PasswordVisibilityButton({
    super.key,
    required this.visible,
    required this.onPressed,
  });

  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: visible ? 'Ocultar senha' : 'Mostrar senha',
    onPressed: onPressed,
    icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
  );
}

class _InlineSecurityHint extends StatelessWidget {
  const _InlineSecurityHint({
    super.key,
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppTheme.space10),
    decoration: BoxDecoration(
      color: AppTheme.frost400.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      border: Border.all(color: AppTheme.frost400.withValues(alpha: 0.24)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.frost400),
        const SizedBox(width: AppTheme.space8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: AppTheme.fontSm,
              height: AppTheme.lineHeightComfortable,
            ),
          ),
        ),
      ],
    ),
  );
}

class _EscapeDismissibleDialog extends StatelessWidget {
  const _EscapeDismissibleDialog({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          Navigator.of(context).pop();
        },
      },
      child: child,
    );
  }
}

class _ProfileSectionPanel extends StatelessWidget {
  const _ProfileSectionPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.outlineMuted.withValues(alpha: 0.74)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.brass500.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(icon, size: 19, color: AppTheme.brass400),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontFamily: AppTheme.displayFontFamily,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space3),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space18),
          child,
        ],
      ),
    );
  }
}
