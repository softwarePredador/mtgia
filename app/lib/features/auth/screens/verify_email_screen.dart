import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../account_security_service.dart';
import '../auth_redirect.dart';
import '../models/email_verification_delivery_result.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_visual_shell.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.token,
    this.redirectPath,
    this.initialDeliveryStatus = EmailVerificationDeliveryStatus.unknown,
    this.service,
  });

  final String token;
  final String? redirectPath;
  final EmailVerificationDeliveryStatus initialDeliveryStatus;
  final AccountSecurityService? service;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  late final AccountSecurityService _service;
  bool _working = false;
  bool _verified = false;
  late EmailVerificationDeliveryStatus _deliveryStatus;
  int _verificationGeneration = 0;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AccountSecurityService();
    _deliveryStatus = widget.initialDeliveryStatus;
    _scheduleVerification(widget.token);
  }

  @override
  void didUpdateWidget(covariant VerifyEmailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDeliveryStatus != widget.initialDeliveryStatus) {
      _deliveryStatus = widget.initialDeliveryStatus;
    }
    if (oldWidget.token.trim() != widget.token.trim()) {
      _scheduleVerification(widget.token);
    }
  }

  void _scheduleVerification(String token) {
    final normalized = token.trim();
    final generation = ++_verificationGeneration;
    if (normalized.isEmpty) {
      _working = false;
      _verified = false;
      _message = null;
      _error = null;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _verificationGeneration) return;
      _verify(normalized, generation: generation);
    });
  }

  Future<void> _verify(String token, {required int generation}) async {
    setState(() {
      _working = true;
      _verified = false;
      _message = null;
      _error = null;
    });
    try {
      final message = await _service.verifyEmail(token);
      if (!mounted || generation != _verificationGeneration) return;
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) await auth.refreshProfile();
      if (!mounted || generation != _verificationGeneration) return;
      setState(() {
        _verified = true;
        _message = message;
      });
    } on AccountSecurityUiException catch (error) {
      if (mounted && generation == _verificationGeneration) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted && generation == _verificationGeneration) {
        setState(() => _error = 'Não foi possível verificar o email.');
      }
    } finally {
      if (mounted && generation == _verificationGeneration) {
        setState(() => _working = false);
      }
    }
  }

  Future<void> _resend() async {
    if (_working) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final result = await _service.resendEmailVerification();
      if (!mounted) return;
      setState(() {
        _deliveryStatus = result.status;
        _verified = result.alreadyVerified;
        _message =
            result.alreadyVerified ||
                result.status == EmailVerificationDeliveryStatus.sent
            ? result.message
            : null;
        _error = result.status == EmailVerificationDeliveryStatus.unavailable
            ? 'Não foi possível enviar o link agora. Tente novamente em instantes.'
            : null;
      });
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
                        : switch (_deliveryStatus) {
                            EmailVerificationDeliveryStatus.sent =>
                              'Link enviado para ${auth.user!.email}. Confira também o spam.',
                            EmailVerificationDeliveryStatus.unavailable =>
                              'O link ainda não foi enviado. Tente novamente em instantes.',
                            EmailVerificationDeliveryStatus.unknown =>
                              'Seu email ainda não foi verificado. Solicite um novo link.',
                          },
                  ),
                  const SizedBox(height: AppTheme.space16),
                  if (auth.isAuthenticated)
                    FilledButton.icon(
                      key: const Key('verify-email-resend-button'),
                      onPressed: _working ? null : _resend,
                      icon: const Icon(Icons.mark_email_unread_outlined),
                      label: Text(
                        _deliveryStatus ==
                                EmailVerificationDeliveryStatus.unavailable
                            ? 'Tentar enviar novamente'
                            : 'Reenviar verificação',
                      ),
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
