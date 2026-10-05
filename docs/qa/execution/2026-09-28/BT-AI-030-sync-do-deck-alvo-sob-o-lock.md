# Receipt — o sync do deck-alvo do Hermes confere o PostgreSQL sob o lock do SQLite (BT-AI-030) — 2026-09-28

- **Origem:** item 3 das decisões do `BT-PRIV-002`, aceito em bloco pelo dono na D-83. O
  `sync_pg_target_deck_to_hermes.py` ganha a mesma proteção que o alimentador
  (`server/bin/pull_learning_events.py`) ganhou no `BT-PRIV-002`.
- **Dono no backlog:** `BT-AI-030` (retração, purge e reconciliação de learning por sujeito em
  PG e Hermes). Esta tarefa fecha a parte "impede regravação em voo" do deck-alvo.
- **Frente A (servidor)**, branch `servidor/rodada2-2026-09-24`.
- Nada tocou a produção, o laboratório Hermes ou o SQLite de verdade: os testes usam SQLite
  temporário e o PostgreSQL 17 descartável da frente.

## O risco

O script copia um deck do PostgreSQL para o SQLite do Hermes (`decks` e `deck_cards`, alvo
`deck_id=6`). Ele lia o deck e só depois abria o SQLite para gravar.

- **A corrida.** Se a conta fosse excluída entre a leitura e a gravação, o expurgo do outbox
  (`server/bin/hermes_learning_purge.py`, com `BEGIN IMMEDIATE`) podia passar antes. Aí o
  script regravava a cópia de um deck apagado, e ela ficava até a varredura seguinte.
- **No agendador isso não acontece hoje.** O `master_optimizer_preflight` roda em sequência
  com o outbox e está desligado.
- **À mão, em paralelo, acontecia.** Por isso a recomendação era fechar antes de ligar o
  preflight.

## O que mudou

- **Com `--apply`, a ordem é:**
  1. `BEGIN IMMEDIATE` no SQLite, com espera de até 30 s pelo lock, a mesma do alimentador;
  2. a conferência no PostgreSQL;
  3. a gravação;
  4. o commit.
- **A conferência.** O deck tem de existir e não estar na lixeira: `decks.id` com
  `deleted_at IS NULL`. Ela abre uma conexão própria e a fecha em seguida.
- **Deck sumiu:**
  - `rollback` e `DeckGoneError`, e o script sai com erro, como nas outras recusas dele;
  - a mensagem não traz o id do deck apagado;
  - a cópia anterior do alvo fica como estava, porque quem apaga cópia de deck excluído é o
    expurgo.
- **Por que a ordem basta.** O expurgo pega o mesmo lock. Se o deck for apagado depois da
  leitura, uma de duas coisas acontece:
  - a cópia é gravada antes de o expurgo pegar o lock, e ele a apaga;
  - ou a conferência já não acha o deck, e nada é gravado.
- **O relatório** ganha `stats.pg_deck_confirmed_under_sqlite_lock`.
- **Sem `--apply`** (simulação), nada muda: sem lock e sem conferência.

## Evidência

- **Unidade:** `test_sync_pg_target_deck_to_hermes.py`, 17/17. São os 12 de antes, agora com uma
  conferência falsa nas gravações, e 5 novos:
  - a conferência roda com o lock de escrita tomado: uma segunda conexão com espera zero não
    consegue `BEGIN IMMEDIATE` dentro da conferência, e consegue depois do commit;
  - o deck apagado depois da leitura é recusado, a cópia anterior fica intacta, e a mensagem não
    traz o id;
  - sem conferência injetada, a gravação usa a do PostgreSQL;
  - a simulação não pega lock nem pergunta nada;
  - a consulta ignora a lixeira e normaliza o id.
- **PostgreSQL:** `test_sync_pg_target_deck_to_hermes_pg_live.py` roda contra o PostgreSQL
  descartável da frente e passa 2/2:
  - a conferência aceita o deck vivo, recusa o da lixeira e recusa o apagado;
  - a gravação com a conferência padrão grava o deck vivo e recusa o mesmo deck depois de
    apagado, com a cópia anterior intacta.
- **Guarda de egress nas duas rodadas.** Todas rodaram sob `sandbox-exec` (só loopback), com
  `DATABASE_URL` explícita.
  - O teste recusa qualquer alvo fora do loopback antes de tocar no banco.
  - Sem `DATABASE_URL`, o `db_helper` procura um `.env` nos diretórios acima. O checkout
    principal tem um `server/.env`, e ele pode apontar para outro banco.
- **Fora do gate.** Os dois arquivos não estão na lista de testes Python do
  `scripts/manaloom_local_ci.sh`, nem o teste antigo do script. Ficam para a coordenação decidir
  se entram.

## Mutações

Cada mutação foi aplicada no worktree. Rodaram então os testes de unidade e o do PostgreSQL, e
por fim o arquivo foi restaurado e conferido byte a byte. As 5 falham como esperado.

| Mutação | O que muda | Falha em |
| --- | --- | --- |
| M145 | a conferência roda sem o lock de escrita | unidade: conferência sob o lock (1) |
| M146 | o deck apagado depois da leitura é gravado | unidade (3) e PostgreSQL (1) |
| M147 | o deck da lixeira passa | unidade: lixeira (1) e PostgreSQL: lixeira (1) |
| M148 | a recusa expõe o id do deck apagado | unidade: recusa sem o id (1) |
| M149 | o lock só vem na primeira escrita (`BEGIN` comum) | unidade: conferência sob o lock (1) |
