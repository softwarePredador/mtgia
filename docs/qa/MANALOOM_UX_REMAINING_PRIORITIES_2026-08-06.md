# ManaLoom — pendências e prioridades UX após o UX-PACK-08

**Atualizado em:** 2026-08-10

**Escopo:** fechamento técnico da auditoria UX integral e ordem restante de
release

**Digest UI final:**
`4aee811479449e64c388e9ebd977ecb1c97e7f9626b38e720afa35cea1c6170c`

## Leitura executiva

- `UX-PACK-01` a `UX-PACK-08`, o polish responsivo autorizado e a correção
  do canvas Web estão concluídos no escopo local.
- Os 26 manifests correntes somam 456 capturas no mesmo digest; todas foram
  abertas e reconciliadas sem divergência de caminho, SHA-256, bytes ou
  dimensão.
- O aggregate oficial em
  [`docs/qa/ui-live/latest.json`](ui-live/latest.json) registra
  `PASS_AUTOMATED · PASS_RUNTIME · PASS_VISUAL_REVIEWED`.
- Evidence gate, `ui-proof` e `ui-audit` passaram; o `ui-audit` concluiu
  analyzer limpo e `56/56` testes.
- A etapa técnica de recaptura P0/aggregate está encerrada. Restam checks
  humanos/hardware e, por último, o parecer jurídico externo assinado.

O ledger completo está em
[`MANALOOM_P0_GLOBAL_REANCHOR_CONTINUATION_2026-08-07.md`](MANALOOM_P0_GLOBAL_REANCHOR_CONTINUATION_2026-08-07.md).

## Estado dos pacotes

| Pacote | Estado atual | Próximo cuidado |
|---|---|---|
| `UX-PACK-01` — identidade/printing | `COMPLETE · CURRENT_REVIEWED` | preservar exact-ID e printing |
| `UX-PACK-02` — coleção | `COMPLETE · CURRENT_REVIEWED` | localização estruturada e scanner são decisões futuras |
| `UX-PACK-03` — Workshop/Optimize | `COMPLETE · CURRENT_REVIEWED` | preservar preview, decisão humana, histórico e undo |
| `UX-PACK-04` — partida/aprendizado | `COMPLETE · CURRENT_REVIEWED` | preservar privacidade, replay e handoff pós-jogo |
| `UX-PACK-05` — social/trades | `COMPLETE · CURRENT_REVIEWED` | pagamento, entrega e disputa exigem contratos próprios |
| `UX-PACK-06` — onboarding/Home | `COMPLETE · CURRENT_REVIEWED` | progresso cross-device exige contrato backend próprio |
| `UX-PACK-07` — sistema visual/wide | `COMPLETE · CURRENT_REVIEWED` | priorizar densidade adaptativa como próxima frente de polish |
| `UX-PACK-08` — estados/prova/acessibilidade | `COMPLETE · CURRENT_REVIEWED` | executar checks humanos separados |
| Canvas Web Obsidian | `COMPLETE · CURRENT_REVIEWED` | impedir regressão para fundo branco |
| Aggregate global | `26/26 · 456/456 · PASS` | invalidar e recapturar quando houver nova mudança app-facing |

## Evidência corrente

| Superfície | Manifests | Capturas | Estado |
|---|---:|---:|---|
| P0 Web mobile/desktop/wide | 3 | 160 | `PASS_RUNTIME · VISUAL_REVIEWED` |
| Samsung SM-A135M físico | 1 | 54 | `PASS_RUNTIME · VISUAL_REVIEWED` |
| Battle Live | 1 | 5 | `PASS_RUNTIME · VISUAL_REVIEWED` |
| UX-PACKs 02–08 | 21 | 237 | `PASS_RUNTIME · VISUAL_REVIEWED` |
| **Política total** | **26** | **456** | **`GLOBAL_AGGREGATE_PASS`** |

## Prioridades restantes

### P0-A — verificações humanas e de hardware

Estas verificações continuam obrigatórias para release, mas não invalidam o
fechamento técnico da auditoria:

1. TalkBack humano no Samsung físico;
2. navegação Web com teclado de hardware real;
3. smoke de câmera, scanner, deep links e comportamento de release no aparelho
   físico, somente onde a feature estiver habilitada;
4. VoiceOver/iOS se iOS entrar no escopo da release.

Widget test, golden, emulador e inspeção automatizada não substituem esses
checks.

### P0-B — parecer jurídico externo assinado, por último

Depois dos checks humanos/hardware, encaminhar o briefing a advogado
habilitado para revisar LGPD, menores, consumidor, termos, beta/Pro,
social/trades, transferências internacionais e propriedade intelectual.

Até existir parecer assinado, o lançamento comercial permanece bloqueado. A
pesquisa preparada pelo Codex organiza fontes e perguntas, mas não constitui
parecer jurídico e não substitui responsabilidade profissional.

Briefing:
[`MANALOOM_EXTERNAL_LEGAL_REVIEW_BRIEF_2026-08-07.md`](MANALOOM_EXTERNAL_LEGAL_REVIEW_BRIEF_2026-08-07.md).

## Próxima frente app-facing recomendada

Quando o responsável sinalizar uma nova rodada de UI, a ordem sugerida é:

| Prioridade | Tema | Resultado esperado |
|---|---|---|
| `P1` | composição adaptativa desktop/wide | usar melhor o canvas em resultados únicos, vazios e superfícies administrativas |
| `P1` | abas compactas de detalhe de deck | substituir “Visão Ge” por affordance legível e acessível |
| `P2` | nomes e identidades longas | aplicar wrap/ellipsis consistente sem perder o nome acessível |
| `P2` | carrosséis móveis | tornar a possibilidade de rolagem horizontal explícita |
| `P2` | fixtures realistas | remover “Revisão aaaaaaaa” e usernames artificiais |
| `P2` | consentimento no cadastro | corrigir o anchor do título “Criar conta” após scroll |
| `P2` | prova de recuperação do comandante | mostrar o contexto do CTA pai, reduzindo vazio focal |
| `P2/LEGAL` | Legal/Privacy | ajustar conteúdo e composição depois do parecer externo |

Esses itens são não bloqueantes para a evidência atual. Iniciá-los muda o
digest e requer recaptura aplicável.

## Backlog de produto não autorizado nesta atividade

| Tema | Condição para iniciar |
|---|---|
| localização estruturada da coleção | definir área/caixa/fichário/posição antes de migration |
| scanner físico | homologar flag, hardware, permissão, fallback e contrato de release |
| onboarding cross-device | definir persistência backend e política de sincronização |
| pagamento, entrega, disputa e localização em Trade | definir mediação, privacidade, fraude, suporte e responsabilidades |
| compartilhamento estruturado, diff e thread de feedback | promover a frente a pacote próprio com critérios de aceite |

Nenhum desses itens autoriza migration, PostgreSQL live, Hermes/SQLite, deploy,
push, pins, regras ou decks.

## Próximo sinal operacional

Para continuar trabalhando no app sem misturar o fechamento da auditoria com
uma nova recaptura, o sinal recomendado é:

```text
INICIAR POLISH UX P1 — COMPOSIÇÃO ADAPTATIVA DESKTOP/WIDE
```

O parecer jurídico permanece a última etapa de release comercial.
