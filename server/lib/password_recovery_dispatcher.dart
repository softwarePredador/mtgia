import 'dart:async';

import 'package:dart_frog/dart_frog.dart';
import 'package:meta/meta.dart' show visibleForTesting;

import 'auth_service.dart';
import 'logger.dart';
import 'observability.dart';
import 'password_reset_delivery_service.dart';
import 'runtime_environment.dart';

/// Recuperação de senha sem oráculo de tempo (BT-AUTH-003, D-21).
///
/// `POST /auth/forgot-password` responde 202 com o mesmo texto para qualquer
/// e-mail, e o caminho da requisição é o mesmo com ou sem conta: o trabalho
/// que depende da conta (achar a conta, criar o token e entregar o e-mail)
/// roda depois da resposta, num turno seguinte do event loop. Uma falha
/// nesse trabalho vai para o log e a observabilidade, nunca para o cliente.
///
/// Não há fila persistente: se o processo cair entre a resposta e a entrega,
/// o pedido se perde e a pessoa pede de novo (cada pedido novo já invalida o
/// token anterior).
class PasswordRecoveryDispatcher {
  PasswordRecoveryDispatcher({
    required Future<PasswordResetRequest?> Function(String email) createRequest,
    required Future<bool> Function(PasswordResetRequest request) deliver,
    required Future<void> Function(Object error, StackTrace stackTrace)
    reportFailure,
    void Function(Future<void> Function() work)? scheduler,
  }) : _createRequest = createRequest,
       _deliver = deliver,
       _reportFailure = reportFailure,
       _scheduler = scheduler ?? _afterResponse;

  /// Dependências de produção: `AuthService` e `PasswordResetDeliveryService`.
  factory PasswordRecoveryDispatcher.standard({
    required Future<void> Function(Object error, StackTrace stackTrace)
    reportFailure,
  }) => PasswordRecoveryDispatcher(
    createRequest:
        (email) => AuthService().createPasswordResetRequest(email: email),
    deliver:
        (request) => PasswordResetDeliveryService().deliver(
          email: request.email,
          token: request.token,
          expiresAt: request.expiresAt,
        ),
    reportFailure: reportFailure,
  );

  final Future<PasswordResetRequest?> Function(String email) _createRequest;
  final Future<bool> Function(PasswordResetRequest request) _deliver;
  final Future<void> Function(Object error, StackTrace stackTrace)
  _reportFailure;
  final void Function(Future<void> Function() work) _scheduler;

  /// Agenda o pedido inteiro para depois da resposta. Nada aqui depende de o
  /// e-mail ter conta.
  void dispatch(String email) => _scheduler(() => _process(email));

  /// Só no modo de teste (fora de produção, com a frase de aprovação): cria o
  /// token dentro da requisição, para a resposta levar `test_reset_token`, e
  /// deixa a entrega para depois. Falha vira `null`, sem vazar.
  Future<PasswordResetRequest?> createNowAndDispatchDelivery(
    String email,
  ) async {
    final PasswordResetRequest? request;
    try {
      request = await _createRequest(email);
    } catch (error, stackTrace) {
      await _safeReport(error, stackTrace);
      return null;
    }
    if (request case final PasswordResetRequest created) {
      _scheduler(() => _deliverSafely(created));
    }
    return request;
  }

  Future<void> _process(String email) async {
    final PasswordResetRequest? request;
    try {
      request = await _createRequest(email);
    } catch (error, stackTrace) {
      await _safeReport(error, stackTrace);
      return;
    }
    if (request != null) await _deliverSafely(request);
  }

  Future<void> _deliverSafely(PasswordResetRequest request) async {
    try {
      await _deliver(request);
    } catch (error, stackTrace) {
      await _safeReport(error, stackTrace);
    }
  }

  Future<void> _safeReport(Object error, StackTrace stackTrace) async {
    try {
      await _reportFailure(error, stackTrace);
    } catch (_) {
      // Registrar a falha não pode derrubar o processo.
    }
  }

  static void _afterResponse(Future<void> Function() work) {
    // Future(...) começa num turno seguinte do event loop, depois de a rota
    // devolver a resposta.
    unawaited(Future<void>(work));
  }
}

PasswordRecoveryDispatcher Function(RequestContext context)?
_dispatcherOverride;
bool? _tokenExposureOverride;

@visibleForTesting
void overridePasswordRecoveryDispatcherForTesting(
  PasswordRecoveryDispatcher Function(RequestContext context)? factory,
) {
  _dispatcherOverride = factory;
}

@visibleForTesting
void overridePasswordResetTokenExposureForTesting(bool? expose) {
  _tokenExposureOverride = expose;
}

/// O despachante da requisição: falhas do trabalho assíncrono vão para o log
/// (só o tipo do erro, sem e-mail nem token) e para a observabilidade.
PasswordRecoveryDispatcher passwordRecoveryDispatcherFor(
  RequestContext context,
) =>
    _dispatcherOverride?.call(context) ??
    PasswordRecoveryDispatcher.standard(
      reportFailure: (error, stackTrace) async {
        Log.w('[auth_forgot_password] async_failure type=${error.runtimeType}');
        await captureRouteException(
          context,
          error,
          stackTrace: stackTrace,
          tags: const {'route': 'auth_forgot_password', 'stage': 'async'},
        );
      },
    );

/// Se a resposta pode levar `test_reset_token` (nunca em produção).
bool passwordResetTokenExposureEnabled() {
  if (_tokenExposureOverride case final bool expose) return expose;
  final environment = loadRuntimeEnvironment();
  return mayExposePasswordResetTokenForTesting({
    if (environment['ENVIRONMENT'] case final String value)
      'ENVIRONMENT': value,
    if (environment[passwordResetTestResponseEnvironment]
        case final String value)
      passwordResetTestResponseEnvironment: value,
  });
}
