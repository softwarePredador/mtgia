@Tags(['live', 'live_backend', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/beta_invites/beta_invite_issuance.dart';
import '../lib/legal_policy.dart';

/// BT-LEGAL-ACCEPT-001 de ponta a ponta, por HTTP contra a API local com a
/// trava ligada (`MANALOOM_LEGAL_REACCEPTANCE=enforce`) e as capabilities
/// `account_registration`, `decks_private`, `deck_replace_all` (para
/// `PUT /decks/:id`), `collection_private` (fichário) e
/// `ai_analyze_optimize_advisory` (`/ai/explain`) ligadas no manifesto
/// isolado. A conta entra por convite com as versões atuais; o teste simula
/// uma versão nova voltando a versão aceita da conta no banco. Criar deck,
/// importar, aplicar o import do fichário e pedir à IA ficam bloqueados com
/// `legal_acceptance_required`; ler, editar e conferir o import seguem
/// livres; o reaceite pela rota libera, e o histórico guarda o cadastro e o
/// reaceite.
///
/// Requer `RUN_LEGAL_ACCEPTANCE_E2E_TESTS=1`, `TEST_API_BASE_URL` e as
/// variáveis `DB_*` do mesmo banco da API.
void main() {
  final enabled = Platform.environment['RUN_LEGAL_ACCEPTANCE_E2E_TESTS'] == '1';
  final skipReason = enabled ? null : 'Requer API local com o reaceite ligado.';
  final baseUrl =
      Platform.environment['TEST_API_BASE_URL'] ?? 'http://127.0.0.1:8082';
  late Pool pool;
  late String token;
  late String userId;
  late String deckId;
  var sequence = 0;

  String unique(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  Map<String, String> headers() => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
    'x-request-id': 'e2e-legal-${++sequence}',
  };

  Map<String, dynamic> json(http.Response response) =>
      jsonDecode(response.body) as Map<String, dynamic>;

  Future<http.Response> createDeck() => http.post(
    Uri.parse('$baseUrl/decks'),
    headers: headers(),
    body: jsonEncode({'name': unique('deck'), 'format': 'commander'}),
  );

  setUpAll(() async {
    if (!enabled) return;
    pool = Pool.withEndpoints([
      Endpoint(
        host: Platform.environment['DB_HOST'] ?? '127.0.0.1',
        port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
        database: Platform.environment['DB_NAME']!,
        username: Platform.environment['DB_USER']!,
        password: Platform.environment['DB_PASS'] ?? '',
      ),
    ], settings: const PoolSettings(sslMode: SslMode.disable));
    final sent = <String, String>{};
    final issuer = BetaInviteIssuer(
      pool,
      deliver: ({
        required String email,
        required String code,
        required DateTime expiresAt,
      }) async {
        sent[email] = code;
        return true;
      },
    );
    final email = '${unique('legal')}@example.invalid';
    await issuer.issue(
      await issuer.plan([email]),
      batchLabel: 'teste-legal',
      validity: const Duration(days: 14),
      issuedBy: 'teste',
    );
    final created = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: const {
        'Content-Type': 'application/json',
        'x-request-id': 'e2e-legal-cadastro',
      },
      body: jsonEncode({
        'username': unique('legal'),
        'email': email,
        'password': 'Convite!Beta-2026',
        'legal_accepted': true,
        'terms_version': currentTermsVersion,
        'privacy_version': currentPrivacyVersion,
        'invite_code': sent[email],
      }),
    );
    expect(created.statusCode, 201, reason: created.body);
    final body = json(created);
    token = body['token'] as String;
    userId = (body['user'] as Map<String, dynamic>)['id'] as String;
  });

  tearDownAll(() async {
    if (!enabled) return;
    await pool.close();
  });

  test(
    'conta em dia: a situação diz que não falta nada e o deck sai',
    () async {
      final status = await http.get(
        Uri.parse('$baseUrl/users/me/legal-acceptance'),
        headers: headers(),
      );
      expect(status.statusCode, 200, reason: status.body);
      expect((json(status)['legal'] as Map)['reacceptance_required'], isFalse);

      final created = await createDeck();
      expect(created.statusCode, anyOf(200, 201), reason: created.body);
      deckId =
          ((json(created)['deck'] ?? json(created)) as Map)['id'] as String;
    },
    skip: skipReason,
  );

  test('versão nova: bloqueia só o deck novo, até o reaceite', () async {
    // A conta passa a ter aceito uma versão antiga, como se os Termos
    // tivessem mudado depois do cadastro.
    await pool.execute(
      Sql.named('''
        UPDATE users SET terms_version = '2026-01-01'
        WHERE id = CAST(@userId AS uuid)
      '''),
      parameters: {'userId': userId},
    );

    final blocked = await createDeck();
    expect(blocked.statusCode, 403, reason: blocked.body);
    final body = json(blocked);
    expect(body['error'], 'legal_acceptance_required');
    expect(body['request_id'], blocked.headers['x-request-id']);
    expect(body['legal'], {
      'accepted_terms_version': '2026-01-01',
      'accepted_privacy_version': currentPrivacyVersion,
      'current_terms_version': currentTermsVersion,
      'current_privacy_version': currentPrivacyVersion,
      'reacceptance_required': true,
      'accept_path': '/users/me/legal-acceptance',
    });

    // Ler e editar o que já existe seguem livres.
    final list = await http.get(
      Uri.parse('$baseUrl/decks'),
      headers: headers(),
    );
    expect(list.statusCode, 200, reason: list.body);
    final edit = await http.put(
      Uri.parse('$baseUrl/decks/$deckId'),
      headers: headers(),
      body: jsonEncode({'name': unique('editado')}),
    );
    expect(edit.statusCode, 200, reason: edit.body);

    // As outras cadeias com a trava: import, fichário e IA. Nada chega ao
    // handler (na IA, nem o limite nem a cota do plano).
    for (final path in ['/import', '/binder/import/apply', '/ai/explain']) {
      final response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: headers(),
        body: jsonEncode({'list': '1 Sol Ring', 'card_name': 'Sol Ring'}),
      );
      expect(response.statusCode, 403, reason: '$path ${response.body}');
      expect(
        json(response)['error'],
        'legal_acceptance_required',
        reason: path,
      );
    }
    // Conferir a lista antes de importar segue livre.
    final validate = await http.post(
      Uri.parse('$baseUrl/import/validate'),
      headers: headers(),
      body: jsonEncode({'list': '1 Sol Ring', 'format': 'commander'}),
    );
    expect(
      validate.body,
      isNot(contains('legal_acceptance_required')),
      reason: '${validate.statusCode}',
    );

    final status = await http.get(
      Uri.parse('$baseUrl/users/me/legal-acceptance'),
      headers: headers(),
    );
    expect((json(status)['legal'] as Map)['reacceptance_required'], isTrue);

    final stale = await http.post(
      Uri.parse('$baseUrl/users/me/legal-acceptance'),
      headers: headers(),
      body: jsonEncode({
        'legal_accepted': true,
        'terms_version': '2026-01-01',
        'privacy_version': currentPrivacyVersion,
      }),
    );
    expect(stale.statusCode, 400, reason: stale.body);
    expect(json(stale)['error'], 'legal_acceptance_required');

    final accepted = await http.post(
      Uri.parse('$baseUrl/users/me/legal-acceptance'),
      headers: headers(),
      body: jsonEncode({
        'legal_accepted': true,
        'terms_version': currentTermsVersion,
        'privacy_version': currentPrivacyVersion,
      }),
    );
    expect(accepted.statusCode, 200, reason: accepted.body);
    expect((json(accepted)['legal'] as Map)['reacceptance_required'], isFalse);

    final created = await createDeck();
    expect(created.statusCode, anyOf(200, 201), reason: created.body);
    final importAfter = await http.post(
      Uri.parse('$baseUrl/import'),
      headers: headers(),
      body: jsonEncode({
        'name': unique('importado'),
        'format': 'commander',
        'list': '1 Sol Ring',
      }),
    );
    expect(
      importAfter.body,
      isNot(contains('legal_acceptance_required')),
      reason: '${importAfter.statusCode}',
    );

    final history = await pool.execute(
      Sql.named('''
        SELECT source, terms_version, request_id
        FROM user_legal_acceptances
        WHERE user_id = CAST(@userId AS uuid)
        ORDER BY id
      '''),
      parameters: {'userId': userId},
    );
    expect(
      [for (final row in history) row.toList()],
      [
        ['register', currentTermsVersion, 'e2e-legal-cadastro'],
        ['reaccept', currentTermsVersion, accepted.headers['x-request-id']],
      ],
    );
  }, skip: skipReason);
}
