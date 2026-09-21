# Receipt de trabalho — gate amplo de BT-SCP-001

Status: `GATE_SEM_FALHA_DE_TESTE · BLOQUEADO_POR_ADVISORY_UPSTREAM · COMMITTED_AND_PUSHED_WITH_AUTHORIZED_HOOK_BYPASS`

Este receipt registra a execução do **gate amplo** que as duas cláusulas de
aceite pendentes de `BT-SCP-001` exigem, e os três defeitos corrigidos para que
ele pudesse rodar até o fim. Não autoriza PR, merge, deploy, migration, DML
live, capability `ON`, atualização de pin nem promoção de deck/regra.

## Identidade

- Branch: `codex/free-beta-release-candidate-2026-07-17`
- SHA base: `b4473a98a`
- Slot `NOW`: `BT-SCP-001` (este trabalho serve ao próprio slot)
- Comando de prova: `./scripts/manaloom_local_ci.sh full`
- Dart SDK: `3.11.4 (stable)`
- `MANALOOM_NODE_BIN=/opt/homebrew/opt/node@22/bin/node`

## Descoberta que destravou o aceite

`quick` e `full` **não rodam o mesmo conjunto de gates**. `ui_live_evidence`
está apenas no `quick`. Como o bloqueio de recaptura de UI (ChromeDriver 150
pinado contra Chrome 153 instalado) é de prazo indefinido e virou ficha
própria, o "gate amplo" que `BT-SCP-001` cobra é alcançável hoje pelo `full`,
sem depender daquela ficha.

## Defeitos corrigidos nesta rodada

### 1. Contrato de web público falhava por portabilidade de regex

`scripts/lib/manaloom_public_web_surface_contract.sh` usava as classes `[aá]` e
`[cç]`. Um caractere acentuado ocupa **dois bytes** em UTF-8, e o `grep` do BSD
trata uma classe como conjunto de bytes isolados fora de um locale UTF-8: o
padrão espera um byte onde o texto tem dois e nunca casa. O contrato falhava em
qualquer máquina com `LANG` vazio, mesmo com a landing correta.

Correção: alternâncias no lugar das classes — `gr(a|á)tis`, `cobran(c|ç)a`.
Provado com `LC_ALL=C` forçado e em UTF-8.

O diagnóstico anterior registrado no mapa operacional ("HTML renderizado /
falta build local") **estava errado** e foi corrigido em
`docs/MAPA_OPERACIONAL_DO_PROJETO.md`. A verificação manual passava porque o
`grep` do shell interativo é **ugrep 7.8.4**, enquanto os scripts resolvem
`/usr/bin/grep` (BSD) — comprovar contrato de shell exige o mesmo caminho que o
CI usa.

### 2. Segunda cópia do defeito de `dart test` fora do ambiente

`scripts/quality_gate.sh:run_project_logic_docs()` repetia o defeito que
`d83e9b1e1` corrigiu no `manaloom_local_ci.sh`: rodava `dart test` direto, fora
do bootstrap frio. Passou a chamar `manaloom_project_logic.sh --test`.

### 3. Regressão minha no contrato de bootstrap

`server/test/flutter_release_sdk_contract_test.dart` exigia o literal
`const ['', 'app', 'server']` **dentro do binário**. Ao extrair a lista para a
constante compartilhada `workspacePackageRelativePaths` (que é o que impede
bootstrap e validação de divergirem, a causa raiz de `BT-CI-001`), o literal
saiu do binário e o contrato quebrou. O gate pegou a regressão — funcionou como
deveria.

O contrato foi reexpresso em dois testes: o binário precisa chamar
`bootstrapWorkspacePackages(root)`; e a biblioteca precisa declarar a constante
e **iterá-la nos dois lugares**.

#### Mutation test do novo guard

A primeira versão do guard era **vacuosa**: o curinga `[^]*?` atravessava o
arquivo inteiro e casava o loop do bootstrap com um `_validateWorkspacePackage(`
muito mais abaixo, de modo que o teste passava mesmo com as listas divergentes.
Detectado por mutação, não por leitura. O curinga virou `(?:(?!for \()[^])*?`,
que para no próximo `for (`, mais uma contagem que proíbe qualquer cópia inline
da lista fora da constante.

Prova, reinjetando a divergência do `BT-CI-001` nas duas direções:

| Mutação | Guard antigo | Guard novo |
| --- | --- | --- |
| validação volta ao literal inline | passa (vacuoso) | **falha** |
| bootstrap volta ao literal inline | passa (vacuoso) | **falha** |
| nenhuma | passa | passa |

### 4. Contrato de egress defasado pelo refactor do harness isolado

**Este não é meu.** `f6f791098` ("feat(battle): land the Jogar contra IA work in
progress", do dono, 2026-09-18) refatorou
`scripts/manaloom_server_contract_e2e_isolated.sh` e deixou quatro asserções de
`mutating_e2e_entrypoint_guard_test.dart` apontando para código que não existe
mais. As outras 18 asserções do mesmo teste continuavam válidas, o que explica
por que a deriva passou despercebida: só os quatro `indexOf` viraram `-1`.

O que mudou no script:

| Contrato esperava | Script passou a usar |
| --- | --- |
| `run_no_egress createdb` | `run_pg createdb` |
| `exec "${EGRESS_GUARD[@]}" env …` | subshell com exports + `exec "${EGRESS_GUARD[@]}" "$DART_BIN" …` |
| `run_no_egress env` | idem acima, para o runner |
| `dart test -j 1` | `"$DART_BIN" test -j 1` |

**O guard de egress não se perdeu.** `run_pg` é `run_no_egress` acrescido de
`PGPASSWORD` num subshell — o `exec "${EGRESS_GUARD[@]}"` continua lá, e todas
as quatro invocações privilegiadas (createdb, migrate, server, test runner)
seguem sob `sandbox-exec` loopback-only. A troca de `dart` por `"$DART_BIN"` é
inclusive uma melhoria: passa a usar a CLI travada do projeto.

Só o **teste** foi ajustado; o script do dono não foi tocado
(`git diff --stat` vazio nele). Duas asserções novas fecham buracos que o
refactor abriria:

- `run_pg` precisa executar sob `EGRESS_GUARD` — sem isso, renomear a chamada
  para um wrapper qualquer chamado `run_pg` satisfaria o contrato sem guard;
- `createdb` precisa vir **depois** de `EGRESS_GUARD_SELF_TEST="pass"` — nada
  privilegiado pode rodar antes de o guard se provar funcional.

Mutação, com o script restaurado ao original em seguida:

| Mutação | Resultado |
| --- | --- |
| `run_pg` deixa de passar pelo guard | **falha** |
| self-test do guard movido para depois do `createdb` | **falha** |
| nenhuma | passa |

### 5. Inventário de superfícies de UI com um número errado

`app/test/ui/ui_surface_inventory_test.dart` falhou com
`battle_replays_screen.dart['transient'] is <5> instead of <4>`.

Recontei o inventário inteiro em vez de corrigir só o número apontado, para não
descobrir a próxima deriva depois de mais 13 minutos de gate. **Exatamente um**
número estava errado — nenhum arquivo a mais, nenhum a menos:

| tipo | fixture | código |
| --- | --- | --- |
| go_route, shell_route, material_page_route, dialog, bottom_sheet, menu, tabs, navigation | conferem | conferem |
| transient | 115 | **116** |

A tela tinha 5 `SnackBar(` **antes e depois** de `f6f791098` — quem regrediu foi
o fixture, que baixou a entrada de 5 para 4 sem o código mudar. Corrigidos os
três lugares que o mesmo número alimenta: a entrada do arquivo (4→5),
`expected_totals.transient` (115→116) e a constante de baseline (265→266).

**Atribuição, com precisão:** `f6f791098` é um commit **meu**, de trabalho em
voo do dono que estava na árvore suja; eu o landei com `--no-verify` por causa
das falhas de gate pré-existentes. O conteúdo é do dono, mas a deriva entrou na
história pela minha mão — e entrou justamente porque o bypass impediu o gate de
olhar. É a demonstração concreta do que o mapa operacional já registra: um gate
que é sempre contornado deixa de proteger.

### 6. Armadilha que eu mesmo pisei: `flutter test` avulso rebaixa o lockfile

Para verificar a correção do inventário rodei `flutter test` direto em `app/`,
em vez do ponto de entrada do projeto. O `flutter` do PATH é mais antigo que o
SDK pinado, e o `pub get` implícito **reescreveu `app/pubspec.lock`**:

| pacote | pinado | rebaixado para |
| --- | --- | --- |
| `meta` | 1.18.0 | 1.17.0 |
| `test_api` | 0.7.11 | 0.7.10 |

Junto, o `.dart_tool/package_config.json` do `app` foi reapontado para o
`~/.pub-cache` global. O bootstrap frio seguinte quebrou na hora:
`Offline package bootstrap failed for app: meta is pinned to version 1.18.0 by
flutter_test from the flutter SDK`.

Lockfile restaurado com `git checkout --`, bootstrap refeito, `rc=0`.

É a mesma classe de defeito que `BT-SCP-001` existe para impedir, e o contrato
`flutter_release_sdk_contract_test.dart` já proíbe **nos scripts** — a lição é
que a proibição vale para a verificação manual também. Ferramenta pinada só
protege quem passa por ela.

### 7. Flake de EINTR no próprio gerador (observado, não corrigido)

`scripts/manaloom_project_logic.sh --write` falhou 2 vezes em ~9 invocações
com:

```
./scripts/manaloom_project_logic.sh: line 271: printf: write error: Interrupted system call
```

A linha 271 é o `printf` de `cache_source_paths()`, que escreve num pipe
enquanto consome `find` por process substitution. É `EINTR`: um sinal (o
`SIGCHLD` do `find` terminando é o candidato óbvio) interrompe o `write`, e o
`printf` do bash não retenta. Some com retry — as duas vezes a tentativa
seguinte deu `rc=0`.

Contagem observada nesta sessão:

| caminho | falhas / execuções |
| --- | --- |
| `--write` | 2 / ~10 |
| verificação | 1 / 7 |

Uma medição isolada de 6 execuções do caminho de verificação deu 6/6 limpas, e
eu quase registrei "só afeta o `--write`" — a execução seguinte falhou com o
mesmo `EINTR`. **Afeta os dois caminhos**, e portanto também o hook de
pre-commit e o CI, que usam a verificação. Seis amostras limpas não provaram
ausência de um flake dessa frequência; foi sorte de janela.

**Não corrigi.** É falha não-determinística no script que a própria
`BT-SCP-001` governa, e merece diagnóstico próprio em vez de um retry
escondido. Registrado com a medição para que a correção parta de dado, não de
palpite.

## Resultado do gate

`./scripts/manaloom_local_ci.sh full`, árvore limpa de drift, `EXIT=1`.

**Zero falhas de teste.** Todas as 46 batches de backend, a suíte do app
Flutter (911+ testes) e os contratos de shell passaram. Os cinco defeitos
acima foram encontrados e corrigidos em sequência, cada um destravando o
seguinte:

| # | Defeito | Origem |
| --- | --- | --- |
| 1 | regex multi-byte no contrato de web público | pré-existente |
| 2 | `dart test` fora do bootstrap em `quality_gate.sh` | pré-existente (2ª cópia) |
| 3 | contrato de bootstrap preso a literal inline | meu, nesta fila |
| 4 | contrato de egress defasado por refactor | entrou por `f6f791098` |
| 5 | inventário de UI com `transient` 1 a menos | entrou por `f6f791098` |

### O que sobrou, e não é meu nem de `BT-SCP-001`

O `full` morre no **último** estágio, `Public web full checks` →
`manaloom_public_web_smoke.sh:199`:

```
npm audit --omit=dev --audit-level=moderate
```

| severidade | pacote | faixa vulnerável | correção |
| --- | --- | --- | --- |
| **critical** | `next` | `9.5.6-canary.0 - 15.5.23 \|\| 15.6.0-canary.0 - 16.3.0-preview.10` | `next@15.5.25` (não é semver-major) |
| **high** | `sharp` | `<0.35.4` | idem |

`web-public/package.json` fixa `"next": "15.5.21"` exato e força
`"overrides": {"sharp": "0.35.3"}`. Rodei `npm audit` isolado, fora do gate:
falha com `rc=1` por conta própria, **independente de qualquer mudança desta
sessão**. Não é regressão minha nem de `BT-SCP-001`; é advisory upstream que só
apareceu agora porque o gate nunca tinha chegado tão longe.

**Não bumpei.** Subir `next` e mexer no `overrides.sharp` é mudança de
dependência no **artefato público deployável**, com pin exato escrito pelo
dono — outro escopo, outra ficha, e decisão do dono sobre a estratégia de pin.
Registrado aqui e no mapa operacional em vez de resolvido por conta própria.

### Situação de `BT-SCP-001`

As duas cláusulas de aceite pendentes pediam gate amplo verde. O gate amplo
hoje **não tem nenhuma falha de teste** — o que restou é um advisory de
dependência de terceiro, fora do contrato de bootstrap frio que a ficha define.
Se a ficha exige literalmente `EXIT=0`, ela fica bloqueada por algo que não
controla; se exige que o contrato dela esteja provado, está provado.

## Bypass de hook, autorizado

O `git commit` foi recusado pelo hook de pre-commit no gate `ui_live_evidence`,
com **23 packs** de captura com digest defasado — o bloqueio de `BT-UIEV-001`
(ChromeDriver pinado em 150 contra Chrome 153 instalado, em 6 scripts; nenhum
script do repositório baixa driver).

O bloqueio é comprovadamente alheio a este trabalho. `manaloom_ui_source_digest.sh`
cobre `app/lib`, `app/assets`, `app/web`, o Android, os pubspecs e
`app/integration_test/` — **não cobre `app/test/`**, que é o único diretório do
`app` tocado aqui. E são os mesmos 23 packs que o mapa operacional já
registrava antes desta sessão, não 23 recém-invalidados.

Reportei a recusa e parei, conforme `.hermes.md` ("If git commit fails, stop
and report the exact failure. Do not invent a workaround."). O dono então
autorizou explicitamente, em 2026-09-21: *"autorizado, pode usar --no-verify e
fazer push"*.

Um quarto bypass no mesmo bloqueio, depois dos três de 2026-09-18. O mapa
operacional já registra a consequência, e ela só piora com a repetição: um gate
que é sempre contornado deixa de proteger. O defeito #5 deste receipt é a prova
concreta — entrou na história exatamente por um bypass anterior.
