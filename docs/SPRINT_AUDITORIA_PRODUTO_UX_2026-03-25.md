# Sprint de Auditoria de Produto, UX e Direção Visual

> Documento operacional criado em `2026-03-25`.
> Objetivo: transformar a revisão visual do app em uma sprint formal, com critério de produto, checklist de avaliação por tela e critérios objetivos de aceite.

## Objetivo da sprint

Esta sprint existe para fechar um gap que apareceu claramente durante a evolução recente do app:

- o produto melhorou tecnicamente
- a arquitetura ficou mais segura
- a consistência visual melhorou
- mas parte das telas ainda não foi avaliada com lente de **produto real em viewport real**

O foco aqui não é “deixar bonito”.
O foco é garantir que cada tela:

- tenha hierarquia clara
- comunique o estado certo
- não penalize o usuário com ruído desnecessário
- mantenha identidade sem sacrificar leitura
- apoie decisão e ação com clareza

## Problema que esta sprint resolve

O problema identificado não é apenas paleta ou cor.
O problema central é:

- composição de tela
- densidade de informação
- excesso de elementos com peso parecido
- leitura de viewport pequeno
- semântica visual inadequada em estados iniciais
- falta de priorização do que o usuário deve ver primeiro

Em termos profissionais:

- antes houve boa revisão de componente e implementação
- faltou revisão editorial da interface como produto

Esta sprint corrige isso.

## Definição de sucesso

Ao final da sprint:

1. todas as telas principais terão sido revisadas com a mesma lente de produto
2. cada tela terá um veredito documentado:
   - manter
   - ajustar
   - refatorar
   - redesenhar parcialmente
3. cada ajuste executado terá critério de aceite explícito
4. o app terá menos ruído visual, menos semântica agressiva indevida e mais clareza de hierarquia
5. o time terá uma linguagem comum para aceitar ou rejeitar interface

## Escopo

### Dentro do escopo

- telas Flutter em `app/lib/features/**/screens`
- widgets de alto impacto na experiência visual e leitura do fluxo
- cards, heroes, chips, seções de ação, estados vazios, estados de erro, painéis de diagnóstico e blocos de resumo
- coerência entre:
  - cor
  - opacidade
  - contraste
  - densidade
  - espaçamento
  - borda
  - radius
  - ordem dos blocos
  - prioridade visual

### Fora do escopo

- redesign completo de branding
- troca de paleta base do app
- reescrita de fluxo backend
- motion system avançado
- redesenho de features secundárias sem passar pela fila definida aqui

## Lente oficial de avaliação

Toda tela deve ser avaliada nestes eixos:

1. **Hierarquia**
- o que o usuário vê primeiro?
- o que o usuário entende nos primeiros 2 segundos?
- o CTA principal é inequívoco?

2. **Densidade**
- há informação demais no primeiro viewport?
- existem elementos demais com peso semelhante?
- algum bloco deveria ser resumo e não detalhe?

3. **Semântica**
- vermelho aparece só para problema real?
- warning aparece só quando importa?
- estado vazio parece “começo” e não “falha”?

4. **Leitura**
- nome, metadado e texto secundário estão legíveis em viewport pequeno?
- a opacidade dos textos está correta?
- overlays e imagens de fundo atrapalham ou ajudam?

5. **Cor**
- existe mais de um acento dominante ao mesmo tempo?
- WUBRG, raridade, condição e score estão informando ou decorando?
- a tela respeita orçamento de cor?

6. **Composição**
- cards estão bem posicionados?
- a ordem das seções ajuda decisão?
- o radius está coerente entre blocos?
- superfícies parecem pertencentes à mesma família?

7. **Ação**
- a tela só informa ou também ajuda a agir?
- há CTA secundário demais?
- existe CTA errado no topo da hierarquia?

## Orçamento de cor oficial da sprint

Cada viewport deve obedecer, salvo exceções justificadas:

1. no máximo `1` acento dominante
2. `error` e `warning` só quando houver problema real
3. cores de domínio só quando agregarem leitura funcional
4. imagem de fundo exige proteção de leitura
5. texto secundário não pode virar “quase invisível”
6. `primary`, `secondary`, `success`, `warning`, `error` não podem competir todos no mesmo bloco

## Escala de severidade

### `P0`

Quebra leitura, comunicação errada ou compromete o entendimento do fluxo principal.

Exemplos:

- deck vazio parece inválido
- CTA errado domina a tela
- hero com arte sacrifica legibilidade do nome
- chip semântico errado aparece no topo

### `P1`

Não quebra o fluxo, mas reduz qualidade, clareza ou confiança.

Exemplos:

- excesso de chips no hero
- texto secundário apagado demais
- ações rápidas sem hierarquia
- card útil posicionado tarde demais na tela

### `P2`

Refino visual e consistência.

Exemplos:

- radius levemente inconsistente
- alpha stacking em excesso
- bordas sem coerência fina
- diferença pequena entre pesos visuais de cards irmãos

## Critérios gerais de aceite

Uma tela só pode ser considerada aceita quando:

1. o primeiro viewport tem foco dominante claro
2. texto principal e secundário estão legíveis em device pequeno
3. status inicial, estado vazio e estado de erro não se confundem
4. o usuário entende rapidamente o que fazer em seguida
5. não existe competição visual relevante entre hero, chips, CTA e status
6. o uso de cor é funcional e não ornamental
7. analyze e testes relevantes seguem verdes
8. o ajuste fica documentado no contexto ativo

## Termos oficiais de aceite

### `Aceite visual`

- leitura clara sem esforço
- sem ruído dominante
- hierarquia evidente
- contraste suficiente

### `Aceite de produto`

- tela ajuda a completar a tarefa principal
- não comunica estado errado
- CTA principal é coerente com o momento do usuário

### `Aceite técnico`

- sem regressão funcional
- sem overflow
- analyze verde
- teste novo ou ajustado quando o risco justificar

### `Aceite final`

Uma tela só é “DONE” quando os três aceites acima forem satisfeitos.

## Método de execução por tela

Para cada tela:

1. capturar estado atual
2. listar o que é:
   - útil
   - neutro
   - ruído
   - erro semântico
3. classificar problemas em `P0`, `P1`, `P2`
4. executar ajustes mínimos com maior retorno
5. validar em teste/analyze
6. documentar decisão

## Checklist padrão por tela

### Bloco A: Hierarquia

- o título principal domina?
- existe um CTA principal claro?
- o primeiro viewport responde “o que é isto?” e “o que faço agora?”

### Bloco B: Ruído

- há chips demais?
- há cards demais no primeiro viewport?
- há cor demais concorrendo ao mesmo tempo?

### Bloco C: Texto

- texto principal tem contraste alto?
- texto secundário está visível o bastante?
- texto terciário não está morto demais?
- o comprimento do texto foi considerado?

### Bloco D: Superfícies

- card tem radius coerente?
- bordas são consistentes?
- overlays são suficientes para leitura?
- backgrounds com arte atrapalham?

### Bloco E: Semântica

- warning está no lugar certo?
- error está no lugar certo?
- estado vazio foi tratado como onboarding?

### Bloco F: Ação

- CTA principal está evidente?
- ações secundárias estão discretas?
- ação de alto risco está bem separada?

### Bloco G: Layout

- espaçamento respira?
- cards estão em ordem útil?
- o usuário precisa rolar para chegar no que importa?

## Matriz completa de telas da sprint

### Wave 1: Core de deck

1. `app/lib/features/decks/screens/deck_details_screen.dart`
Status atual:
- parcialmente revisada
- ainda exige crítica contínua por viewport real
Aceite:
- hero sem ruído dominante
- overview, cards e analysis coerentes entre si
- estados vazios, inválidos e operacionais bem separados

2. `app/lib/features/decks/widgets/deck_details_overview_tab.dart`
Status atual:
- revisada
- precisa manutenção sob lente de composição
Aceite:
- hero legível
- ações rápidas úteis
- status de deck no lugar certo
- descrição, comandante e estratégia em ordem correta

3. `app/lib/features/decks/widgets/deck_analysis_tab.dart`
Status atual:
- revisada
Aceite:
- leitura executiva clara
- IA, curva e cor bem segmentadas
- CTA de análise correto

4. `app/lib/features/decks/screens/deck_import_screen.dart`
Status atual:
- revisada
Aceite:
- onboarding calmo
- erro inline sem agressividade indevida
- resultado priorizado por importância

5. `app/lib/features/decks/screens/deck_list_screen.dart`
Status atual:
- precisa revisão de produto na lista completa
Aceite:
- cards com assinatura visual coerente
- leitura rápida entre decks
- metadados úteis e não excessivos

6. `app/lib/features/decks/widgets/deck_card.dart`
Status atual:
- revisado recentemente
Aceite:
- arte do comandante melhora identidade sem destruir leitura
- textos legíveis
- card escaneável em lista

7. `app/lib/features/cards/screens/card_search_screen.dart`
Status atual:
- UX de gesto revisada
Aceite:
- intenção de toque inequívoca
- lista clara
- adicionar vs ver detalhes bem separados

8. `app/lib/features/cards/screens/card_detail_screen.dart`
Status atual:
- precisa auditoria formal
Aceite:
- carta continua protagonista
- metadados não competem com arte
- CTA do deck flow é claro

### Wave 2: Entrada, descoberta e navegação principal

9. `app/lib/features/home/home_screen.dart`
Status atual:
- revisada parcialmente
Aceite:
- um CTA dominante
- ações rápidas neutras
- empty state não compete com hero

10. `app/lib/features/auth/screens/login_screen.dart`
11. `app/lib/features/auth/screens/register_screen.dart`
12. `app/lib/features/auth/screens/splash_screen.dart`
Status atual:
- revisadas parcialmente
Aceite:
- branding com menos ruído
- foco em ação
- contraste e hierarquia corretos

13. `app/lib/features/notifications/screens/notification_screen.dart`
Aceite:
- estados de lista claros
- prioridade de conteúdo acima de decoração

### Wave 3: Scanner e utilitários

14. `app/lib/features/scanner/screens/card_scanner_screen.dart`
15. `app/lib/features/scanner/widgets/scanned_card_preview.dart`
16. `app/lib/features/scanner/widgets/scanner_overlay.dart`
Status atual:
- preview já revisado parcialmente
Aceite:
- scanner prioriza captura
- preview prioriza carta
- confiança/condição/edição não competem ao mesmo tempo

### Wave 4: Comunidade, social e mensagens

17. `app/lib/features/community/screens/community_screen.dart`
18. `app/lib/features/community/screens/community_deck_detail_screen.dart`
19. `app/lib/features/social/screens/user_profile_screen.dart`
20. `app/lib/features/social/screens/user_search_screen.dart`
21. `app/lib/features/messages/screens/message_inbox_screen.dart`
22. `app/lib/features/messages/screens/chat_screen.dart`
Status atual:
- backlog
Aceite:
- foco em conteúdo
- chips e estados sociais menos ornamentais
- leitura entre cards/threads mais rápida

### Wave 5: Market, collection, binder e trade

23. `app/lib/features/market/screens/market_screen.dart`
24. `app/lib/features/collection/screens/collection_screen.dart`
25. `app/lib/features/collection/screens/latest_set_collection_screen.dart`
26. `app/lib/features/binder/screens/binder_screen.dart`
27. `app/lib/features/binder/screens/marketplace_screen.dart`
28. `app/lib/features/binder/widgets/binder_item_editor.dart`
29. `app/lib/features/trades/screens/trade_inbox_screen.dart`
30. `app/lib/features/trades/screens/create_trade_screen.dart`
31. `app/lib/features/trades/screens/trade_detail_screen.dart`
Aceite:
- densidade controlada
- informação comercial/coleção legível
- semântica de preço/condição/estoque não vira ruído

## Artefatos obrigatórios da sprint

Ao longo da sprint, cada rodada deve deixar:

1. código ajustado
2. teste novo ou ajustado quando necessário
3. atualização em `docs/CONTEXTO_PRODUTO_ATUAL.md`
4. atualização nesta sprint quando uma tela mudar de estado

## Registro por tela

Cada tela deve terminar com estes campos preenchidos:

- `Status`: `BACKLOG`, `IN_PROGRESS`, `DONE`, `REVISIT`
- `Problemas encontrados`
- `Mudanças executadas`
- `Riscos restantes`
- `Aceite visual`
- `Aceite de produto`
- `Aceite técnico`

## Modelo de registro de execução

### Tela

`path/da/tela.dart`

### Diagnóstico

- problema 1
- problema 2
- problema 3

### Mudança aplicada

- mudança 1
- mudança 2

### Aceite

- visual: `OK` / `PENDENTE`
- produto: `OK` / `PENDENTE`
- técnico: `OK` / `PENDENTE`

### Decisão final

- `DONE`
- `REVISIT`

## Ordem oficial de execução

1. core de deck
2. home e auth
3. scanner
4. community/social/messages
5. market/collection/binder/trades

Nenhuma tela lateral deve furar o core de deck.

## Definição de encerramento da sprint

Esta sprint só termina quando:

1. todas as telas da Wave 1 estiverem com aceite final
2. as Waves 2 e 3 estiverem pelo menos auditadas e classificadas
3. a maioria das telas de alta frequência tiver `DONE` ou `REVISIT` com risco documentado
4. existir uma visão comum e documentada do que é interface aceitável no produto

## Próximo passo oficial após esta sprint

Depois de fechar esta sprint:

1. consolidar checklist final de release visual/UX
2. continuar bloqueadores operacionais restantes
3. só então avançar para performance/assíncrono/Redis e superfícies secundárias
