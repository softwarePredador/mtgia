import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/widgets/shell_app_bar_actions.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../auth/models/user.dart';
import '../auth/providers/auth_provider.dart';
import '../commercial/widgets/ai_usage_meter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _displayNameController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  final _cityController = TextEditingController();
  final _tradeNotesController = TextEditingController();
  String? _selectedState;
  bool _isSaving = false;

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
              const SizedBox(height: 12),
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
      floatingActionButton:
          user == null
              ? null
              : FloatingActionButton.extended(
                key: const Key('profile-save-button'),
                tooltip: 'Salvar perfil',
                onPressed: _isSaving ? null : _save,
                icon:
                    _isSaving
                        ? const SizedBox(
                          width: 18,
                          height: 18,
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
      body:
          user == null
              ? const Center(child: CircularProgressIndicator())
              : Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.scaffoldGradient,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
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
                                            style: theme
                                                .textTheme
                                                .headlineMedium
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
                                          onTap:
                                              () => _showAvatarDialog(context),
                                          child: const Padding(
                                            padding: EdgeInsets.all(5),
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
                            const SizedBox(width: 14),
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
                                  const SizedBox(height: 3),
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
                      const SizedBox(height: 18),
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
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
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
                      const SizedBox(height: 18),

                      _ProfileSectionPanel(
                        title: 'Localização',
                        icon: Icons.location_on_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Text(
                                'Usada para facilitar trocas presenciais.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontSize: AppTheme.fontSm,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
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
                                        horizontal: 10,
                                        vertical: 14,
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
                                    onChanged:
                                        (v) =>
                                            setState(() => _selectedState = v),
                                  ),
                                ),
                                const SizedBox(width: 12),
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
                            const SizedBox(height: 16),
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
                      const SizedBox(height: 18),
                      const AiUsageMeter(compact: true),
                      const SizedBox(height: 12),
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
                          const SizedBox(width: 12),
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
                      const SizedBox(height: 18),
                      _ProfileSectionPanel(
                        title: 'Coleção',
                        icon: Icons.collections_bookmark_outlined,
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                key: const Key('profile-open-binder-button'),
                                onPressed:
                                    () => context.push('/collection?tab=0'),
                                icon: const Icon(Icons.collections_bookmark),
                                label: const Text('Meu Fichário'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                key: const Key(
                                  'profile-open-marketplace-button',
                                ),
                                onPressed:
                                    () => context.push('/collection?tab=1'),
                                icon: const Icon(Icons.store),
                                label: const Text('Marketplace'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 112),
                    ],
                  ),
                ),
              ),
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
      padding: const EdgeInsets.all(16),
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
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontFamily: AppTheme.displayFontFamily,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
