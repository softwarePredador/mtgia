# Recaptura dos 34 manifestos no digest `ab2715e3`

> **Nota editorial (2026-10-08).** Registro histórico da árvore antiga do gate
> (backup `refs/backup/2026-10-08/gate-arvore-1419`), trazido como estava. Os
> digests `108f74a9` e `ab2715e3`, as contagens de manifestos e o estado de
> revisão daqui são daquela árvore. Depois dele, o master recapturou os
> manifestos num digest único (`e873943a0`, BT-UIEV-001;
> `docs/qa/execution/2026-10-06/btuiev001-recaptura-unica.md`). O bloqueio do
> pré-voo `core-product-android` em `flutter-tester` ganhou no master o factory
> sqflite ffi do host em `app/integration_test/flutter_test_config.dart`.
> Medido no port, com o mesmo comando do gate: com o arquivo anterior, `+0 -4`,
> todos em `MissingPluginException(getDatabasesPath)`; com o factory, `+2 -2`,
> sem erro de plugin, e as duas falhas restantes são de conteúdo do próprio
> teste, não do banco.

Data: 2026-09-23
Digest anterior: `108f74a9` · Digest corrente: `ab2715e3`

## Por que 34 e não 16

A correção do defeito que expulsava o jogador da mesa está em
`app/lib/core/config/release_capabilities.dart`, e `app/lib` está nas 49 raízes
de `scripts/manaloom_ui_source_digest.sh`. Corrigir mexeu no digest, então os 18
manifestos que ainda estavam correntes ficaram defasados junto com os 16 que já
estavam.

Não é retrabalho evitável: qualquer correção em `app/lib` teria o mesmo efeito, e
recapturar uma vez depois de todas as correções de app custa menos que
recapturar duas.

## O que é automatizável e o que não é

| categoria | pacotes | roteiro |
| --- | --- | --- |
| `ux-pack-02` a `ux-pack-08` | 21 | automatizado, roda sem intervenção |
| Android | 2 | `manaloom_p0_runtime_capture.sh`, precisa de emulador |
| **sem roteiro** | **11** | capturados à mão em 2026-07-28 |

Os 11 sem roteiro: `ux-pack-01-{card-printing,catalog,community,completion,deck-detail}-web`,
`battle-coach-web-keyboard`, `battle-live-web`, `card-back-fallback-web`,
`card-details-navigation-web`, `optimization-card-reader-web` e
`play-vs-ai-web-real`.

Conferido, não presumido: nenhum script em `scripts/` menciona esses pacotes,
salvo o próprio gate que os valida. Os manifestos deles registram
`runtime: in_app_browser` a 1280x720 e `generated_at` em julho — foram dirigidos
à mão.

Isso importa para o planejamento porque é exatamente a classe de trabalho que
consumiu horas hoje no `play-vs-ai-web-real`, e são onze.

## Resultado

Os 21 automatizáveis fecharam, cada roteiro com `EXIT=0` e `PASS_RUNTIME` nos
três perfis Web:

```
ux-pack-02 collection-import      ux-pack-06 onboarding-intent
ux-pack-03 deck-workshop          ux-pack-07 visual-system
ux-pack-04 battle-learning        ux-pack-08 critical-overlays
ux-pack-05 social-trade
```

Medido ao fim: **21 de 34 no digest `ab2715e3`**, 13 defasados — exatamente os
13 que exigem condução manual.

Falta ainda o terceiro nível do contrato para esses 21: `PASS_VISUAL_REVIEWED`
só vale depois de abrir **todas** as capturas. Os roteiros dizem isso na própria
saída ("Open all 21 PNGs before recording PASS_VISUAL_REVIEWED"), e nesta sessão
abrir a imagem foi o que pegou quatro evidências falsas que o código deixou
passar.

## O que o driver manual me ensinou

Abandonei o driver manual do `play-vs-ai-web-real` depois de cada iteração
revelar um defeito no meu próprio instrumento, não no produto:

| eu presumia | estava medido |
| --- | --- |
| painel em `x > 1000` | `x = 620` numa janela de 942 |
| viewport 1440x900 | **942x770**, janela em `y=939` |
| linhas clicáveis têm `role="button"` | no picker em 1440 vêm com `role=""` |
| opções do painel têm rótulo | em prompt de alvo são ladrilhos sem texto |
| meu campo = faixa entre dois cabeçalhos | faltava limitar por X: a coluna de decisão vazava para dentro |
| `\n` em regex JS | virou quebra de linha real, duas vezes |

Os dois piores eram silenciosos. O `except: return False` transformava erro de
sintaxe em "não achei o botão". E o campo sem limite de X gerou uma captura
rotulada `03-land-played` cuja imagem dizia **"Nenhuma permanente no campo"** —
só peguei porque abri a imagem, que é o que o contrato manda fazer e o que teria
evitado as outras capturas falsas desta sessão.

Nenhuma captura falsa foi aproveitada: todas foram apagadas, e o pacote
commitado de `play-vs-ai-web-real` está restaurado byte a byte.

## Correção: o gate também captura

Eu afirmei que 11 pacotes "não têm roteiro". Estava errado. Meu grep excluiu
`scripts/manaloom_ui_live_evidence_gate.sh` presumindo que ele só valida, e ele
também captura, em três modos:

| modo | pacote |
| --- | --- |
| `--capture-battle-coach` (alias `--capture-play-vs-ai`) | `battle-coach-android` |
| `--capture-core-product` | `core-product-android` |
| `--capture-battle-live-web` | `battle-live-web` |

`battle-live-web` foi capturado com `EXIT=0` e `PASS_RUNTIME`.

## Bloqueio pré-existente no Android

`--capture-core-product` falhou, mas **não na captura**: na etapa de pré-voo, que
roda o mesmo `integration_test` em `flutter-tester` (VM do host) antes de ir ao
emulador. Lá o sqflite não tem implementação:

```
MissingPluginException(No implementation found for method getDatabasesPath ...)
'package:flutter_test/src/binding.dart': Failed assertion:
    line 3081 pos 12: '_pendingFrame == null': is not true.
```

Medido, e não presumido, se a culpa era minha: rodei o pré-voo **duas vezes com
a minha versão e duas vezes com o arquivo em HEAD**. Os quatro resultados são
`+0 -4`. A falha é idêntica com e sem a minha mudança, portanto pré-existente.

(Uma execução isolada deu `+1 -3` e por um momento pareceu que eu tinha
agravado; repetir mostrou que era flakiness. Registrado porque a primeira
leitura teria me feito acusar a própria correção.)

Não contornei o pré-voo. Ele é um gate, e desligar gate para a captura passar é
exatamente o que o contrato existe para impedir.

## Os dois pacotes Android estão bloqueados, e não por esta sessão

| pacote | falha | culpa medida |
| --- | --- | --- |
| `core-product-android` | pré-voo em `flutter-tester`: `MissingPluginException(getDatabasesPath)` e `_pendingFrame == null` | 2 execuções com a minha versão e 2 com HEAD: `+0 -4` nas quatro |
| `battle-coach-android` | captura no emulador: `Play vs AI did not finish rendering every visible card image within the live-proof window` | 1 execução com a minha versão e 1 com HEAD: falha idêntica, `+1 -1`, "no evidence was approved" |

Em ambos o gate **recusou aprovar evidência** — comportamento correto, e a razão
de eu não ter contornado nenhum dos dois.

Nos dois casos eu medi antes de concluir, em vez de assumir que a falha era
ambiente. No primeiro isso importou: uma execução isolada deu `+1 -3` e teria me
feito acusar a própria correção.

## Um erro meu na revisão visual

Ao ver arte de carta como marcador quebrado no `ux-pack-02`, afirmei que era
próprio da fixture e "não é defeito da tela". Citei um contrato de device de
**outro** pacote (`card-back-fallback-web`, que de fato registra
"disposable card image URL absent"). O contrato do `ux-pack-02` não diz nada
disso:

```
Chrome real release build; Binder Import controlled Flutter surface requested
at 1440x900; device metrics DPR 1; symmetric near-white host margins cropped
```

E no `ux-pack-08` a arte do Sol Ring **renderiza** normalmente. Ou seja: não sei
se o marcador quebrado no `ux-pack-02` é esperado. Fica como pergunta aberta, não
como fato resolvido — generalizar o contrato de um pacote para outro foi
exatamente o tipo de atalho que esta sessão mostrou ser caro.

## Revisão visual concluída até aqui

| pacote | abertos |
| --- | --- |
| `battle-live-web` | 5 de 5 |
| `ux-pack-02-collection-import-web-desktop` | 7 de 7 |
| `ux-pack-08-critical-overlays-web-desktop` | 2 de 16 |

`PASS_VISUAL_REVIEWED` continua **não** concedido a nenhum pacote: o contrato
exige abrir todas as capturas de todos eles.
