import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class CommercialLegalScreen extends StatelessWidget {
  const CommercialLegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Legal')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        children: const [
          _LegalSection(
            title: 'Termos de uso',
            icon: Icons.description_outlined,
            body:
                'ManaLoom ajuda a criar, analisar, otimizar e acompanhar decks de Magic. O usuário continua responsável por revisar legalidade, preços, recomendações, compras, trades e decisões de mesa antes de agir.',
          ),
          _LegalSection(
            title: 'Privacidade',
            icon: Icons.privacy_tip_outlined,
            body:
                'Decks privados, coleção, fichário, histórico pós-jogo e preferências de IA devem ser tratados como dados do usuário. Dados públicos só devem ser exibidos quando o usuário publicar deck, perfil, fichário ou lista de trade.',
          ),
          _LegalSection(
            title: 'IP e conteúdo',
            icon: Icons.copyright_outlined,
            body:
                'Magic: The Gathering e nomes de cartas pertencem aos seus respectivos titulares. ManaLoom não reivindica propriedade sobre IP de terceiros. Listas, notas e comentários criados pelo usuário permanecem vinculados à conta do usuário.',
          ),
          _LegalSection(
            title: 'Disclaimer de IA',
            icon: Icons.auto_awesome_outlined,
            body:
                'Sugestões de IA podem errar preço, disponibilidade, regra, bracket ou contexto local. O app mostra motivos e preview para revisão humana antes de aplicar mudanças no deck.',
          ),
          _LegalSection(
            title: 'Monetização',
            icon: Icons.payments_outlined,
            body:
                'Antes de concluir uma assinatura, confira no checkout os limites de uso, valores, recorrência, cancelamento, reembolso e canais de suporte aplicáveis ao plano.',
          ),
        ],
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({
    required this.title,
    required this.icon,
    required this.body,
  });

  final String title;
  final IconData icon;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.frost400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    height: 1.45,
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
