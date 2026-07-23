import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../account_security_service.dart';
import '../password_policy.dart';
import '../widgets/auth_visual_shell.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.token, this.service});

  final String token;
  final AccountSecurityService? service;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  late final AccountSecurityService _service;
  bool _submitting = false;
  bool _obscure = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AccountSecurityService();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      await _service.resetPassword(
        token: widget.token,
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha alterada. Entre novamente.')),
      );
      context.go('/login');
    } on AccountSecurityUiException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Não foi possível alterar a senha.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final missingToken = widget.token.trim().isEmpty;
    return AuthVisualShell(
      maxWidth: 500,
      child: Column(
        children: [
          const AuthBrandHeader(
            title: 'Criar nova senha',
            subtitle: 'Este link funciona uma única vez e expira rapidamente.',
            logoSize: 76,
          ),
          const SizedBox(height: AppTheme.space18),
          AuthFormSurface(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (missingToken || _errorMessage != null)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        missingToken
                            ? 'Link de recuperação inválido. Solicite outro.'
                            : _errorMessage!,
                        key: const Key('reset-password-error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (!missingToken) ...[
                    TextFormField(
                      key: const Key('reset-password-field'),
                      controller: _passwordController,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: 'Nova senha',
                        helperText: 'Use 12+ caracteres e evite sequências.',
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        suffixIcon: IconButton(
                          tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: validateRegistrationPassword,
                    ),
                    const SizedBox(height: AppTheme.space16),
                    TextFormField(
                      key: const Key('reset-password-confirm-field'),
                      controller: _confirmationController,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: const InputDecoration(
                        labelText: 'Confirmar nova senha',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) => value != _passwordController.text
                          ? 'Senhas não correspondem'
                          : null,
                    ),
                    const SizedBox(height: AppTheme.space20),
                    FilledButton(
                      key: const Key('reset-password-submit-button'),
                      onPressed: _submitting ? null : _submit,
                      child: Text(_submitting ? 'Alterando' : 'Alterar senha'),
                    ),
                  ],
                  const SizedBox(height: AppTheme.space8),
                  TextButton(
                    onPressed: () => context.go('/forgot-password'),
                    child: const Text('Solicitar outro link'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
