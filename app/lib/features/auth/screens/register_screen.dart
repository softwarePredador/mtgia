import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_visual_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
    context.go('/login');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      context.go('/home');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(authProvider.errorMessage ?? 'Erro ao criar conta'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
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
          const SizedBox(height: 18),
          AuthFormSurface(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Username
                  TextFormField(
                    key: const Key('register-username-field'),
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Nome de usuário',
                      hintText: 'ex: mage42',
                      helperText: 'Você poderá ajustar isso depois.',
                      prefixIcon: const Icon(Icons.alternate_email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    key: const Key('register-email-field'),
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'seu@email.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
                  const SizedBox(height: 16),

                  // Senha
                  TextFormField(
                    key: const Key('register-password-field'),
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip:
                            _obscurePassword
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
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite uma senha';
                      }
                      if (value.length < 6) {
                        return 'Senha deve ter no mínimo 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirmar Senha
                  TextFormField(
                    key: const Key('register-confirm-password-field'),
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirmar senha',
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip:
                            _obscureConfirmPassword
                                ? 'Mostrar confirmação de senha'
                                : 'Ocultar confirmação de senha',
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
                  const SizedBox(height: 22),

                  Consumer<AuthProvider>(
                    builder: (context, auth, child) {
                      if (auth.status == AuthStatus.loading) {
                        return Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                          ),
                          child: const Center(
                            child: SizedBox.square(
                              dimension: AppTheme.iconSpinnerSm,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.backgroundAbyss,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.brass400.withValues(alpha: 0.28),
                              blurRadius: 18,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: Material(
                          color: AppTheme.transparent,
                          child: InkWell(
                            key: const Key('register-submit-button'),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            onTap: _handleRegister,
                            child: const Center(
                              child: Text(
                                'Criar conta',
                                style: TextStyle(
                                  color: AppTheme.backgroundAbyss,
                                  fontSize: AppTheme.fontLg,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  // Link para login
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Já tem uma conta? ',
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        key: const Key('register-open-login-button'),
                        onPressed: _returnToLogin,
                        child: const Text(
                          'Entrar',
                          style: TextStyle(
                            color: AppTheme.brass400,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
