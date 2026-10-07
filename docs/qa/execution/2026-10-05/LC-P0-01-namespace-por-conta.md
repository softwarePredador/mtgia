# Receipt — LC-P0-01: namespace local por conta — 2026-10-05

- Branch `claude/frente-contador-de-vida-ibnawb`, sobre `origin/integracao/2026-09-23`. Raia do app. Nada tocou a produção; sem migration; sem servidor.
- `app/lib/features/home/life_counter/life_counter_account_scope.dart` (novo): `LifeCounterAccountScope` guarda a conta ligada e uma geração. Cada store pega o namespace na construção; as chaves viram `manaloom.local.v1.account.<id>.<chave antiga>` (`manaloom.local.v1.signed_out.` sem conta, apagado a cada transição). Depois da troca de conta, leitura e escrita de uma store antiga lançam `LifeCounterStorageScopeClosedException`.
- Sob o escopo: sessão, histórico, configurações, timer, dia/noite, perfis de aparência (nicks), snapshot Lotus, snapshot de UI, trilha de diagnóstico, as chaves cruas `manaloom_lotus_web_storage_v1` do host Web e as notas e o outbox do pós-jogo.
- Legado: as chaves sem prefixo não têm dono comprovável (o logout nunca as limpou), então são apagadas no primeiro login, sem migração. Fica o receipt local `manaloom.local.life_counter_legacy_purge_receipt_v1` com chaves (id de deck redigido) e contagens de pendências descartadas, sem conteúdo.

## Evidência

`app/test/features/home/life_counter_account_scope_test.dart`, 7/7: B não lê sessão, histórico, nick nem snapshot de A e A recupera os dela; store de A falha fechada depois da troca; mesma conta não abre geração nova; dados sem conta não passam para a conta; legado apagado com receipt; exclusão apaga só a conta; notas e outbox de A invisíveis para B e nunca enviados com o token de B.

Suítes `test/features/home`, `test/features/auth`, `test/features/profile`, `test/features/retention` e `test/features/decks` passam, menos 4 goldens que já falham na base deste container, iguais antes e depois: os 3 heróis da home (`home_screen_test.dart`) e a galeria larga (`deck_list_responsive_test.dart`).

Falta: prova de UI no lote do `BT-UIEV-001` e roteiro A → logout → B em Android físico.
