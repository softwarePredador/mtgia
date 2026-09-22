# Ponto de retomada — coordenação das sessões do mtgia — 2026-09-21

> Lifecycle: `HISTORICAL_EVIDENCE · SUPERSEDED · NO_MUTATION_AUTHORITY`.
> Fotografia do fim de 2026-09-21, escrita para retomar a pausa pedida pelo dono. Superada por
> `docs/status/ESTADO_DO_PROJETO_2026-09-22.md` (estado verificado) e por `docs/verdade/FATOS.md`
> (evidência linha a linha). Não executar nem priorizar a partir daqui.
> Correções feitas nesta fotografia em 2026-09-22: o app tem **46** rotas (`GoRoute`), não 48 —
> 48 é a contagem de `path:`, que inclui dois `Uri(`; os rascunhos de fluxo já foram copiados
> para `docs/flows/`; a medição das P0 foi retomada; as datas de decisão do dono são 2026-09-21.

- Escrito pela sessão coordenadora "Atividade de agentes ativos no MTGIA".
- Commit base observado: `d15beb05b`.
- Motivo da pausa: pedido do Rafa para economizar tokens.

---

## 1. O que cada frente estava fazendo

### Frente A — gate de evidência de UI (`BT-UIEV-001` / `BT-SCP-001`)
Sessão "Nex-N2.5-Pro limite de uso". **Encerrada por conta própria, em ponto seguro.**
Ponto de retomada dela, mais detalhado que este: `docs/qa/execution/2026-09-21/PONTO_DE_RETOMADA.md`.

- 22 dos 23 manifests que o `latest.json` referencia estão verdes no digest `8bba809c`.
- Perfil Android fechou (exit 0, zero falhas de imagem) depois de `-wipe-data` no AVD
  `ManaLoom_API34` — **os dados daquele AVD foram apagados**; foi isso que consertou a rede dele.
- ChromeDriver `153.0.8010.52` é o pin novo, em cache permanente.
- **Bloqueio corrente (item 1 da retomada dela):** `manaloom_play_vs_ai_e2e.sh` invoca
  `manaloom_server_contract_e2e_isolated.sh` duas vezes; a segunda para em
  `BLOCKED: build output has a consumer` porque o servidor da primeira ainda não soltou
  `server/build`. Reproduzido 2×; logo após a falha o `lsof` não devolve nada. A guarda está
  certa — falta o estágio esperar a liberação. **Detalhe operacional:** o script recria a pasta
  de captura vazia antes de falhar; conferir e remover antes de cada nova tentativa.

### Frente B — contador de vida, linguagem visual nova
Sessão "Leitura e compreensão do projeto".

- Fila de telas secundárias **fechada**: menu, jogadores, regras, dados, quem começa, folha do
  jogador, turnos, plano, partidas guardadas, partida aberta, resumo, teclado de vida e quem
  fica com a peça. 16 provas de aparelho (iPhone) em
  `docs/design/life-counter-prototype/provas-iphone/`.
- Suíte própria do protótipo em 81/81, com réguas novas (distância de cor de estado até cor de
  jogador; nada cortado; nada sob o ✕; alvo ≥ 44px; apagar em dois toques).
- Regra medida que saiu daqui: **a cor de estado ruim precisa estar a ΔE ≥ 25 de toda cor de
  jogador**. A cor "Vinho" saiu da paleta por estar a ΔE 10; entrou "Oliva".
- **Onda 8 entregue**, dentro da escolha do Rafa: catálogo só com fileira de até três (2+1/1+2,
  3+1/2+2/1+3, 3+2/2+3, 3+3) e, de sete jogadores em diante, a divisão equilibrada de sempre, sem
  oferecer escolha que não cumpra o piso. Travado pelas checagens 82 e 83; provado no iPhone
  (`provas-iphone/vt-17-mesa-arranjo.png`, `vt-18-arranjo-3-1.png`), numeral a ±2 px do centro de
  cada card. Suíte em 83/83.
- **Os dois itens de contraste que estavam abertos foram RESOLVIDOS** (medidos em pixel, não
  derivados do CSS): ícone sobre a peça coroa acesa 2,81 → **3,49** (clareando o topo do gradiente
  da peça, não o ícone); fio da placa em repouso 1,84 → **4,09**. Ambos entraram na checagem 76,
  que derruba a suíte em qualquer REPROVA.
- **A onda 8 destapou uma decisão do Rafa que ainda está aberta — ver §6, item 7.** Nenhuma linha
  de código assume qualquer uma das saídas.
- **Onda 9 (arte do card) mal começou** — a sessão foi interrompida nos primeiros passos de
  reconhecimento, sem trabalho a perder. Onda 10 (busca de card) não começou.

### Frente C — auditoria visual, kit de UI e mockups
Sessão "Consistência visual do app".

- Auditoria das telas fora do contador: `docs/design/visual-audit-2026-09-21/`. Notas de 3,5 a 5
  de 10 contra a régua do contador; nível dominante "formulário". 213 cheiros de formulário com
  arquivo:linha. **Errata registrada: 12 de 92 `arquivo:linha` conferidos não bateram** — conferir
  a linha antes de abrir qualquer tarefa a partir da auditoria.
- Kit extraído do protótipo: `docs/design/ui-kit/` (`kit.css`, `tokens.json` com 114 tokens,
  espécimes) e a spec em `docs/design/ui-kit-spec.md` (1.635 linhas, com contraste WCAG calculado
  no ponto onde o texto cai sobre o gradiente).
- Task packet pronto: `docs/design/execution/BT-UX-KIT-001-proposto.md`. **O ID é proposto e não
  existe no registry.**
- Decisão técnica assumida por ela (F1): os literais de cor ficam em `app_theme.dart`;
  `bt_tokens.dart` não tem nenhum, para não abrir uma quinta isenção no teste de uso de token.
- **Estado na pausa:** onboarding em rodada de correção (nota 6,5; defeitos conhecidos: numeral em
  sans-serif em vez de Fraunces, azulejo "Criar do zero" virando retângulo preto vazio); gerador
  com as três direções rodando.
- Regra permanente que saiu daqui, vale para as 43 telas: **o azulejo é ícone/miniatura + rótulo,
  só.** A descrição aparece quando a escolha é feita, dentro do herói; se precisa existir antes,
  vira palavra de estado curta no canto do objeto. Nunca segunda linha embaixo do rótulo.
- **Pendência que ela levantou e ninguém mais tem:** a captura de evidência do onboarding se
  ancora na chave do dropdown de formato, que o redesenho elimina. Quando virar código,
  `app/test/ui/fixtures/ui_authenticated_visual_matrix.json` precisa de âncora e estado novos.

### Frente D — documentação e validação dos fluxos (esta sessão)
- **11 de 11 fluxos documentados**, cada um com cético adversarial. Copiados para
  `docs/flows/` em 2026-09-22.
- Cobertura: **as 120 rotas do servidor e as 46 do app ficaram todas cobertas**. O que escapou são
  16 superfícies que não são rota (ver §4).
- ~200 achados, **cerca de 30 de severidade alta**.
- Medição das 49 P0 CORE **interrompida pela pausa** (ver §3).

---

## 2. O que está sujo na árvore, e de quem é

| Caminho | Dono | Situação |
| --- | --- | --- |
| `server/routes/community/marketplace/index.dart` | frente D | correção de privacidade, não staged |
| `server/test/community_marketplace_privacy_contract_test.dart` | frente D | teste novo, untracked |
| `docs/generated/*` e `project_logic_manifest.json` | frente D | regenerados por causa da rota acima; `--check` diz sincronizado |
| `docs/design/` | frentes B e C | protótipo, auditoria, kit, mockups, packet |
| `docs/PONTO_DE_RETOMADA_COORDENACAO_2026-09-21.md` | frente D | este arquivo |

**Nada disso foi commitado.** Os quatro artefatos gerados acompanham a rota do marketplace: quem
landar a rota precisa landar os artefatos junto, senão o gate de drift fica pendurado.

### Recursos da máquina
- PostgreSQL 17 ad hoc em 5432: **derrubado**. Para religar (precisa de locale válido, senão
  "postmaster became multithreaded during startup"):
  `LC_ALL=en_US.UTF-8 /opt/homebrew/opt/postgresql@17/bin/pg_ctl -D /opt/homebrew/var/postgresql@17 -l /tmp/pg17.log -o "-p 5432 -c listen_addresses=127.0.0.1" start`
- Emulador, netsimd, qemu: mortos. Sobraram processos `crashpad_handler` órfãos do emulador
  (inofensivos, consomem pouco); podem ser mortos com `pkill -f crashpad_handler`.
- O aparelho físico do Rafa está plugado e **nunca foi tocado**.

### Regra de ferramenta que custou caro hoje
**Sempre usar o Flutter pinado**, nunca o do PATH:
`~/.manaloom/toolchains/flutter-3.44.6/bin/flutter test ... --no-pub --no-version-check`
O `flutter` do PATH é mais antigo e reescreve `app/pubspec.lock` no `pub get` implícito — isso
quebra o build de `integration_test` e **move o digest de UI**, invalidando capturas em voo.
Com o pinado, a suíte do app deu **1604 testes, 0 falhas**.

---

## 3. A medição das 49 P0 CORE — interrompida

O alvo não é release público: é a beta controlada gratuita (`CONTROLLED_FREE_BETA`).
São **126 P0 abertas**, das quais **49 são `P0 CORE`** e bloqueiam a beta; as demais bloqueiam
apenas a própria capability. **Só 1 das 49 tem ficha própria** — as outras existem como uma linha
de critério no backlog.

Script da medição: `<scratchpad>/medir-p0.js` (aceita `only` para lote e `final` para consolidar).
Grupos: `contencao-escopo`, `auth-conta`, `deck-core`, `catalogo-arte` (lote 1, interrompido),
e ainda não medidos: `privacidade-telemetria`, `ux-telas`, `banco`, `infra-release`, `gates-qa-web`.
Saída em `docs/flows/_p0/`: `auth-conta.md` (312 l.), `catalogo-arte.md` e `medir-p0.js`.

O método: decompor cada critério de aceite em asserções verificáveis e classificar cada uma em
`PRONTO_E_PROVADO`, `PRONTO_SEM_PROVA`, `PARCIAL` ou `NAO_ENCONTRADO`, com cético reabrindo tudo
que foi dado como pronto. Medida em trabalho concreto (arquivos a tocar, testes a escrever,
migração, prova viva, decisão humana), nunca em dias.

---

## 4. Achados que valem mais que o resto

**Quebram a jornada do usuário, independentemente de capability:**
1. **O app expulsa o usuário da tela a cada retomada.** `ReleaseCapabilitiesProvider.refresh()`
   publica `denied()` antes da chamada HTTP; o GoRouter reage e redireciona. `/notifications`,
   `/decks`, `/collection` caem para `/home`. O redirect é destrutivo — ninguém é devolvido.
   Os autores conheciam a janela: protegeram `_disablePushForSession` com `loadState != loading`,
   mas não o router. `app/lib/main.dart:422`.
2. **O pós-jogo está morto em partida real.** `GET /decks/{id}` devolve `deck_version_at` com
   `DateTime.now()` a cada requisição; a tela compara com a versão pedida. Cache de 5 min disfarça
   em partida curta. `server/routes/decks/[id]/index.dart:831`.
3. **A otimização de IA gasta a cota e falha no apply.** O app libera o fluxo por
   `ai_analyze_optimize_advisory`, mas o apply usa `PUT /decks/:id`, que o servidor classifica como
   `deck_replace_all`. Mais três ações com a mesma assimetria.
4. **Erro interno vaza cru para o usuário:** `capability_unavailable` aparece literalmente no aviso,
   e o tradutor prefere o campo `error` ao `message`, descartando as frases em português do servidor.

**Segurança e privacidade:**
5. `GET /cards/printings?sync=true` é anônimo, write-capable e chama a Scryfall sem timeout nem cache.
6. O OpenAPI gerado **declara `bearerAuth` para rotas que não têm autenticação** — qualquer auditoria
   que leia o spec conclui errado.
7. `EndpointCache` não tem teto e `clearExpired()` não é chamado por ninguém.

**Governança:**
8. **Existe um terceiro portão fail-closed** que nenhum documento menciona:
   `server/bin/manaloom_ops_daemon.py` (política própria, 16 jobs, `/health` separado na porta `MANALOOM_NATIVE_BATTLE_PORT`).
   O mapa operacional afirma "os dois portões". **O Rafa decidiu corrigir o mapa e documentar o
   daemon — não foi feito antes da pausa.**
9. **Nenhum gate executa `app/integration_test/`** (158 arquivos). O `full` roda `flutter test` sem
   alvo, que cobre só `app/test/`. **O Rafa decidiu que o gate passa a rodar tudo** — a implementar,
   e ficou combinado fazer isso só depois que o `full` da frente A fechasse.
10. Um cron apaga em 30 minutos os jobs de IA cuja retomada o app implementa e documenta.
    **O Rafa decidiu subir a retenção** — não implementado.
11. Quatro eventos de ativação do onboarding são rejeitados pelo allowlist do servidor, em silêncio.

---

## 5. Decisões do Rafa já tomadas e ainda não executadas

| Decisão | Estado |
| --- | --- |
| Bump do `npm audit` (`next` 15.5.25, `sharp` 0.35.4) — RCE crítico | autorizado, **não executado** |
| Gate passa a rodar `integration_test/` | decidido, **não implementado** |
| Corrigir o mapa e documentar o terceiro portão | decidido, **não feito** |
| Subir a retenção dos jobs de IA | decidido, **não implementado** |
| Kit visual em `app/lib` é o próximo `NOW` da fila | decidido pelo dono em 2026-09-21 (`BT-UX-KIT-001` depois de `BT-SCP-001`); linha registrada no backlog e na fila em 2026-09-22, sem commit; packet pronto, **implementação represada pelo digest** |
| Onda 8: cortar catálogo de arranjos para duas fileiras | decidido, repassado à frente B |
| Corrigir o vazamento do marketplace | **feito**, não commitado |
| Correção de uma linha em `_friendlyMessage` (`not_waiting`) | decidido implicitamente na investigação; **represado pelo digest** |

## 6. Decisões ainda pendentes

1. `trade_visibility` no marketplace: quem escolheu "só seguidores" deve sumir da busca global?
2. Mockups de onboarding e gerador — julgar pelo olho quando saírem.
3. Pack 05 de evidência mostra marketplace com preços e CTAs enquanto a capability está OFF (C17):
   continua, vira evidência de capability futura, ou sai?
4. Declarar no contrato os fluxos que existem em código mas não em
   `project_logic_contracts.json`: home/onboarding, comercial e fichário.
5. Priorização dos ~30 achados graves.
6. ~~Dois itens de contraste do protótipo~~ — **RESOLVIDOS**, saem da lista (ver frente B).
7. **Piso do numeral em mesa de sete jogadores ou mais.** A restrição que a frente B mediu não é
   a que foi levada ao Rafa: o que limita o numeral **não é o número de fileiras, é quantos cards
   cabem numa fileira** — 3 por fileira dá 109 px (40% da altura do card, cumpre o piso de 38%),
   4 dá 81 px (30%) e 5 dá 65 px (23%). Com duas fileiras, mesa de 7 a 10 jogadores **não tem
   nenhuma divisão** que cumpra o piso. **Isso não é regressão da onda 8: é o comportamento de
   hoje** — a checagem 41 só olhava de 2 a 6 jogadores, faixa em que a divisão equilibrada nunca
   passa de 3 por fileira, e de 7 em diante ninguém nunca mediu. As saídas:
   - **(a)** aceitar numeral menor acima de seis jogadores e registrar o piso dessa faixa como 23%
     — assume o que já acontece hoje;
   - **(b)** deixar o numeral usar mais da largura do card (hoje `38cqw`; a 62% a fileira de cinco
     volta aos 38% de altura), ao custo de uma vida de três dígitos ocupar a largura inteira —
     troca piso por folga do "100". A frente B quer medir com vida de três dígitos em todas as
     fileiras **antes** de aplicar;
   - **(c)** limitar a mesa a seis jogadores, e o piso vale em toda a faixa oferecida.
   Tabela da medição em `docs/design/life-counter-prototype/README.md`.
   **Nuance que importa para quem retomar:** a decisão que o Rafa tomou foi "cortar o catálogo para
   duas fileiras", mas **a mesa já tinha só duas fileiras** — a escolha não mudou nada estrutural.
   O que a frente B entregou foi o espírito dela (fileira de até três), e foi medindo para isso que
   o buraco dos 7+ jogadores apareceu. A pergunta original foi mal formulada pela coordenação, que
   repassou a restrição sem pedir a medição antes.

---

## 7. Como retomar

1. Ler `docs/qa/execution/2026-09-21/PONTO_DE_RETOMADA.md` (frente A) — é mais detalhado sobre o gate.
2. Copiar os rascunhos de fluxo do scratchpad para `docs/flows/` **antes que `/private/tmp` seja
   limpo**; o mesmo para `<scratchpad>/p0/` e `medir-p0.js`.
3. Retomar a medição das P0 pelos 5 grupos que faltam, e depois a fase de consolidação
   (`final: true`), que produz o caminho crítico.
4. Executar as decisões da §5 que continuam válidas.
5. Só então voltar ao produto.
