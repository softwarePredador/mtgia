import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_page_frame.dart';
import '../legal_policy.dart';

enum _LegalSectionTarget { terms, privacy }

class CommercialLegalScreen extends StatefulWidget {
  const CommercialLegalScreen({super.key, this.initialSection});

  final String? initialSection;

  @override
  State<CommercialLegalScreen> createState() => _CommercialLegalScreenState();
}

class _CommercialLegalScreenState extends State<CommercialLegalScreen> {
  final _scrollController = ScrollController();
  final _termsKey = GlobalKey();
  final _privacyKey = GlobalKey();
  var _initialLocationScheduled = false;
  var _selectedSection = _LegalSectionTarget.terms;

  @override
  void initState() {
    super.initState();
    if (widget.initialSection == 'privacy') {
      _selectedSection = _LegalSectionTarget.privacy;
    }
  }

  @override
  void didUpdateWidget(covariant CommercialLegalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSection != widget.initialSection) {
      _selectedSection = widget.initialSection == 'privacy'
          ? _LegalSectionTarget.privacy
          : _LegalSectionTarget.terms;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.initialSection == null) {
          if (_scrollController.hasClients) _scrollController.jumpTo(0);
          return;
        }
        _scrollTo(_selectedSection, animate: false);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialLocationScheduled) return;
    _initialLocationScheduled = true;
    if (widget.initialSection == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollTo(_selectedSection, animate: false);
    });
  }

  Future<void> _scrollTo(
    _LegalSectionTarget section, {
    bool animate = true,
  }) async {
    final target = switch (section) {
      _LegalSectionTarget.terms => _termsKey,
      _LegalSectionTarget.privacy => _privacyKey,
    };
    final targetContext = target.currentContext;
    if (targetContext == null) return;
    setState(() => _selectedSection = section);
    await Scrollable.ensureVisible(
      targetContext,
      duration: animate ? const Duration(milliseconds: 220) : Duration.zero,
      curve: Curves.easeOutCubic,
      // The scrollable viewport already starts below the fixed app bar. Align
      // the requested section with its exact leading edge so no line from the
      // previous legal section remains visibly clipped below the bar.
      alignment: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Termos e privacidade')),
      body: SelectionArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            final horizontalGutter =
                viewport.maxWidth < AppTheme.breakpointCompact ? 16.0 : 24.0;
            return ListView(
              key: const Key('legal-scroll-view'),
              controller: _scrollController,
              padding: EdgeInsets.only(
                top: AppTheme.space20,
                bottom:
                    AppTheme.space32 +
                    MediaQuery.of(context).padding.bottom +
                    // The privacy section is the final document block. Keep
                    // one viewport of trailing extent so its deep link can
                    // align exactly below the app bar even on wide screens,
                    // where the short, single-line document blocks otherwise
                    // leave too little scroll range.
                    viewport.maxHeight,
              ),
              children: [
                ResponsivePageFrame(
                  key: const Key('legal-responsive-frame'),
                  maxWidth: AppTheme.readingMaxWidth,
                  padding: EdgeInsets.symmetric(horizontal: horizontalGutter),
                  child: Column(
                    key: const Key('legal-content'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _LegalHeader(),
                      const SizedBox(height: AppTheme.space20),
                      _LegalSectionNavigation(
                        selected: _selectedSection,
                        onSelected: _scrollTo,
                      ),
                      const SizedBox(height: AppTheme.space20),
                      const _LegalReviewStatus(),
                      const SizedBox(height: AppTheme.space28),
                      _LegalDocumentSection(
                        key: _termsKey,
                        anchorKey: const Key('legal-terms-section'),
                        title: 'Termos de uso',
                        icon: Icons.description_outlined,
                        body:
                            'ManaLoom ajuda a criar, analisar, otimizar e acompanhar decks de Magic. O usuário continua responsável por revisar legalidade, preços, recomendações, compras, trades e decisões de mesa antes de agir.',
                      ),
                      const _LegalDocumentSection(
                        title: 'IP e conteúdo',
                        icon: Icons.copyright_outlined,
                        body:
                            'Magic: The Gathering e nomes de cartas pertencem aos seus respectivos titulares. ManaLoom não reivindica propriedade sobre IP de terceiros. Listas, notas e comentários criados pelo usuário permanecem vinculados à conta do usuário.',
                      ),
                      const _LegalDocumentSection(
                        title: 'Disclaimer de IA',
                        icon: Icons.auto_awesome_outlined,
                        body:
                            'Sugestões de IA podem errar preço, disponibilidade, regra, bracket ou contexto local. O app mostra motivos e preview para revisão humana antes de aplicar mudanças no deck.',
                      ),
                      const _LegalDocumentSection(
                        title: 'Trocas entre usuários',
                        icon: Icons.swap_horiz_rounded,
                        body:
                            'ManaLoom coordena propostas e conversas, mas não recebe, guarda ou protege pagamentos e não garante entrega, estado ou autenticidade das cartas. Os usuários devem verificar os itens e combinar pagamento e envio diretamente entre si.',
                      ),
                      const _LegalDocumentSection(
                        anchorKey: Key('legal-monetization-section'),
                        title: 'Monetização',
                        icon: Icons.payments_outlined,
                        body:
                            'A beta pública atual é gratuita e não oferece assinatura, checkout ou cobrança. Se houver planos pagos no futuro, valores e condições serão apresentados separadamente antes de qualquer confirmação.',
                      ),
                      _LegalDocumentSection(
                        key: _privacyKey,
                        anchorKey: const Key('legal-privacy-section'),
                        title: 'Política de privacidade',
                        icon: Icons.privacy_tip_outlined,
                        body:
                            'Decks privados, coleção, fichário, histórico pós-jogo e preferências de IA devem ser tratados como dados do usuário. Dados públicos só devem ser exibidos quando o usuário publicar deck, perfil, fichário ou lista de trade.',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LegalHeader extends StatelessWidget {
  const _LegalHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.shield_outlined, color: AppTheme.frost400, size: 32),
        const SizedBox(height: AppTheme.space12),
        Semantics(
          header: true,
          child: Text(
            'Termos e privacidade',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.space8),
        Text(
          'Leia o que rege o uso do ManaLoom e como seus dados são tratados.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondary,
            height: AppTheme.lineHeightComfortable,
          ),
        ),
        const SizedBox(height: AppTheme.space14),
        Semantics(
          label:
              'Versões vigentes. Termos $currentTermsVersion. '
              'Privacidade $currentPrivacyVersion.',
          child: ExcludeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_outlined,
                  size: 18,
                  color: AppTheme.brass400,
                ),
                const SizedBox(width: AppTheme.space8),
                Expanded(
                  child: Wrap(
                    spacing: AppTheme.space14,
                    runSpacing: AppTheme.space6,
                    children: [
                      Text(
                        'Termos · $currentTermsVersion',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          height: AppTheme.lineHeightCompact,
                        ),
                      ),
                      Text(
                        'Privacidade · $currentPrivacyVersion',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          height: AppTheme.lineHeightCompact,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegalSectionNavigation extends StatelessWidget {
  const _LegalSectionNavigation({
    required this.selected,
    required this.onSelected,
  });

  final _LegalSectionTarget selected;
  final ValueChanged<_LegalSectionTarget> onSelected;

  @override
  Widget build(BuildContext context) {
    final terms = _LegalNavigationButton(
      key: const Key('legal-show-terms-button'),
      label: 'Termos',
      semanticLabel: 'Abrir Termos de uso',
      icon: Icons.description_outlined,
      selected: selected == _LegalSectionTarget.terms,
      onPressed: () => onSelected(_LegalSectionTarget.terms),
    );
    final privacy = _LegalNavigationButton(
      key: const Key('legal-show-privacy-button'),
      label: 'Privacidade',
      semanticLabel: 'Abrir Política de privacidade',
      icon: Icons.privacy_tip_outlined,
      selected: selected == _LegalSectionTarget.privacy,
      onPressed: () => onSelected(_LegalSectionTarget.privacy),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        if (constraints.maxWidth < 360 || textScale >= 1.5) {
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
    );
  }
}

class _LegalNavigationButton extends StatelessWidget {
  const _LegalNavigationButton({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final String semanticLabel;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      onTap: onPressed,
      excludeSemantics: true,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, AppTheme.touchTargetMin),
          foregroundColor: selected
              ? AppTheme.backgroundAbyss
              : AppTheme.brass400,
          backgroundColor: selected ? AppTheme.brass400 : AppTheme.transparent,
          side: BorderSide(
            color: selected
                ? AppTheme.brass400
                : AppTheme.brass400.withValues(alpha: 0.64),
            width: 1,
          ),
        ),
        icon: Icon(icon, size: 18),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _LegalReviewStatus extends StatelessWidget {
  const _LegalReviewStatus();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const status =
        'Conteúdo informativo da beta. A revisão jurídica externa permanece '
        'pendente antes do lançamento comercial.';
    return Semantics(
      container: true,
      label: 'Status jurídico. $status',
      child: ExcludeSemantics(
        child: Container(
          key: const Key('legal-review-status'),
          padding: const EdgeInsets.all(AppTheme.space14),
          decoration: BoxDecoration(
            color: AppTheme.frost600.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: AppTheme.frost400.withValues(alpha: 0.34),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.gavel_outlined,
                color: AppTheme.frost400,
                size: 20,
              ),
              const SizedBox(width: AppTheme.space10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status do documento',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      status,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        height: AppTheme.lineHeightComfortable,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalDocumentSection extends StatelessWidget {
  const _LegalDocumentSection({
    super.key,
    this.anchorKey,
    required this.title,
    required this.icon,
    required this.body,
    this.isLast = false,
  });

  final Key? anchorKey;
  final String title;
  final IconData icon;
  final String body;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: anchorKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.frost600.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(icon, color: AppTheme.frost400, size: 22),
            ),
            const SizedBox(width: AppTheme.space14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: AppTheme.space24),
          const Divider(color: AppTheme.outlineMuted, height: 1),
          const SizedBox(height: AppTheme.space24),
        ],
      ],
    );
  }
}
