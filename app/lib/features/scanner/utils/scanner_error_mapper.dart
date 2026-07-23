import '../../../core/resilience/offline_capability.dart';

enum ScannerErrorStage { camera, capture, processing, search }

/// Converts camera, OCR and lookup failures into short, actionable copy.
///
/// Exception details stay in debug logs; they must never be rendered to the
/// player because plugin and network errors commonly include platform names,
/// paths or transport internals.
class ScannerErrorMapper {
  const ScannerErrorMapper._();

  static String friendly(Object? error, {required ScannerErrorStage stage}) {
    final raw = error?.toString().toLowerCase() ?? '';

    if (_looksLikeNetworkFailure(raw)) {
      return offlineContractFor(
        OfflineProductFlow.cardCatalog,
      ).disconnectedMessage;
    }
    if (raw.contains('timeout') || raw.contains('timed out')) {
      return 'A busca demorou mais que o esperado. Tente novamente em instantes.';
    }
    if (raw.contains('permission') ||
        raw.contains('accessdenied') ||
        raw.contains('access denied')) {
      return 'O acesso à câmera foi bloqueado. Autorize a câmera nas configurações do app.';
    }
    if (raw.contains('camerainuse') ||
        raw.contains('camera in use') ||
        raw.contains('camera is in use')) {
      return 'A câmera está sendo usada por outro app. Feche-o e tente novamente.';
    }

    return switch (stage) {
      ScannerErrorStage.camera =>
        'Não foi possível iniciar a câmera. Feche outros apps que possam estar usando-a e tente novamente.',
      ScannerErrorStage.capture =>
        'Não foi possível capturar a imagem. Mantenha o aparelho firme e tente novamente.',
      ScannerErrorStage.processing =>
        'Não foi possível ler esta carta. Melhore a iluminação, evite reflexos e tente novamente.',
      ScannerErrorStage.search =>
        'Não foi possível buscar esta carta agora. Confira o nome ou tente novamente.',
    };
  }

  static bool _looksLikeNetworkFailure(String raw) {
    return raw.contains('socketexception') ||
        raw.contains('clientexception') ||
        raw.contains('failed host lookup') ||
        raw.contains('connection refused') ||
        raw.contains('connection closed') ||
        raw.contains('network is unreachable') ||
        raw.contains('xmlhttprequest error');
  }
}
