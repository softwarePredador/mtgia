# ManaLoom — continuação da reancoragem P0 e revisão visual integral

Iniciada em: 2026-08-07

Concluída em: 2026-08-10

Digest UI final:
`4aee811479449e64c388e9ebd977ecb1c97e7f9626b38e720afa35cea1c6170c`

Estado:
`PASS_AUTOMATED · PASS_RUNTIME · PASS_VISUAL_REVIEWED · HUMAN_CHECKS_PENDING · COUNSEL_SIGNOFF_LAST`

## Decisão executiva

A reancoragem técnica e visual prevista para esta atividade foi concluída. Os
26 manifests obrigatórios pertencem ao mesmo digest, somam 456 capturas e
foram reconciliados com os arquivos reais sem divergência de caminho,
SHA-256, bytes ou dimensão.

A revisão visual abriu as 456 capturas em 85 pranchas de até seis telas:

- 214 capturas P0: 54 Web mobile, 53 desktop, 53 wide e 54 no Samsung físico;
- cinco capturas de Battle Live;
- 237 capturas focais dos UX-PACKs 02–08;
- nenhum blocker visual;
- nenhuma faixa branca do host Web;
- nenhuma perda permanente de navegação, CTA ou formulário.

O aggregate oficial corrente é
[`docs/qa/ui-live/latest.json`](ui-live/latest.json) e registra
`PASS_AUTOMATED · PASS_RUNTIME · PASS_VISUAL_REVIEWED`.

Isso conclui a prova viva de UI, mas não concede release comercial. TalkBack
humano, teclado Web de hardware real, smoke físico de release e parecer
jurídico externo assinado continuam separados; o parecer jurídico permanece
por último.

## Execução P0 autorizada

A fixture autenticada permaneceu exclusivamente loopback e descartável. O
primeiro build frio do Dart Frog exigiu ampliar o timeout de readiness de 90
segundos para dez minutos, preservando checks de processo, coordenadas
loopback, egress, cleanup e falha fechada.

O Samsung foi atestado como aparelho físico:

- serial ADB: `R58T300SREH`;
- modelo: Samsung SM-A135M;
- Android: 14;
- superfície: 1080×2408;
- emulador: não.

Resultados P0:

| Perfil | Capturas | Digest | Resultado |
|---|---:|---|---|
| Web mobile 390×844 | 54 | `4aee8114…` | `PASS_RUNTIME · VISUAL_REVIEWED` |
| Web desktop 1440×900 | 53 | `4aee8114…` | `PASS_RUNTIME · VISUAL_REVIEWED` |
| Web wide 1920×1080 | 53 | `4aee8114…` | `PASS_RUNTIME · VISUAL_REVIEWED` |
| Samsung SM-A135M físico | 54 | `4aee8114…` | `PASS_RUNTIME · VISUAL_REVIEWED` |

Nenhum emulador recebeu crédito de aparelho físico e nenhum estado `skipped`
foi tratado como saudável.

## Ledger dos 26 manifests e 456 capturas

| Superfície | Manifests | Capturas | Estado |
|---|---:|---:|---|
| P0 Samsung físico | 1 | 54 | `PASS_RUNTIME · VISUAL_REVIEWED` |
| P0 Web mobile/desktop/wide | 3 | 160 | `PASS_RUNTIME · VISUAL_REVIEWED` |
| Battle Live | 1 | 5 | `PASS_RUNTIME · VISUAL_REVIEWED` |
| UX-PACK-02 — Collection Import | 3 | 21 | `PASS_RUNTIME · VISUAL_REVIEWED` |
| UX-PACK-03 — Deck Workshop | 3 | 27 | `PASS_RUNTIME · VISUAL_REVIEWED` |
| UX-PACK-04 — Battle Learning | 3 | 30 | `PASS_RUNTIME · VISUAL_REVIEWED` |
| UX-PACK-05 — Social/Trade | 3 | 48 | `PASS_RUNTIME · VISUAL_REVIEWED` |
| UX-PACK-06 — Onboarding Intent | 3 | 15 | `PASS_RUNTIME · VISUAL_REVIEWED` |
| UX-PACK-07 — Visual System | 3 | 30 | `PASS_RUNTIME · VISUAL_REVIEWED` |
| UX-PACK-08 — Critical Overlays | 3 | 66 | `PASS_RUNTIME · VISUAL_REVIEWED` |
| **Total da política** | **26** | **456** | **`COMPLETE`** |

## Reconciliação técnica final

Os manifests selecionados foram comparados com os arquivos reais:

- manifests esperados/encontrados: `26/26`;
- screenshots declaradas/encontradas: `456/456`;
- caminhos únicos: `456`;
- caminhos duplicados: `0`;
- arquivos ausentes: `0`;
- divergências de SHA-256: `0`;
- divergências de bytes: `0`;
- divergências de dimensão: `0`;
- manifests fora de `PASS_RUNTIME`: `0`;
- manifests fora do digest final: `0`.

## Parecer visual

### Pontos fortes confirmados

- o canvas Web permanece Obsidian de ponta a ponta, inclusive sob overlays;
- onboarding começa pela intenção e conduz a uma ação real;
- Home, decks, Binder, Workshop, Battle e Trade usam cartas e objetos de Magic
  como âncoras visuais;
- estados vazios, loading, saving, erro, retry, reconexão, timeout, conclusão,
  consentimento, sessão expirada e permissão negada explicam o próximo passo;
- revisão de propostas preserva printing, idioma, condição, quantidade, preço
  e diferença de valor;
- overlays destrutivos distinguem cancelar e confirmar e cabem nos viewports;
- formulários e campos permanecem utilizáveis em mobile, desktop e wide.

### Follow-ups não bloqueantes

1. `P1`: recompor telas desktop/wide com pouco conteúdo para aproveitar melhor
   o canvas sem adicionar decoração sem função;
2. `P1`: evitar o truncamento móvel “Visão Ge” nas abas de detalhe de deck;
3. `P2`: estabilizar wrap/ellipsis de identidades muito longas;
4. `P2`: tornar a rolagem horizontal de carrosséis mais explícita;
5. `P2`: substituir “Revisão aaaaaaaa” por fixture determinística realista;
6. `P2`: ajustar o anchor do título “Criar conta” após rolagem de consentimento;
7. `P2`: dar contexto de CTA pai à prova isolada de recuperação de comandante;
8. `P2/LEGAL`: reduzir vazios de Legal/Privacy depois da revisão externa.

Qualquer mudança app-facing futura altera o digest e exige recaptura aplicável.

## Gates executados

No digest final:

- analyzer do `ui-audit`: `PASS`, sem issues;
- testes do `ui-audit`: `56/56 PASS`;
- `./scripts/manaloom_ui_live_evidence_gate.sh --check`: `PASS`;
- `./scripts/quality_gate.sh ui-proof`: `PASS`;
- `./scripts/quality_gate.sh ui-audit`: `PASS`.

## Limpeza da fixture

O resumo final está em:

`/var/folders/33/24q27rwn2v5_h9gfctty7t_40000gn/T/manaloom_visual_qa/20260810T145520Z_79928_3356/cleanup-summary.json`

Ele registrou:

- `database_remaining=0`;
- `web_listeners=0`;
- `api_listeners=0`;
- `credentials_file_removed=true`.

Não houve escrita em PostgreSQL live, Hermes, SQLite ou runtime de produção.

## Ordem restante, com advogado por último

1. executar TalkBack humano no Samsung físico;
2. executar navegação com teclado Web de hardware real;
3. realizar smoke físico de release para câmera, scanner, deep links e
   integrações que estiverem habilitadas no escopo;
4. **por último**, encaminhar o briefing a advogado habilitado e obter parecer
   assinado antes de qualquer lançamento comercial.

O briefing permanece em
[`MANALOOM_EXTERNAL_LEGAL_REVIEW_BRIEF_2026-08-07.md`](MANALOOM_EXTERNAL_LEGAL_REVIEW_BRIEF_2026-08-07.md)
com estado
`OFFICIAL_SOURCE_REVIEW_COMPLETE · LICENSED_COUNSEL_SIGNOFF_PENDING · COMMERCIAL_RELEASE_BLOCKED`.

Nenhum push, migration, deploy, pin, regra, deck, PostgreSQL live, Hermes,
SQLite ou runtime de produção foi alterado.
