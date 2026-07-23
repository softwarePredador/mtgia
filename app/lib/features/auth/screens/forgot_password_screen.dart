import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../account_security_service.dart';
import '../widgets/auth_visual_shell.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.service});

  final AccountSecurityService? service;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  late final AccountSecurityService _service;
  bool _submitting = false;
  String? _successMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AccountSecurityService();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() {
      _submitting = true;
      _successMessage = null;
      _errorMessage = null;
    });
    try {
      final message = await _service.requestPasswordReset(
        _emailController.text,
      );
      if (!mounted) return;
      setState(() => _successMessage = message);
    } on AccountSecurityUiException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Não foi possível solicitar a recuperação agora.';
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthVisualShell(
      maxWidth: 500,
      leading: IconButton(
        tooltip: 'Voltar para login',
        onPressed: () => context.go('/login'),
        icon: const Icon(Icons.arrow_back),
      ),
      child: Column(
        children: [
          const AuthBrandHeader(
            title: 'Recuperar senha',
            subtitle: 'Enviaremos um link de uso único para seu email.',
            logoSize: 76,
          ),
          const SizedBox(height: AppTheme.space18),
          AuthFormSurface(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_successMessage != null)
                    _AuthNotice(
                      key: const Key('forgot-password-success'),
                      message: _successMessage!,
                      color: AppTheme.success,
                    ),
                  if (_errorMessage != null)
                    _AuthNotice(
                      key: const Key('forgot-password-error'),
                      message: _errorMessage!,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  TextFormField(
                    key: const Key('forgot-password-email-field'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      final normalized = value?.trim() ?? '';
                      if (normalized.isEmpty || !normalized.contains('@')) {
                        return 'Digite um email válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.space20),
                  FilledButton.icon(
                    key: const Key('forgot-password-submit-button'),
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.mark_email_read_outlined),
                    label: Text(_submitting ? 'Enviando' : 'Enviar instruções'),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Voltar para entrar'),
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

class _AuthNotice extends StatelessWidget {
  const _AuthNotice({super.key, required this.message, required this.color});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space16),
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Text(message),
    ),
  );
}
