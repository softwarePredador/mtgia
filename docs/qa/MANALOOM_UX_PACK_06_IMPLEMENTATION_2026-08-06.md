# ManaLoom UX-PACK-06 — implementação e evidência local

Data: 2026-08-06
Estado: `COMPLETE_LOCAL · FOCAL_WEB_VISUAL_PASS · GLOBAL_UI_EVIDENCE_STALE`
Autorização: continuação explícita do usuário — “continue”.

## Resultado

O primeiro uso deixou de ser uma sequência de painéis informativos e passou a
começar pela intenção do jogador:

```text
objetivo: catalogar / montar / importar / jogar / melhorar
  → experiência e formato
  → método guiado ou manual quando aplicável
  → tarefa real e endereçável
  → conclusão somente depois do sucesso da tarefa
  → Home com uma única próxima ação contextual
```

O fluxo pode ser pulado e retomado sem perder a intenção. Um deck que já
existia antes do onboarding não é tratado como conclusão de uma tarefa nova.
Falha de persistência bloqueia o handoff em vez de inferir sucesso.

## Rotas e fronteira de conclusão

- catalogar: `/collection/import?list_type=have&from=onboarding`;
- montar manualmente:
  `/decks?create=1&format=<format>&from=onboarding`;
- montar com guia:
  `/decks/generate?format=<format>&from=onboarding`;
- importar deck:
  `/decks/import?format=<format>&from=onboarding`;
- jogar ou melhorar: Home mantém a intenção pendente até abrir uma mesa real
  ou entrar no Optimize com um deck real.

Criar, gerar, importar ou aplicar coleção só conclui o onboarding depois da
resposta bem-sucedida do fluxo correspondente. O retorno à Home remove
`from=onboarding` da navegação ativa e mostra o deck ou a próxima ação coerente.

## Persistência e escopo de dados

Objetivo, experiência, formato, método, estado de skip e conclusão são
owner-scoped no store local existente e compatíveis com chaves antigas. A
decisão corrente é deliberadamente **por dispositivo**, em
`SharedPreferences`. Sincronização cross-device permanece uma decisão futura:
ela exigiria contrato backend e autorização próprios e não foi simulada no
cache local.

Não houve migration, escrita em PostgreSQL, Hermes/SQLite, mudança de regras,
deck automático, runtime de produção ou deploy.

## Tese visual aplicada

A lente do `frontend-skill` definiu uma “mesa de escolha” Obsidian/Frost. A
ilustração ManaLoom ancora identidade e atmosfera; Brass aparece apenas na
próxima ação. O conteúdo segue intenção → contexto → método → tarefa, com
progresso visível, movimento reduzível e uma Home enxuta depois do handoff.

A revisão iterativa corrigiu o helper de formato no mobile, tornou a retomada
inequívoca com “PLANO RETOMADO” e manteve o primeiro passo naturalmente
rolável. Em desktop e wide, a composição preserva leitura e hierarquia; o
espaço wide ainda subutilizado pertence ao `UX-PACK-07` e não bloqueia o fluxo.

## Evidência automatizada e runtime

O harness usa `MainScaffold`, memória controlada e Chrome real em build Web
release. Cinco checkpoints são exigidos por perfil:

1. primeiro uso;
2. caminho de montagem configurado;
3. plano persistido e retomado;
4. Home depois de pular;
5. Home depois de concluir com deck real.

Comando focal:

```bash
./scripts/manaloom_onboarding_intent_visual_qa.sh
```

Resultado no digest
`5df01bcd9322d7bd5809ae5c15bd6f592e4871a5c247a014a2689f854b68abd7`:

- `web_onboarding_intent_mobile_390x844`: `5/5 PASS_RUNTIME`;
- `web_onboarding_intent_desktop_1440x900`: `5/5 PASS_RUNTIME`;
- `web_onboarding_intent_wide_1920x1080`: `5/5 PASS_RUNTIME`;
- `15/15 PASS_VISUAL_REVIEWED`, após abrir cada PNG final individualmente;
- consoles dos três perfis: zero entrada proibida.

Manifests:

```text
mobile   a2af736bba96e3ee88b14cd26e7b188b3bb1f704dc8abf8931e591d7c26fdb52
desktop  ea22fa2f1dd42b6b4525580f3bc8c2b160af9db7780d96edfe92b8f7cfa8d47b
wide     2f3a92faf199282126a68a6d804c4c22619c8096cb995040533e412d3f2560cc
```

Digest ordenado das 15 imagens:

```text
6e1b9186fa0b1fe520100853acca19b1e4bd8dd2fc8676e3d0166582ce001c1e
```

## Verificações focais

- fluxo, Home, store, autenticação e handoffs reais: `86/86 PASS`;
- integration test controlado no Flutter tester: `PASS`;
- analyzer dos arquivos focais: `PASS · no issues found`;
- Chrome release 390×844, 1440×900 e 1920×1080:
  `15/15 PASS_RUNTIME`;
- inspeção manual de cada PNG final: `15/15 PASS_VISUAL_REVIEWED`.

Uma execução acidental com o Flutter 3.41.6 do PATH foi recusada por
incompatibilidade entre engine e framework (`DisplayCornerRadii`). A mesma
suíte foi repetida com o Flutter 3.44.6 pinado pelo projeto e passou 86/86; o
resultado incompatível não recebeu crédito.

`./scripts/manaloom_project_logic.sh --write` e `--check` passaram. O comando
`./scripts/quality_gate.sh ui-proof` foi executado no digest corrente e recusou
corretamente o aggregate: review e 14 manifests continuam stale, e os três
perfis `web_social_trade_*` e os três `web_onboarding_intent_*` ainda não
pertencem a `latest.json`. Nenhum PASS global foi forçado.

## Aggregate e trabalho remanescente

`docs/qa/ui-live/latest.json` permanece propositalmente no digest global
anterior `93009fc2…`, com 14 manifests e 294 capturas. A política corrente,
agora incluindo Social/Trade e Onboarding Intent, exige 20 manifests e 357
capturas. A prova focal deste pacote não promove nem reaproveita hashes antigos.

A reancoragem integral não foi iniciada: somente `emulator-5554` está
disponível como Android, enquanto o perfil obrigatório é o Samsung físico
`android_physical_sm_a135m`; o volume raiz também tem aproximadamente 2,2 GiB
livres, insuficientes para uma matriz integral segura. TalkBack humano, teclado
Web de hardware e smoke físico continuam gates separados de release.

## Segurança de entrega

Não houve commit, push, deploy, migration, limpeza do checkout, escrita em
PostgreSQL live nem alteração de Hermes/SQLite. O checkout sujo preexistente
foi preservado.
