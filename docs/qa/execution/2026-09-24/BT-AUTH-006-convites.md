# Receipt — BT-AUTH-006: admissão da coorte por convite — 2026-09-24

- Tarefa: `BT-AUTH-006`, Frente A (servidor, convite e segurança) da rodada de 2026-09-24,
  branch `servidor/rodada2-2026-09-24` a partir de `44cfc0eef`.
- Decisões do dono aplicadas:
  - D-16: convite de uso único, emitido por ele em lotes de 20 a 30, entregue por e-mail,
    com expiração e revogável; sem lista de espera; deixa de ser exigido quando o
    cadastro abrir.
  - D-56: aceitar o convite enviado ao e-mail conta como verificação do e-mail.
- Nada tocou a produção. Tudo rodou num PostgreSQL 17 descartável da frente (loopback,
  `LC_ALL=C`) e numa API local do worktree presa ao loopback. A migration 061 não foi
  aplicada fora dele.
- A capability `account_registration` continua desligada no manifesto. Com ela desligada,
  o cadastro segue negado antes do handler. Ligá-la é decisão do dono.

## O que mudou

- **Migration 061 (`create_beta_invites`), espelhada em `server/database_setup.sql`:**
  - `beta_invites` guarda:
    - o hash do código e o digest do e-mail convidado, nunca os dois em claro;
    - uma pista mascarada (`an***@example.com`) e o lote;
    - quem emitiu, a validade, a entrega, a revogação com motivo e o aceite, ligado à
      conta.
  - Um convite aberto por e-mail, pelo índice parcial `uq_beta_invites_open_email`.
  - `beta_invite_events` é a auditoria, sem dado pessoal: evento, ator, request-id e
    data.
  - O rollback só roda com a tabela vazia.
- **`POST /auth/register` no modo `invite`:**
  - O modo vem de `MANALOOM_REGISTRATION_ADMISSION`. É o padrão da produção; `open`
    abre o cadastro, e qualquer valor desconhecido fecha em `invite`.
  - O código do convite é obrigatório. O portão nega sem consultar o banco quando não há
    código ou o formato está errado.
  - Uma checagem só de leitura nega convite ruim antes do bcrypt.
  - Na transação do cadastro, o convite é travado com `FOR UPDATE` antes de qualquer
    escrita e marcado aceito junto com a conta. A conta já nasce com `email_verified_at`
    e sem token nem e-mail de verificação.
  - Códigos de negativa (403): `invite_required`, `invite_invalid` (código desconhecido
    ou de outro e-mail, sem revelar qual dos dois), `invite_expired`, `invite_revoked` e
    `invite_already_used`.
- **Limites:** por IP (o que já existia), por e-mail (`auth_register_email`) e por código
  (`auth_invite_code`, 10 por 15 min). Na produção são distribuídos, por
  `rate_limit_events`.
- **Caminho do dono:** `server/bin/beta_invites.dart`, com os comandos `emitir`,
  `reenviar`, `revogar` e `listar`.
  - É simulação por padrão, com prévia do e-mail.
  - `--aplicar` exige as duas aprovações canônicas e, fora do loopback, o
    `with_new_server_pg.sh --write-approved`.
  - No máximo 30 e-mails por lote, validade de 1 a 60 dias (padrão 14).
  - O e-mail vai pelo mesmo transporte das contas: template `beta_invite`, link
    `BETA_INVITE_APP_URL?invite_code=…` e o código para digitar.

## Evidência

| Teste | Onde | Resultado |
| --- | --- | --- |
| `server/test/beta_invite_policy_test.dart` | unitário | 23/23 |
| `server/test/beta_invite_registration_route_test.dart` | rota com pool roteirizado: nenhuma consulta além do previsto | 8/8 |
| `server/test/beta_invite_db_live_test.dart` | PostgreSQL descartável (`RUN_BETA_INVITE_DB_TESTS=1`) | 13/13 |
| `server/test/beta_invite_e2e_live_test.dart` | HTTP contra a API local em modo `invite`, e-mail verificado exigido, capabilities de cadastro e decks ligadas num manifesto isolado (`RUN_BETA_INVITE_E2E_TESTS=1`) | 6/6 |

O E2E cobre estes casos:

- **Válido:** 201, `email_verified: true`, `GET /auth/me` verificado e `POST /decks` 200
  sem passar pela verificação (D-56).
- **Sem convite:** 403 `invite_required`, com `x-request-id`.
- **Inválido:** 403 `invite_invalid`.
- **Expirado:** 403 `invite_expired` e nenhuma conta criada.
- **Replay:** o segundo cadastro dá 403 `invite_already_used`.
- **Concorrência:** 10 cadastros simultâneos com o mesmo convite resultam em uma conta só.

O teste de banco cobre ainda:

- emissão simulada sem gravar nada;
- emissão repetida sem duplicar;
- e-mail com conta ativa sem convite;
- convite expirado substituído;
- revogação idempotente;
- reenvio que troca o código;
- a trava: a segunda transação espera a primeira e encontra o convite usado.

**Mutações, cada uma restaurada depois** (todas fizeram os testes falharem):

| Mutação | Testes que falharam |
| --- | --- |
| M25: sem `FOR UPDATE` | concorrência e trava |
| M26: aceite sem `accepted_at IS NULL` | aceite duplo |
| M27: sem `invite_required` | portão, rota e banco |
| M28: sem expiração | política, rota e banco |
| M29: conta de convite sem e-mail verificado | cadastro válido |
| M30: sem a checagem antes do bcrypt | rota |

**Script do dono, contra o banco descartável e o fixture de e-mail do repositório** (o
fixture guarda só o template, o domínio e a presença do link):

1. Simulação: 2 `novo`, 1 `repetido`, 1 `email_invalido`, mais a prévia do e-mail. Nada
   foi gravado.
2. `--aplicar` sem as aprovações: `BLOCKED`, saída 3.
3. Com as aprovações: 2 convites `novo`, com envio `enviado`.
4. Repetido: 2 `ja_convidado`, sem e-mail novo.
5. `reenviar`: código novo, enviado.
6. `revogar`: `revogado`; na segunda vez, `sem_convite_aberto`.
7. `listar`: `aberto` e `revogado`, com o e-mail mascarado.

O fixture recebeu 3 e-mails `beta_invite`, nenhum com o código gravado.

## O que isto não prova

- **Não prova nada na produção.** A 061 precisa ser aplicada pelo dono, pela coordenação,
  e a capability precisa ser ligada.
- **O app ainda não mostra o campo de convite** nem lê `invite_code` do link. Isso fica
  para a raia do app, depois do `BT-UIEV-001`.
- **As dependências `BT-AUTH-001` e `BT-AUTH-002` ainda estavam abertas quando este
  receipt foi escrito.** A coordenação pôs esta tarefa antes delas.
- **A retenção das linhas de convite não aceito** (digest e pista do e-mail) ainda não
  tem regra. O mesmo vale para o convite de quem exclui a conta. Ficou registrado como
  pendência no diário da frente.
