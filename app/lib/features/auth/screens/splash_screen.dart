import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.redirectPath});

  final String? redirectPath;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

@visibleForTesting
String? normalizePostSplashRedirect(String? redirectPath) {
  final trimmed = redirectPath?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.hasScheme || uri.hasAuthority) {
    return null;
  }

  final path = uri.path;
  if (!path.startsWith('/') ||
      path == '/' ||
      path == '/login' ||
      path == '/register') {
    return null;
  }

  return uri.toString();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    _authProvider = context.read<AuthProvider>();
    _initializeApp(_authProvider);
  }

  Future<void> _initializeApp(AuthProvider authProvider) async {
    final startedAt = DateTime.now();
    await authProvider.initialize();

    const minimumDwell = Duration(milliseconds: 650);
    final remaining = minimumDwell - DateTime.now().difference(startedAt);
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }

    if (!mounted) return;

    final postAuthRedirect = normalizePostSplashRedirect(widget.redirectPath);
    context.go(
      authProvider.isAuthenticated ? postAuthRedirect ?? '/home' : '/login',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundAbyss,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/branding/splash_art.png',
            fit: BoxFit.cover,
            semanticLabel: 'ManaLoom splash art',
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.backgroundAbyss.withValues(alpha: 0.1),
                  AppTheme.backgroundAbyss.withValues(alpha: 0.18),
                  AppTheme.backgroundAbyss.withValues(alpha: 0.72),
                ],
                stops: const [0, 0.52, 1],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 72, 28, 52),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const Spacer(flex: 5),
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 116,
                            height: 116,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundAbyss.withValues(
                                alpha: 0.34,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusLogoOuter,
                              ),
                              border: Border.all(
                                color: AppTheme.brass400.withValues(
                                  alpha: 0.24,
                                ),
                                width: AppTheme.strokeHairline,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusLogoInner,
                              ),
                              child: Image.asset(
                                'assets/branding/app_logo.png',
                                fit: BoxFit.cover,
                                semanticLabel: 'ManaLoom logo',
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'ManaLoom',
                            textAlign: TextAlign.center,
                            style: Theme.of(
                              context,
                            ).textTheme.headlineLarge?.copyWith(
                              color: AppTheme.textPrimary,
                              fontFamily: AppTheme.displayFontFamily,
                              fontWeight: FontWeight.w900,
                              fontSize: AppTheme.fontDisplay + 2,
                              letterSpacing: 0,
                              height: 1.03,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tecendo estratégias lendárias',
                            textAlign: TextAlign.center,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                              height: 1.28,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 4),
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.brass400,
                        ),
                      ),
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
