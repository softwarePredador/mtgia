import 'package:dart_frog/dart_frog.dart';

import 'verified_email_middleware.dart';

/// Decisão do dono em 2026-09-23 (extensão do BT-AUTH-010): escrever deck
/// exige e-mail verificado, como importar deck e mexer no fichário.
///
/// Gravar conteúdo de deck é persistir o que define o deck ou uma cópia dele:
/// - o próprio deck: nome, formato, descrição, arquétipo, bracket e
///   visibilidade;
/// - a lista de cartas: adicionar, mudar quantidade, substituir, remover,
///   trocar a lista inteira ou voltar a uma lista anterior;
/// - um deck novo: criar, importar, copiar ou salvar o rascunho do rebuild;
/// - uma cópia pública do conteúdo: o relatório compartilhável.
///
/// Sob `/decks` a regra falha fechado: toda escrita (método que não é GET,
/// HEAD ou OPTIONS) exige e-mail verificado, menos as exceções de
/// [deckWriteVerificationExemptions], cada uma com o porquê. Rota nova sob
/// `/decks` nasce exigindo; tirar a exigência é uma linha nova nessa lista.
bool isDeckContentWrite({required String method, required String path}) {
  final normalizedMethod = method.toUpperCase();
  if (normalizedMethod == 'GET' ||
      normalizedMethod == 'HEAD' ||
      normalizedMethod == 'OPTIONS') {
    return false;
  }
  final normalizedPath =
      path.length > 1 && path.endsWith('/')
          ? path.substring(0, path.length - 1)
          : path;
  if (normalizedPath != '/decks' && !normalizedPath.startsWith('/decks/')) {
    return false;
  }
  return !deckWriteVerificationExemptions.any(
    (exemption) =>
        exemption.method == normalizedMethod &&
        exemption.pattern.hasMatch(normalizedPath),
  );
}

/// Escritas sob `/decks` que não gravam conteúdo de deck.
final deckWriteVerificationExemptions = <DeckWriteVerificationExemption>[
  DeckWriteVerificationExemption(
    'DELETE',
    r'^/decks/[^/]+$',
    'apagar o próprio deck: decisão do dono, remover não pede verificação',
  ),
  DeckWriteVerificationExemption(
    'POST',
    r'^/decks/[^/]+/validate$',
    'cálculo do servidor sobre a lista atual; grava só o estado de validação',
  ),
  DeckWriteVerificationExemption(
    'POST',
    r'^/decks/[^/]+/pricing$',
    'cálculo do servidor sobre a lista atual; grava só o retrato de preço',
  ),
  DeckWriteVerificationExemption(
    'POST',
    r'^/decks/[^/]+/ai-analysis$',
    'cálculo do servidor (IA) sobre a lista atual; grava só a análise',
  ),
  DeckWriteVerificationExemption(
    'POST',
    r'^/decks/[^/]+/recommendations$',
    'cálculo do servidor; só devolve sugestões',
  ),
  DeckWriteVerificationExemption(
    'POST',
    r'^/decks/[^/]+/post-game-notes$',
    'registro privado das partidas, usado pelo pós-jogo do contador de '
        'vida; não muda o deck nem é publicado',
  ),
  DeckWriteVerificationExemption(
    'DELETE',
    r'^/decks/[^/]+/post-game-notes/[^/]+$',
    'apagar registro privado das partidas',
  ),
  DeckWriteVerificationExemption(
    'POST',
    r'^/decks/[^/]+/battle-replays/[^/]+/annotations$',
    'anotação privada de replay; não muda o deck nem é publicada',
  ),
  DeckWriteVerificationExemption(
    'DELETE',
    r'^/decks/[^/]+/battle-replays/[^/]+/annotations/[^/]+$',
    'apagar anotação privada de replay',
  ),
];

class DeckWriteVerificationExemption {
  DeckWriteVerificationExemption(this.method, String pattern, this.reason)
    : pattern = RegExp(pattern);

  final String method;
  final RegExp pattern;
  final String reason;
}

/// Middleware de `/decks`: exige e-mail verificado só nas escritas que gravam
/// conteúdo de deck, com a mesma resposta do fichário e do import.
Middleware verifiedEmailForDeckContentWrites() => verifiedEmailForMutations(
  appliesTo:
      (request) => isDeckContentWrite(
        method: request.method.value,
        path: request.uri.path,
      ),
);
