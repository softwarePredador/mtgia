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
import '../../core/widgets/responsive_page_frame.dart';
import '../auth/models/user.dart';
import '../auth/password_policy.dart';
import '../auth/providers/auth_provider.dart';
import '../commercial/widgets/ai_usage_meter.dart';
import 'account_privacy_service.dart';

typedef AccountDataShare = Future<void> Function(String content);

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
  bool _isSaving = false;
  bool _isExporting = false;
  bool _isDeleting = false;
  bool _isSecuring = false;
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      await auth.refreshProfile();
      final user = auth.user;
      if (!mounted || user == null) return;
      _displayNameController.text = user.displayName ?? '';
      _avatarUrlController.text = user.avatarUrl ?? '';
      _cityController.text = user.locationCity ?? '';
      _tradeNotesController.text = user.tradeNotes ?? '';
      setState(() {
        _selectedState = user.locationState;
      });
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _avatarUrlController.dispose();
    _cityController.dispose();
    _tradeNotesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
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
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Perfil atualizado')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Falha ao atualizar perfil'),
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
    setState(() => _isSecuring = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.changePassword(
      currentPassword: credentials.currentPassword,
      newPassword: credentials.newPassword,
    );
    if (!mounted) return;
    setState(() => _isSecuring = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Senha alterada e outras sessões encerradas.'
              : auth.errorMessage ?? 'Não foi possível alterar a senha.',
        ),
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
    setState(() => _isSecuring = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.revokeOtherSessions(currentPassword: password);
    if (!mounted) return;
    setState(() => _isSecuring = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Outras sessões foram encerradas.'
              : auth.errorMessage ?? 'Não foi possível encerrar as sessões.',
        ),
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

  void _showAvatarDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(
          text: _avatarUrlController.text,
        );
        return AlertDialog(
          key: const Key('profile-avatar-dialog'),
          title: const Text('Alterar foto de perfil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Cole a URL de uma imagem (ex: link do Imgur, Gravatar, etc.)',
                style: TextStyle(
                  fontSize: AppTheme.fontMd,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppTheme.space12),
              TextField(
                key: const Key('profile-avatar-url-field'),
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'URL da imagem',
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
          actions: [
            TextButton(
              key: const Key('profile-avatar-cancel-button'),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            if (_avatarUrlController.text.isNotEmpty)
              TextButton(
                key: const Key('profile-avatar-remove-button'),
                onPressed: () {
                  _avatarUrlController.clear();
                  Navigator.pop(ctx);
                  setState(() {});
                },
                child: const Text(
                  'Remover foto',
                  style: TextStyle(color: AppTheme.error),
                ),
              ),
            ElevatedButton(
              key: const Key('profile-avatar-apply-button'),
              onPressed: () {
                _avatarUrlController.text = controller.text.trim();
                Navigator.pop(ctx);
                setState(() {});
              },
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.select<AuthProvider, User?>((p) => p.user);

    return Scaffold(
      backgroundColor: AppTheme.backgroundAbyss,
      floatingActionButton: user == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('profile-save-button'),
              tooltip: 'Salvar perfil',
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: AppTheme.space18,
                      height: AppTheme.space18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_isSaving ? 'Salvando' : 'Salvar'),
            ),
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
                  maxWidth: 840,
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        MediaQuery.sizeOf(context).width <
                            AppTheme.breakpointCompact
                        ? AppTheme.space16
                        : AppTheme.space24,
                  ),
                  child: Column(
                    key: const Key('profile-content'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.space16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceSlate,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLg,
                          ),
                          border: Border.all(
                            color: AppTheme.brass400.withValues(alpha: 0.24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.backgroundAbyss.withValues(
                                alpha: 0.18,
                              ),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 34,
                                  backgroundColor: AppTheme.brass500.withValues(
                                    alpha: 0.16,
                                  ),
                                  backgroundImage:
                                      (user.avatarUrl != null &&
                                          user.avatarUrl!.trim().isNotEmpty)
                                      ? CachedNetworkImageProvider(
                                          user.avatarUrl!,
                                        )
                                      : null,
                                  child:
                                      (user.avatarUrl == null ||
                                          user.avatarUrl!.trim().isEmpty)
                                      ? Text(
                                          (user.displayName ?? user.username)
                                                  .trim()
                                                  .isNotEmpty
                                              ? (user.displayName ??
                                                        user.username)
                                                    .trim()
                                                    .characters
                                                    .first
                                                    .toUpperCase()
                                              : '?',
                                          style: theme.textTheme.headlineMedium
                                              ?.copyWith(
                                                color: AppTheme.brass400,
                                                fontWeight: FontWeight.w900,
                                              ),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.brass400,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.backgroundAbyss,
                                        width: AppTheme.strokeStrong,
                                      ),
                                    ),
                                    child: Semantics(
                                      button: true,
                                      label: 'Alterar foto de perfil',
                                      child: Tooltip(
                                        message: 'Alterar foto de perfil',
                                        child: InkWell(
                                          key: const Key(
                                            'profile-avatar-edit-button',
                                          ),
                                          customBorder: const CircleBorder(),
                                          onTap: () =>
                                              _showAvatarDialog(context),
                                          child: const Padding(
                                            padding: EdgeInsets.all(
                                              AppTheme.space5,
                                            ),
                                            child: Icon(
                                              Icons.camera_alt,
                                              size: 14,
                                              color: AppTheme.backgroundAbyss,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: AppTheme.space14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    user.username,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                  const SizedBox(height: AppTheme.space3),
                                  Text(
                                    user.email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.space18),
                      _ProfileSectionPanel(
                        title: 'Configurações',
                        icon: Icons.auto_awesome_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              key: const Key('profile-display-name-field'),
                              controller: _displayNameController,
                              decoration: const InputDecoration(
                                labelText: 'Nick / Apelido',
                                hintText: 'Ex: Planeswalker42',
                                prefixIcon: Icon(Icons.face),
                              ),
                            ),
                            const SizedBox(height: AppTheme.space8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.space4,
                              ),
                              child: Text(
                                'Nome exibido na busca, nos decks e nas trocas.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontSize: AppTheme.fontSm,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.space18),

                      _ProfileSectionPanel(
                        title: 'Localização',
                        icon: Icons.location_on_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.space4,
                              ),
                              child: Text(
                                'Usada para facilitar trocas presenciais.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontSize: AppTheme.fontSm,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTheme.space12),
                            Row(
                              children: [
                                // Estado dropdown
                                SizedBox(
                                  width: 116,
                                  child: DropdownButtonFormField<String?>(
                                    key: const Key('profile-state-field'),
                                    initialValue: _selectedState,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Estado',
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: AppTheme.space10,
                                        vertical: AppTheme.space14,
                                      ),
                                    ),
                                    dropdownColor: AppTheme.surfaceSlate,
                                    items: [
                                      const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text('--'),
                                      ),
                                      ..._brazilStates.map(
                                        (s) => DropdownMenuItem<String?>(
                                          value: s,
                                          child: Text(s),
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _selectedState = v),
                                  ),
                                ),
                                const SizedBox(width: AppTheme.space12),
                                // Cidade
                                Expanded(
                                  child: TextField(
                                    key: const Key('profile-city-field'),
                                    controller: _cityController,
                                    decoration: const InputDecoration(
                                      labelText: 'Cidade',
                                      hintText: 'Ex: São Paulo',
                                      prefixIcon: Icon(
                                        Icons.location_city,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.space16),
                            TextField(
                              key: const Key('profile-trade-notes-field'),
                              controller: _tradeNotesController,
                              maxLines: 3,
                              maxLength: 500,
                              decoration: const InputDecoration(
                                labelText: 'Observação para trocas',
                                hintText:
                                    'Ex: Consigo entregar em mãos em SP, ou deixo na loja X em Curitiba...',
                                prefixIcon: Icon(Icons.info_outline, size: 20),
                                alignLabelWithHint: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.space18),
                      const AiUsageMeter(compact: true),
                      const SizedBox(height: AppTheme.space12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('profile-open-plans-button'),
                              onPressed: () => context.push('/plans'),
                              icon: const Icon(Icons.tune_outlined),
                              label: const Text('Planos'),
                            ),
                          ),
                          const SizedBox(width: AppTheme.space12),
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('profile-open-legal-button'),
                              onPressed: () => context.push('/legal'),
                              icon: const Icon(Icons.policy_outlined),
                              label: const Text('Legal'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space18),
                      _ProfileSectionPanel(
                        title: 'Segurança',
                        icon: Icons.lock_outline,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Trocar a senha ou encerrar outras sessões invalida imediatamente os acessos anteriores.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: AppTheme.space14),
                            if (!user.emailVerified) ...[
                              FilledButton.icon(
                                key: const Key('profile-verify-email-button'),
                                onPressed: () => context.push('/verify-email'),
                                icon: const Icon(
                                  Icons.mark_email_unread_outlined,
                                ),
                                label: const Text('Verificar email'),
                              ),
                              const SizedBox(height: AppTheme.space8),
                            ],
                            OutlinedButton.icon(
                              key: const Key('profile-change-password-button'),
                              onPressed: _isSecuring ? null : _changePassword,
                              icon: const Icon(Icons.password_outlined),
                              label: const Text('Trocar senha'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                            const SizedBox(height: AppTheme.space8),
                            TextButton.icon(
                              key: const Key('profile-revoke-sessions-button'),
                              onPressed: _isSecuring ? null : _revokeSessions,
                              icon: const Icon(Icons.phonelink_erase_outlined),
                              label: const Text('Encerrar outras sessões'),
                              style: TextButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.space18),
                      _ProfileSectionPanel(
                        title: 'Privacidade e conta',
                        icon: Icons.shield_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Baixe uma cópia portátil dos seus dados ou solicite a exclusão definitiva da conta.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: AppTheme.space14),
                            OutlinedButton.icon(
                              key: const Key('profile-export-data-button'),
                              onPressed: _isExporting || _isDeleting
                                  ? null
                                  : _exportData,
                              icon: _isExporting
                                  ? const SizedBox(
                                      width: AppTheme.space18,
                                      height: AppTheme.space18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.download_outlined),
                              label: Text(
                                _isExporting
                                    ? 'Preparando exportação'
                                    : 'Exportar meus dados',
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                            const SizedBox(height: AppTheme.space8),
                            TextButton.icon(
                              key: const Key('profile-delete-account-button'),
                              onPressed: _isExporting || _isDeleting
                                  ? null
                                  : _deleteAccount,
                              icon: _isDeleting
                                  ? const SizedBox(
                                      width: AppTheme.space18,
                                      height: AppTheme.space18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.delete_forever_outlined),
                              label: Text(
                                _isDeleting
                                    ? 'Excluindo conta'
                                    : 'Excluir minha conta',
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.error,
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.space18),
                      _ProfileSectionPanel(
                        title: 'Coleção',
                        icon: Icons.collections_bookmark_outlined,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final binderButton = OutlinedButton.icon(
                              key: const Key('profile-open-binder-button'),
                              onPressed: () =>
                                  context.push('/collection?tab=0'),
                              icon: const Icon(Icons.collections_bookmark),
                              label: const Text('Meu Fichário'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                            );
                            final marketplaceButton = OutlinedButton.icon(
                              key: const Key('profile-open-marketplace-button'),
                              onPressed: () =>
                                  context.push('/collection?tab=1'),
                              icon: const Icon(Icons.store),
                              label: const Text('Marketplace'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                            );

                            if (constraints.maxWidth < 420) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  binderButton,
                                  const SizedBox(height: AppTheme.space8),
                                  marketplaceButton,
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(child: binderButton),
                                const SizedBox(width: AppTheme.space12),
                                Expanded(child: marketplaceButton),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppTheme.space112),
                    ],
                  ),
                ),
              ),
            ),
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
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha atual'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Informe sua senha atual.'
                    : null,
              ),
              const SizedBox(height: AppTheme.space12),
              TextFormField(
                key: const Key('profile-new-password-field'),
                controller: _newController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nova senha',
                  helperText: 'Use 12+ caracteres e evite sequências.',
                ),
                validator: validateRegistrationPassword,
              ),
              const SizedBox(height: AppTheme.space12),
              TextFormField(
                key: const Key('profile-confirm-password-field'),
                controller: _confirmationController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirmar senha'),
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
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Senha atual'),
          validator: (value) => value == null || value.isEmpty
              ? 'Informe sua senha atual.'
              : null,
        ),
      ),
      actions: [
        TextButton(
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
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(labelText: 'Senha'),
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
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.62),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.backgroundAbyss.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.brass400),
              const SizedBox(width: AppTheme.space8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontFamily: AppTheme.displayFontFamily,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space14),
          child,
        ],
      ),
    );
  }
}
