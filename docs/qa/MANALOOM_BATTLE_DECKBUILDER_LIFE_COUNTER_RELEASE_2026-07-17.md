# Fechamento de Battle, Deckbuilder e Life Counter — 2026-07-17

**Escopo:** beta gratuita Web + Android
**Versão local:** `1.0.0+2`
**Estado do código:** gates locais aprovados
**Estado live:** migrations, deploy e E2E publicado ainda não executados neste
snapshot documental

Este documento é a fonte de consulta para os três módulos que formam o ciclo
principal do ManaLoom:

```text
criar/importar deck → validar → simular Battle → consultar replay → jogar no
Life Counter → registrar aprendizado pós-jogo
```

Um `PASS local` comprova comportamento no checkout e nos ambientes isolados
descritos. Não equivale a `PASS live`, publicação ou validação em aparelho
físico.

## 1. Veredito

Battle, Deckbuilder e Life Counter estão funcionalmente fechados para a etapa
local da release. Eles passaram análise, testes focados, suíte integrada e
builds de plataforma. O que resta não é uma implementação funcional conhecida
desses módulos, mas a sequência operacional que torna a mesma versão válida em
produção: congelar a SHA, gerar backup pós-rotação, aplicar migrations 038–040,
promover backend/Web e executar E2E autenticado no runtime publicado.

Consequentemente:

- é correto dizer **“os três módulos passaram os gates locais”**;
- ainda não é correto dizer **“os três módulos estão 100% validados em
  produção”**;
- nenhuma evidência abaixo declara deploy, publicação, Play Store ou teste em
  aparelho físico.

## 2. Battle

### Implementado

- seleção do oponente entre decks próprios e públicos, com busca e UUID;
- ordenação determinística das cartas carregadas do banco;
- persistência obrigatória da simulação: sucesso sem replay durável falha
  fechado, em vez de retornar uma batalha descartável;
- `replay_id` canônico no topo da resposta e dentro do bloco de persistência;
- `winner_deck_id` limitado ao deck A ou B tanto na resposta quanto no banco;
- listagem/leitura de replay autorizada somente para o proprietário do deck que
  iniciou a Battle; possuir apenas o deck oponente não concede leitura;
- repetição da mesma seed produz o mesmo resultado no ambiente determinístico;
- erros `500` de replay são sanitizados; detalhes internos são enviados à
  observabilidade, não ao cliente;
- o app recusa resposta cujo `replay_id` de topo diverge do ID persistido.

### Evidência local

| Prova | Resultado | Limite |
|---|---|---|
| Gate estático do produto Battle | **46/46 PASS** | Contrato de código, sem runtime live |
| E2E PostgreSQL descartável + sidecar nativo | **PASS** | Quatro replays e IDs duráveis; seed repetida determinística; autorização positiva/negativa comprovada |
| Suítes focadas de servidor e app | **PASS** | Incluídas na rodada integrada; não usam o backend publicado |
| Sidecars live observados em read-only | XMage, Forge e native saudáveis; native reportou 7.045 regras | Saúde do sidecar não comprova o backend candidato nem a persistência nova |

### Pendente live

- executar Battle entre dois decks do usuário descartável após as migrations;
- confirmar `replay_id` no POST, na listagem e no detalhe;
- repetir a seed e comparar o resultado;
- provar que um segundo usuário e o proprietário apenas do deck B recebem
  negação de acesso;
- confirmar que falha de persistência retorna erro e não “sucesso sem replay”.

## 3. Deckbuilder

### Implementado

- geração de deck falha fechado quando a validação não retorna estado válido;
- estados persistentes `unknown`, `draft` e `validated`, com motivos e data da
  última validação;
- alteração de cartas, formato ou transferência de carta entre decks invalida
  corretamente o estado anterior por trigger;
- importação atômica: uma falha não deixa metade da operação aplicada;
- importação incompleta pode ser salva como rascunho seguro e revisável, sem
  fingir que o deck está validado;
- o formato normalizado é enviado ao lookup para preferir impressões legais e
  restritas de forma consistente;
- mensagens técnicas são sanitizadas antes de chegar ao app;
- lista, detalhe, geração e importação exibem o estado de revisão/validação;
- `cards.is_reserved` é normalizado como `BOOLEAN NOT NULL DEFAULT FALSE`.

### Evidência local

| Prova | Resultado | Limite |
|---|---|---|
| Testes focados de servidor | **56 PASS** | Ambiente local/isolado |
| Contratos de documentação | **6 PASS** | Coerência de contrato, não runtime |
| Testes Flutter focados | **73 PASS** | Cliente local |
| PostgreSQL 16 fresh schema | **PASS** | Inclui migrations 039/040 |
| Upgrade de clone anterior à 039 | **PASS** | Migração real e triggers validados |
| Reaplicação/idempotência | **PASS** | Não substitui postcheck live |

### Migrations do Deckbuilder

- `039`: adiciona o ciclo de validação do deck, motivos/timestamp e triggers de
  invalidação;
- `040`: converte e fixa `cards.is_reserved` como booleano não nulo com default
  falso.

### Pendente live

- criar e importar decks pelo app publicado;
- confirmar `draft` para importação incompleta e motivos de revisão;
- validar um deck e observar `validated` persistido após reabrir;
- alterar carta/formato e provar retorno automático a estado não validado;
- confirmar que `is_reserved` não possui nulos e mantém semântica booleana.

## 4. Life Counter

### Implementado

- experiência Lotus única para entrada Web e app, sem uma segunda tela
  divergente para a rota manual;
- matriz de 2 a 6 jogadores;
- vida, comandante, veneno, energia, experiência, marcadores, histórico, turno,
  moeda e dados;
- correção de rótulos falsos de empate/eliminado e dos ponteiros de turno;
- validação dos dados personalizados;
- limites seguros para incremento/decremento por long press;
- persistência da sessão ao fechar/reabrir e no reload Web;
- layout responsivo e sem corte nos controles de dados, personalizado, moeda,
  fechar e `ROLAR`.

### Evidência local

| Prova | Resultado | Limite |
|---|---|---|
| Suíte VM focada | **370 PASS + 1 skip intencional** | Local |
| Suíte Chrome focada | **2 PASS** | Web local |
| Android 36 — 2 a 6 jogadores | **PASS** | Emulador, não aparelho físico |
| Persistência Android | **PASS** | Vida 40→41; após reabrir, captura idêntica byte a byte |
| Web desktop e 390 × 844 | **PASS** | Reload, rota direta, menu/histórico e console limpo no ambiente local |

### Pendente live

- abrir `/app/life-counter` na Web promovida e confirmar que é a mesma
  experiência acessada manualmente pelo app;
- executar 40→41, reload e reabertura no host publicado;
- conferir 2, 4 e 6 jogadores em desktop e viewport móvel;
- validar console, IndexedDB/local storage e navegação de retorno no domínio
  público;
- repetir no APK da SHA promovida; aparelho físico permanece uma prova separada.

## 5. Gates integrados e artefatos

| Gate/artefato | Resultado confirmado | Observação |
|---|---|---|
| Flutter analyze | **0 issues** | Flutter `3.44.6` / Dart `3.12.2` |
| Flutter completo | **948 PASS + 1 skip** | Inclui as integrações atuais dos três módulos |
| Servidor all-local | **1.583/1.583 PASS** | Sem PostgreSQL live |
| Python `unittest` raiz | **144/144 PASS** | Suite local |
| Web release | **PASS**, cerca de 49 MB | Não publicada neste snapshot |
| APK release | **PASS**, 115,6 MB | SHA-256 `f8cc6a5b74c24ccb601e5577053d59439121f60f06f8b52c82fac27c94b395b4`; assinatura v2 aprovada |
| AAB release | **PASS**, 93,7 MB | SHA-256 `3f9b55d216646797e757f61d6a8ba963151948e77dd7e79db3936dcb4c5b9fd4`; JAR/certificado aprovados |
| iOS sem codesign | **PASS** | `Runner.app` cerca de 94,4 MB; sem distribuição Apple |
| SBOM + OSV | **PASS LOCAL** | 936 componentes consultados; 226 excluídos; 60 vulnerabilidades somente não-release/excluídas; 0 vulnerabilidade de release |

Os hashes acima identificam probes do checkout ativo. Uma alteração posterior ou
o congelamento de outra SHA exige reconstrução e novos hashes.

## 6. Banco e segurança antes do deploy

O precheck live read-only registrou:

- migration máxima `037`;
- `12` replays Battle existentes;
- `34.331` cartas;
- `0` valor nulo em `cards.is_reserved` no snapshot consultado.

As migrations ainda pendentes são:

1. `038` — privacidade, exclusão/sync pós-jogo e contratos relacionados;
2. `039` — estados/triggers de validação do Deckbuilder;
3. `040` — normalização booleana de `cards.is_reserved`.

O dump pré-migration existente tem 300.692.505 bytes, modo `0600`, checksum
validado e restore de schema em PostgreSQL 17 com 87 tabelas. Ele antecede a
rotação da senha da conta e não deve ser usado como backup final da janela: um
novo dump é obrigatório antes do apply.

A senha exposta no snapshot predecessor de `origin/master` e no histórico já foi
rotacionada. A senha antiga retornou HTTP 401 e a nova HTTP 200; o novo valor
fica fora do repositório. Um novo `JWT_SECRET` forte também está armazenado fora
do repositório, mas só revogará na prática os tokens antigos quando o backend
for promovido. A prova pós-deploy deve mostrar:

- token emitido antes da rotação do backend → rejeitado;
- login com a nova senha → aceito;
- token novo → `/auth/me` aceito;
- nenhum segredo, token ou resposta sensível gravado na evidência versionada.

## 7. Sequência obrigatória para fechar live

1. revisar o diff, fazer staging explícito, commit/push e congelar checkout limpo
   com `HEAD == origin/master`;
2. reconstruir Web/APK/AAB/SBOM/provenance a partir dessa mesma SHA;
3. gerar e validar backup fresco pós-rotação;
4. executar precheck read-only e aplicar migrations 038, 039 e 040 em ordem,
   com as autorizações literais de banco/live;
5. executar postcheck de schema, contagens, triggers e readiness;
6. promover backend com o novo JWT e validar revogação/login;
7. promover Web e confirmar `release.json`, SHA, health e headers;
8. criar usuário QA descartável e percorrer:
   - cadastro/login;
   - criação/importação/validação de dois decks;
   - Battle nativa, replay persistido, listagem, detalhe e autorização negativa;
   - Life Counter 40→41, reload/reabertura e matriz responsiva;
   - ausência de preço, checkout ou paywall na beta gratuita;
9. remover o usuário QA e provar ausência de resíduo;
10. registrar Sentry/health/readiness e a identidade final dos serviços.

Somente após o passo 10 é permitido atualizar este documento para `PASS live`.

## 8. Limitações físicas e externas

Estas provas continuam abertas e não devem ser inferidas dos gates locais:

- nenhum aparelho Android físico estava conectado; a prova atual usa emulador
  Android API 36;
- compatibilidade da upload key com Play App Signing não foi comprovada no Play
  Console;
- FCM em foreground e background tap não foi comprovado em aparelho físico;
- o APK/AAB não foi publicado na Play Store;
- iOS passou apenas build sem codesign; não há TestFlight/App Store;
- scanner/câmera/OCR permanecem desabilitados e sem prova física fresca;
- backup off-site criptografado e restore a partir dessa cadeia não foram
  executados por ausência de destino/recipient configurado.

Essas limitações não invalidam o fechamento funcional local dos três módulos,
mas impedem qualquer afirmação de distribuição física ou continuidade externa
completa.

## 9. Regra de atualização

Toda mudança de status deve registrar a SHA, versão, ambiente, comando ou
jornada executada e limite da evidência. Não substituir `pendente` por `passou`
com base em build, teste de outra SHA, saúde isolada de sidecar ou artefato
anterior.
