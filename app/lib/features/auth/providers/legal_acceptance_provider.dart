import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/utils/friendly_error_mapper.dart';
import '../../commercial/legal_policy.dart' as legal_policy;

/// Where the account stands with the current Terms and Privacy Policy.
@immutable
class LegalAcceptanceStatus {
  const LegalAcceptanceStatus({
    required this.acceptedTermsVersion,
    required this.acceptedPrivacyVersion,
    required this.currentTermsVersion,
    required this.currentPrivacyVersion,
    required this.reacceptanceRequired,
  });

  /// Reads the `legal` object of `GET /users/me/legal-acceptance` and of the
  /// 403 `legal_acceptance_required` body. Returns null when it is missing.
  static LegalAcceptanceStatus? fromBody(Object? body) {
    if (body is! Map) return null;
    final legal = body['legal'];
    if (legal is! Map) return null;
    String? read(String key) {
      final value = legal[key]?.toString().trim();
      return value == null || value.isEmpty ? null : value;
    }

    final currentTerms = read('current_terms_version');
    final currentPrivacy = read('current_privacy_version');
    if (currentTerms == null || currentPrivacy == null) return null;
    final acceptedTerms = read('accepted_terms_version');
    final acceptedPrivacy = read('accepted_privacy_version');
    final required = legal['reacceptance_required'];
    return LegalAcceptanceStatus(
      acceptedTermsVersion: acceptedTerms,
      acceptedPrivacyVersion: acceptedPrivacy,
      currentTermsVersion: currentTerms,
      currentPrivacyVersion: currentPrivacy,
      reacceptanceRequired: required is bool
          ? required
          : acceptedTerms != currentTerms || acceptedPrivacy != currentPrivacy,
    );
  }

  final String? acceptedTermsVersion;
  final String? acceptedPrivacyVersion;
  final String currentTermsVersion;
  final String currentPrivacyVersion;
  final bool reacceptanceRequired;

  /// True when the text bundled in this app is the version the server asks
  /// for. Accepting a text the person did not read would not be consent.
  bool get appTextIsCurrent =>
      currentTermsVersion == legal_policy.currentTermsVersion &&
      currentPrivacyVersion == legal_policy.currentPrivacyVersion;
}

/// Re-acceptance of updated Terms and Privacy Policy (BT-LEGAL-ACCEPT-001,
/// D-24).
///
/// The server blocks only what creates or shares data (new deck, import, AI)
/// with 403 `legal_acceptance_required`; reading, login, export and account
/// deletion stay free. This provider learns the state from
/// `GET /users/me/legal-acceptance` after login and from any blocked write,
/// asks the app to show the re-acceptance prompt, and records the acceptance
/// of the exact versions bundled in the app.
class LegalAcceptanceProvider extends ChangeNotifier {
  LegalAcceptanceProvider({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  static const endpoint = '/users/me/legal-acceptance';

  final ApiClient _apiClient;
  LegalAcceptanceStatus? _status;
  bool _promptPending = false;
  bool _promptedFromRefresh = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  int _generation = 0;

  LegalAcceptanceStatus? get status => _status;
  bool get reacceptanceRequired => _status?.reacceptanceRequired ?? false;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  /// True when the app should show the prompt. [takePrompt] clears it.
  bool get promptPending => _promptPending;

  /// Returns true once per pending prompt, so one event shows one dialog.
  bool takePrompt() {
    if (!_promptPending) return false;
    _promptPending = false;
    return true;
  }

  /// Reads the current state. A failure keeps the previous state: the server
  /// still enforces the block, so the prompt is only a convenience.
  Future<void> refresh() async {
    final generation = _generation;
    final ApiResponse response;
    try {
      response = await _apiClient.get(endpoint);
    } catch (_) {
      return;
    }
    if (generation != _generation || response.statusCode != 200) return;
    final status = LegalAcceptanceStatus.fromBody(response.data);
    if (status == null) return;
    _status = status;
    // After login the prompt shows once; a blocked write shows it again.
    if (status.reacceptanceRequired && !_promptedFromRefresh) {
      _promptedFromRefresh = true;
      _promptPending = true;
    }
    notifyListeners();
  }

  /// Called with the body of a 403 `legal_acceptance_required`.
  void markRequiredFromBody(Object? body) {
    final status = LegalAcceptanceStatus.fromBody(body);
    if (status != null) {
      _status = status;
    } else if (_status == null || !_status!.reacceptanceRequired) {
      _status = LegalAcceptanceStatus(
        acceptedTermsVersion: _status?.acceptedTermsVersion,
        acceptedPrivacyVersion: _status?.acceptedPrivacyVersion,
        currentTermsVersion:
            _status?.currentTermsVersion ?? legal_policy.currentTermsVersion,
        currentPrivacyVersion:
            _status?.currentPrivacyVersion ??
            legal_policy.currentPrivacyVersion,
        reacceptanceRequired: true,
      );
    }
    _promptPending = true;
    notifyListeners();
  }

  /// Records the acceptance of the versions bundled in this app.
  Future<bool> accept() async {
    if (_isSubmitting) return false;
    final generation = _generation;
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(endpoint, const {
        'legal_accepted': true,
        'terms_version': legal_policy.currentTermsVersion,
        'privacy_version': legal_policy.currentPrivacyVersion,
      });
      if (generation != _generation) return false;
      if (response.statusCode == 200) {
        _status = LegalAcceptanceStatus.fromBody(response.data) ?? _status;
        _promptPending = false;
        return true;
      }
      final serverStatus = LegalAcceptanceStatus.fromBody(response.data);
      if (serverStatus != null && !serverStatus.appTextIsCurrent) {
        _errorMessage =
            'Os Termos mudaram depois desta versão do app. Atualize o app '
            'para ler e aceitar o texto atual.';
      } else {
        _errorMessage = FriendlyErrorMapper.fromApiResponse(
          response,
          fallback: 'Não foi possível registrar o aceite agora. Tente de novo.',
        );
      }
      return false;
    } catch (error) {
      if (generation != _generation) return false;
      _errorMessage = FriendlyErrorMapper.fromException(
        error,
        fallback: 'Não foi possível registrar o aceite agora. Tente de novo.',
      );
      return false;
    } finally {
      if (generation == _generation) {
        _isSubmitting = false;
        notifyListeners();
      }
    }
  }

  /// Forgets everything; called when the account changes or logs out.
  void reset() {
    _generation++;
    _status = null;
    _promptPending = false;
    _promptedFromRefresh = false;
    _isSubmitting = false;
    _errorMessage = null;
    notifyListeners();
  }
}
