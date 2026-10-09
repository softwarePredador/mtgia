# Architecture Decision Records

ADRs registram decisões que o código não consegue explicar sozinho: contexto,
intenção, alternativas, consequências, exceções e critérios de revisão.

- Numere arquivos de forma sequencial: `NNNN-titulo-curto.md`.
- Não altere silenciosamente uma decisão aceita; crie um ADR que a substitua.
- Referencie implementações e provas executáveis quando existirem.
- O manifesto valida a existência dos ADRs canônicos e inclui seu conteúdo no
  digest, mas não tenta inferir a intenção da decisão.

## Colisão histórica resolvida

Dois arquivos receberam o número `0004`. O registro
`0004-xmage-human-spike-go.md` permanece apenas como evidência histórica e foi
renumerado canonicamente para `0012-xmage-human-spike-go.md`. Novas referências
devem usar ADR 0012; o ADR 0004 canônico continua sendo o contrato de polling e
checkpoints duráveis de Battle Live.

## Decisão Battle corrente

O ADR 0013 substitui o ADR 0005 quanto ao produto e à UX: a superfície
interativa é **Jogar contra IA**, e Battle Live não é uma visão pública. Os
limites técnicos de privacidade, autenticação, persistência e respostas tipadas
do ADR 0005 continuam válidos.

## Pergunta genérica do motor no Jogar contra IA

O ADR 0014, aceito em 2026-10-08 (D-88), complementa o ADR 0012 (e o registro
histórico `0004-xmage-human-spike-go.md`) e o ADR 0005 sem substituí-los. A
falha fechada deixa de valer para o **texto** de `GAME_ASK` e `GAME_SELECT`:
pergunta de sim/não que não é o mulligan vira o prompt genérico `question`, e
frase de `GAME_SELECT` desconhecida vira `combat` quando o payload traz
atacantes ou bloqueadores possíveis, e `main_action` quando não traz. Método,
payload, limites, IDs opacos e a allowlist de kinds do servidor continuam
fail-closed. O servidor aceita `question` antes ou junto do sidecar.
