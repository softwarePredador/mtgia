# Harness WebDriver: o que ele prova e por que existe

> **Nota editorial (2026-10-08).** Registro histórico da árvore antiga do gate
> (backup `refs/backup/2026-10-08/gate-arvore-1419`), trazido como estava. O
> harness entrou no master depois, em `scripts/lib/`, com três mudanças sobre
> o que está descrito aqui: o PID do navegador vem da própria sessão
> (`goog:processID`), não de um `pgrep` global que podia achar o Chrome de
> outra corrida; o ChromeDriver nasce numa sessão de processo própria e o
> encerramento mata o grupo inteiro (`killpg`), com `TMPDIR=/tmp`; e
> `resolver_binarios` resolve o ChromeDriver pelo pin de
> `scripts/lib/manaloom_chromedriver.sh`, falhando fechado se o major dele não
> for o do Chrome. Medido no port: com a versão daqui, uma sessão abandonada
> sem `DELETE` deixou o Chrome órfão; com a do master, não.

Data: 2026-09-24
Arquivo: `scripts/lib/manaloom_webdriver_capture.py`

## Por que não dá para usar `flutter drive` nesses pacotes

Quatro pacotes provam justamente o caminho que o evento sintético do Flutter
pula: histórico do navegador, hover e teclado físico sobre platform view. A arte
da carta na web é um `<img>` de plataforma
(`app/lib/core/widgets/cached_card_image.dart:285-288`), e é ali que a web
costuma falhar.

Eu tinha proposto capturar dois deles por `flutter drive`, reescrevendo o
`device_contract` para descrever a corrida mais fraca. A coordenação recusou com
um argumento melhor que o meu: eu olhei para o estado final da tela, eles
olharam para o caminho que o pacote prova. Aceito e registrado.

## O que o harness prova, medido

| capacidade | prova em 2026-09-24 |
| --- | --- |
| histórico real | `dois` → `voltar` → `um` → `avancar` → `dois` |
| teclado físico | Tab foca `INPUT`, digita, Tab vai ao botão, Shift+Tab volta |
| hover real | `rgb(0,0,255)` → `rgb(255,0,0)` ao parar o ponteiro |
| tamanho da captura | lê largura e altura do IHDR do PNG e aborta se divergir |

## As seis regras, cada uma cicatriz de evidência falsa

A corrida manual do `play-vs-ai-web-real` produziu evidência falsa **quatro
vezes** num único dia, e as quatro só foram pegas porque alguém abriu a imagem,
nunca pelo código. As regras existem para que o instrumento não minta de novo:

1. **Viewport conferida, nunca presumida.** A janela apareceu com 942x770
   quando o contrato pedia 1440x900. As capturas teriam ido embora fora do
   contrato sem ninguém notar.
2. **Foco reafirmado a cada leitura.** `battle_coach_screen.dart:100` faz
   `_appActive = state == resumed`. Janela visível mas sem foco já conta como
   inativa: o tabuleiro congela e o prazo do prompt expira no servidor.
3. **Rótulo é folha pequena.** Só `children.length <= 1` deixa passar o
   contêiner da tela inteira, cujo `textContent` contém tudo — isso gerou três
   capturas mentirosas, uma delas rotulada `03-land-played` numa tela que dizia
   "Nenhuma permanente no campo".
4. **Clique não exige `role="button"`.** A mesma linha vem com `role=""` numa
   largura e `role="button"` noutra.
5. **JS em string raw.** `\n` dentro de regex virou quebra de linha real duas
   vezes, e o erro aparecia como "não achei o elemento".
6. **Falha de JS é registrada, nunca engolida.** `except: return False`
   transformou erro de sintaxe em "não achei o botão" e matou duas corridas.

A regra 6 se provou na primeira execução: três erros do meu próprio cenário de
teste apareceram altos e imediatos, em vez de virarem silêncio.

## Onde ele mora

No repositório, não em `/tmp`. O harness anterior vivia em `/tmp/qa` e sumiu num
reinício de sessão, levando junto tudo que eu tinha aprendido nele.

## Headless, a pedido do dono

O dono pediu que tudo rode sem abrir janela: janelas surgindo e roubando o foco
atrapalham quem está usando a máquina. O harness passou a usar `--headless=new`
por padrão — o próprio Chrome sem janela, mesmo motor, com as ações do WebDriver
continuando a gerar eventos reais por CDP.

Medido em 2026-09-24, sem janela:

| capacidade | headless |
| --- | --- |
| viewport 1280x720 | conferida |
| `document.hasFocus()` | **true** |
| hover real | `rgb(0,0,255)` → `rgb(255,0,0)` |
| teclado físico | Tab → `INPUT`, digita, Tab → botão, Shift+Tab volta |
| histórico real | voltar → `um`, avançar → `dois` |
| captura | tamanho conferido contra o contrato |

A captura headless do `01_deck_card_preview_modal` é indistinguível da feita com
janela: CanvasKit, fontes e arte renderizam igual.

### Uma armadilha que headless NÃO remove

`--window-size=1280,720` **não** define a viewport: ela sai 1280x577, medido. O
navegador reserva altura também sem janela, e quanto reserva varia por modo e
versão. Quem presumir que a flag basta entrega capturas fora do contrato sem
perceber — que é precisamente a regra 1. A busca pela altura que produz a
viewport pedida agora vale nos dois modos.

### Um problema que headless remove

Sem janela não há disputa de foco do sistema, e `document.hasFocus()` é sempre
verdadeiro. O polling da mesa em `battle_coach_screen.dart:100` para quando o
app não está `resumed`, e foi isso que abandonou sessões do `play-vs-ai` no
turno 1 enquanto o prazo do prompt corria no servidor. Em headless esse modo de
falha deixa de existir.

## Morte certa do navegador

Um Chrome deste harness ficou **17 horas e meia órfão, com janela aberta**, na
máquina do dono. A causa é banal e minha: o `finally` do script não roda quando
o processo é morto — e eu matei scripts com `pkill` várias vezes ao depurar. O
`DELETE /session` também não chega quando o ChromeDriver já caiu.

O encerramento passou a ter três camadas, nenhuma dependendo da anterior:
`atexit`, handlers de `SIGINT`/`SIGTERM`/`SIGHUP`, e o PID do navegador morto
direto quando o WebDriver não responde.

Provado nos três cenários, com `pgrep` direto (contar por `grep` inflava o
número com o próprio pipeline):

| cenário | Chrome sobrevivente |
| --- | --- |
| fim normal | 0 |
| exceção sem `fechar()` explícito | 0 |
| **script morto por `pkill`** | 0 |

O ChromeDriver também passou a ter vida atada à corrida, via a classe
`ChromeDriver` usada como contexto. Nada de navegador ou driver vivo entre
capturas: driver vivo entre corridas é justamente o que deixa um navegador
sobreviver sem ninguém reparar.
