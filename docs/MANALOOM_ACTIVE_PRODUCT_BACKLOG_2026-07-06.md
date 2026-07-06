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
| Backup automatico do Postgres novo | EM_ANDAMENTO_VALIDADO_MANUALMENTE | Backup real gerado por `scripts/manaloom_easypanel_backup.sh`; falta agendar rotina recorrente. |
| Restore real de backup | EM_ANDAMENTO_VALIDADO_MANUALMENTE | Restore schema validado em Postgres 17 temporario remoto; falta rotina recorrente/full em janela controlada. |
| Remover dependencia operacional do droplet antigo | EM_ANDAMENTO_BLOQUEADO_EXTERNO | Executar apos DNS final e janela de convivencia. |
| Padronizar `.env`, deploy e runbooks | EM_ANDAMENTO | Atualizar `server/.env.example` e runbook a cada novo servico. |

## 2. App Flutter Producao

Objetivo: app mobile/web usando o backend novo com prova de fluxo real.

| Item | Status | Proxima execucao |
| --- | --- | --- |
| Apontar app para dominio definitivo | EM_ANDAMENTO_BLOQUEADO_EXTERNO | Trocar `--dart-define` quando o dominio final existir. |
| Atualizar builds Android/iOS/Web para API nova | EM_ANDAMENTO | Rodar build release com API nova apos DNS final ou host temporario aprovado. |
| Revalidar login/cadastro/decks/colecao/marketplace/IA | EM_ANDAMENTO | Usar `scripts/manaloom_product_smoke.sh` e QA mobile visual. |
| Revalidar Sentry/logs/erros reais | EM_ANDAMENTO | Rodar scripts de Sentry quando DSN/projeto estiverem configurados. |
| Garantir ausencia de mocks em telas principais | EM_ANDAMENTO | Auditar `mock/fallback/demo/sample` antes de release. |
| Revisar botoes, modais, loaders, empty states e erros | EM_ANDAMENTO | Rodar QA visual focado nos fluxos comerciais e IA. |

## 3. Monetizacao

Objetivo: usuario entende Free/Pro, limite, valor do Pro e caminho de upgrade.

| Item | Status | Proxima execucao |
| --- | --- | --- |
| Tela Free/Pro | CONCLUIDO_PARCIAL | Validar copy e responsividade no QA final. |
| Medidor de uso de IA | CONCLUIDO_PARCIAL | Confirmar leitura remota em app logado. |
| Limite por plano | CONCLUIDO_PARCIAL | Monitorar `402` no middleware de IA. |
| Paywall ao atingir limite | CONCLUIDO_PARCIAL | Testar nos fluxos reais de generate/optimize/rebuild. |
| Upgrade dentro do app | CONCLUIDO_PARCIAL | Integrar URL real de checkout. |
| Checkout/pagamento | EM_ANDAMENTO_BLOQUEADO_EXTERNO | Escolher provedor e implementar adaptador do webhook. |
| Termos, privacidade, disclaimer e IA/IP | EM_ANDAMENTO_BLOQUEADO_EXTERNO | Revisao juridica final. |

## 4. Diferencial Da IA

Objetivo: recomendacao confiavel, explicada e adaptada ao contexto do jogador.

| Item | Status | Proxima execucao |
| --- | --- | --- |
| Melhorar deck usando cartas da colecao | EM_ANDAMENTO | Validar UX e cobertura de owned cards no optimize. |
| Melhorar deck por orcamento | EM_ANDAMENTO | Validar `budgetLimitBrl` em fluxo real. |
| Explicar troca por funcao/risco/curva/preco/bracket | EM_ANDAMENTO | Expandir apresentacao no app e relatorio publico. |
| Relatorio antes/depois compartilhavel | CONCLUIDO_PARCIAL | Melhorar visual e CTA publico. |
| Sugestao por Commander Bracket | CONCLUIDO_PARCIAL | Validar bloqueios por bracket com casos reais. |
| Rebuild guiado casual/upgraded/optimized/cEDH | EM_ANDAMENTO | Expor intencao no app com UX mais clara. |

## 5. Retencao

Objetivo: ManaLoom acompanha a vida do deck depois da primeira criacao.

| Item | Status | Proxima execucao |
| --- | --- | --- |
| Historico de partidas | CONCLUIDO_PARCIAL | Endpoint `GET /decks/:id/post-game-timeline` e tela pos-jogo com historico. |
| Notas pos-jogo | CONCLUIDO_PARCIAL | Validar sync e UX em deck real. |
| Cartas que performaram bem/mal | CONCLUIDO_PARCIAL | Exibir agregados por deck. |
| Diagnostico mana/compra/remocao/win condition | CONCLUIDO_PARCIAL | Backend agrega issues e gera diagnosticos/acoes. |
| Sugestao automatica depois da partida | CONCLUIDO_PARCIAL | Backend retorna `next_actions`; falta CTA direto para optimize/rebuild. |
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
| QA completo web/mobile | EM_ANDAMENTO | Rodar smoke automatizado + QA visual. |
| Performance da geracao de decks | EM_ANDAMENTO | Monitorar `/health/commercial` e `ai_logs`. |
| Tempo medio por endpoint de IA | EM_ANDAMENTO | Usar `/health/metrics` e `/health/commercial`. |
| Metricas de conversao | EM_ANDAMENTO | Usar funil `activation_funnel_events`. |
| Revisao de copy da landing React | EM_ANDAMENTO | Fazer rodada de copy e SEO apos dominio. |
| SEO, sitemap, robots, paginas indexaveis | EM_ANDAMENTO | Finalizar quando dominio definitivo estiver publicado. |
| Fallback da IA sem mock em producao | EM_ANDAMENTO | Validar `OPENAI_PROFILE=prod` e smoke sem resposta mockada. |

## Evidencia Operacional Atual

- API nova validada em `https://evolution-cartinhas.2ta7qx.easypanel.host`.
- Web publica validada em `https://evolution-manaloom-web-public.2ta7qx.easypanel.host`.
- Migração `030` aplicada no banco novo em validacao anterior.
- Backup real gerado em `backups/manaloom-postgres/` e restore schema validado
  em container Postgres 17 temporario com `80` tabelas publicas.
- Scripts adicionados para repetir backup, restore e smoke sem depender de
  execucao manual ad hoc.
