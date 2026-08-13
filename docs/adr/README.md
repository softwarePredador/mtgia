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
