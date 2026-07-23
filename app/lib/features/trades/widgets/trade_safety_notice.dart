import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class TradeSafetyNotice extends StatelessWidget {
  const TradeSafetyNotice({super.key, this.compact = false});

  final bool compact;

  static const String message =
      'O ManaLoom registra a proposta e a conversa, mas não recebe, guarda '
      'nem protege pagamentos. Confira cartas, valores, identidade e entrega '
      'diretamente com o outro jogador.';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Aviso de segurança para trades. $message',
      child: Container(
        key: const Key('trade-safety-notice'),
        width: double.infinity,
        padding: EdgeInsets.all(compact ? AppTheme.space10 : AppTheme.space12),
        decoration: BoxDecoration(
          color: AppTheme.frost400.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: AppTheme.frost400.withValues(alpha: 0.28),
            width: AppTheme.strokeHairline,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.shield_outlined,
              color: AppTheme.frost400,
              size: 20,
            ),
            const SizedBox(width: AppTheme.space9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Combinação entre jogadores',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: AppTheme.fontMd,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space4),
                  Text(
                    message,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: compact ? AppTheme.fontSm : AppTheme.fontMd,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
