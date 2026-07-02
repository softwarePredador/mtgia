import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_visual_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();

    // Evita que emails longos fiquem "rolados" para o final depois que o campo perde foco.
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        _emailController.selection = const TextSelection.collapsed(offset: 0);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    debugPrint('[📱 LoginScreen] _handleLogin() chamado');
    if (!_formKey.currentState!.validate()) {
      debugPrint('[📱 LoginScreen] formulário inválido, abortando');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    debugPrint('[📱 LoginScreen] chamando authProvider.login()...');
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    debugPrint('[📱 LoginScreen] login retornou: success=$success');

    if (!mounted) {
      debugPrint('[📱 LoginScreen] widget desmontado após login!');
      return;
    }

    if (success) {
      debugPrint(
        '[📱 LoginScreen] ✅ login OK — aguardando redirect do GoRouter',
      );
      // Navegação é feita automaticamente pelo redirect do GoRouter
      // quando o status muda para 'authenticated'.
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(authProvider.errorMessage ?? 'Erro ao fazer login'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthVisualShell(
      child: Column(
        children: [
          const AuthBrandHeader(
            title: 'ManaLoom',
            subtitle: 'Entre na sua conta',
            eyebrow: 'Tecendo estratégias lendárias',
          ),
          const SizedBox(height: 22),
          AuthFormSurface(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Email
                  TextFormField(
                    key: const Key('login-email-field'),
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
                    key: const Key('login-password-field'),
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
                        return 'Digite sua senha';
                      }
                      if (value.length < 6) {
                        return 'Senha deve ter no mínimo 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 22),

                  // Botão Login com gradiente
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
                            child: SizedBox(
                              height: 20,
                              width: 20,
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
                            key: const Key('login-submit-button'),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            onTap: _handleLogin,
                            child: const Center(
                              child: Text(
                                'Entrar',
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

                  // Link para registro
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Não tem uma conta? ',
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        key: const Key('login-open-register-button'),
                        onPressed: () => context.push('/register'),
                        child: const Text(
                          'Criar conta',
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
