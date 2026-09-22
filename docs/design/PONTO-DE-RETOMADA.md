# Ponto de retomada — conversão visual do app para o padrão do contador

> Escrito em **2026-09-21 23:35** (horário local), numa parada geral pedida pelo dono para economizar
> tokens. Tudo abaixo está **untracked** em `docs/design/`. Nada foi commitado, nada em `app/` foi
> tocado, nenhum comando de flutter/dart/git de escrita foi rodado.
>
> Commit da árvore no momento da parada: `b397f477` · branch `codex/free-beta-release-candidate-2026-07-17`.

## Em uma frase

A auditoria, a spec do kit, a sequência das telas e o packet de implementação estão **prontos**. Os
mockups do **onboarding** estão na terceira rodada de correção (abortada no meio) e os do **gerador**
têm as três direções e o júri prontos, com a síntese abortada no meio.

## O que está pronto e não precisa ser refeito

| Arquivo | O que é |
|---|---|
| `visual-audit-2026-09-21/README.md` | Auditoria de 85 telas: nota por critério, 213 cheiros de formulário com `arquivo:linha`, errata com as 12 afirmações que não conferem |
| `visual-audit-2026-09-21/audit.json` | Bruto dos 19 agentes |
| `sequencia-e-esforco.md` | 6 ondas de conversão, esforço por tela, e as 9 capturas que faltam |
| `ui-kit/kit.css` + `tokens.json` | Kit CSS fiel ao protótipo: 133 tokens, 10 derivados, cada um com origem |
| `ui-kit/specimen-390.png` / `-1440.png` | Folha de espécimes, conferida contra a régua |
| `ui-kit/NOTAS-PARA-O-PROTOTIPO.md` | Defeitos achados no protótipo, para a sessão dona dele |
| `ui-kit-spec.md` | Spec do kit Flutter, 1.635 linhas, com contraste WCAG medido na geometria real do gradiente |
| `execution/BT-UX-KIT-001-proposto.md` | Packet de implementação. **É o primeiro NOW quando o dono mandar voltar** |
| `mockups/onboarding/inventario.md` | 94 funções, 21 estados |
| `mockups/gerador/inventario.md` | 125 funções, 25 estados |

## Onboarding — onde parou

> **Decidido pelo dono em 2026-09-22 (D-42):** mais uma rodada de correção antes de julgar o
> onboarding.

**Direções (prontas, não mexer):** `mockups/onboarding/dir-a|b|c/`, 6 estados cada.
Júri de três lentes: **B "Três batidas" venceu por unanimidade** (24 × 16 × 13). Enxertos aplicados:
de A a rima `0` × `99` e o herói tracejado; de C o bloco "Oficina · na Home" com arte real.

**Final:** `mockups/onboarding/final/` — 17 estados, 23 PNGs, todos mais novos que o `index.html`
(estado consistente). Última nota dos auditores: **beleza 6,5 · função 6**, nenhum dos dois aprovou.

**A rodada abortada estava atacando isto**, em ordem de importância:

1. **O conflito que causou a regressão.** Repor as descrições dos objetivos (ON-68) fez voltar
   subtítulo cinza embaixo de quase todo azulejo — seis de uma vez em `formato-390.png`. A regra
   de resolução está escrita na seção "Pendências que só existem aqui", abaixo.
2. `formato-390.png`: o numeral **`100` saiu em sans-serif**, não em Fraunces. É o maior elemento
   da tela e o único do pacote que quebra a família. Deve usar `.bt-numeral` do kit.
3. O azulejo "Criar do zero" é uma **caixa quase preta enorme e vazia** (~1030×1170px em 1920).
   Tracejado quer dizer "vazio, sem dono", não "buraco".
4. `negado-390.png` parece **wireframe não terminado**: tracejado dentro de tracejado, sem imagem,
   com duas faixas empilhadas brigando por herói.
5. `ajuste-390.png` **perdeu o ✕** — a regra é um único ✕, não zero.
6. Menores: "SEU PLANO" virou sopa de chips com setinhas de direção inconsistente na mesma fileira;
   fileira desalinhada em `retomado-390`; brilho de carregamento com borda dura lendo como artefato;
   parede de texto em `lista-390`; cromo de outra tela (sino e selo "3") dentro do overlay no desktop;
   véu caindo sobre texto pequeno em vez de sobre a mesa.
7. Função, bloqueantes: `#aviso` sem saída desenhada; falta o estado da batida 2 com o momento ainda
   pendente (criar `#momento`); `#erro` perdeu a live region; a trilha mente em `#retomado`;
   `#semia` usa a chave legada errada; a faixa tracejada some em `#leitura`, `#carregando` e `#sessao`.

**O que o crítico de beleza já assinou embaixo:** `jogar-390` (2×2 de assentos com 40 em cada),
`colecao-390` (6 miniaturas + 2 lugares tracejados) e `vazio-390`. Sobre o conjunto, comparando com o
onboarding de hoje (que ele pontuou 3/10): *"é outro planeta — é reconhecivelmente a mesma família do
contador"*. O desktop usa a largura de verdade, não é mobile esticado.

## Gerador de Decks com IA — onde parou

> **Decidido pelo dono em 2026-09-22 (D-42 de `docs/status/DECISOES_PENDENTES_2026-09-22.md`):** a
> direção A, "Bancada do comandante", está aprovada para a síntese, com os defeitos listados abaixo
> a resolver. O gerador é do Generate/Rebuild, que continua fora da primeira coorte.

**Direções (prontas, não mexer):** `mockups/gerador/dir-a|b|c/`.
Júri de três lentes: **A "Bancada do comandante" venceu nas três** (15 + 7,5 = 22,5 · B 16 · C 14).
**Nenhuma das três chegou ao nível do contador**, e os jurados disseram o que falta:

- A já está no nível em `#preenchido`, `#vazio`, `#gerando`, `#negado` e `#erro`.
- Defeitos de A a resolver na síntese: **dois ✕ na mesma tela** (o hub em latão e um segundo em brasa
  sobre a arte do comandante); `#resultado` e `#bloqueado` com **lista de texto dentro de caixa cinza**;
  e a receita **esconde as opções** — formato, bracket e orçamento são peças que mostram só o valor
  atual e giram no toque, então com pressa o usuário não vê o que existe.
- De B vale enxertar o que for objeto; o veto dela é a **nuvem de treze pílulas cinzas** com nome de
  carta em `#gerando` e `#resultado`, e a cor que deixou de carregar significado (cinco cores cheias
  numa fileira só).
- De C, o veto é **código de engenharia na cara do usuário** ("Chave 7C2F" em cinco telas) e a chapa de
  latão de ~400px com um numeral pequeno boiando. O acerto de C é a forja durante o job assíncrono.
- Um jurado levantou algo que vale para as duas telas: **nada foi provado no simulador do iPhone**,
  só em Chromium a 390×844, e `tools/contrast.py` do protótipo não foi rodado sobre os mockups.

**Final:** `mockups/gerador/final/` — parcial, 7 PNGs, HTML e PNGs consistentes entre si (re-renderizei
o que tinha ficado defasado). **Não confie nela**: a síntese foi abortada no meio e ainda não passou por
nenhum auditor.

## Próximo passo exato, quando o dono mandar voltar

1. **Terminar a síntese do gerador** a partir da direção A, aplicando os enxertos e vetos acima, e
   depois rodar função + beleza. (A versão parcial em `final/` pode ser descartada e refeita.)
2. **Terminar a última rodada do onboarding** com a lista de 1 a 7 da seção dele.
3. Mandar os PNGs das duas telas para o dono julgar pelo olho.
4. Só então, e **só depois de a coordenação confirmar que o gate de evidência de UI fechou**, abrir
   `BT-UX-KIT-001` em worktree próprio.

Os scripts dos workflows abortados ficaram salvos e podem ser retomados com `resumeFromRunId` — os
agentes já concluídos voltam do cache, sem custo:

- onboarding, última rodada: `wf_74535090-205`
- gerador, direções + júri + síntese: `wf_c3f42a4c-8f6`

## Pendências que só existem aqui

**1. A regra do azulejo** (derivada hoje, resolve um conflito que vai reaparecer em todas as 43 telas).
"Nenhuma função se perde" colide com "nada de subtítulo cinza" toda vez que uma tela tem escolha com
descrição. A resolução:

> O azulejo é ícone ou miniatura, mais o rótulo. Só. A descrição aparece **quando a escolha é feita**,
> dentro do herói, junto da frase de confirmação. Quando ela precisa existir antes da escolha, vira
> **palavra de estado curta no canto** do objeto — o slot onde a régua põe "VALE" e "SEM DONO" — nunca
> uma segunda linha embaixo do rótulo. Teto: **uma** linha de texto corrido fora de um objeto por tela.

Gravada na memória do projeto, em `feedback-visual-quality-over-forms.md` (confirmado em disco).

**2. A âncora da evidência automática do onboarding.** A captura de `onboarding_core_flow` roda no
estado `empty` e é ancorada na chave `onboarding-format-dropdown`. O redesenho **elimina esse dropdown**:
o formato vira um segundo nível, e a chave deixa de existir na primeira tela. Quando o onboarding virar
código, `app/test/ui/fixtures/ui_authenticated_visual_matrix.json` vai precisar de **âncora e estado
novos**, senão a captura quebra ou fotografa a tela errada. Nenhuma outra sessão tem esse achado.

**3. Decisões do dono que continuavam em aberto** (ratificadas em 2026-09-22, D-44: o protótipo já
resolveu A7, C2/C3, D1 e E1, e o dono aprovou as saídas propostas; ver a nota no topo da §11 da spec) — estão na §11 da `ui-kit-spec.md`, com a conta de cada
uma: A7 (ícone da coroa a 2,81 de contraste), C2/C3 (brasa cheia reprova no título e no estado), D1
(fio da placa a 1,84), E1 (brasa cheia e o assento vermelho são quase a mesma cor), F1 (já decidida por
mim: literais de cor ficam no `app_theme.dart`). Duas delas exigem mexer no protótipo, que é de outra
sessão.
