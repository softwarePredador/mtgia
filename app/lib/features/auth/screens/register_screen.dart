import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../auth_redirect.dart';
import '../models/email_verification_delivery_result.dart';
import '../password_policy.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_visual_shell.dart';
import '../../commercial/legal_policy.dart';

const _registerButtonTextStyle = TextStyle(
  color: AppTheme.backgroundAbyss,
  fontSize: AppTheme.fontLg,
  fontWeight: FontWeight.bold,
  letterSpacing: 0,
);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.redirectPath});

  final String? redirectPath;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _legalSectionKey = GlobalKey();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _legalFocusNode = FocusNode();
  final _submitFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _legalAccepted = false;
  String? _legalError;

  @override
  void initState() {
    super.initState();

    // Evita que emails longos fiquem "rolados" para o final depois que o campo perde foco,
    // o que parece um corte do primeiro caractere.
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        _emailController.selection = const TextSelection.collapsed(offset: 0);
      }
    });
  }

  void _returnToLogin() {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go(buildAuthLocation('/login', widget.redirectPath));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _legalFocusNode.dispose();
    _submitFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_legalAccepted) {
      setState(() {
        _legalError =
            'Leia e aceite os Termos de uso e a Política de privacidade.';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final legalContext = _legalSectionKey.currentContext;
        if (legalContext != null) {
          Scrollable.ensureVisible(
            legalContext,
            duration: const Duration(milliseconds: 180),
            alignment: 0.45,
          );
        }
        _legalFocusNode.requestFocus();
      });
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      legalAccepted: true,
      termsVersion: currentTermsVersion,
      privacyVersion: currentPrivacyVersion,
    );

    if (!mounted) return;

    if (success) {
      final delivery = switch (authProvider.emailVerificationDeliveryStatus) {
        EmailVerificationDeliveryStatus.sent => 'sent',
        EmailVerificationDeliveryStatus.unavailable => 'unavailable',
        EmailVerificationDeliveryStatus.unknown => null,
      };
      context.go(
        Uri(
          path: '/verify-email',
          queryParameters: {
            if (widget.redirectPath != null) 'redirect': widget.redirectPath!,
            if (delivery != null) 'delivery': delivery,
          },
        ).toString(),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(authProvider.errorMessage ?? 'Erro ao criar conta'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _openLegalSection(String section) {
    context.push(
      Uri(path: '/legal', queryParameters: {'section': section}).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthVisualShell(
      maxWidth: 500,
      leading: IconButton(
        key: const Key('register-back-button'),
        tooltip: 'Voltar para login',
        style: IconButton.styleFrom(
          backgroundColor: AppTheme.surfaceSlate.withValues(alpha: 0.78),
          foregroundColor: AppTheme.textPrimary,
          side: BorderSide(color: AppTheme.outlineMuted.withValues(alpha: 0.8)),
        ),
        icon: const Icon(Icons.arrow_back),
        onPressed: _returnToLogin,
      ),
      child: Column(
        children: [
          const AuthBrandHeader(
            title: 'Criar conta',
            subtitle: 'Configure seu acesso em menos de um minuto.',
            logoSize: 76,
          ),
          const SizedBox(height: AppTheme.space18),
          AuthFormSurface(
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Username
                    TextFormField(
                      key: const Key('register-username-field'),
                      controller: _usernameController,
                      focusNode: _usernameFocusNode,
                      autofillHints: const [AutofillHints.newUsername],
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
                      decoration: InputDecoration(
                        labelText: 'Nome de usuário',
                        hintText: 'ex: mage42',
                        helperText: 'Você poderá ajustar isso depois.',
                        prefixIcon: const Icon(Icons.alternate_email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Digite um nome de usuário';
                        }
                        if (value.length < 3) {
                          return 'Mínimo 3 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.space16),

                    // Email
                    TextFormField(
                      key: const Key('register-email-field'),
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      autofillHints: const [AutofillHints.email],
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          _passwordFocusNode.requestFocus(),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'seu@email.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Digite seu email';
                        }
                        if (!value.contains('@')) {
                          return 'Email inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.space16),

                    // Senha
                    TextFormField(
                      key: const Key('register-password-field'),
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          _confirmPasswordFocusNode.requestFocus(),
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        hintText: '••••••••',
                        helperText:
                            'Use 12+ caracteres e evite sequências, seu nome ou email.',
                        helperMaxLines: 2,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Mostrar senha'
                              : 'Ocultar senha',
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                      ),
                      validator: (value) => validateRegistrationPassword(
                        value,
                        username: _usernameController.text,
                        email: _emailController.text,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),

                    // Confirmar Senha
                    TextFormField(
                      key: const Key('register-confirm-password-field'),
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordFocusNode,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => _legalFocusNode.requestFocus(),
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirmar senha',
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscureConfirmPassword
                              ? 'Mostrar confirmação de senha'
                              : 'Ocultar confirmação de senha',
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirme sua senha';
                        }
                        if (value != _passwordController.text) {
                          return 'Senhas não correspondem';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.space16),
                    _LegalConsentBlock(
                      key: _legalSectionKey,
                      accepted: _legalAccepted,
                      error: _legalError,
                      focusNode: _legalFocusNode,
                      onChanged: (value) => setState(() {
                        _legalAccepted = value;
                        if (_legalAccepted) _legalError = null;
                      }),
                      onOpenTerms: () => _openLegalSection('terms'),
                      onOpenPrivacy: () => _openLegalSection('privacy'),
                    ),
                    const SizedBox(height: AppTheme.space14),

                    Consumer<AuthProvider>(
                      builder: (context, auth, child) {
                        final loading = auth.status == AuthStatus.loading;
                        return Semantics(
                          button: true,
                          enabled: !loading,
                          liveRegion: loading,
                          label: loading ? 'Criando conta' : 'Criar conta',
                          child: ExcludeSemantics(
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                                boxShadow: loading
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: AppTheme.brass400.withValues(
                                            alpha: 0.28,
                                          ),
                                          blurRadius: 18,
                                          offset: const Offset(0, 7),
                                        ),
                                      ],
                              ),
                              child: Material(
                                color: AppTheme.transparent,
                                child: InkWell(
                                  key: const Key('register-submit-button'),
                                  focusNode: _submitFocusNode,
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMd,
                                  ),
                                  onTap: loading ? null : _handleRegister,
                                  child: Center(
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 140,
                                      ),
                                      child: loading
                                          ? const Row(
                                              key: Key(
                                                'register-submit-loading',
                                              ),
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox.square(
                                                  dimension:
                                                      AppTheme.iconSpinnerSm,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(
                                                          AppTheme
                                                              .backgroundAbyss,
                                                        ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: AppTheme.space10,
                                                ),
                                                Text(
                                                  'Criando conta…',
                                                  style:
                                                      _registerButtonTextStyle,
                                                ),
                                              ],
                                            )
                                          : const Text(
                                              'Criar conta',
                                              key: Key('register-submit-label'),
                                              style: _registerButtonTextStyle,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppTheme.space14),

                    // Link para login
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Já tem uma conta? ',
                          style: theme.textTheme.bodyMedium,
                        ),
                        SizedBox(
                          height: AppTheme.touchTargetCompactPlatformHeight,
                          child: TextButton(
                            key: const Key('register-open-login-button'),
                            style: AppTheme.accessibleTextButtonStyle,
                            onPressed: _returnToLogin,
                            child: const Text(
                              'Entrar',
                              style: TextStyle(
                                color: AppTheme.brass400,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalConsentBlock extends StatelessWidget {
  const _LegalConsentBlock({
    super.key,
    required this.accepted,
    required this.error,
    required this.focusNode,
    required this.onChanged,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
  });

  final bool accepted;
  final String? error;
  final FocusNode focusNode;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = error == null
        ? AppTheme.textHint.withValues(alpha: 0.72)
        : theme.colorScheme.error;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            type: MaterialType.transparency,
            child: CheckboxListTile(
              key: const Key('register-legal-acceptance'),
              focusNode: focusNode,
              value: accepted,
              onChanged: (value) => onChanged(value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.fromLTRB(
                AppTheme.space8,
                AppTheme.space4,
                AppTheme.space12,
                AppTheme.space2,
              ),
              visualDensity: VisualDensity.standard,
              activeColor: AppTheme.brass400,
              checkColor: AppTheme.backgroundAbyss,
              side: const BorderSide(color: AppTheme.textHint, width: 1.2),
              title: Text(
                'Li e aceito os Termos de uso e a Política de privacidade',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  height: AppTheme.lineHeightCompact,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Consentimento necessário para criar a conta.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  height: AppTheme.lineHeightCompact,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space12,
              0,
              AppTheme.space12,
              AppTheme.space8,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final terms = _LegalDocumentButton(
                  key: const Key('register-open-terms-button'),
                  icon: Icons.description_outlined,
                  label: 'Ler Termos',
                  onPressed: onOpenTerms,
                );
                final privacy = _LegalDocumentButton(
                  key: const Key('register-open-privacy-button'),
                  icon: Icons.privacy_tip_outlined,
                  label: 'Ler Privacidade',
                  onPressed: onOpenPrivacy,
                );
                if (constraints.maxWidth < 360) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      terms,
                      const SizedBox(height: AppTheme.space8),
                      privacy,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: terms),
                    const SizedBox(width: AppTheme.space8),
                    Expanded(child: privacy),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space14,
              0,
              AppTheme.space14,
              AppTheme.space12,
            ),
            child: error == null
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 16,
                        color: AppTheme.frost400,
                      ),
                      const SizedBox(width: AppTheme.space6),
                      Expanded(
                        child: Text(
                          'Versões $currentTermsVersion / '
                          '$currentPrivacyVersion',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  )
                : Semantics(
                    liveRegion: true,
                    child: Text(
                      error!,
                      key: const Key('register-legal-error'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w700,
                        height: AppTheme.lineHeightCompact,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LegalDocumentButton extends StatelessWidget {
  const _LegalDocumentButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, AppTheme.touchTargetMin),
        foregroundColor: AppTheme.brass400,
        side: BorderSide(
          color: AppTheme.brass400.withValues(alpha: 0.62),
          width: 1,
        ),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
