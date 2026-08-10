# ManaLoom — continuação da reancoragem P0 e revisão visual integral

Data: 2026-08-07
Digest UI final: `c25eb28be42b00787c8c40ffa24e15013de176d67015f098d10d8172b24099be`
Estado: `WEB_FINAL_VISUAL_REVIEW_COMPLETE · 25_MANIFESTS_402_CURRENT · ANDROID_PHYSICAL_REQUIRED_STALE · AGGREGATE_FAIL_CLOSED · HUMAN_CHECKS_PENDING · COUNSEL_SIGNOFF_LAST`

## Decisão executiva

Todo o trabalho técnico e visual executável sem o aparelho físico foi
concluído. Os 25 manifests Web obrigatórios foram recapturados no digest final,
somam 402 PNGs e passaram por reconciliação de arquivo, SHA-256, bytes,
dimensões, contagem e unicidade.

A cobertura visual final dos 402 PNGs Web também foi concluída:

- 273 imagens eram byte a byte idênticas a capturas já abertas nesta mesma
  auditoria;
- 129 imagens novas ou alteradas foram reabertas individualmente depois da
  última mudança de UI;
- nenhum blocker visual foi encontrado;
- duas observações P2 não bloqueantes permanecem: nomes artificiais muito
  longos da fixture ainda geram composição pouco natural em Profile, e o
  compositor fixo do detalhe de Trade exige rolagem para rever o último item
  em viewports compactos.

O Samsung SM-A135M físico obrigatório não estava conectado. O ADB mostrou
somente `emulator-5554`; ele não foi usado nem rotulado como aparelho físico.
Consequentemente, o manifest `android_physical_sm_a135m` e suas 54 capturas
continuam no digest antigo `a2fcd795…` e não recebem crédito corrente.

Por isso:

- `25/26` manifests e `402/456` capturas estão no digest final;
- `1/26` manifest e `54/456` capturas físicas estão stale;
- `docs/qa/ui-live/latest.json` permanece como o último aggregate histórico,
  no digest `f45f96e3…`, e não foi promovido manualmente;
- `PASS_VISUAL_REVIEWED` global e `PASS` de release não foram concedidos;
- os gates oficiais permanecem fail-closed até a recaptura física.

## Implementação final antes da captura

Além do polish P1/P2 já descrito nos relatórios próprios, a última rodada
fechou três resíduos detectados durante a recaptura:

1. o helper do importador de Fichário passou a reservar duas linhas, evitando
   compressão do campo;
2. `Enviar proposta` só fica habilitado quando o rascunho de Trade contém todos
   os itens ou pagamento exigidos pelo tipo de negociação;
3. o harness de onboarding restaura o viewport Web antes dos screenshots,
   removendo o deslocamento horizontal do canvas entre checkpoints.

Analyzer, testes focais e project logic foram repetidos após essas mudanças.

## Execução P0 autorizada

A fixture autorizada permaneceu exclusivamente loopback e descartável:

- run dir:
  `/var/folders/33/24q27rwn2v5_h9gfctty7t_40000gn/T/manaloom_visual_qa/20260807T204639Z_40538_3226`;
- API: `127.0.0.1:51368`;
- Web: `127.0.0.1:51437`;
- banco descartável: `manaloom_s1_api_20260807T204640Z_40551`;
- Chrome/ChromeDriver: versão 151 compatível;
- coordenadas de produção: proibidas pela própria fixture.

Resultados P0:

| Perfil | Capturas | Digest | Resultado |
|---|---:|---|---|
| Web mobile 390×844 | 54 | `c25eb28b…` | `PASS_RUNTIME · VISUAL_REVIEWED` |
| Web desktop 1440×900 | 53 | `c25eb28b…` | `PASS_RUNTIME · VISUAL_REVIEWED` |
| Web wide 1920×1080 | 53 | `c25eb28b…` | `PASS_RUNTIME · VISUAL_REVIEWED` |
| Samsung SM-A135M físico | 54 | `a2fcd795…` | `STALE · DEVICE_NOT_CONNECTED · NOT_PROMOTABLE` |

O perfil físico não foi tratado como skipped saudável. Não houve tentativa de
limpar o checkout, reaproveitar o emulador ou transportar crédito antigo.

## Ledger dos 26 manifests e 456 capturas

| Superfície | Manifests | Capturas | Estado no digest final |
|---|---:|---:|---|
| P0 Samsung físico | 1 | 54 | `STALE · HISTORICAL_ONLY` |
| P0 Web mobile/desktop/wide | 3 | 160 | `PASS_RUNTIME · VISUAL_REVIEWED` |
| Battle Live | 1 | 5 | `PASS_RUNTIME · VISUAL_REVIEWED` |
| UX-PACK-02 — Collection Import | 3 | 21 | `PASS_RUNTIME · VISUAL_REVIEWED` |
| UX-PACK-03 — Deck Workshop | 3 | 27 | `PASS_RUNTIME · VISUAL_REVIEWED` |
| UX-PACK-04 — Battle Learning | 3 | 30 | `PASS_RUNTIME · VISUAL_REVIEWED` |
| UX-PACK-05 — Social/Trade | 3 | 48 | `PASS_RUNTIME · VISUAL_REVIEWED` |
| UX-PACK-06 — Onboarding Intent | 3 | 15 | `PASS_RUNTIME · VISUAL_REVIEWED` |
| UX-PACK-07 — Visual System | 3 | 30 | `PASS_RUNTIME · VISUAL_REVIEWED` |
| UX-PACK-08 — Critical Overlays | 3 | 66 | `PASS_RUNTIME · VISUAL_REVIEWED` |
| **Total Web corrente** | **25** | **402** | **`COMPLETE`** |
| **Total da política** | **26** | **456** | **`1/54 PHYSICAL_STALE`** |

## Reconciliação técnica final da Web

Os 25 manifests correntes foram comparados com os arquivos reais:

- manifests esperados/encontrados: `25/25`;
- screenshots declaradas/encontradas: `402/402`;
- caminhos únicos: `402`;
- caminhos duplicados: `0`;
- arquivos ausentes: `0`;
- divergências de SHA-256: `0`;
- divergências de bytes: `0`;
- divergências de dimensão: `0`;
- manifests fora de `PASS_RUNTIME`: `0`;
- manifests Web fora do digest final: `0`.

O manifest físico continua coerente internamente, mas é stale por digest. Isso
é uma pendência de freshness, não uma autorização para carry-forward.

## Parecer visual

### Pontos fortes confirmados

- onboarding começa pela intenção do jogador e conduz a uma ação real;
- Home, decks, Card Reader, Sample Hand, Fichário, Battle e Trade usam objetos
  de Magic como âncoras visuais, evitando aparência de painel genérico;
- matches de Trade preservam largura útil em mobile e usam composição
  mestre–detalhe em desktop/wide;
- revisão de proposta mostra carta, printing, foil, idioma, condição,
  quantidade e diferença de valor antes do envio;
- importação de Fichário mantém fonte, fila, plano, confirmação, falha parcial,
  retry e histórico legíveis nas três larguras;
- estados vazios, loading, saving, erro, reconnect, sessão expirada,
  indisponibilidade e conclusão apresentam próxima ação clara;
- overlays críticos preservam contexto e distinguem cancelar, tentar novamente,
  confirmar e concluir.

### Follow-ups não bloqueantes

- substituir, em uma futura rodada que já toque as fixtures, usernames baseados
  em timestamp por nomes determinísticos realistas;
- reservar padding de rolagem ainda mais explícito sob o compositor persistente
  de Trade em telas compactas;
- continuar aumentando densidade contextual nas superfícies wide que exibem
  apenas um único resultado, sem preencher o canvas com decoração sem função.

Esses itens não justificam invalidar novamente os 402 PNGs Web antes da prova
física. Qualquer mudança app-facing futura criará novo digest e exigirá nova
recaptura aplicável.

## Gates executados

No digest final:

- analyzer do `ui-audit`: `PASS`;
- testes do `ui-audit`: `56/56 PASS`;
- testes focais finais de Fichário/Trade: `20/20 PASS`;
- integração focal de onboarding: `1/1 PASS`;
- project logic: `8/8` artefatos sincronizados após a consolidação documental;
- `./scripts/manaloom_ui_live_evidence_gate.sh --check`: `FAIL-CLOSED`;
- `./scripts/quality_gate.sh ui-proof`: `FAIL-CLOSED`;
- `./scripts/quality_gate.sh ui-audit`: analyzer e `56/56 PASS`, seguido de
  `FAIL-CLOSED` somente no vínculo global de evidência.

A recusa global é esperada porque `latest.json` ainda referencia o digest e os
hashes históricos e porque o único perfil físico obrigatório está stale. Não
há falha de integridade nos 402 PNGs Web correntes.

## Limpeza da fixture

`cleanup-summary.json` registrou:

- `database_remaining=0`;
- `web_listeners=0`;
- `api_listeners=0`;
- `credentials_file_removed=true`.

O código de saída original `130` corresponde à interrupção controlada depois
das capturas Web, quando ficou comprovado que o Samsung não estava disponível.
A limpeza removeu banco, credenciais e listeners mesmo nesse caminho.

## Ordem restante, com advogado por último

1. conectar e atestar por ADB o Samsung SM-A135M físico;
2. reiniciar somente a fixture PostgreSQL loopback descartável;
3. recapturar `54/54` checkpoints de `android_physical_sm_a135m` no digest
   `c25eb28b…`;
4. abrir individualmente as 54 novas capturas físicas e corrigir eventual
   blocker antes de qualquer aggregate;
5. reconciliar os 26 manifests/456 PNGs e gerar `latest.json` pela ferramenta
   oficial;
6. repetir evidence gate, `ui-proof` e `ui-audit` até PASS;
7. executar TalkBack humano, teclado Web de hardware real e smoke de hardware
   no Android físico;
8. **por último**, encaminhar o briefing já pronto a advogado habilitado e
   obter o parecer assinado antes de qualquer lançamento comercial.

O briefing jurídico permanece em
[`MANALOOM_EXTERNAL_LEGAL_REVIEW_BRIEF_2026-08-07.md`](MANALOOM_EXTERNAL_LEGAL_REVIEW_BRIEF_2026-08-07.md)
com estado
`OFFICIAL_SOURCE_REVIEW_COMPLETE · LICENSED_COUNSEL_SIGNOFF_PENDING · COMMERCIAL_RELEASE_BLOCKED`.

Nenhum commit, push, migration, deploy, pin, regra, deck, PostgreSQL live,
Hermes, SQLite ou runtime de produção foi alterado.
