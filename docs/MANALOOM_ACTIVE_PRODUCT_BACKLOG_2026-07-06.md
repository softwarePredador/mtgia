# ManaLoom Active Product Backlog - 2026-07-06

Status padrao desta lista: tudo que antes estava como "falta" foi colocado em
andamento. Itens com dependencia externa seguem ativos, mas bloqueados por uma
entrada concreta do usuario ou fornecedor.

## 1. Fechar Infra

Objetivo: deixar o ManaLoom novo operavel sem depender do ambiente antigo.

| Item | Status | Proxima execucao |
| --- | --- | --- |
| Migrar DNS/dominio definitivo para o novo stack | EM_ANDAMENTO_BLOQUEADO_EXTERNO | Aguardar dominio/DNS final e apontar para API/web novos. |
| React publico como servico proprio no EasyPanel novo | CONCLUIDO | Manter smoke em cada deploy. |
| Backup automatico do Postgres novo | CONCLUIDO | Cron remoto instalado no EasyPanel novo: `17 2 * * * # manaloom-postgres-backup`; ultimo dump validado com `279087037` bytes. |
| Restore real de backup | CONCLUIDO | Cron remoto instalado: `47 3 * * 0 # manaloom-postgres-restore-check`; restore `schema` recorrente e restore `full` manual validados com `82` tabelas. |
| Remover dependencia operacional do droplet antigo | EM_ANDAMENTO_BLOQUEADO_EXTERNO | Executar apos DNS final e janela de convivencia. |
| Padronizar `.env`, deploy e runbooks | CONCLUIDO_PARCIAL | `server/.env.example`, runbook, backup cron e quality gate comercial padronizados; atualizar de novo quando dominio/pagamento finais existirem. |

## 2. App Flutter Producao

Objetivo: app mobile/web usando o backend novo com prova de fluxo real.

| Item | Status | Proxima execucao |
| --- | --- | --- |
| Apontar app para dominio definitivo | EM_ANDAMENTO_BLOQUEADO_EXTERNO | Trocar `--dart-define` quando o dominio final existir. |
| Atualizar builds Android/iOS/Web para API nova | CONCLUIDO_PARCIAL | Build Flutter Web release validado com `API_BASE_URL` no host novo; Android/iOS finais dependem de assinatura/distribuicao. |
| Revalidar login/cadastro/decks/colecao/marketplace/IA | EM_ANDAMENTO_VALIDADO_PARCIAL | Quality gate comercial validou smoke produto no backend novo; login web local abriu sem `RangeError` e sem erro de console. Falta QA mobile autenticado. |
| Revalidar Sentry/logs/erros reais | EM_ANDAMENTO | Rodar scripts de Sentry quando DSN/projeto estiverem configurados. |
| Garantir ausencia de mocks em telas principais | EM_ANDAMENTO_VALIDADO_PARCIAL | `/ai/generate` nao retorna mock 200 em producao; geracao invalida retorna 422. Falta QA visual completo. |
| Revisar botoes, modais, loaders, empty states e erros | EM_ANDAMENTO_VALIDADO_PARCIAL | Tela web de login validada visualmente; fluxo pos-jogo ganhou CTAs diretos para optimize/rebuild. Falta varredura mobile completa. |

## 3. Monetizacao

Objetivo: usuario entende Free/Pro, limite, valor do Pro e caminho de upgrade.

| Item | Status | Proxima execucao |
| --- | --- | --- |
| Tela Free/Pro | CONCLUIDO_PARCIAL | Validar copy e responsividade no QA final. |
| Medidor de uso de IA | CONCLUIDO_PARCIAL | Confirmar leitura remota em app logado. |
| Limite por plano | CONCLUIDO_PARCIAL | Monitorar `402` no middleware de IA. |
| Paywall ao atingir limite | CONCLUIDO_PARCIAL | Contratos de limite/paywall testados no provider; falta teste manual autenticado em todos os fluxos de IA. |
| Upgrade dentro do app | CONCLUIDO_PARCIAL | Integrar URL real de checkout. |
| Checkout/pagamento | EM_ANDAMENTO_BLOQUEADO_EXTERNO | Escolher provedor e implementar adaptador do webhook. |
| Termos, privacidade, disclaimer e IA/IP | EM_ANDAMENTO_BLOQUEADO_EXTERNO | Revisao juridica final. |

## 4. Diferencial Da IA

Objetivo: recomendacao confiavel, explicada e adaptada ao contexto do jogador.

| Item | Status | Proxima execucao |
| --- | --- | --- |
| Melhorar deck usando cartas da colecao | EM_ANDAMENTO_VALIDADO_PARCIAL | Sheet de otimizacao expoe preferencia por colecao; agora tambem pode ser aberta pelo pos-jogo. Falta validar caso real com colecao carregada. |
| Melhorar deck por orcamento | EM_ANDAMENTO_VALIDADO_PARCIAL | Sheet de otimizacao expoe limite de orcamento; agora tambem pode ser aberta pelo pos-jogo. Falta validar caso real com precos. |
| Explicar troca por funcao/risco/curva/preco/bracket | EM_ANDAMENTO | Expandir apresentacao no app e relatorio publico. |
| Relatorio antes/depois compartilhavel | CONCLUIDO_PARCIAL | Melhorar visual e CTA publico. |
| Sugestao por Commander Bracket | CONCLUIDO_PARCIAL | Validar bloqueios por bracket com casos reais. |
| Rebuild guiado casual/upgraded/optimized/cEDH | EM_ANDAMENTO_VALIDADO_PARCIAL | Link `?optimize=rebuild` abre a sheet em modo rebuild/intencao inicial; falta refino de copy por nivel. |

## 5. Retencao

Objetivo: ManaLoom acompanha a vida do deck depois da primeira criacao.

| Item | Status | Proxima execucao |
| --- | --- | --- |
| Historico de partidas | CONCLUIDO_PARCIAL | Endpoint `GET /decks/:id/post-game-timeline` e tela pos-jogo com historico. |
| Notas pos-jogo | CONCLUIDO_PARCIAL | Validar sync e UX em deck real. |
| Cartas que performaram bem/mal | CONCLUIDO_PARCIAL | Exibir agregados por deck. |
| Diagnostico mana/compra/remocao/win condition | CONCLUIDO_PARCIAL | Backend agrega issues e gera diagnosticos/acoes. |
| Sugestao automatica depois da partida | CONCLUIDO_PARCIAL | Backend retorna `next_actions`; tela pos-jogo agora possui CTAs diretos para otimizar ou iniciar rebuild do deck. |
| Linha do tempo de evolucao do deck | CONCLUIDO_PARCIAL | Backend retorna `weekly_activity` e `timeline`; falta visual refinado. |
| Alertas de preco/cartas faltantes/upgrades | EM_ANDAMENTO | Consolidar market movers + wishlist/binder. |

## 6. Comunidade E Trade

Objetivo: produto vira rede, nao apenas ferramenta individual.

| Item | Status | Proxima execucao |
| --- | --- | --- |
| Perfil publico de jogador | CONCLUIDO_PARCIAL | QA visual e SEO da pagina publica. |
| Decks publicos com analise visual | CONCLUIDO_PARCIAL | API publica retorna `visual_analysis`; app exibe leitura visual. |
| Seguir jogadores | CONCLUIDO_PARCIAL | Validar feed e notificacoes. |
| Comentarios/feedback em decks | CONCLUIDO_PARCIAL | Rotas `comments`, provider e tela publica implementados. |
| Binder publico | CONCLUIDO_PARCIAL | QA de privacidade e campos publicos. |
| Lista de cartas para troca | CONCLUIDO_PARCIAL | QA de disponibilidade e filtros. |
| Match entre carta faltante e usuario que tem | CONCLUIDO_PARCIAL | `GET /community/trade-matches` cruza want list/deck faltante com ficharios publicos. |
| Moderacao/denuncia basica | CONCLUIDO_PARCIAL | `POST /community/decks/:id/reports` registra denuncias em `content_reports`; falta painel admin. |
| Compartilhamento externo de deck/analise | CONCLUIDO_PARCIAL | API publica inclui analise visual; falta metadados sociais finais. |

## 7. Qualidade Comercial

Objetivo: publicar com confianca, medicao e fallback controlado.

| Item | Status | Proxima execucao |
| --- | --- | --- |
| QA completo web/mobile | EM_ANDAMENTO_VALIDADO_PARCIAL | `scripts/manaloom_commercial_quality_gate.sh` passou no stack novo; login web local validado. Falta varredura mobile fisica/simulador. |
| Performance da geracao de decks | CONCLUIDO_PARCIAL | Quality gate rodou benchmark curto com `successful_runs=2`, `mock_response_count=0` e status `pass`; manter medicao a cada deploy. |
| Tempo medio por endpoint de IA | EM_ANDAMENTO_VALIDADO_PARCIAL | `/health/commercial` e benchmark estao integrados ao quality gate; falta dashboard historico. |
| Metricas de conversao | EM_ANDAMENTO | Usar funil `activation_funnel_events`. |
| Revisao de copy da landing React | EM_ANDAMENTO | Fazer rodada de copy e SEO apos dominio. |
| SEO, sitemap, robots, paginas indexaveis | EM_ANDAMENTO | Finalizar quando dominio definitivo estiver publicado. |
| Fallback da IA sem mock em producao | CONCLUIDO_PARCIAL | Produção bloqueia fallback deterministico como 200; benchmark reporta `mock_response_count=0`. Falta elevar taxa de sucesso sem fallback. |

## Evidencia Operacional Atual

- API nova validada em `https://evolution-cartinhas.2ta7qx.easypanel.host`.
- Web publica validada em `https://evolution-manaloom-web-public.2ta7qx.easypanel.host`.
- Migração `030` aplicada no banco novo em validacao anterior.
- Migração `031` aplicada no banco novo para `deck_comments` e
  `content_reports`.
- Deploy final validado no backend novo com SHA
  `7cd6fbf5eb99192bd7346933f4e3220734e1ec2e`.
- Smoke final validou plano Free, checkout bloqueado por provedor ausente,
  pos-jogo, timeline, relatorio publico, deck publico, comentarios, denuncia,
  trade match, exclusao do deck e limpeza do usuario temporario.
- Benchmark final de IA confirmou `mock_response_count=0`; quando a geracao
  falha na validacao, producao responde 422 em vez de mock 200.
- Backup automatico remoto instalado em `/opt/manaloom/scripts/postgres_backup.sh`
  com cron diario no EasyPanel novo.
- Restore automatico remoto instalado em
  `/opt/manaloom/scripts/postgres_restore_validate_latest.sh` com cron semanal.
- Backup real atual: `/opt/manaloom/backups/postgres/manaloom-postgres-20260706T173318Z.dump`
  com `279087037` bytes.
- Restore `schema` e restore `full` validados em container Postgres 17
  temporario com `82` tabelas publicas.
- Quality gate comercial passou em 2026-07-06:
  `docs/qa/runtime/manaloom-commercial-quality-gate-20260706T173758Z/summary.json`.
- Login Flutter Web local validado em `http://127.0.0.1:8088/app/#/login`,
  sem `RangeError` e sem erros de console.
- Fluxo pos-jogo agora leva diretamente para otimizacao/rebuild do deck com
  contrato testado em `post_game_optimization_cta_contract_test.dart`.
