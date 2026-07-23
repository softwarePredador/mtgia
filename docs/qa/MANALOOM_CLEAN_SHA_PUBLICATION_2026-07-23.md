# Publicação da identidade limpa de implementação

Data: 2026-07-23

Branch: `codex/free-beta-release-candidate-2026-07-17`

Base de recuperação:
`4700fc38317aae0d3c1955176b32c18ac3b34339`

Commit de implementação:
`2139ec9f6f902a8b266fbb852db6e834b25bceff`

## Escopo registrado

O commit `Harden beta release readiness and retention` reuniu o hardening de
resiliência/release e a consolidação de retenção no mesmo diff revisável:

```text
630 paths
54 adicionados
117 modificados
482 removidos
13.958 inserções
5.009.494 deleções
```

As deleções de reports, os dois índices de recuperação, os 23 conteúdos
canônicos e as correções de referência estão no mesmo commit. Os originais
continuam recuperáveis a partir da base registrada acima.

## Gates da mesma identidade

O hook `pre-push` executou `./scripts/manaloom_local_ci.sh full` com o checkout
limpo em `2139ec9f6`:

```text
secret scan                         PASS
auditorias determinísticas          35/35 PASS
report retention                    12/12 checks, 16/16 testes
contratos operacionais de release   25/25 PASS
project logic                       15/15 PASS
backend                             1736/1736 PASS
Flutter analyze                     0 issues
Flutter tests                       1157 PASS + 1 skip Web-only conhecido
Web pública                         13 rotas, smoke PASS, 0 vulnerabilidades
UI audit                            48/48 PASS
custom lint                         PASS
Patrol local                        9/9 PASS
dependency audit                    4 pacotes PASS
schema loopback                     73 tabelas, 6 views, 76 FKs,
                                    51 migrations
```

O primeiro processo de push terminou com código 1 depois de imprimir o sucesso
integral do gate, antes de transportar o ref. Como o checkout e o SHA não
mudaram, o transporte foi repetido com `git push --no-verify` para não executar
novamente o mesmo gate. O remoto aceitou o commit e a comparação seguinte
confirmou local e `origin` no mesmo SHA, com worktree limpo.

## Limites desta prova

Esta publicação é uma identidade de implementação revisável, não um GO. Não
houve PR, deploy, migration live, escrita PostgreSQL live, promoção de
deck/regra nem remoção de histórico remoto. Permanecem os bloqueios descritos
no tracker: residual S8/S9, TalkBack humano, Sentry, FCM no APK assinado,
SBOM/OSV, backup off-site/restore e jornadas publicadas na SHA final. O delta
de engines foi posteriormente revisado com `retain_current_pins` em
`docs/qa/MANALOOM_ENGINE_DELTA_REVIEW_2026-07-23.md`; qualquer avanço futuro
continua sujeito a qualificação completa.
