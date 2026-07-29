# Revalidação da fundação de mana do otimizador — 2026-07-28

## Decisão

O fluxo de otimização, conclusão e reconstrução de decks passa a tratar a
quantidade física de terrenos como uma invariante de segurança desde o preview
até a persistência.

Para mutações automáticas:

| Formato | Total do deck | Piso automático | Alvo padrão | Faixa de alvo aceita | Excesso estrutural |
|---|---:|---:|---:|---:|---:|
| Commander/EDH | 100 | 34 | 36 | 34–42 | 55 ou mais |
| Brawl | 60 | 24 | 25 | 24–30 | 36 ou mais |

O piso não é uma regra de legalidade do formato. Ele é uma proteção
conservadora para que o ManaLoom não aplique automaticamente um deck
estruturalmente inutilizável. Edição manual continua independente. Uma futura
exceção para listas cEDH abaixo do piso deverá ser explícita, versionada e
acompanhada de prova de fontes/ramp; não pode nascer de um bypass silencioso.

## Causas encontradas

1. Parte do app comparava linhas detalhadas, enquanto o backend trabalha com
   quantidades físicas. Assim, `Plains x25` podia ser exibido ou validado como
   uma única linha.
2. O estado incompleto olhava apenas para a quantidade atual de terrenos. Ele
   não verificava se os slots restantes ainda conseguiam alcançar o piso.
3. Terrenos básicos virtuais não carregavam `type_line`, texto de mana e
   identidade de cor. O segundo estágio de planejamento não reconhecia
   corretamente o que o primeiro havia acabado de adicionar.
4. O rebuild parcial adicionava básicos e podia removê-los novamente na etapa
   de ajuste do total.
5. O preview possuía validação, mas os endpoints de escrita não recalculavam a
   fundação final dentro da mesma transação.
6. A assinatura do deck não distinguia comandante e main deck; uma troca de
   papel podia reutilizar preview/cache antigo.
7. Alguns loaders de candidatos fixavam legalidade `commander`, inclusive
   quando o fluxo solicitado era Brawl.
8. Sem EDHREC/cache, o rebuild completo descartava não terrenos seguros do
   deck original e completava os slots restantes com básicos. O novo gate
   impedia persistir o resultado, mas a montagem ainda podia chegar a 99–100
   terrenos antes de falhar.
9. A seleção de metagame da conclusão completa fixava o escopo como
   `commander`. Assim, um pedido Brawl podia respeitar a legalidade Brawl no
   catálogo e ainda herdar sinais competitivos de Commander na ordenação.
10. O provedor de IA ainda consultava ML, staples, anti-meta, EDHREC e
    sinergias Scryfall no contexto Commander. Um Brawl podia receber uma base
    de mana numericamente correta, mas candidatos do formato errado e só
    descobrir a incompatibilidade na aplicação.
11. A chave do cache persistente não incluía o formato. O mesmo deck,
    assinatura e arquétipo podiam reutilizar um payload calculado para outro
    formato após uma troca entre Commander e Brawl.
12. O contrato de decisão ainda declarava as adições de `Complete` como
    individualmente selecionáveis e parte da telemetria contava linhas
    detalhadas, não as cópias físicas agregadas.

## Contrato implementado

### Política única

`server/lib/commander_mana_floor.dart` centraliza piso, alvo, limites de perfil,
excesso estrutural, fontes de cor e a versão
`optimization_mana_foundation_v1_2026-07-28`.

Valores vindos de perfis, cache ou EDHREC são limitados pela política do
formato. Eles podem orientar o alvo dentro da faixa, mas não reduzir o piso
automático nem elevar o alvo além do limite protegido.

### Preview e conclusão

- A quantidade é preservada e somada fisicamente.
- `Complete` só é acionável quando a soma detalhada das adições alcança
  exatamente o total esperado.
- Todas as adições de `Complete` são inseparáveis na aplicação; seleção parcial
  é rejeitada.
- O contrato `optimize_decision_contract_v2_2026-07-28` marca
  `selection_unit=complete_plan`, `complete_selection_required=true` e informa
  a quantidade física de adições. A telemetria de retorno usa a mesma contagem.
- Um Commander com 90 cartas e nove terrenos é encaminhado para reparo/rebuild,
  porque os dez slots restantes não conseguem alcançar 34.
- Um deck esparso ainda completável continua elegível para `Complete`.
- Básicos virtuais carregam tipo, habilidade de mana e identidade de cor.

### Persistência atômica

`PUT /decks/:id` e `POST /decks/:id/cards/bulk`:

1. exigem a assinatura do preview para mutações de otimização;
2. rejeitam assinatura ausente ou obsoleta;
3. resolvem `type_line` no PostgreSQL;
4. recontam a lista final antes do commit;
5. bloqueiam abaixo do piso ou acima do excesso estrutural;
6. revertem metadados, cartas e histórico na mesma transação em qualquer falha.

O erro público estável é `optimization_land_floor_violation`. O detalhe
estrutural diferencia `OPTIMIZATION_APPLY_LAND_FLOOR` e
`OPTIMIZATION_APPLY_LAND_EXCESS`.

### Rebuild

O rebuild calcula o alvo pelo formato, impede que dados históricos/cache
ultrapassem a faixa protegida, remove não terrenos antes de terrenos e valida
total, piso e excesso novamente antes de criar o draft. O resultado expõe o
contrato da fundação de mana no `source_summary`.

Quando fontes externas não oferecem candidatos suficientes, cartas não terreno
legais cortadas do próprio deck entram como fallback determinístico, ordenadas
pelo score já calculado. Se nem o catálogo externo nem o deck original
conseguirem completar os slots não terreno, o fluxo falha por capacidade de
catálogo e não transforma slots restantes em terrenos.

### Cache e concorrência

A assinatura canônica inclui:

```text
card_id:quantity:condition:commander|main
```

O namespace do cache foi elevado para `v12`, e a chave inclui o formato
normalizado. Dessa forma, formato, quantidade, condição ou papel alterados
invalidam o preview; a assinatura física também protege o histórico aplicado.
Commander e Brawl nunca compartilham a mesma entrada, ainda que deck,
arquétipo e cartas sejam idênticos.

### Legalidade por formato

Loaders de preenchimento, fundação e trocas recebem `deckFormat` e vinculam a
consulta a `card_legalities.format`. O E2E isolado contém cartas-canário com
legalidades opostas e prova que o loader não cruza Commander e Brawl.

O escopo de metagame usado por `Complete` também recebe o formato real do deck.
O fluxo Brawl não consulta mais o metagame competitivo de Commander. Um teste
de contrato de fonte protege esse encaminhamento para impedir a reintrodução
de um literal `commander`.

O formato também percorre o contexto de IA completo: ML, anti-meta,
`format_staples`, busca de sinergias no Scryfall e prompt. Tanto a preparação
do `Complete` quanto o pool auxiliar e a validação pós-otimização deixam de
consultar perfil/EDHREC de Commander em Brawl. O rebuild Brawl também ignora
essas fontes Commander-only e trabalha com catálogo legal e fallback do
próprio deck. O prompt Brawl recebe uma diretiva explícita de 60 cartas,
legalidade Brawl e faixa automática de 24–30 terrenos.

Depois que nomes retornam do provedor, o PostgreSQL aplica um filtro por
`card_legalities` antes do preview. Legalidade conhecida incompatível é
fail-closed; ausência total de linha materializada permanece fail-open para
compatibilidade com cartas recém-sincronizadas. A ordem e quantidades físicas,
incluindo básicos repetidos, são preservadas.

## Evidência executada

| Camada | Resultado |
|---|---|
| Testes focados de backend | 173 casos amplos aprovados; 107 regressões finais de formato/cache/rebuild aprovadas |
| Testes focados de app | 121 aprovados |
| Suíte completa do backend | 41 lotes determinísticos aprovados; tags live excluídas pelo gate |
| Suíte completa Flutter | 1.352 aprovados; 1 teste condicionado ao ambiente pulado |
| PostgreSQL loopback descartável | 3/3 aprovados |
| Gate de schema PostgreSQL/tbls | 79 tabelas, 6 views, 98 FKs e 56 migrations sincronizadas |
| Gate de performance | aprovado |
| Gate Web/Node 26 | aprovado; zero vulnerabilidades |
| Análise estática backend | sem problemas |
| Análise estática Flutter | sem problemas |

O E2E descartável prova:

- ausência e obsolescência de assinatura retornam `409`;
- `Complete` com nove terrenos retorna `409` sem alterar deck ou histórico;
- uma aplicação segura persiste exatamente 100 cartas, 34 terrenos e um evento;
- `PUT` com nove terrenos faz rollback;
- `PUT` com 90 terrenos faz rollback como excesso estrutural;
- candidatos Commander-only e Brawl-only são separados pelo formato;
- o filtro pós-provedor preserva duas cópias físicas de um básico permitido e
  remove o candidato conhecido como incompatível com Brawl;
- sem EDHREC/cache, o rebuild reaproveita os não terrenos seguros do deck
  original e entrega exatamente o total e o alvo físico de terrenos.

O resumo do harness obteve SHA-256
`46bdd1ddeea88914141d66e311447ce08402913d33a05d791a815f86f264c70a`.

### Prova viva Web e mobile

A captura foi executada contra PostgreSQL, API e build Web exclusivamente
loopback e descartáveis. A fixture reproduziu o defeito reportado com um deck
Commander legal de 100 cartas, sendo 90 não terrenos distintos, nove `Plains`
e um comandante.

No fluxo real:

1. a análise exibiu nove terrenos e o piso automático de 34;
2. o otimizador recusou tratar os dez slots restantes como uma conclusão
   suficiente e encaminhou para rebuild;
3. sem EDHREC/cache, o rebuild preservou não terrenos seguros do deck original;
4. o deck original permaneceu com `100/9`;
5. o draft foi criado com `100/36`, dentro da faixa Commander `34–42`;
6. a UI mostrou `Terrenos 36` e `Na faixa` em `390×844` e `1440×900`;
7. a navegação trocou para a rota canônica do draft
   `/decks/f9aef527-3230-4ab3-8608-21fe2c420a1e`, e recarregar a página
   preservou o mesmo recurso.

O bundle Web inspecionado obteve SHA-256
`551326eb74a170ee4319a3296d628405fd49f3aab1b1d4b041d92bb870117db8`.
A conferência final no PostgreSQL confirmou que o original não foi mutado e
que o draft possui exatamente 100 cartas e 36 terrenos. Ao encerrar, o harness
removeu credenciais e banco descartável e confirmou zero listeners restantes
da API e do servidor Web.

Além da reprodução dirigida, a matriz visual P0 foi recapturada e revisada em
contact sheets:

- 54 checkpoints Web mobile em `390×844`;
- 53 checkpoints Web desktop em `1440×900`;
- 53 checkpoints Web wide em `1920×1080`;
- 54 checkpoints no Samsung SM-A135M, incluindo um checkpoint landscape real
  do Life Counter.

As 160 capturas Web pertencem integralmente ao digest de UI
`a22e35a6e71544d3d31d1c9ca1e636116c8f5a7f708cb472a7240803c2898695`.
No Android, 43 checkpoints foram recapturados nesta rodada, incluindo modal de
criação, lista, busca e detalhes de deck acima/abaixo da dobra; 11 telas de
comunidade e trades, cujas fontes não mudaram, foram preservadas da execução
física completa aprovada anteriormente. O aparelho deixou de aparecer no ADB
após um reboot de recuperação, portanto esta evidência não é descrita como uma
nova execução monolítica de 54 checkpoints.

As 214 imagens indexadas são PNGs válidos: 53 capturas Android têm
`1080×2408`, o Life Counter tem `2408×1080`, e os quatro manifests cobrem
exatamente os perfis revisados. Não houve overflow, exceção Flutter,
`CachedCardImage` com falha ou erro não tratado nos logs aceitos.

## Limites conscientes

- O gate físico garante quantidade de terrenos, não uma prova completa de
  suficiência W/U/B/R/G. A distribuição de fontes continua advisory porque
  rocks, dorks, fetches, efeitos condicionais e terrenos como Urborg exigem um
  modelo semântico com baixa taxa de falso positivo antes de virar hard gate.
- Legalidade ausente em `card_legalities` continua seguindo a política legada
  fail-open. Mudar isso exige uma decisão de ingestão/catálogo separada para não
  bloquear cartas recém-sincronizadas sem linha materializada.
- O E2E usa PostgreSQL/API descartáveis e catálogo controlado. Ele prova
  contrato, transação e separação por formato; não declara a qualidade
  estratégica de toda sugestão de um provedor externo.
- A rodada física Android foi incremental por indisponibilidade do aparelho
  após reboot. Todas as superfícies alteradas de deck foram recapturadas; uma
  nova passagem monolítica continua desejável quando o SM-A135M voltar ao ADB,
  mas não há lacuna visual nas telas afetadas por esta mudança.
- Deploy do backend não faz parte desta revalidação. Produção só recebe este
  contrato após promoção/deploy separado e autorizado.

## Critério de conclusão

Esta mudança pode ser promovida quando:

1. o manifesto e a documentação gerada estiverem sem drift;
2. testes, análise estática e gates locais estiverem verdes;
3. o build Web real mostrar quantidades físicas, piso automático e aplicação
   integral sem erro de layout;
4. commit e push preservarem os mesmos gates.
