# ManaLoom UX-PACK-03 — implementação e evidência local

Data: 2026-08-05
Estado: `COMPLETE_LOCAL · FOCAL_WEB_VISUAL_PASS · GLOBAL_P0_AUTH_PENDING`
Autorização: continuação explícita do usuário — “okay então pode prosseguir”.

## Resultado

O pacote deixou de tratar geração, import e Optimize como formulários e listas
desconectadas. O fluxo local agora funciona como uma oficina de deck:

```text
comandante/objetivo
  → preflight sem escrita
  → fontes e impacto
  → trocas pareadas sai ↔ entra
  → validação
  → aplicação registrada
  → histórico/undo seguro
  → mão inicial ou Battle/replays
```

O eixo visual é comandante/arte primeiro, Brass para decisões e Frost para
evidência. A IA propõe; legalidade, assinatura do deck, persistência e conflito
continuam backend-owned.

## Escopo implementado

### Geração

- `DeckGenerateScreen` mantém o campo de nome compatível, mas adiciona a seleção
  canônica de comandante por `DeckCardItem`;
- a confirmação mostra arte, nome, tipo e identidade de cor antes da proposta;
- texto livre sem objeto selecionado permanece explicitamente não confirmado.

### Import de deck

- o primeiro CTA chama `POST /import/validate`; nenhuma criação ocorre;
- o preflight mostra total detectado, identidades reconhecidas, nomes
  localizados, linhas não identificadas, warnings e uma faixa de artes;
- somente o segundo CTA cria o deck, com copy distinta para deck revisado ou
  rascunho com pendências;
- o comandante informado participa do mesmo preflight da criação real, evitando
  falso warning de comandante ausente;
- a decklist resolve identidade jogável. Nenhuma cópia física/printing do Binder
  é inferida, conforme ADR 0008.

### Optimize

- remoção e adição deixaram de ser checkboxes independentes: uma única decisão
  controla o par `sai ↔ entra`;
- cada lado preserva motivo, função, prioridade, risco, confiança, custo,
  coleção, bracket e reader de carta;
- seleção parcial avisa que curva, terrenos e indicadores globais serão
  recalculados no servidor;
- fontes, shells de referência e impacto antes/depois ficam no ponto de decisão.

### Oficina e undo persistente

- `DeckDetailsScreen` ganhou a aba `Oficina`;
- comandante, estratégia, bracket e legalidade formam o hero da revisão;
- a trilha `Objetivo → Trocas pareadas → Validação → Teste em jogo` torna o
  próximo passo explícito;
- histórico PostgreSQL mostra pares aplicados, fonte, validação e pendência de
  teste;
- `Desfazer aplicação` permanece no evento; não depende do snackbar;
- edição posterior desabilita rollback e produz explicação inline. O POST de
  rollback ainda revalida tudo sob lock e nunca sobrescreve drift.

## Contrato backend e dados

Foi adicionado somente o endpoint read-only:

```text
GET /decks/:id/optimizations
```

Propriedades:

- exige autenticação e filtra por `deck_id` + `user_id`;
- lista no máximo os 20 eventos mais recentes;
- devolve somente resumos públicos de mudanças e fontes;
- não expõe `before_snapshot`, `after_snapshot`, payload bruto de recomendação
  nem report payload;
- `can_rollback` é advisory e deriva da assinatura exata atual, disponibilidade
  de snapshots e rollback anterior;
- o POST existente revalida a autorização sob lock.

PostgreSQL permanece verdade. A tabela existente `deck_optimization_events` foi
reutilizada. Não houve migration, escrita live, Hermes/SQLite, alteração de pin,
runtime ou deploy.

## Principais artefatos

- app:
  - `app/lib/features/decks/models/deck_optimization_event.dart`;
  - `app/lib/features/decks/widgets/deck_workshop_tab.dart`;
  - providers de deck/import/mutation;
  - screens de generate, import e details;
  - widgets de commander e Optimize;
- backend:
  - `server/routes/decks/[id]/optimizations/index.dart`;
  - `server/routes/import/validate/index.dart`;
- prova:
  - `app/integration_test/deck_workshop_visual_runtime_proof_test.dart`;
  - `scripts/manaloom_deck_workshop_visual_qa.sh`;
  - política/digest de evidência visual.

## Evidência automatizada e runtime

O harness usa build Web real em release, API controlada, servidor loopback para
assets governados e exatamente oito checkpoints:

1. `deck_workshop_00_commander`;
2. `deck_workshop_01_import_preflight`;
3. `deck_workshop_02_sources`;
4. `deck_workshop_03_paired_swaps`;
5. `deck_workshop_04_partial_selection`;
6. `deck_workshop_05_card_reader`;
7. `deck_workshop_06_history_undo`;
8. `deck_workshop_07_conflict`.

Comando focal:

```bash
./scripts/manaloom_deck_workshop_visual_qa.sh
```

Resultado: `PASS_RUNTIME` nos três perfis e 24 PNGs abertos individualmente por
`Codex /root`, todos com `PASS_VISUAL_REVIEWED`:

- `docs/qa/ui-live/current/ux-pack-03-deck-workshop-web-mobile/` — 390x844;
- `docs/qa/ui-live/current/ux-pack-03-deck-workshop-web-desktop/` — 1440x900;
- `docs/qa/ui-live/current/ux-pack-03-deck-workshop-web-wide/` — 1920x1080.

Digest da captura:

```text
80205a33a8784b44c4a9aceee6345aabc01c2dfd8bcd1eb1dca296a516e23a65
```

Durante a revisão, os primeiros checkpoints de histórico ainda continham o
modal de Optimize. Eles foram rejeitados, o harness passou a fechar o modal pela
ação real da UI e os três perfis foram recapturados antes da aprovação.

## Verificações

- `flutter analyze --no-pub --no-version-check`: `PASS`;
- suíte Flutter completa: `1478 PASS`, `1 SKIP` declarado;
- `dart analyze` no server: `PASS`;
- suíte server completa: `752 PASS`, `3 SKIP` declarados;
- testes de modelo/provider/import/Optimize/Oficina e fluxos de deck: `PASS`;
- teste de contrato da nova rota e serviço de histórico: `PASS`;
- inventário oficial: `256` superfícies classificadas e internamente coerentes;
- smoke do harness em `flutter-tester`: `PASS`;
- Chrome release 390x844, 1440x900 e 1920x1080: `PASS_RUNTIME`;
- revisão de todos os 24 PNGs: `PASS_VISUAL_REVIEWED`;
- hashes das 24 imagens e digest dos três manifests: `PASS`;
- `quality_gate.sh ui-proof`: bloqueado somente pela matriz P0 global e review
  agregado ainda presos ao digest anterior, além de não indexarem os perfis
  focais do UX-PACK-02/03; nenhuma evidência global foi promovida ou
  recapturada sem autorização;
- project logic: `--write` e `--check` executados no fechamento.

## Limites e trabalho remanescente

- a aprovação é focal Web; não é aprovação da matriz P0 global;
- Android físico, TalkBack humano e teclado Web real continuam gates separados;
- o pacote não declara deck “ideal”, win rate ou correção estratégica absoluta;
- não prova aplicação contra PostgreSQL live nem autoriza deploy;
- consumo/conclusão da intenção no onboarding global permanece no UX-PACK-06;
- retorno de evidência de partida para aprendizado permanece no UX-PACK-04;
- superfícies sociais/faltantes relacionadas a explicabilidade permanecem no
  UX-PACK-05.

## Segurança de entrega

Não houve commit, push, deploy, migration, limpeza de checkout ou alteração de
pins. O checkout sujo preexistente foi preservado.
