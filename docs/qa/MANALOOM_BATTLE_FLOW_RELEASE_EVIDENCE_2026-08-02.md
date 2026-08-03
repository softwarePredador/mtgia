# Evidência de release do fluxo Battle — 2026-08-02

## Resultado

`PASS_SOFTWARE_DEPLOYED_WITH_HARDWARE_RESIDUALS` para Battle Lab, simulação
automática, Live Spectator e Battle Coach alpha. A validação cobriu código,
PostgreSQL, deploy e uma jornada live criada do zero. Esta evidência não atribui
crédito a Android físico nem TalkBack humano.

## Escopo e autoridade

- branch: `codex/free-beta-release-candidate-2026-07-17`;
- baseline funcional publicada: `026bfc000de6b23dfdb2bb27f92e0bcb0347efed`;
- autorização live: `I_HAVE_EXPLICIT_APPROVAL`, fornecida pelo usuário;
- alvos: PostgreSQL/API, Web release, serviço de operações e sidecars Battle do
  ambiente EasyPanel ManaLoom;
- verdade de produto: PostgreSQL/backend; caches locais não receberam promoção.

O acabamento visual final do replay pertence ao commit que contém esta
evidência. A release publicada deve expor esse mesmo `git_sha` em
`/app/release.json`; a conferência é parte do smoke final e não é substituída
pelo hash histórico acima.

## Segurança operacional

Antes das migrations e dos smokes mutantes foi criado o backup:

- arquivo local: `/tmp/manaloom-deploy-fa369ca-backups/manaloom-postgres-20260802T204400Z.dump`;
- tamanho: `304496419` bytes;
- SHA-256: `292ff1d832dc3e6c4b4997b4e10dba49d9569e259642cbf1b790c8503a35e480`;
- modo: `0600`;
- formato: dump PostgreSQL 17, com lista de restore validada.

O banco live reportou 56 migrations e zero pendentes, incluindo a migration
056 das sessões interativas. Segredos de autenticação e entrega de e-mail não
foram gravados na evidência nem impressos em logs.

## Jornada live executada

1. Uma conta nova foi criada pelo formulário Web, com aceite legal alinhado e
   redirecionamento para verificação de e-mail com `delivery=sent`.
2. Um deck Commander foi importado do zero usando a seção `[Commander]`. O
   backend detectou Talrand como comandante, aceitou 100/100 cartas e apresentou
   o deck como validado.
3. O seletor de comandante retornou apenas criaturas lendárias elegíveis; a
   busca por Talrand não duplicou a carta.
4. Um caso extremo com 99 terrenos foi corretamente recusado para uma troca
   incremental insegura e encaminhado à reconstrução guiada.
5. A reconstrução gerou um deck Commander de 100 cartas, bracket 2,
   Spellslinger, validado, com 36 terrenos e CMC médio não-terreno 3,39.
6. O preflight positivo iniciou a sessão interativa
   `5ae08121-2640-44e5-96b2-581ad25d42be`. O usuário manteve a mão, passou a
   prioridade, observou o avanço de turno e concedeu.
7. O replay interativo `8d7fdeec-0c7e-4ef0-a87c-d291370d63a2` persistiu a
   timeline e as decisões “Manter esta mão” e “Passar prioridade”.
8. O job automático `f4aa8c6e-ac90-4c04-92bd-903253623291` concluiu e gerou o
   replay `f02fe068-44f7-4a57-adf6-c8990719c660`, com 10 turnos, 380 eventos e
   21 snapshots visuais.
9. A troca entre dois IDs de deck foi exercitada após a conclusão do job; lista,
   job e replay foram recarregados sem reaproveitar estado do deck anterior.

## Achados corrigidos durante o E2E

- o importador anunciava suporte a `[Commander]`, mas o servidor não preservava
  cabeçalhos entre colchetes; parser e testes foram alinhados;
- o cliente esperava `external_battle_request_v2` em um job cujo contrato
  correto é `battle_job_request_v1`; o parser foi corrigido e passou a validar
  `request_correlation` sem rejeitar sucesso legítimo;
- requisições em voo podiam atualizar a tela depois de uma troca de deck; os
  estados específicos do deck agora são zerados e protegidos por epoch;
- o replay externo expunha `deck_a`, `deck_b`, UUID do job e “T17” em snapshots
  que não tinham turno confiável; a UI agora usa os nomes dos decks, ações
  legíveis e “Etapa/Estado observado”, preservando a limitação da fonte.

## Auditoria do bracket 2

A composição reconstruída foi consultada diretamente no PostgreSQL:

- 100 cartas, 1 comandante e 36 terrenos;
- zero cartas da lista oficial de Game Changers;
- zero ocorrências dos sinais curados de fast mana, interação gratuita e
  combo infinito usados pelo policy gate;
- nenhuma ocorrência de Lion's Eye Diamond, Grim Monolith, Mox Diamond, Mana
  Vault ou The One Ring;
- as 36 cópias de Snow-Covered Island são terrenos básicos, portanto não são
  duplicatas ilegais;
- Aetherize, Consuming Tide e Devastation Tide fornecem resets/tempo em vez de
  deixar o indicador de wipes sem resposta.

## Gates e provas

- gate integrado anterior ao acabamento: 748 testes backend, com 3 skips
  históricos; 1421 testes Flutter, com 1 skip histórico; analyzer limpo; Web
  build/smoke, performance e carga verdes;
- regressão do contrato de job/troca de deck: 52 testes Flutter;
- regressão do acabamento do replay: 42 testes Flutter;
- regressão dos fixtures do Live Spectator/runner: 22 testes Flutter; os três
  fixtures agora reutilizam `battleJobRequestSchemaVersion` e não carregam uma
  versão literal obsoleta;
- project logic: `--write` e `--check` obrigatórios depois do fechamento;
- UI: nova matriz P0 Web mobile/desktop/wide + Android emulator, jornada core,
  Battle Coach Android e teclado Web precisam compartilhar o digest final e
  receber revisão visual de todas as capturas antes do `ui-proof`.

O gate local `full` final passou depois dessas regressões, incluindo 43 lotes
backend, Flutter/analyzer, UI audit, custom lint, Patrol, auditoria de
dependências e PostgreSQL descartável. O SHA publicado fica registrado pelos
manifestos imutáveis dos serviços e pelo smoke de release, evitando inserir
uma referência circular ao próprio commit neste documento.

## Limites honestos do produto

- o Battle Coach é interativo nos prompts expostos pela sessão; não é uma
  substituição integral de um cliente de jogo;
- o replay automático mostra somente o que o sidecar observou. Nesta amostra,
  os 21 snapshots carregaram sobretudo vida e não forneceram racional da IA;
- zonas ausentes aparecem como “não observadas” e nenhuma ausência é tratada
  como prova de que uma carta não foi usada;
- o replay do Coach contém decisões reais do usuário e é a fonte adequada para
  revisar essas escolhas;
- o nome da implementação externa não aparece na interface do usuário.

## Pendências não ocultadas

- smoke no Samsung SM-A135M: pendente porque o aparelho não estava conectado
  no fechamento;
- TalkBack humano: pendente e não substituído por semantics automatizada;
- conteúdo legal/privacy: a composição visual passou, mas a revisão jurídica e
  a governança do texto permanecem necessárias antes de promoção comercial;
- domínio próprio de e-mail: o adaptador HTTPS e a entrega Resend funcionam com
  remetente verificado do provedor; `notify.manaloom.com` ainda depende de DNS.
