# Receipt — BT-GATE-007: `integration_test` no gate `full` — 2026-10-05

- **Tarefa:** `BT-GATE-007` (P0 CORE), frente de servidor e release, branch
  `claude/frente-servidor-release-nknr66` (PR #23), a partir de `integracao/2026-09-23`.
- **Aceite:** o `full` executa a camada de integração com runtime isolado; falha ali derruba o
  gate; tempo e vermelhos revelados registrados aqui.
- **Digest de UI intacto:** nenhum arquivo das `SOURCE_ROOTS` mudou.
- **Nada tocou a produção.** Toda execução passou `API_BASE_URL=http://127.0.0.1:9`.

## O que mudou

1. **`server/config/integration_test_lanes.json` (novo).** Cada um dos 147
   `app/integration_test/*_test.dart` está em exatamente uma trilha, com o motivo:

   | Trilha | Arquivos | Onde roda |
   |---|---|---|
   | `web_hermetic` | 42 | `quality_gate.sh full`, Chrome real, API em loopback fechado |
   | `web_backend` | 7 | precisa de API e PostgreSQL descartáveis em loopback; fora do gate |
   | `device` | 71 | Android físico, iOS ou WebView nativa do Lotus; sessão no Mac do dono |
   | `ui_proof` | 11 | os arquivos do digest de UI; scripts de captura do `BT-UIEV-001` |
   | `triage` | 16 | vermelhos no Chrome sem causa de ambiente identificada; precisam de dono |

2. **`scripts/manaloom_integration_lanes.py` (novo).** `check` falha fechado com arquivo sem
   trilha, entrada para arquivo que sumiu, duplicata, trilha desconhecida, motivo vazio ou
   `web_hermetic` vazia. `list` e `report` alimentam o gate.
3. **`scripts/manaloom_integration_lane_gate.sh` (novo).** Confere o manifesto e roda a trilha
   `web_hermetic` com `flutter drive -d web-server` contra o ChromeDriver resolvido por
   `scripts/lib/manaloom_chromedriver.sh` (major igual ao do Chrome). O `API_BASE_URL` é fixo no
   script e nunca vem do ambiente: sem ele o `ApiClient` cai no host de produção. Um teste só passa
   com exit 0 e `All tests passed`. Qualquer vermelho dá exit 1. O ChromeDriver roda com
   `TMPDIR=/tmp` e no próprio grupo de processos, que a limpeza mata inteiro.
4. **`scripts/quality_gate.sh`.** `full` chama `run_integration_lanes` depois da performance;
   modo novo `integration` roda só essa etapa.
5. **`server/test/integration_test_lanes_contract_test.dart` (novo, 6 testes).** Prende cobertura
   do manifesto contra o disco, `ui_proof` igual aos arquivos do digest de UI, `full` chamando a
   etapa, API em loopback sem leitura do ambiente, falha fechada e limpeza do grupo.

## Execução

Nuvem, Linux, Flutter 3.44.6, Chromium 141 headless, ChromeDriver 141.0.7390.37.

- **Inventário (147 arquivos, 2 shards em paralelo):** 41 passaram na primeira passada e 1
  (`scanner_controlled_harness`) nos 14 restantes; os demais caíram nas trilhas acima.
- **`./scripts/quality_gate.sh integration`, rodada final:** 42 de 42 `PASS`, exit 0,
  **3.995 s (66,6 min)**, média de 95 s por arquivo, máximo 110 s. Quase todo o tempo é a
  compilação web de cada alvo.
- **Duas rodadas anteriores deram 42 de 42 vermelhos sem rodar teste nenhum.** Causa: o
  ChromeDriver herdou um `TMPDIR` longo, o socket de instância única do Chrome passou do limite de
  caminho de socket Unix e toda sessão falhou com "user data directory is already in use". A
  correção é o `TMPDIR=/tmp` do item 3; a mesma situação foi reproduzida e passou com 2 testes.

## Vermelhos revelados

- **`triage` (16):** dois cenários do contador (`two_players`, `tabletop_seat_orientation`), sete
  `life_counter_native_*` (dano de comandante, contadores e card pool do Planechase),
  `app_full_non_life_counter_visual_capture`, `card_add_commander_choice`,
  `collection_entrypoints` (aba "Fichário" não aparece), `manaloom_authenticated_mobile_qa`,
  `release_observability` (`UnsupportedError` na Web), `sets_catalog` e `sets_search_catalog`
  (este estourou 600 s). O motivo de cada um está no manifesto.
- **`web_backend` (7):** pedem fixtures por `--dart-define` e uma API viva; ganham trilha própria
  quando houver API e PostgreSQL descartáveis em loopback no gate.

## O que falta

- Rodar `quality_gate.sh full` inteiro no Mac do dono: a etapa nova soma cerca de 67 min ao
  `full`, e ali o ChromeDriver é o pin `153.0.8010.52`.
- Dar dono aos 16 de `triage` e ligar a trilha `web_backend` com runtime descartável.
- A trilha `device` continua dependente da sessão semanal com Android físico.
