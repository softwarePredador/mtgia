import 'dart:math';

import 'package:test/test.dart';

import '../lib/beta_invites/beta_invite_admission_gate.dart';
import '../lib/beta_invites/beta_invite_cli.dart';
import '../lib/beta_invites/beta_invite_delivery_service.dart';
import '../lib/beta_invites/beta_invite_policy.dart';

/// BT-AUTH-006 (D-16, D-56): regras puras da admissão por convite, do
/// portão do cadastro e do script do dono.
void main() {
  group('modo de admissão', () {
    RegistrationAdmission admission(Map<String, String> environment) =>
        RegistrationAdmission.fromEnvironment(environment);

    test('produção exige convite, salvo open explícito', () {
      expect(
        admission({'ENVIRONMENT': 'production'}),
        RegistrationAdmission.invite,
      );
      expect(
        admission({
          'ENVIRONMENT': 'production',
          registrationAdmissionEnvironment: 'open',
        }),
        RegistrationAdmission.open,
      );
    });

    test('valor desconhecido fecha em convite, também fora da produção', () {
      for (final value in ['opne', 'aberto', 'true', '1', 'INVITE']) {
        expect(
          admission({registrationAdmissionEnvironment: value}),
          RegistrationAdmission.invite,
          reason: value,
        );
        expect(
          admission({
            'ENVIRONMENT': 'production',
            registrationAdmissionEnvironment: value,
          }),
          RegistrationAdmission.invite,
          reason: value,
        );
      }
    });

    test('fora da produção o cadastro fica aberto sem configuração', () {
      expect(admission(const {}), RegistrationAdmission.open);
      expect(
        admission({registrationAdmissionEnvironment: ' Open '}),
        RegistrationAdmission.open,
      );
    });
  });

  group('código do convite', () {
    final formatted = RegExp(
      r'^[0-9A-HJKMNP-TV-Z]{4}-[0-9A-HJKMNP-TV-Z]{4}-'
      r'[0-9A-HJKMNP-TV-Z]{4}-[0-9A-HJKMNP-TV-Z]{4}$',
    );

    test('tem 16 símbolos de Crockford e não repete', () {
      final codes = {for (var i = 0; i < 500; i++) newBetaInviteCode()};
      expect(codes, hasLength(500));
      for (final code in codes) {
        expect(code, matches(formatted));
        expect(normalizeBetaInviteCode(code), hasLength(16));
      }
    });

    test('normaliza caixa, espaços, hífens e letras parecidas', () {
      final code = newBetaInviteCode(random: Random(7));
      final compact = code.replaceAll('-', '');
      expect(normalizeBetaInviteCode(code.toLowerCase()), compact);
      expect(
        normalizeBetaInviteCode(
          ' ${compact.substring(0, 8)} ${compact.substring(8)} ',
        ),
        compact,
      );
      expect(
        normalizeBetaInviteCode('OOOO-IIII-LLLL-0000'),
        '0000111111110000',
      );
    });

    test('recusa o que não é código', () {
      for (final raw in <Object?>[
        null,
        42,
        '',
        'ABCD-EFGH',
        'ABCD-EFGH-JKMN-PQRS-TVWX',
        'UUUU-UUUU-UUUU-UUUU',
        'ABCD-EFGH-JKMN-PQR!',
        'A' * 65,
      ]) {
        expect(normalizeBetaInviteCode(raw), isNull, reason: '$raw');
      }
    });

    test('hash e digest estáveis, sem o valor cru', () {
      final code = normalizeBetaInviteCode(newBetaInviteCode())!;
      final hash = betaInviteTokenHash(code);
      expect(hash, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(betaInviteTokenHash(code), hash);
      expect(hash, isNot(contains(code.toLowerCase())));
      expect(
        betaInviteEmailDigest(' Pessoa@Example.COM '),
        betaInviteEmailDigest('pessoa@example.com'),
      );
      expect(
        betaInviteEmailDigest('pessoa@example.com'),
        isNot(betaInviteTokenHash(code)),
      );
      expect(
        betaInviteRateLimitIdentifier(code),
        allOf(startsWith('invite:'), isNot(contains(code))),
      );
    });

    test('pista do e-mail mascara a parte local', () {
      expect(
        betaInviteEmailHint('Joao.Silva@Example.com'),
        'jo***@example.com',
      );
      expect(betaInviteEmailHint('ab@example.com'), 'a***@example.com');
      expect(betaInviteEmailHint('sem-arroba'), '***');
    });
  });

  group('decisão do convite', () {
    BetaInviteStatus status({
      bool emailMatches = true,
      bool accepted = false,
      bool revoked = false,
      bool expired = false,
    }) => BetaInviteStatus(
      inviteId: 'convite-1',
      emailMatches: emailMatches,
      accepted: accepted,
      revoked: revoked,
      expired: expired,
    );

    test('código desconhecido: invalid, sem trilha', () {
      final denied = evaluateBetaInvite(null)!;
      expect(denied.denial, BetaInviteDenial.invalid);
      expect(denied.inviteId, isNull);
      expect(denied.auditEvent, isNull);
    });

    test('e-mail diferente vem antes de tudo e não revela o estado', () {
      for (final other in [
        status(emailMatches: false),
        status(emailMatches: false, accepted: true),
        status(emailMatches: false, revoked: true),
        status(emailMatches: false, expired: true),
      ]) {
        final denied = evaluateBetaInvite(other)!;
        expect(denied.denial, BetaInviteDenial.invalid);
        expect(denied.auditEvent, 'denied_email_mismatch');
      }
    });

    test('usado, revogado e expirado têm códigos próprios', () {
      expect(
        evaluateBetaInvite(status(accepted: true, expired: true))!.denial,
        BetaInviteDenial.alreadyUsed,
      );
      expect(
        evaluateBetaInvite(status(revoked: true, expired: true))!.denial,
        BetaInviteDenial.revoked,
      );
      final expired = evaluateBetaInvite(status(expired: true))!;
      expect(expired.denial, BetaInviteDenial.expired);
      expect(expired.auditEvent, 'denied_expired');
      expect(expired.inviteId, 'convite-1');
      expect(evaluateBetaInvite(status()), isNull);
    });

    test('negativas públicas: 403, código snake_case e frase em português', () {
      for (final denial in BetaInviteDenial.values) {
        expect(denial.statusCode, 403);
        expect(denial.code, matches(RegExp(r'^invite_[a-z_]+$')));
        expect(denial.toJson(), {
          'error': denial.code,
          'message': denial.message,
        });
        expect(denial.message, isNotEmpty);
      }
    });
  });

  group('portão do cadastro', () {
    test('modo invite sem código nega com invite_required', () {
      for (final raw in <Object?>[null, '', '   ']) {
        final gate = BetaInviteAdmissionGate.evaluate(
          admission: RegistrationAdmission.invite,
          rawInviteCode: raw,
        );
        expect(gate.denial, BetaInviteDenial.required, reason: '$raw');
      }
    });

    test('modo open sem código segue, sem convite', () {
      final gate = BetaInviteAdmissionGate.evaluate(
        admission: RegistrationAdmission.open,
        rawInviteCode: null,
      );
      expect(gate.denial, isNull);
      expect(gate.inviteCode, isNull);
    });

    test('código fora do formato nega com invite_invalid nos dois modos', () {
      for (final admission in RegistrationAdmission.values) {
        final gate = BetaInviteAdmissionGate.evaluate(
          admission: admission,
          rawInviteCode: 'nao-e-convite',
        );
        expect(gate.denial, BetaInviteDenial.invalid);
      }
    });

    test('código válido segue normalizado', () {
      final gate = BetaInviteAdmissionGate.evaluate(
        admission: RegistrationAdmission.invite,
        rawInviteCode: 'abcd-efgh-jkmn-pqrs',
      );
      expect(gate.denial, isNull);
      expect(gate.inviteCode, 'ABCDEFGHJKMNPQRS');
    });
  });

  group('script do dono', () {
    test('emitir exige lote válido e e-mails', () {
      expect(
        () => parseBetaInviteArgs(['emitir', '--email', 'a@example.com']),
        throwsA(isA<BetaInviteUsageException>()),
      );
      expect(
        () => parseBetaInviteArgs([
          'emitir',
          '--lote',
          'Lote Maiusculo',
          '--email',
          'a@example.com',
        ]),
        throwsA(isA<BetaInviteUsageException>()),
      );
      expect(
        () => parseBetaInviteArgs(['emitir', '--lote', 'beta-a']),
        throwsA(isA<BetaInviteUsageException>()),
      );
      final options = parseBetaInviteArgs([
        'emitir',
        '--lote',
        'beta-2026-10-a',
        '--email',
        'a@example.com',
        '--email',
        'b@example.com',
        '--validade-dias',
        '7',
      ]);
      expect(options.command, BetaInviteCommand.emitir);
      expect(options.apply, isFalse, reason: 'sem --aplicar é simulação');
      expect(options.emails, ['a@example.com', 'b@example.com']);
      expect(options.validity, const Duration(days: 7));
      expect(options.issuedBy, 'dono');
    });

    test('validade de 1 a 60 dias e argumentos desconhecidos recusados', () {
      for (final days in ['0', '61', 'x']) {
        expect(
          () => parseBetaInviteArgs([
            'emitir',
            '--lote',
            'b',
            '--email',
            'a@example.com',
            '--validade-dias',
            days,
          ]),
          throwsA(isA<BetaInviteUsageException>()),
          reason: days,
        );
      }
      expect(
        () => parseBetaInviteArgs(['listar', '--apagar-tudo']),
        throwsA(isA<BetaInviteUsageException>()),
      );
      expect(
        () => parseBetaInviteArgs(['listar', '--aplicar']),
        throwsA(isA<BetaInviteUsageException>()),
      );
      expect(
        () => parseBetaInviteArgs(['convidar-todo-mundo']),
        throwsA(isA<BetaInviteUsageException>()),
      );
    });

    test('revogar pede um alvo só e um motivo', () {
      expect(
        () => parseBetaInviteArgs(['revogar', '--email', 'a@example.com']),
        throwsA(isA<BetaInviteUsageException>()),
      );
      expect(
        () => parseBetaInviteArgs([
          'revogar',
          '--email',
          'a@example.com',
          '--convite',
          'x',
          '--motivo',
          'pedido',
        ]),
        throwsA(isA<BetaInviteUsageException>()),
      );
      final options = parseBetaInviteArgs([
        'revogar',
        '--convite',
        '0b8c',
        '--motivo',
        'pedido do dono',
        '--aplicar',
      ]);
      expect(options.inviteId, '0b8c');
      expect(options.apply, isTrue);
    });

    test('lista de e-mails ignora vazias e comentários', () {
      expect(
        readBetaInviteEmails(
          '# lote de outubro\na@example.com\n\n  b@example.com  \n#c@example.com\n',
        ),
        ['a@example.com', 'b@example.com'],
      );
    });

    test('lote tem no máximo 30 e-mails distintos (D-16)', () {
      final thirty = [for (var i = 0; i < 30; i++) 'p$i@example.com'];
      checkBetaInviteBatchSize([...thirty, 'P0@example.com', 'invalido']);
      expect(
        () => checkBetaInviteBatchSize([...thirty, 'p30@example.com']),
        throwsA(isA<BetaInviteUsageException>()),
      );
      expect(
        () => checkBetaInviteBatchSize(['sem-arroba']),
        throwsA(isA<BetaInviteUsageException>()),
      );
    });

    test('--aplicar exige as duas aprovações e o wrapper fora do loopback', () {
      const approved = {
        'MANALOOM_CONFIRM_POSTGRES_WRITES': 'I_HAVE_EXPLICIT_APPROVAL',
        'MANALOOM_CONFIRM_LIVE_MUTATIONS': 'I_HAVE_EXPLICIT_APPROVAL',
      };
      expect(
        betaInviteWriteBlockedReason(apply: false, environment: const {}),
        isNull,
      );
      expect(
        betaInviteWriteBlockedReason(apply: true, environment: const {}),
        isNotNull,
      );
      expect(
        betaInviteWriteBlockedReason(
          apply: true,
          environment: {
            'MANALOOM_CONFIRM_POSTGRES_WRITES': 'I_HAVE_EXPLICIT_APPROVAL',
          },
        ),
        isNotNull,
      );
      expect(
        betaInviteWriteBlockedReason(
          apply: true,
          environment: {...approved, 'DB_HOST': '127.0.0.1'},
        ),
        isNull,
      );
      expect(
        betaInviteWriteBlockedReason(
          apply: true,
          environment: {...approved, 'DB_HOST': 'db.exemplo.com'},
        ),
        isNotNull,
      );
      expect(
        betaInviteWriteBlockedReason(
          apply: true,
          environment: {
            ...approved,
            'DB_HOST': 'db.exemplo.com',
            'MANALOOM_PG_WRAPPER_MODE': 'write-approved',
          },
        ),
        isNull,
      );
    });

    test('link do convite leva o código no parâmetro invite_code', () {
      expect(
        betaInviteActionUrl({
          betaInviteAppUrlEnvironment: 'https://brewtact.com/app/#/register',
        }, 'ABCD-EFGH-JKMN-PQRS'),
        'https://brewtact.com/app/#/register?invite_code=ABCD-EFGH-JKMN-PQRS',
      );
      expect(
        betaInvitePreview(const {}, const Duration(days: 14)),
        allOf(
          contains('invite_code=XXXX-XXXX-XXXX-XXXX'),
          contains('Código do convite: XXXX-XXXX-XXXX-XXXX'),
        ),
      );
    });
  });
}
