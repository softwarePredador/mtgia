import 'dart:io';

import 'package:test/test.dart';

/// Contrato de privacidade da busca global do marketplace.
///
/// Antes desta guarda, `GET /community/marketplace` devolvia itens de fichário
/// sem ler o observador e sem nenhuma das três proteções que os endpoints
/// irmãos aplicam sobre os MESMOS dados (`user_binder_items` + `users`):
/// `binder_visibility`, `profile_visibility` e `user_blocks`. Fichário de
/// perfil privado e de quem bloqueou o observador aparecia para qualquer um.
///
/// O teste é por comparação com os irmãos, não por string solta: se as
/// proteções saírem do marketplace enquanto continuarem em
/// `/community/binders/:userId`, ele falha.
void main() {
  group('contrato de privacidade do marketplace', () {
    final marketplace =
        File('routes/community/marketplace/index.dart').readAsStringSync();
    final binderPorUsuario =
        File('routes/community/binders/[userId].dart').readAsStringSync();
    final tradeMatches =
        File('lib/community_engagement_service.dart').readAsStringSync();

    test('a rota lê o observador antes de montar a consulta', () {
      expect(
        marketplace,
        contains('readAuthenticatedUserId(context)'),
        reason:
            'sem o observador não há como decidir visibilidade nem bloqueio; '
            'era exatamente o que faltava (a rota nem lia o viewer)',
      );
      expect(
        marketplace,
        contains("sqlParams = <String, dynamic>{'viewerUserId': viewerUserId}"),
        reason:
            'o observador precisa entrar nos parâmetros compartilhados, que '
            'alimentam tanto a contagem quanto a listagem',
      );
    });

    test('as três proteções dos endpoints irmãos estão no marketplace', () {
      const protecoes = <String, String>{
        'binder_visibility':
            "(u.binder_visibility = 'public' OR u.id = CAST(@viewerUserId AS uuid))",
        'profile_visibility':
            "(u.profile_visibility = 'public' OR u.id = CAST(@viewerUserId AS uuid))",
        'user_blocks': 'FROM user_blocks b',
      };

      protecoes.forEach((nome, trecho) {
        expect(
          marketplace,
          contains(trecho),
          reason:
              '$nome é filtrado em /community/binders/:userId e em '
              'findTradeMatches sobre os mesmos dados; o marketplace não pode '
              'ser a porta que escapa',
        );
      });
    });

    test('os irmãos continuam filtrando — a comparação segue válida', () {
      // Se um dia estes caírem, o teste acima vira comparação com o vazio e
      // passaria por acidente. Esta amarra impede isso.
      expect(binderPorUsuario, contains('u.binder_visibility'));
      expect(binderPorUsuario, contains('u.profile_visibility'));
      expect(binderPorUsuario, contains('FROM user_blocks b'));
      expect(tradeMatches, contains('FROM user_blocks b'));
    });

    test('as proteções vivem no WHERE compartilhado, não só na listagem', () {
      // A contagem e a listagem usam a mesma variável `$where`. Se alguém
      // montar uma segunda lista de cláusulas para a contagem, o total volta a
      // vazar (número de itens privados), mesmo com a listagem filtrada.
      final ocorrenciasDeWhereClauses =
          RegExp(r'whereClauses\s*=').allMatches(marketplace).length;
      expect(
        ocorrenciasDeWhereClauses,
        1,
        reason:
            'só pode existir uma lista de cláusulas WHERE nesta rota; a '
            'contagem e a listagem têm de compartilhar as mesmas proteções',
      );
      expect(
        marketplace,
        contains(
          r'final where = whereClauses.join('
          "' AND '"
          r');',
        ),
        reason: 'a junção compartilhada é o que garante o parágrafo acima',
      );
    });

    test('"só seguidores" vale também na busca global (D-38)', () {
      // findTradeMatches já respeitava trade_visibility; o marketplace
      // mostrava a oferta de quem abriu as trocas só para seguidores a
      // qualquer um. A prova em banco está em
      // community_marketplace_trade_visibility_db_live_test.dart.
      for (final trecho in const [
        "u.trade_visibility = 'everyone'",
        "u.trade_visibility = 'followers'",
        'FROM user_follows f',
        'f.follower_id = CAST(@viewerUserId AS uuid)',
        'AND f.following_id = u.id',
      ]) {
        expect(marketplace, contains(trecho), reason: trecho);
      }
      expect(tradeMatches, contains("u.trade_visibility = 'followers'"));
    });

    test('observador anônimo não é tratado como bloqueado', () {
      // `CAST(@viewerUserId AS uuid) IS NULL` é o ramo que mantém o
      // marketplace aberto a quem não está logado — sem ele, a busca pública
      // ficaria vazia para visitante.
      expect(
        marketplace,
        contains('OR CAST(@viewerUserId AS uuid) IS NULL'),
        reason:
            'ninguém bloqueia um anônimo; sem este ramo a proteção de bloqueio '
            'zeraria o marketplace público',
      );
    });
  });
}
