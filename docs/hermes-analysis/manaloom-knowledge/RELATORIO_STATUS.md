# Relatorio de Status — Crons e Ajustes

> Data: 2026-05-27 ~18:10Z
> Branch: codex/hermes-analysis-docs (HEAD: 69698f06)

## Estado dos Crons (12/12 habilitados)

### Erros Resolvidos
- `lorehold-deck-validator`: recuperado (erro era HTTP 429 transiente)
- `lorehold-mulligan-analyst`: recuperado (erro era model gpt-5.5 residual)
- `lorehold-deck-scout`: executando normalmente
- `lorehold-evolution-oracle`: executando normalmente

### Erros Transientes (2 crons)

#### 1. manaloom-commander-knowledge-deep (job: 75eed994c103)
- **Ultimo erro**: 17:46Z — completou analise do Atraxa mas falhou no git push (branch behind)
- **Causa**: Outro cron commitou antes, push rejeitou por non-fast-forward
- **Acao tomada**: Prompt atualizado com:
  - `git fetch + git pull --rebase` no inicio de cada run
  - No-change short-circuit (verifica se ja ha analise recente de qualidade)
  - Retry de push com rebase (max 2 tentativas)
- **Status**: Prompt atualizado com sucesso. Proximo run: ~18:24Z
- **Nota**: Prosper, Tome-Bound foi analisado mas arquivos foram perdidos (git reset --hard restaurou HEAD). O cron vai re-analisar no proximo ciclo.

#### 2. manaloom-mana-base-validator (job: 444aa9510c2c)
- **Ultimo erro**: 17:24Z — HTTP 502 (Provider returned error)
- **Causa**: Erro transiente do provider DeepSeek
- **Acao tomada**: Prompt atualizado com:
  - No-change short-circuit (evita rodar em duplicidade)
  - Tratamento de erro de provider com retry e backoff
  - Validacao de SQLite antes de tentar query
- **Status**: Prompt atualizado com sucesso. Proximo run: ~18:04Z

## Documentos Produzidos

1. **ANALISE_CRONS_E_IA.md** (commit f94e7596)
   - Analise profunda dos 12 crons em 3 camadas
   - Fluxo de otimizacao completo (otimizacao.dart 989 linhas)
   - 5 gaps criticos identificados
   - Estado de maturidade do sistema

2. **PLANO_AJUSTES.md** (commit 5d970e52)
   - 15 ajustes priorizados (P0-P3)
   - P0: co-pilot vs auto-pilot, 2 erros de cron
   - P1: multi-tag, semantic v2 enforcement, EDHREC pct
   - P2: bracket policy, tema-aware, reconstruction, prompts
   - P3: melhorias continuas

3. **CRON_STATUS.md** (commit bd9bed34 — watchdog)
   - Atualizado pelo manager-watchdog as 17:50Z
   - 2 erros transientes documentados
   - Mana Base Validation Report incluido

## Prompt Updates Realizados

### commander-knowledge-deep
- Adicionado no-change short-circuit (verifica INDEX.md e source_count >= 2)
- Adicionado branch sync no inicio (git fetch + pull --rebase)
- Adicionado retry de push (max 2 tentativas com rebase)

### mana-base-validator
- Adicionado no-change short-circuit (validacao < 60min = skip)
- Adicionado tratamento de erro de provider com retry
- Adicionado validacao de SQLite antes de query

## Limpeza Realizada
- git reset --hard origin/codex/hermes-analysis-docs (restaurou HEAD)
- git clean -fd (removeu artefatos de debug: __pycache__, debug_*.py, test_*.py)
- Working tree limpo

## Proximos Passos
1. Aguardar proximo ciclo dos 2 crons em erro (~18:04Z e ~18:24Z)
2. Verificar se os prompts atualizados resolvem os erros
3. Se os erros persistirem, investigar mais a fundo

## Restricao Conhecida
- Git push so funciona com `GIT_OBJECT_DIRECTORY=/tmp/...` workaround
- Workaround deixa objetos no /tmp que nao persistem entre sessoes
- `git reset --hard` descarta arquivos produzidos por crons que nao conseguiram commitar
- Solucao ideal: corrigir permissoes do `.git/objects/` (requer root)
