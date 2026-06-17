# EasyPanel Hermes Lab Container — 2026-06-17

## Objetivo

Substituir o Hermes AWS por um container dedicado no EasyPanel sem misturar o
laboratório com o worker operacional do produto.

Separação obrigatória:

- `manaloom-ops`: runtime determinístico do produto, sem provider obrigatório.
- `hermes-lab`: chat/dashboard, auditoria, docs branch, experimentos e rotinas
  de laboratório.

## Imagem e bootstrap

Base:

- `nousresearch/hermes-agent:latest`

Camada adicional do projeto:

- `server/Dockerfile.hermes-lab`
- `server/bin/hermes_lab_entrypoint.sh`

O bootstrap precisa garantir:

1. volume persistente em `/opt/data`;
2. clone do repo em `/opt/data/workspace/mtgia` quando ainda nao existir;
3. `fetch --all --prune` seguro quando o repo ja existir;
4. toolchain local para o laboratorio:
   - Flutter
   - Dart
   - dart_frog_cli
   - git
   - python3
   - jq
   - node/npm
5. `PATH` consistente escrito em `/opt/data/.profile`.
6. handoff final para o binário oficial do Hermes:
   - `hermes gateway run`
   - sem reencadear `main-wrapper`/`entrypoint` depois que o container já
     entrou pelo `/init` da imagem base.

## O que o container precisa para funcionar

Obrigatorio:

- volume persistente `/opt/data`;
- `HERMES_HOME=/opt/data`;
- `HERMES_DASHBOARD=1`;
- `HERMES_DASHBOARD_HOST=127.0.0.1` por padrão seguro;
- `HERMES_DASHBOARD_PORT=9119`;
- `API_SERVER_ENABLED=true`;
- `API_SERVER_HOST=0.0.0.0`;
- `API_SERVER_KEY` com valor aleatório persistido no serviço;
- repo público ou credencial Git se for preciso push.

Opcional:

- `HERMES_GITHUB_TOKEN` para push na branch `codex/hermes-analysis-docs`;
- tokens de provider para jobs/chat LLM;
- domínio público dedicado do dashboard somente com auth/OAuth explícito.

Nao expor publicamente:

- dashboard em `0.0.0.0` sem auth provider;
- dashboard com `HERMES_DASHBOARD_INSECURE=1` na internet pública.

Se precisar acesso web imediato antes de configurar auth:

- manter o dashboard em loopback;
- usar `docker exec`/túnel SSH/console controlado;
- ou expor apenas o API server com `API_SERVER_KEY`.

Observação de runtime:

- o bootstrap local preserva `HERMES_HOME=/opt/data` e evita reencadear o
  `main-wrapper` depois do `/init`, porque essa cadeia já teve regressões de
  env/workdir no upstream Docker do Hermes.

## Tokens de IA

Diferente do `manaloom-ops`, o `hermes-lab` pode operar em dois modos:

### 1. Determinístico / read-only

Funciona sem token de IA para:

- leitura do repo;
- `dart analyze`;
- `dart test`;
- `flutter analyze`;
- scripts Python determinísticos;
- auditorias read-only;
- atualização de docs locais/manual.

### 2. Provider-enabled

Exige token de IA apenas para:

- chat Hermes com LLM;
- crons provider-heavy;
- research loops;
- síntese automática baseada em modelo.

Sem token de IA o container continua útil como ambiente de laboratório e
validação, mas nao executa tarefas dependentes de provider.

## Guardrails

- `hermes-lab` nao deve virar fonte de verdade do produto.
- PostgreSQL/backend continuam donos da decisão.
- SQLite Hermes continua cache/laboratório.
- metadata Hermes segue escondida do usuário normal.
- jobs determinísticos do produto nao devem rodar dentro do `hermes-lab` se já
  estiverem estáveis no `manaloom-ops`.

## Próximos passos pós-provisionamento

1. Subir o serviço `hermes-lab` no projeto `evolution`.
2. Validar que o volume persiste entre restarts.
3. Validar `flutter --version`, `dart --version`, `python3 --version` e repo
   disponível dentro do container.
4. Validar `hermes status`.
5. Só expor domínio público quando houver auth do dashboard ou política clara
   de reverse proxy privado.
6. Só depois desligar a AWS.
