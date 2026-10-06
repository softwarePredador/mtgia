import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../commercial/legal_policy.dart';
import '../providers/legal_acceptance_provider.dart';

/// Asks the person to accept the updated Terms and Privacy Policy
/// (BT-LEGAL-ACCEPT-001, D-24).
///
/// Only creating or sharing data waits for the acceptance, so "Agora não"
/// always closes the dialog: reading, export and account deletion stay free.
/// Returns true when the acceptance was recorded.
Future<bool> showLegalReacceptanceDialog({
  required BuildContext context,
  required LegalAcceptanceProvider provider,
  required void Function(String section) onReadDocument,
}) async {
  final accepted = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (dialogContext) => LegalReacceptanceDialog(
      provider: provider,
      onReadDocument: onReadDocument,
    ),
  );
  return accepted ?? false;
}

class LegalReacceptanceDialog extends StatefulWidget {
  const LegalReacceptanceDialog({
    super.key,
    required this.provider,
    required this.onReadDocument,
  });

  final LegalAcceptanceProvider provider;
  final void Function(String section) onReadDocument;

  @override
  State<LegalReacceptanceDialog> createState() =>
      _LegalReacceptanceDialogState();
}

class _LegalReacceptanceDialogState extends State<LegalReacceptanceDialog> {
  var _checked = false;

  Future<void> _accept() async {
    final navigator = Navigator.of(context);
    final ok = await widget.provider.accept();
    if (!mounted) return;
    if (ok) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, _) {
        final provider = widget.provider;
        final status = provider.status;
        final appIsCurrent = status?.appTextIsCurrent ?? true;
        final submitting = provider.isSubmitting;
        final error = appIsCurrent
            ? provider.errorMessage
            : 'Os Termos mudaram depois desta versão do app. Atualize o app '
                  'para ler e aceitar o texto atual.';

        return AlertDialog(
          key: const Key('legal-reaccept-dialog'),
          backgroundColor: AppTheme.surfaceElevated,
          title: const Text('Termos atualizados'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Os Termos de uso ou a Política de privacidade mudaram. '
                  'Para criar decks, importar listas e usar a IA, leia e '
                  'aceite a versão atual.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    height: AppTheme.lineHeightCompact,
                  ),
                ),
                const SizedBox(height: AppTheme.space8),
                Text(
                  'Ver seus decks, exportar seus dados e excluir a conta '
                  'continuam livres.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    height: AppTheme.lineHeightCompact,
                  ),
                ),
                const SizedBox(height: AppTheme.space12),
                Wrap(
                  spacing: AppTheme.space8,
                  runSpacing: AppTheme.space8,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('legal-reaccept-read-terms'),
                      onPressed: () => widget.onReadDocument('terms'),
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: const Text('Ler Termos'),
                    ),
                    OutlinedButton.icon(
                      key: const Key('legal-reaccept-read-privacy'),
                      onPressed: () => widget.onReadDocument('privacy'),
                      icon: const Icon(Icons.privacy_tip_outlined, size: 18),
                      label: const Text('Ler Privacidade'),
                    ),
                  ],
                ),
                if (appIsCurrent) ...[
                  const SizedBox(height: AppTheme.space8),
                  CheckboxListTile(
                    key: const Key('legal-reaccept-checkbox'),
                    value: _checked,
                    onChanged: submitting
                        ? null
                        : (value) => setState(() => _checked = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppTheme.brass400,
                    checkColor: AppTheme.backgroundAbyss,
                    title: Text(
                      'Li e aceito os Termos de uso e a Política de '
                      'privacidade',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        height: AppTheme.lineHeightCompact,
                      ),
                    ),
                    subtitle: Text(
                      'Versões $currentTermsVersion / $currentPrivacyVersion',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: AppTheme.space8),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      error,
                      key: const Key('legal-reaccept-error'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w700,
                        height: AppTheme.lineHeightCompact,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              key: const Key('legal-reaccept-later'),
              onPressed: submitting
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: const Text('Agora não'),
            ),
            if (appIsCurrent)
              FilledButton(
                key: const Key('legal-reaccept-submit'),
                onPressed: _checked && !submitting ? _accept : null,
                child: submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Aceitar'),
              ),
          ],
        );
      },
    );
  }
}
