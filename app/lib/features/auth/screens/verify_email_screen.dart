import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../account_security_service.dart';
import '../auth_redirect.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_visual_shell.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.token,
    this.redirectPath,
    this.service,
  });

  final String token;
  final String? redirectPath;
  final AccountSecurityService? service;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  late final AccountSecurityService _service;
  bool _working = false;
  bool _verified = false;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AccountSecurityService();
    if (widget.token.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _verify());
    }
  }

  Future<void> _verify() async {
    if (_working) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final message = await _service.verifyEmail(widget.token);
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) await auth.refreshProfile();
      if (!mounted) return;
      setState(() {
        _verified = true;
        _message = message;
      });
    } on AccountSecurityUiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível verificar o email.');
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _resend() async {
    if (_working) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final message = await _service.resendEmailVerification();
      if (mounted) setState(() => _message = message);
    } on AccountSecurityUiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível reenviar a verificação.');
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _continue() {
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) {
      context.go(
        resolveAuthenticatedLocation(
          redirectPath: widget.redirectPath,
          defaultLocation: auth.defaultAuthenticatedLocation,
        ),
      );
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return AuthVisualShell(
      maxWidth: 520,
      child: Column(
        children: [
          const AuthBrandHeader(
            title: 'Verifique seu email',
            subtitle:
                'A leitura continua disponível; publicar, conversar e negociar exigem email verificado.',
            logoSize: 76,
          ),
          const SizedBox(height: AppTheme.space18),
          AuthFormSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_working)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.space20),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (_message != null)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _message!,
                      key: const Key('verify-email-message'),
                    ),
                  ),
                if (_error != null)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      key: const Key('verify-email-error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (!_verified && widget.token.trim().isEmpty) ...[
                  Text(
                    auth.user == null
                        ? 'Entre na sua conta para solicitar outro link.'
                        : 'Confira a caixa de entrada de ${auth.user!.email}.',
                  ),
                  const SizedBox(height: AppTheme.space16),
                  if (auth.isAuthenticated)
                    FilledButton.icon(
                      key: const Key('verify-email-resend-button'),
                      onPressed: _working ? null : _resend,
                      icon: const Icon(Icons.mark_email_unread_outlined),
                      label: const Text('Reenviar verificação'),
                    ),
                ],
                if (_verified) ...[
                  const SizedBox(height: AppTheme.space16),
                  FilledButton(
                    key: const Key('verify-email-continue-button'),
                    onPressed: _continue,
                    child: const Text('Continuar'),
                  ),
                ],
                const SizedBox(height: AppTheme.space8),
                TextButton(
                  onPressed: _continue,
                  child: Text(
                    auth.isAuthenticated ? 'Voltar ao app' : 'Entrar',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
