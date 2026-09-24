import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:test/test.dart';

// Imports relativos, como os das rotas: `package:server/...` criaria uma
// segunda cópia dos singletons (AuthService, Database) que a rota não vê.
import '../lib/auth_service.dart';
import '../lib/beta_invites/beta_invite_admission_gate.dart';
import '../lib/beta_invites/beta_invite_policy.dart';
import '../lib/database.dart';
import '../lib/legal_policy.dart';
import '../routes/auth/register.dart' as register_route;
import 'support/scripted_pool.dart';

/// BT-AUTH-006: no cadastro por convite, a negativa acontece antes de criar
/// a conta ou enviar e-mail. Estes casos usam um pool roteirizado: qualquer
/// consulta que não esteja no roteiro falha o teste.
void main() {
  const email = 'convidada@example.invalid';
  const code = 'ABCD-EFGH-JKMN-PQRS';
  const statusColumns = [
    'id',
    'email_matches',
    'accepted',
    'revoked',
    'expired',
  ];
  const inviteId = '22222222-2222-4222-8222-222222222222';

  setUp(AuthService.resetForTesting);

  tearDown(() {
    overrideRegistrationAdmissionForTesting(null);
    AuthService.resetForTesting();
    Database.resetForTesting();
  });

  Map<String, Object?> body({Object? inviteCode, String mail = email}) => {
    'username': 'convidada',
    'email': mail,
    'password': 'Convite!Beta-2026',
    'legal_accepted': true,
    'terms_version': currentTermsVersion,
    'privacy_version': currentPrivacyVersion,
    if (inviteCode != null) 'invite_code': inviteCode,
  };

  Future<(int, Map<String, dynamic>)> post(Map<String, Object?> payload) async {
    final response = await register_route.onRequest(
      ScriptedRequestContext(
        Request.post(
          Uri.parse('http://localhost/auth/register'),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode(payload),
        ),
      ),
    );
    return (
      response.statusCode,
      jsonDecode(await response.body()) as Map<String, dynamic>,
    );
  }

  test(
    'modo invite sem convite: 403 invite_required sem tocar o banco',
    () async {
      overrideRegistrationAdmissionForTesting(RegistrationAdmission.invite);
      final pool = ScriptedPool(const []);
      Database.useConnectionForTesting(pool);

      final (status, response) = await post(body());

      expect(status, 403);
      expect(response['error'], 'invite_required');
      expect(response['message'], BetaInviteDenial.required.message);
      expect(pool.executedCount, 0);
    },
  );

  test(
    'código fora do formato: 403 invite_invalid sem tocar o banco',
    () async {
      for (final admission in RegistrationAdmission.values) {
        overrideRegistrationAdmissionForTesting(admission);
        final pool = ScriptedPool(const []);
        Database.useConnectionForTesting(pool);

        final (status, response) = await post(
          body(inviteCode: 'convite-falso'),
        );

        expect(status, 403, reason: admission.name);
        expect(response['error'], 'invite_invalid');
        expect(pool.executedCount, 0);
      }
    },
  );

  test(
    'código desconhecido: nega na checagem de leitura, antes do cadastro',
    () async {
      overrideRegistrationAdmissionForTesting(RegistrationAdmission.invite);
      final pool = ScriptedPool([scriptedResult(columns: statusColumns)]);
      Database.useConnectionForTesting(pool);

      final (status, response) = await post(body(inviteCode: code));

      expect(status, 403);
      expect(response['error'], 'invite_invalid');
      // Só a consulta de estado: nenhum INSERT, nenhuma transação de cadastro.
      expect(pool.executedCount, 1);
      expect(pool.queries.single, contains('FROM beta_invites'));
      expect(pool.queries.single, isNot(contains('FOR UPDATE')));
    },
  );

  for (final (label, row, error, event) in [
    (
      'e-mail diferente',
      [inviteId, false, false, false, false],
      'invite_invalid',
      'denied_email_mismatch',
    ),
    (
      'convite expirado',
      [inviteId, true, false, false, true],
      'invite_expired',
      'denied_expired',
    ),
    (
      'convite revogado',
      [inviteId, true, false, true, false],
      'invite_revoked',
      'denied_revoked',
    ),
    (
      'convite já usado',
      [inviteId, true, true, false, false],
      'invite_already_used',
      'denied_used',
    ),
  ]) {
    test('$label: 403 $error e a recusa entra na auditoria', () async {
      overrideRegistrationAdmissionForTesting(RegistrationAdmission.invite);
      final pool = ScriptedPool([
        scriptedResult(columns: statusColumns, rows: [row]),
        scriptedResult(),
      ]);
      Database.useConnectionForTesting(pool);

      final (status, response) = await post(body(inviteCode: code));

      expect(status, 403);
      expect(response['error'], error);
      expect(pool.executedCount, 2);
      expect(pool.queries.last, contains('INSERT INTO beta_invite_events'));
      final auditParameters = pool.parameters.last! as Map<String, Object?>;
      expect(auditParameters['event'], event);
      expect(auditParameters['inviteId'], inviteId);
      expect(auditParameters['actor'], 'auth_register');
      // Nada de users, nada de e-mail de verificação.
      expect(
        pool.queries.any((query) => query.contains('INSERT INTO users')),
        isFalse,
      );
    });
  }

  test(
    'a checagem de leitura usa o hash do código e o digest do e-mail',
    () async {
      overrideRegistrationAdmissionForTesting(RegistrationAdmission.invite);
      final pool = ScriptedPool([scriptedResult(columns: statusColumns)]);
      Database.useConnectionForTesting(pool);

      await post(
        body(
          inviteCode: code.toLowerCase(),
          mail: ' Convidada@Example.invalid ',
        ),
      );

      final parameters = pool.parameters.single! as Map<String, Object?>;
      expect(
        parameters['tokenHash'],
        betaInviteTokenHash(normalizeBetaInviteCode(code)!),
      );
      expect(parameters['emailDigest'], betaInviteEmailDigest(email));
      expect(jsonEncode(parameters), isNot(contains('ABCD')));
      expect(jsonEncode(parameters), isNot(contains('convidada@')));
    },
  );
}
