import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class SocialReportDraft {
  const SocialReportDraft({required this.reason, required this.details});

  final String reason;
  final String details;
}

const socialReportReasonLabels = <String, String>{
  'spam': 'Spam',
  'abuse': 'Assédio ou abuso',
  'scam': 'Golpe ou fraude',
  'inappropriate': 'Conteúdo impróprio',
  'copyright': 'Direitos autorais',
  'other': 'Outro',
};

Future<SocialReportDraft?> showSocialReportDialog(
  BuildContext context, {
  required String targetLabel,
}) {
  return showDialog<SocialReportDraft>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _SocialReportDialog(targetLabel: targetLabel),
  );
}

class _SocialReportDialog extends StatefulWidget {
  const _SocialReportDialog({required this.targetLabel});

  final String targetLabel;

  @override
  State<_SocialReportDialog> createState() => _SocialReportDialogState();
}

class _SocialReportDialogState extends State<_SocialReportDialog> {
  final _detailsController = TextEditingController();
  String _reason = socialReportReasonLabels.keys.first;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('social-report-dialog'),
      title: Text('Denunciar ${widget.targetLabel}'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              key: const Key('social-report-reason-field'),
              initialValue: _reason,
              decoration: const InputDecoration(labelText: 'Motivo'),
              items: socialReportReasonLabels.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) setState(() => _reason = value);
              },
            ),
            const SizedBox(height: AppTheme.space12),
            TextField(
              key: const Key('social-report-details-field'),
              controller: _detailsController,
              maxLength: 1000,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Detalhes',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          key: const Key('social-report-confirm-button'),
          onPressed: () => Navigator.pop(
            context,
            SocialReportDraft(
              reason: _reason,
              details: _detailsController.text.trim(),
            ),
          ),
          icon: const Icon(Icons.flag_outlined),
          label: const Text('Enviar denúncia'),
        ),
      ],
    );
  }
}
