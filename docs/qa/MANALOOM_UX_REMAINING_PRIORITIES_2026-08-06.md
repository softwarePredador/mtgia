# ManaLoom — pendências e prioridades UX após o UX-PACK-08

**Atualizado em:** 2026-08-07
**Escopo:** fechamento técnico da auditoria UX integral e ordem restante de
release; nenhuma autorização de migration, escrita live, deploy, commit ou push
**Digest UI final:**
`c25eb28be42b00787c8c40ffa24e15013de176d67015f098d10d8172b24099be`

## Leitura executiva

- `UX-PACK-01` a `UX-PACK-08`, polish responsivo P1 e polish P2 estão
  concluídos no escopo local autorizado.
- Os 25 manifests Web correntes somam 402 capturas em `PASS_RUNTIME`; todas as
  402 foram cobertas pela revisão visual final e reconciliadas sem divergência
  de arquivo, SHA-256, bytes, dimensão ou caminho duplicado.
- As 54 capturas obrigatórias do Samsung SM-A135M pertencem ao digest antigo e
  continuam `STALE`; o emulador disponível não foi aceito como substituto.
- O aggregate oficial não foi promovido. Enquanto o perfil físico estiver
  stale, os gates globais permanecem corretamente `FAIL-CLOSED`.
- A pesquisa jurídica em fontes oficiais e o briefing para o profissional
  habilitado estão prontos. Conforme a ordem definida pelo responsável do
  produto, o parecer jurídico externo assinado será a última etapa.

O ledger completo está em
[`MANALOOM_P0_GLOBAL_REANCHOR_CONTINUATION_2026-08-07.md`](MANALOOM_P0_GLOBAL_REANCHOR_CONTINUATION_2026-08-07.md).

Nova atividade autorizada antes da prova física:
[`MANALOOM_WEB_HOST_CANVAS_CONTINUITY_ACTIVITY_2026-08-10.md`](MANALOOM_WEB_HOST_CANVAS_CONTINUITY_ACTIVITY_2026-08-10.md).
Ela elimina o fundo branco externo à superfície Flutter. Como o shell Web
participa do digest, sua implementação exigirá nova reancoragem Web antes do
Samsung e do aggregate final.

## Estado dos pacotes

| Pacote | Estado técnico/visual atual | O que ainda pertence ao fechamento |
|---|---|---|
| `UX-PACK-01` — identidade/printing | `COMPLETE_LOCAL · CURRENT_WEB_REVIEWED` | somente participar do aggregate final depois da prova física |
| `UX-PACK-02` — coleção | `PHASE_1_COMPLETE_LOCAL · CURRENT_WEB_REVIEWED` | localização estruturada e scanner são decisões futuras de produto, não pendências do pacote fechado |
| `UX-PACK-03` — Oficina/Optimize | `COMPLETE_LOCAL · CURRENT_WEB_REVIEWED` | nenhum ajuste obrigatório; preservar preview, decisão humana, histórico e undo |
| `UX-PACK-04` — partida/aprendizado | `COMPLETE_LOCAL · CURRENT_WEB_REVIEWED` | nenhum ajuste obrigatório; preservar privacidade, exact-ID e handoff pós-jogo |
| `UX-PACK-05` — social/trades | `COMPLETE_LOCAL · CURRENT_WEB_REVIEWED` | pagamento, entrega, disputa e localização privada exigem contratos próprios antes de futura implementação |
| `UX-PACK-06` — onboarding/Home | `COMPLETE_LOCAL · CURRENT_WEB_REVIEWED` | progresso cross-device é decisão futura e exigiria contrato backend próprio |
| `UX-PACK-07` — sistema visual/wide | `COMPLETE_LOCAL · CURRENT_WEB_REVIEWED` | nenhum ajuste obrigatório; preservar estados, quota e dirty/save |
| `UX-PACK-08` — estados/prova/acessibilidade | `COMPLETE_LOCAL · CURRENT_WEB_REVIEWED · PHYSICAL_STALE` | recapturar o Samsung, fechar aggregate e executar verificações humanas |
| `POLISH-RESPONSIVO-P1/P2` | `COMPLETE_LOCAL · AUTOMATED_PASS · CURRENT_WEB_REVIEWED` | dois follow-ups P2 opcionais; nenhuma nova mudança antes da prova física é recomendada |

## Evidência corrente

| Superfície | Manifests | Capturas | Estado |
|---|---:|---:|---|
| Web P0 + Battle Live + UX-PACKs 02–08 | 25 | 402 | `PASS_RUNTIME · VISUAL_REVIEWED · RECONCILED` |
| Samsung SM-A135M físico | 1 | 54 | `STALE · DEVICE_NOT_CONNECTED · NOT_PROMOTABLE` |
| **Política total** | **26** | **456** | **`GLOBAL_AGGREGATE_PENDING`** |

Na revisão final, 129 imagens novas ou alteradas foram reabertas
individualmente; as outras 273 eram byte a byte idênticas a imagens já abertas
na mesma auditoria. Assim, a cobertura Web corrente é `402/402`, mas a cobertura
global corrente não pode ser chamada de `456/456` enquanto o perfil físico não
for recapturado.

## Prioridades restantes, na ordem correta

### P1-A — continuidade do canvas Web, autorizada

Corrigir o host HTML e o viewport do harness para que bootstrap, resize e
overlays nunca revelem faixas brancas. Validar por contrato automatizado e Web
real. Esta é a última mudança app-facing planejada antes do congelamento e
invalida as capturas Web correntes ao produzir o novo digest.

### P0-A — recaptura física obrigatória

Dependência externa: conectar o Samsung SM-A135M esperado e confirmar sua
identidade por ADB.

Depois disso:

1. iniciar somente a fixture PostgreSQL loopback descartável;
2. recapturar os 54 checkpoints físicos no digest final;
3. abrir individualmente as 54 imagens novas;
4. corrigir qualquer blocker real antes de gerar o aggregate;
5. encerrar a fixture e comprovar banco, listeners e credenciais removidos.

Não substituir o aparelho pelo emulador e não tratar `skipped` como saudável.

### P0-B — aggregate e gates oficiais

Somente depois da recaptura e revisão física:

1. reconciliar `26/26` manifests e `456/456` PNGs;
2. gerar `docs/qa/ui-live/latest.json` pela ferramenta oficial;
3. executar o evidence gate;
4. executar `./scripts/quality_gate.sh ui-proof`;
5. executar `./scripts/quality_gate.sh ui-audit`;
6. exigir `PASS_AUTOMATED · PASS_RUNTIME · PASS_VISUAL_REVIEWED`, sem
   carry-forward de crédito stale.

### P0-C — verificações humanas e de hardware

- TalkBack humano no Android físico;
- navegação Web com teclado de hardware real;
- smoke de câmera, scanner, deep links e comportamento de release no aparelho
  físico, apenas onde a feature estiver habilitada para esse escopo;
- VoiceOver/iOS somente se iOS entrar na release.

Essas verificações não podem ser substituídas por widget test, golden,
emulador ou inspeção automatizada.

### P0-D — parecer jurídico externo assinado, por último

Quando P0-A, P0-B e P0-C estiverem concluídos, encaminhar o briefing já pronto
a advogado habilitado para revisar LGPD, menores, consumidor, termos, beta/Pro,
social/trades, transferências internacionais e uso de propriedade intelectual.

Até existir parecer assinado, o lançamento comercial permanece bloqueado. A
pesquisa preparada pelo Codex organiza fontes e perguntas, mas não substitui
responsabilidade profissional nem constitui parecer jurídico.

Briefing:
[`MANALOOM_EXTERNAL_LEGAL_REVIEW_BRIEF_2026-08-07.md`](MANALOOM_EXTERNAL_LEGAL_REVIEW_BRIEF_2026-08-07.md).

## Backlog futuro que não bloqueia o fechamento atual

| Prioridade futura | Tema | Condição para iniciar |
|---|---|---|
| `P1 PRODUTO · DECISÃO` | localização estruturada da coleção | autorizar contrato de área/caixa/fichário/posição antes de qualquer migration |
| `P1 PRODUTO · DECISÃO` | scanner físico | homologar flag, hardware, permissão, fallback e contrato de release |
| `P1 PRODUTO · DECISÃO` | onboarding cross-device | definir persistência backend e política de sincronização |
| `P1 PRODUTO/LEGAL/SEGURANÇA` | pagamento, entrega, disputa e localização em Trade | definir mediação, privacidade, fraude, suporte e responsabilidades |
| `P2 EXPERIÊNCIA` | compartilhamento estruturado, diff e thread de feedback | promover a frente a pacote próprio com critérios de aceite |
| `P2 EXPERIÊNCIA` | usernames artificiais longos nas fixtures | trocar por nomes determinísticos realistas quando uma futura mudança já exigir recaptura |
| `P2 EXPERIÊNCIA` | padding sob o compositor persistente de Trade | revisar em uma futura rodada compacta sem reabrir o digest atual apenas por esse detalhe |

Qualquer nova alteração app-facing muda o digest e exige recaptura aplicável.
Por isso, a recomendação é congelar a UI até fechar P0-A a P0-C e deixar o
advogado como P0-D, último passo.

## Próximo sinal operacional

O único sinal necessário para continuar a execução técnica é:

```text
SAMSUNG SM-A135M CONECTADO E DESBLOQUEADO PARA RECAPTURA P0
```

Esse sinal autoriza apenas a fixture descartável de QA e a recaptura/revisão
previstas. Não autoriza migration, banco live, Hermes/SQLite, deploy, commit,
push, pins, regras ou decks.
