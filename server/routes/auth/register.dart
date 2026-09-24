import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../../lib/auth_service.dart';
import '../../lib/beta_invites/beta_invite_admission_gate.dart';
import '../../lib/beta_invites/beta_invite_policy.dart';
import '../../lib/beta_invites/beta_invite_store.dart';
import '../../lib/database.dart';
import '../../lib/email_verification_delivery_service.dart';
import '../../lib/email_verification_policy.dart';
import '../../lib/legal_policy.dart';
import '../../lib/observability.dart';
import '../../lib/password_policy.dart';
import '../../lib/rate_limit_middleware.dart';
import '../../lib/request_trace.dart';
import '../../lib/runtime_environment.dart';

/// Registro de novo usuário com gravação no banco de dados
///
/// POST /auth/register
/// Body: {"username": "joao", "email": "joao@example.com", "password": "senha123",
///        "invite_code": "XXXX-XXXX-XXXX-XXXX"}
///
/// Admissão por convite (BT-AUTH-006, D-16): no modo `invite` (padrão da
/// produção), sem convite válido para o e-mail o cadastro é negado antes de
/// criar a conta ou enviar e-mail. Convite aceito verifica o e-mail (D-56).
///
/// Retorna:
/// - 201: {token, user: {id, username, email, email_verified}, admission}
/// - 400: Validação falhou ou username/email já existe
/// - 403: invite_required, invite_invalid, invite_expired, invite_revoked,
///   invite_already_used
/// - 429: muitas tentativas (por IP, por e-mail ou por código de convite)
/// - 500: Erro interno
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final username = (body['username'] as String?)?.trim();
    final email = (body['email'] as String?)?.trim();
    final password = body['password'] as String?;
    final runtime = loadRuntimeEnvironment();
    final environment = <String, String>{
      if (runtime['ENVIRONMENT'] case final String value) 'ENVIRONMENT': value,
      if (runtime[requireLegalAcceptanceEnvironment] case final String value)
        requireLegalAcceptanceEnvironment: value,
    };

    // Portão do convite: sem convite no modo `invite`, ou com um código que
    // nem tem o formato de convite, nega aqui, antes de qualquer consulta.
    final gate = BetaInviteAdmissionGate.evaluate(
      admission: registrationAdmission(),
      rawInviteCode: body['invite_code'],
    );
    if (gate.denial case final BetaInviteDenial denial) {
      BetaInviteAdmission.logDenial(denial, requestId: _requestId(context));
      return Response.json(
        statusCode: denial.statusCode,
        body: denial.toJson(),
      );
    }
    final inviteCode = gate.inviteCode;

    final legalAcceptance = LegalAcceptancePolicy.parse(
      body,
      required: LegalAcceptancePolicy.isRequired(environment),
    );

    // Validações básicas
    if (username == null || username.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'Nome de usuário é obrigatório'},
      );
    }

    if (email == null || email.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'Email é obrigatório'},
      );
    }

    if (password == null || password.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'Senha é obrigatória'},
      );
    }

    if (username.length < 3) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'Nome de usuário deve ter no mínimo 3 caracteres'},
      );
    }

    final passwordValidation = PasswordPolicy.validate(
      password,
      username: username,
      email: email,
    );
    if (!passwordValidation.isValid) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'error': passwordValidation.code,
          'message': passwordValidation.message,
        },
      );
    }

    // Limites distribuídos na produção: por código de convite e por e-mail,
    // além do limite por IP do middleware de /auth.
    if (inviteCode != null) {
      final limited = await betaInviteCodeRateLimitResponse(
        context,
        identifier: betaInviteRateLimitIdentifier(inviteCode),
      );
      if (limited != null) return limited;
    }
    final emailLimited = await credentialEmailRateLimitResponse(
      context,
      email: email,
      bucket: CredentialEmailBucket.registration,
    );
    if (emailLimited != null) return emailLimited;

    final requestId = _requestId(context);
    final invite =
        inviteCode == null
            ? null
            : BetaInviteClaim(code: inviteCode, requestId: requestId);
    if (invite != null) {
      // Checagem só de leitura antes do bcrypt; a que vale é a da transação.
      final denied = await BetaInviteAdmission.preflight(
        Database().connection,
        code: invite.code,
        email: email,
      );
      if (denied != null) {
        await BetaInviteAdmission.recordDenial(
          Database().connection,
          denied,
          requestId: requestId,
        );
        return Response.json(
          statusCode: denied.denial.statusCode,
          body: denied.denial.toJson(),
        );
      }
    }

    // Registrar no banco de dados
    final authService = AuthService();
    final Map<String, dynamic> result;
    try {
      result = await authService.register(
        username: username,
        email: email,
        password: password,
        legalAcceptance: legalAcceptance,
        invite: invite,
      );
    } on BetaInviteDeniedException catch (denied) {
      await BetaInviteAdmission.recordDenial(
        Database().connection,
        denied,
        requestId: requestId,
      );
      return Response.json(
        statusCode: denied.denial.statusCode,
        body: denied.denial.toJson(),
      );
    }

    if (result['emailVerified'] == true) {
      // O convite chegou por este e-mail: a conta nasce verificada e não há
      // e-mail de verificação a mandar (D-56).
      return Response.json(
        statusCode: HttpStatus.created,
        body: {
          'token': result['token'],
          'user': {
            'id': result['userId'],
            'username': result['username'],
            'email': result['email'],
            'email_verified': true,
          },
          'verification_sent': false,
          'admission': 'invite',
        },
      );
    }

    final verificationRequest = EmailVerificationRequest(
      email: result['email'] as String,
      token: result['emailVerificationToken'] as String,
      expiresAt: result['emailVerificationExpiresAt'] as DateTime,
    );
    var verificationSent = false;
    try {
      verificationSent = await EmailVerificationDeliveryService().deliver(
        email: verificationRequest.email,
        token: verificationRequest.token,
        expiresAt: verificationRequest.expiresAt,
      );
    } catch (error, stackTrace) {
      await captureRouteException(
        context,
        error,
        stackTrace: stackTrace,
        tags: const {'route': 'auth_register_email_verification'},
      );
    }
    final verificationEnvironment = emailVerificationEnvironmentValues();

    return Response.json(
      statusCode: HttpStatus.created,
      body: {
        'token': result['token'],
        'user': {
          'id': result['userId'],
          'username': result['username'],
          'email': result['email'],
          'email_verified': false,
        },
        'verification_sent': verificationSent,
        'admission': 'open',
        if (mayExposeEmailVerificationTokenForTesting(verificationEnvironment))
          'test_verification_token': verificationRequest.token,
      },
    );
  } on LegalAcceptanceException catch (error) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': error.code, 'message': error.message},
    );
  } on Exception catch (e) {
    print('[ERROR] handler: $e');
    // Erros de negócio (username/email duplicado, etc)
    final message = e.toString().replaceFirst('Exception: ', '');
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'message': message},
    );
  } catch (e, stackTrace) {
    print('[ERROR] handler: $e');
    print('Erro ao criar conta: $e');
    await captureRouteException(
      context,
      e,
      stackTrace: stackTrace,
      tags: const {'route': 'auth_register'},
    );
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Erro ao criar conta'},
    );
  }
}

String? _requestId(RequestContext context) {
  try {
    return context.read<RequestTrace>().requestId;
  } on Object {
    return null;
  }
}
