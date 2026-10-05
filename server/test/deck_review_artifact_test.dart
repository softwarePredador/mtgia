import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

import '../lib/decks/deck_review_artifact.dart';

/// DCK-P0-02 (decisão D-29 do dono): `DeckReviewArtifact v1`, o artefato
/// único de preview e commit. Liga dono, deck, revisão, assinatura do deck,
/// hashes de entrada e de restrições e expira em 24 h; tamper, outro usuário,
/// deck velho e expirado falham.
void main() {
  const secret = 'test-only-deck-review-secret';
  const owner = '11111111-1111-4111-8111-111111111111';
  const deck = '22222222-2222-4222-8222-222222222222';
  final issuedAt = DateTime.utc(2026, 9, 24, 12);
  final inputHash = canonicalDeckReviewHash({
    'removals': {'a': 1},
    'additions': {'b': 1},
  });
  final constraintsHash = canonicalDeckReviewHash({
    'mode': 'optimize',
    'bracket': 3,
  });

  String issue({
    String kind = 'optimize_apply',
    String ownerId = owner,
    String? deckId = deck,
    int? revision = 7,
    String? signature = 'sig-1',
    Map<String, Object?> body = const {'mode': 'optimize'},
    Duration lifetime = deckReviewArtifactLifetime,
  }) => issueDeckReviewArtifact(
    signingSecret: secret,
    kind: kind,
    ownerId: ownerId,
    deckId: deckId,
    deckRevision: revision,
    deckSignature: signature,
    inputHash: inputHash,
    constraintsHash: constraintsHash,
    body: body,
    issuedAt: issuedAt,
    lifetime: lifetime,
  );

  DeckReviewArtifactVerification verify(
    String token, {
    String ownerId = owner,
    String? deckId = deck,
    int? revision = 7,
    String? signature = 'sig-1',
    String? expectedInputHash,
    String? expectedConstraintsHash,
    DateTime? now,
    String kind = 'optimize_apply',
    String signingSecret = secret,
  }) => verifyDeckReviewArtifact(
    signingSecret: signingSecret,
    token: token,
    expectedKind: kind,
    ownerId: ownerId,
    deckId: deckId,
    currentDeckRevision: revision,
    currentDeckSignature: signature,
    expectedInputHash: expectedInputHash,
    expectedConstraintsHash: expectedConstraintsHash,
    now: now ?? issuedAt.add(const Duration(hours: 1)),
  );

  test('o artefato válido volta com o payload e as chaves do fluxo', () {
    final token = issue();
    final result = verify(
      token,
      expectedInputHash: inputHash,
      expectedConstraintsHash: constraintsHash,
    );

    expect(token, startsWith('drv1.'));
    expect(result.valid, isTrue);
    expect(result.code, 'ok');
    expect(result.payload['version'], deckReviewArtifactVersion);
    expect(result.payload['owner_id'], owner);
    expect(result.payload['deck_revision'], 7);
    expect(result.payload['mode'], 'optimize');
    expect(
      result.payload['expires_at'],
      issuedAt.add(const Duration(hours: 24)).millisecondsSinceEpoch ~/ 1000,
    );
  });

  test('cada recusa tem seu código', () {
    final token = issue();
    final cases = <String, DeckReviewArtifactVerification>{
      'owner_binding_mismatch': verify(
        token,
        ownerId: '33333333-3333-4333-8333-333333333333',
      ),
      'deck_binding_mismatch': verify(
        token,
        deckId: '44444444-4444-4444-8444-444444444444',
      ),
      'stale_deck_revision': verify(token, revision: 8),
      'stale_deck_signature': verify(token, signature: 'sig-2'),
      'expired_token': verify(
        token,
        now: issuedAt.add(const Duration(hours: 24, seconds: 1)),
      ),
      'kind_mismatch': verify(token, kind: 'import_to_deck'),
      'input_mismatch': verify(
        token,
        expectedInputHash: canonicalDeckReviewHash({
          'removals': <String, int>{},
        }),
      ),
      'constraints_mismatch': verify(
        token,
        expectedConstraintsHash: canonicalDeckReviewHash({'mode': 'complete'}),
      ),
      'invalid_signature': verify(token, signingSecret: 'outro-segredo'),
      'signing_secret_unavailable': verify(token, signingSecret: ' '),
    };
    cases.forEach((code, result) {
      expect(result.valid, isFalse, reason: code);
      expect(result.code, code, reason: code);
    });
  });

  test('adulterar payload, assinatura ou prefixo falha', () {
    final token = issue();
    final parts = token.split('.');
    final payload =
        jsonDecode(
              utf8.decode(
                base64Url.decode(
                  '${parts[1]}${'=' * ((4 - parts[1].length % 4) % 4)}',
                ),
              ),
            )
            as Map<String, dynamic>;
    final forgedPayload = base64Url
        .encode(utf8.encode(jsonEncode({...payload, 'owner_id': 'x'})))
        .replaceAll('=', '');

    expect(verify('drv1.$forgedPayload.${parts[2]}').code, 'invalid_signature');
    expect(verify('${parts[0]}.${parts[1]}.AAAA').code, 'invalid_signature');
    expect(verify('drv2.${parts[1]}.${parts[2]}').code, 'malformed_token');
    expect(verify('${parts[1]}.${parts[2]}').code, 'malformed_token');
    expect(verify('drv1.${parts[1]}.***').code, 'malformed_token');
  });

  test('versão desconhecida assinada com o mesmo segredo falha', () {
    final payload = base64Url
        .encode(
          utf8.encode(
            jsonEncode({
              'version': 'deck_review_artifact_v0',
              'kind': 'optimize_apply',
              'owner_id': owner,
              'deck_id': deck,
              'expires_at': 4102444800,
            }),
          ),
        )
        .replaceAll('=', '');
    final signature = base64Url
        .encode(
          Hmac(
            sha256,
            utf8.encode(secret),
          ).convert(utf8.encode('drv1.$payload')).bytes,
        )
        .replaceAll('=', '');

    expect(
      verify('drv1.$payload.$signature', revision: null, signature: null).code,
      'unsupported_version',
    );
  });

  test('o token antigo do Optimize (v2, duas partes) não vale', () {
    expect(
      verify('eyJ2ZXJzaW9uIjoidjIifQ.c2lnbmF0dXJl').code,
      'malformed_token',
    );
  });

  test('revisão e assinatura têm de bater, inclusive quando ausentes', () {
    final withoutRevision = issue(revision: null);
    final withoutDeckState = issue(revision: null, signature: null);

    expect(verify(withoutRevision, revision: null).valid, isTrue);
    expect(verify(withoutRevision, revision: 99).code, 'stale_deck_revision');
    expect(verify(issue(), revision: null).code, 'stale_deck_revision');
    expect(
      verify(withoutRevision, revision: null, signature: 'sig-2').code,
      'stale_deck_signature',
    );
    expect(
      verify(withoutDeckState, revision: null, signature: 'sig-1').code,
      'stale_deck_signature',
    );
    expect(
      verify(withoutDeckState, revision: null, signature: null).valid,
      isTrue,
    );
  });

  test('o mesmo usuário reusa o artefato enquanto vale (D-29)', () {
    final token = issue();

    expect(verify(token).valid, isTrue);
    expect(verify(token).valid, isTrue);
    expect(
      verify(token, now: issuedAt.add(const Duration(hours: 23))).valid,
      isTrue,
    );
  });

  test('o fluxo não sobrescreve chaves reservadas', () {
    expect(() => issue(body: const {'owner_id': 'outro'}), throwsArgumentError);
    expect(() => issue(body: const {'expires_at': 1}), throwsArgumentError);
  });

  test('o hash canônico não depende da ordem das chaves', () {
    expect(
      canonicalDeckReviewHash({
        'b': 1,
        'a': {'y': 2, 'x': 1},
      }),
      canonicalDeckReviewHash({
        'a': {'x': 1, 'y': 2},
        'b': 1,
      }),
    );
    expect(
      canonicalDeckReviewHash({'a': 1}),
      isNot(canonicalDeckReviewHash({'a': 2})),
    );
  });
}
