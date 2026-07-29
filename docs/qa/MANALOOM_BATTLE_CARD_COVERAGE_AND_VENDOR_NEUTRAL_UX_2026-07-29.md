# Battle: cobertura de cartas e UX neutra de fornecedor — 2026-07-29

## Resultado

O conjunto que pode iniciar Battle hoje ficou coberto no runtime candidato:

- 6 decks Commander validados, com exatamente 100 cartas e 1 comandante;
- 336 nomes únicos entre esses decks;
- 336/336 resolvidos;
- `Lorehold` contra `Animar`: preflight interativo `ready`, sem bloqueadores;
- uma sessão real chegou ao prompt, aceitou uma decisão e foi encerrada por
  concessão de QA;
- nenhum nome de fornecedor de motor de regras é apresentado ao usuário no app.

O pin canônico não foi promovido. A cobertura foi homologada em runtime local
isolado, mas a implantação continua bloqueada pelo contrato de transição ativo,
que ainda está em `review_required`. Resolução de catálogo não substitui revisão
semântica nem autoriza contornar esse gate.

## Escopo auditado

### Par real relatado pelo usuário

- deck: `12bfbb84-3e1e-4741-9ba5-56697bfa80fb` (`Lorehold`);
- adversário: `13b58b67-5e72-4584-9841-a859241a906a` (`Animar`);
- ambos: 100 cartas, 1 comandante e `validation_state=validated`.

No pin canônico `2c43ec8cdb5cd475d47e6b555a4077151f476a3b`, o
único nome não resolvido nesse confronto era `Lorehold, the Historian`.

No candidato `3ac810da650a51c33142175d6191693c3a077131`, a mesma
requisição retornou:

```text
status=ready
deck_a=Lorehold ready=true unsupported_cards=[]
deck_b=Animar ready=true unsupported_cards=[]
```

O endpoint autenticado de preflight confirmou:

```text
schema_version=battle_preflight_v1
mode=interactive
status=ready
card_count=100
commander_count=1
opponent.card_count=100
opponent.commander_count=1
selected_engine=internal_primary
unsupported_cards=[]
blockers=[]
```

`internal_primary` acima é apenas a representação neutra deste relatório. O
contrato técnico continua guardando a identidade real internamente para
reprodutibilidade.

### Pool Battle elegível

A consulta de escopo considerou apenas decks não excluídos que atendem
simultaneamente a:

- formato Commander;
- `validation_state=validated`;
- soma de quantidades igual a 100;
- soma de comandantes igual a 1.

Resultado: 6 decks, 336 nomes únicos, 336 suportados e 0 ausentes no candidato.

### Corpus amplo

O PostgreSQL contém 34.071 nomes únicos. Os 3.026 inicialmente chamados de
“ausentes” eram somente o resíduo da execução primária candidata, e não o
resíduo final do produto. O fechamento completo ficou:

| Destino | Nomes únicos |
| --- | ---: |
| Execução primária candidata | 31.045 |
| Execução compatível | 1.784 |
| Regras nativas verificadas | 187 |
| Exclusões técnicas terminais | 1.055 |
| Total | 34.071 |

As 1.055 exclusões receberam uma disposição terminal individual:

- 813 cartas não padronizadas ou de playtest;
- 133 objetos auxiliares de jogo;
- 55 dependentes de interação física ou externa;
- 54 objetos de cenário/challenge deck;
- 0 cartas convencionais ou digitais acionáveis;
- 0 disposições desconhecidas;
- 0 promoções permitidas por esse gate.

Logo, não existe uma fila de 3.026 cartas normais para implementar. A cobertura
operacional do catálogo é 33.016/34.071 nomes (96,9035%); os 1.055 restantes
estão fora do runtime normal por contrato explícito, não por esquecimento.

Entre todos os decks, inclusive incompletos e não validados, havia 1.761 nomes
únicos; 17 não eram resolvidos pela execução primária. Treze fecham na execução
compatível, um em regra nativa e três são não padronizados/não legais em decks
`unknown`. O único nome Commander válido desse grupo, `Improvisation
Capstone`, já está coberto nas lanes compatível e nativa. Nenhum dos 17 aparece
nos seis decks aptos para Battle.

O gate terminal revelou 50 falsos positivos de metadado com
`commander_legality=legal`: 48 folhas de stickers, `Costume Shop` (Attraction)
e `Clear, the Mind` (playtest). Legalidade de formato não significa
elegibilidade para o deck principal. A validação central agora bloqueia objetos
suplementares e produtos de playtest antes da legalidade e da elegibilidade de
comandante; o filtro de candidatos usa a mesma regra. Cartas normais
Eternal-legais de Unfinity continuam permitidas.

Também foi fechado um bypass de autorização: jobs, sessão interativa e
simulação síncrona agora exigem, no backend, formato Commander,
`validation_state=validated`, 100 cartas e exatamente um comandante. O
preflight deixou de consultar cobertura quando já existe bloqueio estrutural e
só conta adversários realmente aptos. Assim, uma chamada direta não consegue
executar um deck `unknown`.

## Implementação candidata de Lorehold

O candidato é uma cadeia linear sobre o pin canônico:

1. `af5e10ed6` — infraestrutura dinâmica de Miracle;
2. `348b4966a` — `Molecule Man`;
3. `f08b501a2` — `Lorehold, the Historian`;
4. `3ac810da6` — `Aminatou, Veil Piercer`.

Foram adicionados três testes focados ao `MiracleTest`:

1. Lorehold concede Miracle `{2}` a instantâneas e feitiços;
2. Lorehold não concede Miracle a criaturas;
3. o descarte e a compra na manutenção do oponente são opcionais e funcionam.

Resultado da suíte focada: 14 testes, 0 falhas, 0 erros e 0 ignorados. O patch
reprodutível está em
`docs/qa/evidence/LOREHOLD_CANDIDATE_FOCUSED_TESTS_2026-07-29.patch`.

## Sessão real

A sessão `9f65db7c-1e76-4688-a665-95a770fd820f` foi criada com os decks acima,
chegou a um prompt interativo, recebeu uma ação válida e foi encerrada para
liberar a cota:

```text
status=conceded
state_version=5
terminal_reason=user_conceded
records=12
record_kinds=action_accepted, action_submitted, concede_requested,
             private_state, prompt_opened, runtime_started,
             session_created, terminal
```

Durante a prova, uma sessão antiga já vencida ainda consumia a cota global. A
consulta de quota foi corrigida para contar apenas registros com
`expires_at > CURRENT_TIMESTAMP`, com teste de regressão.

## Contrato de apresentação

O app:

- chama o recurso de `motor de regras`, `Execução principal`,
  `Execução compatível` ou `Execução revisada`;
- sanitiza mensagens, códigos e JSON técnico antes de mostrá-los;
- não transforma automaticamente uma falha interativa em simulação;
- só oferece `Simular automaticamente` quando um segundo preflight confirma
  cobertura completa;
- preserva nomes legítimos de cartas, como `Battlefield Forge`, sem confundir
  a palavra com um fornecedor técnico.

Identidade, versão, commit e cadeia de fallback continuam presentes somente no
backend, logs internos e persistência de auditoria.

## Validações

```text
Flutter Battle afetado: 61/61
Backend elegibilidade, admissão e contratos: 83/83
Pipeline de cobertura, disposições e caller mode: 19/19
Backend determinístico completo: 325 arquivos de teste, sem falhas
Flutter completo: 1.365 aprovados, 1 skip declarado, sem falhas
Revalidação final da cópia pública e elegibilidade: 13/13
Análise estática Dart/Flutter: sem erros
Contratos operacionais de release: 27/27
Smoke do Web público: pass
Regras do candidato: 14/14
Preflight real Lorehold x Animar: ready
Pool Commander Battle elegível: 336/336
Catálogo primário: 31.045/34.071 nomes
Fallback compatível: 1.784/3.026 nomes
Regras nativas do resíduo: 187/187, oracle_hash presente
Disposições terminais: 1.055/1.055
Resíduo convencional/digital acionável: 0
Sessão real: prompt_opened + action_accepted + terminal
Web release: app/build/web
```

A evidência compacta e os hashes dos artefatos de entrada estão em
`docs/qa/evidence/BATTLE_CARD_COVERAGE_CLOSURE_2026-07-29.json`.

## Prova viva da apresentação neutra

O último digest Web capturado
`fb44ba3de42ffe5e6857a185a3fba4619eeec08281d147fab985c256bcd2f347`
foi exercitado novamente no Web autenticado:

- `web_mobile_390x844`: 54/54 checkpoints;
- `web_desktop_1440x900`: 53/53 checkpoints;
- `web_wide_1920x1080`: 53/53 checkpoints;
- 160 capturas revisadas visualmente, sem nome de fornecedor, overflow,
  sobreposição ou ação bloqueada observada.

Os manifests Web atuais estão versionados em
`docs/qa/ui-live/current/p0-matrix/`. A aprovação agregada de release não foi
atualizada porque o Samsung SM-A135M deixou de aparecer no ADB antes da
recaptura física no mesmo digest. A matriz Android anterior continua válida
somente para o digest que declara; ela não foi reclassificada como prova nova.

Depois dos ajustes de admissão e mensagens deste fechamento, o digest da fonte
de UI passou a
`f883da79de7531d168c5fd3c182b10456dc602bebe03deae87d602c151771a84`.
Consequentemente, as capturas anteriores são evidência histórica, não prova do
digest atual. O gate local permanece corretamente bloqueado até uma recaptura
Web + Android físico e nova revisão visual desse mesmo digest.

## Pendência de promoção

A promoção do candidato requer, nesta ordem:

1. encerrar a qualificação nominal da transição canônica já ativa;
2. criar evidência versionada da transição
   `2c43ec8cdb5cd475d47e6b555a4077151f476a3b` →
   `3ac810da650a51c33142175d6191693c3a077131`;
3. revisar a política de quarentena vinculada ao novo commit;
4. obter `qualification.status=pass` e `deployment_allowed=true`;
5. então alterar o pin, reconstruir os dois runtimes e executar o gate de
   release.

Até lá, o resultado correto é “cobertura candidata localmente concluída,
promoção pendente”, não “implantado em produção”.
