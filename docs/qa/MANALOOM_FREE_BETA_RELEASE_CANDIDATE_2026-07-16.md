# Candidato de release da beta gratuita do ManaLoom

**Data de corte:** 2026-07-16; validação técnica atualizada em 2026-07-17

**Alvo:** Web + Android

**Versão selecionada:** `1.0.0+2`

**SHA de promoção:** resolvida pelo manifest gerado no checkout limpo; o congelamento em `origin/master` continua pendente

**Estado:** implementação e gates locais de Battle, Deckbuilder e Life Counter concluídos; commit final, push para `origin/master`, rebuild da mesma SHA, migrations e promoção live ainda pendentes

**Decisão atual:** **pronto para a sequência controlada de promoção**, sem GO de produção até concluir migrations, deploy e E2E live

Este é o documento operacional do candidato final da beta gratuita. Ele separa o que existe no código, o que já teve prova local, o que ainda depende de ambiente externo e o que foi efetivamente promovido. Não é autorização implícita para migration, deploy, upload, publicação ou mutação de dados.

## 1. Veredito executivo

O candidato cobre as frentes essenciais de produto, segurança e operação para uma beta Web + Android: acesso gratuito, armazenamento seguro de sessão, exportação/exclusão de conta, sincronização pós-jogo com tombstones, Life Counter unificado, disclosure de trocas P2P, billing desabilitado, CORS restrito, artefatos de supply chain e scripts de backup/restore/observabilidade fail-closed.

As suítes integradas do cliente e servidor passaram com, respectivamente,
**948 testes aprovados + 1 skip intencional** e **1.583 testes aprovados**, com
análise estática sem issues. Battle passou persistência/autorização em
PostgreSQL descartável com sidecar nativo; Deckbuilder passou schema, estados de
validação e importação atômica; Life Counter passou Web e Android 2–6 jogadores
com persistência. A credencial histórica da conta já foi rotacionada e a antiga
retorna HTTP 401. O estado ainda não é produção: a SHA precisa ser congelada em
`origin/master`, o PostgreSQL live continua na migration 037, as migrations
038–040 e o backend/Web ainda não foram promovidos, e o E2E publicado não foi
executado.

## 2. Escopo de produto da beta

### Incluído

- cadastro, login e continuidade de deep link;
- Home, decks, coleção, comunidade, mensagens, notificações e perfil;
- ciclo `generate/import → analyze → optimize/rebuild → apply → validate`;
- Battle entre deck próprio e deck próprio/público, com replay persistido e
  autorização por proprietário iniciador;
- Life Counter Lotus na Web e no app, conectado a deck e pós-jogo;
- notas pós-jogo offline e cross-device, condicionadas à migration 038 no servidor;
- exportação dos dados da conta e exclusão/anonimização autenticada;
- coordenação de trocas entre usuários, com aviso explícito de responsabilidade;
- distribuição Web e Android do mesmo código-fonte e da mesma identidade de release.

### Gratuito durante a beta

- O acesso da beta é gratuito por decisão de produto.
- Telas comerciais não anunciam preço ou compra disponível.
- Checkout pago fica desabilitado e o backend de billing falha fechado.
- A gratuidade temporária não deve ser interpretada como promessa de preço futuro ou entitlement permanente.

### Fora do escopo publicável atual

- checkout, assinatura, cobrança, reembolso ou renovação pagos;
- escrow, custódia, proteção de pagamento, garantia de entrega, mediação ou disputa de trocas;
- scanner fora do Android: Web/dev/iOS continuam em busca manual; o pipeline
  Android release habilita `ENABLE_SCANNER_RELEASE=true` após a prova S4-07;
- publicação iOS: build no-codesign é uma prova de compilação, não distribuição;
- expansão de metagame, eventos ou novas áreas sociais antes de estabilizar o ciclo principal.

## 3. Contrato de trocas da beta

Trocas são uma ferramenta de coordenação P2P. ManaLoom registra proposta e estados do fluxo, mas não recebe dinheiro, não segura bens e não garante a conduta dos participantes.

O aviso de segurança deve permanecer visível na criação e no detalhe da troca:

- pagamento e entrega são combinados diretamente entre os usuários;
- o usuário deve validar identidade, condição da carta, valor, frete e forma de entrega;
- nenhum estado da interface equivale a confirmação bancária, proteção de compra ou garantia logística;
- linguagem como “pagamento protegido”, “compra garantida” ou “disputa ManaLoom” é proibida enquanto não existir contrato operacional próprio.

## 4. Invariante de identidade da release

Uma publicação válida deve satisfazer simultaneamente:

```text
HEAD local == origin/master == SHA do backend == SHA do Web == SHA do APK == SHA do AAB
versão em pubspec == versão nos manifests == versionName/versionCode Android
checkout limpo == true
```

Regras obrigatórias:

1. Não reutilizar artefato construído antes do commit final.
2. Não misturar Web de um SHA com API ou Android de outro SHA.
3. Gerar manifest, checksums, SBOM e provenance no mesmo pipeline do artefato.
4. Tratar probe local como probe; somente o orquestrador de mesma SHA produz candidato publicável.
5. Qualquer correção após o build invalida todos os artefatos e exige rebuild completo.

O comando de candidato é:

```bash
MANALOOM_RELEASE_REQUIRE_SENTRY=0 \
  scripts/manaloom_build_beta_release.sh
```

Esse modo permite validação local sem Sentry, mas seus manifests registram `sentry_configured: false` e impedem publicação acidental.

## 5. Matriz de segurança, privacidade e operação

| Controle | Estado no código | Prova atual | Falta para release |
|---|---|---|---|
| Sessão/token | `flutter_secure_storage` com migração do legado | Análise e testes do cliente passaram no ciclo de subsistema | Runtime autenticado no candidato final |
| Android hardening | Backup desabilitado; permissões de áudio/storage/media removidas; allowlist de permissões; dependency locking e metadata de verificação Gradle | APK/AAB `1.0.0+2` passaram pacote, assinatura, release mode, ZIP/JAR e permissões; Android 36 instalou/abriu sem fatal e o Life Counter passou funcional/visualmente no host local | Congelar mesma SHA, confirmar compatibilidade com Play App Signing e instalar/exercitar o APK exato em aparelho físico |
| iOS hardening | ATS arbitrário e anúncio de rede local removidos; baseline mínimo alinhado em iOS 15.5 | Build Debug de simulador sem codesign passou; dependências CocoaPods/SwiftPM ficaram fixadas | Cadeia Apple e runtime instalável; fora do alvo Web+Android |
| Autenticação e abuso | JWT de produção exige segredo forte; política de senha 12–256 bloqueia senhas comuns/dados da conta; identidade e rate limit falham fechados atrás de proxy confiável | Preflight positivo/negativo, contratos e suítes locais passaram | Configurar peers/hops confiáveis exatos e provar runtime após o deploy |
| CORS da API | Allowlist exata HTTPS, sem wildcard/localhost/path/credenciais | Validador e contratos locais passaram | Configurar `MANALOOM_ALLOWED_ORIGINS` no serviço e comprovar spec + runtime |
| Exportação de conta | Cliente e endpoint implementados | 6/6 testes focados de privacidade/perfil | Prova autenticada contra backend migrado |
| Exclusão/anonimização | Confirmação exata + senha; sessão limpa somente após `account_deleted: true`; guards de conta excluída | Testes focados e servidor all-local verdes | Migration 038, prova live controlada e auditoria de dados residuais |
| Pós-jogo cross-device | Revisão, cursor, watermark e tombstones no cliente/servidor | Testes cliente e servidor all-local | Migration 038 e cenário em dois clientes |
| Deckbuilder | Geração falha fechado; importação é atômica e salva rascunho revisável quando incompleta; estados `unknown/draft/validated` são persistidos e invalidados por mudança de carta/formato | 56 testes focados de servidor, 6 de documentação e 73 Flutter; migrations 039/040 passaram fresh install, upgrade e idempotência em PostgreSQL 16 isolado | Aplicar 039/040 e provar criação/importação/validação no backend publicado |
| Battle | Oponente próprio/público, ordem determinística, persistência obrigatória, `replay_id` canônico, leitura limitada ao proprietário iniciador e erros sanitizados | Gate estático 46/46; E2E em PostgreSQL descartável + sidecar nativo persistiu quatro replays, repetiu seed deterministicamente e validou autorização | Provar a mesma jornada contra backend/sidecars publicados após 038–040 |
| Trocas P2P | Aviso de segurança na criação/detalhe; sem promessa financeira | Testes de UI/contratos do cliente no ciclo de subsistema | Runtime autenticado e monitoramento de estados bilaterais |
| Billing | Beta gratuita; checkout não anunciado; backend fail-closed | Contratos locais | Smoke de rotas comerciais no candidato final |
| Contas excluídas | Visibilidade e interações bloqueadas no servidor | Suite all-local | Verificação pós-migration |
| Supply chain | SHA/version manifests, checksums, CycloneDX SBOM e provenance in-toto/SLSA; imagens base e Actions fixadas; Flutter `3.44.6` e seu Dart irmão são obrigatórios | 25/25 contratos operacionais; SBOM com 936 componentes consultados no OSV, 226 excluídos, 60 vulnerabilidades apenas em dependências excluídas/não-release e 0 vulnerabilidade de release | Gerar pacote final a partir de checkout limpo e confirmar CI da SHA publicada |
| Rollback | API, Web, host de distribuição Android, manaloom-ops, XMage e Forge preservam identidade anterior e exigem convergência de digest/health | Contratos locais e builds reais de containers passaram; rollback falha fechado | Capturar digest/serviço/origem reais e executar prova controlada na janela de promoção |
| CI | Workflow com permissões read-only e evidência de APK/SBOM/provenance | Sintaxe/contratos locais | Execução verde no commit final |
| Sentry | Gate rejeita `not_proven` e exige evidência do mesmo SHA/versão | Fail-closed implementado | DSN, token, org/project e evento do candidato |
| FCM | Gate exige foreground e background tap | Fail-closed implementado | Device, credenciais e log com ambas as provas |
| Backup off-site | Criptografia `age`, S3, hashes e manifest; dry-run por padrão | Contrato local passou; `age 1.3.1` e Docker 28.1.1 estão prontos | Configurar destino/recipient, executar upload criptografado e verificar |
| Restore isolado | Decripta em diretório efêmero, Postgres 17 sem rede, constraints/contagens e cleanup | Restore local passou com `postgres:17`, rede desabilitada, constraints válidas e zero writes remotos | Repetir a partir da cópia off-site criptografada; a prova atual teve `encryption_chain=false` |
| Scanner | Android release habilitado; Web/dev/iOS em busca manual | 30/30 focados, 1/1 harness e 2/2 câmera/MLKit no SM A135M; APK release instalado/aberto | Matriz humana normal/foil/baixa luz é calibração P2; runtime iOS segue na sprint Apple |
| Credenciais versionadas | Secret scanner local impede novo segredo no candidato | O literal existia no snapshot predecessor de `origin/master` e permanece no histórico, mas a senha da conta foi rotacionada; a antiga recebeu HTTP 401 e a nova HTTP 200. Novo segredo e JWT ficam no Keychain, fora do repositório | Publicar o candidato sem o literal; implantar o novo JWT e provar que tokens assinados pelo segredo anterior foram recusados |

## 6. Evidências locais confirmadas

As linhas abaixo são evidência de estágio. Nenhuma delas, isoladamente, significa deploy ou aprovação do candidato final.

| Comando ou gate | Resultado confirmado | Limite |
|---|---|---|
| `flutter pub get --enforce-lockfile` | Passou após resolver o lock com Flutter `3.44.6` | Não compila nem executa o produto |
| Análise do cliente | 0 issues | Execução final com `--fatal-infos --fatal-warnings` |
| Suíte completa do cliente | **948 passaram, 1 web-only pulado** | Execução integrada com Flutter `3.44.6`; sem backend live |
| Testes focados de privacidade/perfil | 6/6 passaram | Não substitui backend migrado/runtime autenticado |
| `RUN_INTEGRATION_TESTS=0 ... dart test -P all-local --reporter compact` | **1.583 passaram** | Sem PostgreSQL live |
| Testes focados de sets/Basic Land | 12/12 passaram | Cobertura local |
| `scripts/manaloom_release_ops_contract_test.sh` | **25/25 contratos passaram** | Sem upload, device ou deploy live |
| Execução integrada final de servidor + Flutter | **PASS**: servidor 1.583/1.583, cliente 948 + 1 skip e análises sem issues | Resultados locais do checkout candidato; não representam deploy nem o futuro artefato da SHA congelada |
| `./scripts/quality_gate.sh deps` | Passou | Não é gate funcional completo |
| `./scripts/quality_gate.sh custom-lint` | Passou; 5/5 testes | Subsistema de lint |
| `./scripts/quality_gate.sh ui-audit` | Passou; análise 0 issues e 13 testes | Auditoria automatizada, não jornada visual autenticada completa |
| Build Web/Android/iOS | Web release, APK/AAB release e iOS sem codesign passaram localmente para `1.0.0+2` | Não equivale a publicação nem prova de mesma SHA congelada |
| AAB Android | 93,7 MB; SHA-256 `3f9b55d216646797e757f61d6a8ba963151948e77dd7e79db3936dcb4c5b9fd4` | JAR/certificado aprovados; artefato local, ainda não publicado |
| APK Android | 115,6 MB; SHA-256 `f8cc6a5b74c24ccb601e5577053d59439121f60f06f8b52c82fac27c94b395b4` | `com.mtgia.mtg_app`, `1.0.0+2`, assinatura v2/certificado aprovados e cold launch em emulador Android 36 |
| SBOM + OSV do AAB | **PASS**: 936/936 componentes consultados, 226 excluídos, 60 vulnerabilidades apenas em dependências não-release/excluídas e 0 vulnerabilidade de release | Deve ser regenerado a partir da SHA final limpa |
| Android 36 emulador | Instalação e cold launch passaram, sem fatal/`MissingPlugin` | Não substitui aparelho físico |
| Life Counter web | Desktop e 390 × 844 passaram; vida 40→41→40, menu/histórico/rota direta, localização e acessibilidade dos dados/moeda/personalizado validados | A recaptura final desktop confirmou D4/D6/D8/D10/D12/D20, personalizado, moeda, fechar e o botão `ROLAR` integralmente visível; a jornada autenticada completa continua aberta |
| Life Counter nativo isolado | 370 testes VM + 1 skip e 2 testes Chrome; matriz Android 2–6 jogadores passou; vida 40→41 persistiu após fechar/reabrir e a captura reaberta foi idêntica à anterior | Emulador Android 36; não substitui aparelho físico |
| Battle focada | Gate estático 46/46; PostgreSQL descartável + sidecar nativo persistiu quatro replays com IDs duráveis, repetiu a seed deterministicamente e bloqueou leitura cruzada | Ambiente isolado, não produção |
| Deckbuilder focado | 56 testes de servidor, 6 de documentação e 73 Flutter; fresh schema, upgrade e idempotência das migrations 039/040 passaram em PostgreSQL 16 | Ambiente isolado, não produção |
| Patrol smoke | 9/9 passaram | Smoke local |
| Web pública | **PASS** | `npm ci`, audit de produção com 0 vulnerabilidades, lint e build Next.js de 13 rotas passaram |
| Host Web do app | **PASS** | Contexto Docker reduzido de 4,4 GB para 51,10 MB; imagem Nginx real ficou healthy; `/healthz` 200, `/` 404, `/app/` 200 e headers de segurança/cache conferidos |
| Containers de operação | **PASS LOCAL DE BUILD/RUNTIME** | manaloom-ops e XMage construíram/rodaram com health 200; o Forge compilou os 6 módulos e seu runtime final respondeu `/health` 200 com commit fixado e 33.288 cartas indexadas. Os hardenings P1 de usuário/`Dockerfile HEALTHCHECK` permanecem separados |
| Auditoria de dependências | **PASS** | App, server e lints sem incoerências; diretórios Flutter efêmeros/build são excluídos da varredura para impedir travessia de symlinks gerados |
| `./scripts/quality_gate.sh e2e` | **PASS** | 14 etapas executadas e 5 opt-in em SKIP; revalidação pós-correções em `/tmp/manaloom_e2e_suite_reports/manaloom_e2e_suite_20260717T005439Z/summary.md` |
| `VALIDATION_PREFLIGHT_ONLY=1 ./scripts/quality_gate.sh resolution` | **PASS** | 19/19 Commander; sem writes |
| Backup/restore PostgreSQL pré-migration | **PASS LOCAL, NÃO FINAL** | Dump `backups/manaloom-postgres/manaloom-postgres-20260717T105914Z.dump`, 300.692.505 bytes, modo `0600`, checksum validado; restore de schema em PostgreSQL 17 confirmou 87 tabelas. Como o dump antecede a rotação da senha, um backup fresco é obrigatório antes do apply live |
| Backup off-site criptografado | **PENDENTE** | Ferramentas prontas; faltam destino e recipient |

## 7. Estado local versus produção

| Área | Checkout/candidato | Produção atualmente | Conclusão permitida |
|---|---|---|---|
| App Web | Build `1.0.0+2` e runtime do Life Counter passaram localmente | Instalação já existente não contém este candidato | Não dizer “está no ar” |
| Android | APK/AAB `1.0.0+2` validados localmente; emulador passou; aparelho físico pendente | Publicação anterior não prova este candidato | Não distribuir antes da identidade final e prova física |
| API | Privacidade, guards, sync, Deckbuilder, Battle e CORS implementados localmente | API atual ainda é a versão anterior | Não atribuir os contratos novos ao runtime live |
| PostgreSQL | Migrations 038–040 preparadas e provadas em PostgreSQL isolado | Precheck live read-only reporta migration máxima 037 | Aplicar 038–040 somente após backup fresco e autorização explícita |
| iOS | Build sem codesign | Sem distribuição nativa habilitada | Fora do alvo desta beta |
| Observabilidade | Gates fail-closed implementados; Sentry DSN/token e JWT novo estão em Keychain | Evidência do SHA final e ingestão pós-deploy ainda não existem | Não inferir observabilidade live |
| Backup/DR | Restore local isolado passou; `age`/Docker prontos | Cópia off-site criptografada ainda não existe/provou restore | Continuidade externa ainda aberta |

## 8. Bloqueios P0 e condição de fechamento

1. **Congelamento:** fazer staging explícito, commit/push intencional, checkout limpo e `HEAD == origin/master`.
2. **Banco:** gerar backup fresco após a rotação da senha, executar precheck read-only das migrations 038–040, preparar rollback e usar a autorização literal antes de qualquer write.
3. **Backend e borda:** configurar CORS, `MANALOOM_TRUSTED_PROXY_HOPS`, `MANALOOM_TRUSTED_PROXY_PEERS` e JWT forte; validar `/health`, `/ready`, identidade do cliente, rate limit e contratos após deploy.
4. **Privacidade e sync:** provar export/delete e tombstone/reconciliação contra o backend migrado.
5. **Web autenticada:** percorrer as áreas críticas em mobile e desktop; o Life Counter isolado já passou.
6. **Android físico:** confirmar compatibilidade do upload key com Play App Signing; instalar o APK assinado exato, conferir versão/certificado e executar login, navegação, Life Counter/retomada e push; emulador não substitui esta prova.
7. **Observabilidade:** evento Sentry do SHA final e FCM foreground/background tap.
8. **DR off-site:** enviar backup criptografado para destino externo e repetir a verificação/restore a partir dessa cadeia.
9. **Credencial/JWT:** a senha exposta já foi rotacionada; publicar a remoção do literal, promover o novo JWT e provar que um token assinado pelo segredo anterior foi invalidado.

Sem esses itens, o estado continua **candidato local**, não release concluída.

## 9. Autoridade para operações live

Os checks read-only podem ser executados sem alterar produção. Writes e deploys permanecem separados.

Antes de PostgreSQL write, o fluxo exige autorização literal por meio de:

```text
MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL
```

Antes de mutações live/deploy, o fluxo exige:

```text
MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL
```

Esses valores são confirmações operacionais, não credenciais. Eles não devem ser definidos automaticamente a partir de uma autorização genérica. A sequência segura é precheck → plano/contagens → aprovação → apply → postcheck → evidência.

## 10. Ordem de promoção

1. Preservar a evidência verde das suítes finais, E2E, resolution preflight, Patrol e contratos operacionais; fechar formatação, `git diff --check` e secret scan.
2. Revisar o diff completo, definir versão e congelar a SHA em `origin/master`.
3. Gerar um dump fresco pós-rotação e rodar precheck read-only das migrations 038–040, capturando contagens, compatibilidade e `pgcrypto`.
4. Confirmar backup e rollback; somente então solicitar a autorização literal de PostgreSQL.
5. Aplicar migrations 038–040 em ordem e registrar postcheck; 038 é de privacidade/sync, 039 adiciona estados/triggers do Deckbuilder e 040 normaliza `cards.is_reserved`.
6. Construir e promover a API da SHA congelada, com CORS exato e health checks.
7. Construir o pacote Web/APK/AAB pelo orquestrador de mesma SHA.
8. Executar smoke autenticado Web e Android físico; fechar Sentry/FCM.
9. Fechar backup off-site criptografado e repetir o restore a partir dessa cadeia; o restore local isolado já passou.
10. Publicar Web e promover Android de forma controlada; monitorar erros, auth, privacidade, sync e filas.

## 11. Rollback

### Backend/API

- Preservar a imagem anterior identificada por SHA.
- Se health, auth, export/delete ou sync falhar, reverter o serviço para a imagem anterior.
- As migrations 038–040 são aditivas/normalizadoras; rollback do backend pode deixar o schema novo sem uso.
- Não remover colunas/tabelas automaticamente durante rollback de aplicação.

### PostgreSQL

- Guardar dump, precheck, migration aplicada, postcheck e script de rollback no bundle de evidência.
- Só executar rollback SQL se o plano aprovado demonstrar que não perde dados escritos pelo backend novo.
- Em dúvida, manter schema aditivo e reverter apenas a aplicação.

### Web

- Preservar artefato/imagem e manifest da versão anterior.
- Reverter para o Web da SHA anterior juntamente com a API compatível.
- Invalidar cache/CDN e confirmar `release.json` após a reversão.

### Android

- Usar rollout controlado; interromper promoção ao detectar regressão.
- Não é possível retirar um APK já instalado. Manter build anterior e preparar incremento corretivo de `versionCode`.
- Correlacionar crash/eventos por SHA e versão antes de ampliar o rollout.

### Observabilidade e operação

- Não desligar gates para “destravar” publicação.
- Se Sentry/FCM ou a cadeia off-site de backup/restore não produzir evidência válida, manter esses controles explicitamente abertos e não ampliar a distribuição dependente deles.
- Nunca registrar DSN, tokens, URLs de banco, senhas, keystore ou conteúdo sensível nos artefatos versionados.

## 12. Checklist final de go/no-go

### Código e identidade — owner de release

- [x] Suítes integradas verdes com Flutter `3.44.6`: servidor all-local 1.583/1.583, Flutter analyze 0 e Flutter 948 + 1 skip.
- [x] Web pública verde: npm audit de produção com 0 vulnerabilidades, lint e build de 13 rotas.
- [x] Gate operacional verde: 25/25 contratos; os 35 arquivos shell presentes no diff final passaram `bash -n` e `shellcheck -S warning -x`.
- [x] E2E verde: 14 etapas executadas, 5 opt-in em SKIP.
- [x] Resolution preflight verde: 19/19, sem writes.
- [x] Patrol smoke verde: 9/9.
- [x] `git diff --check`, formatação e secret scan repetidos após a última edição de código.
- [x] Revisão final do diff concluída sem artefatos grandes, credenciais literais ou mudanças de modo acidentais.
- [ ] Staging explícito, commit e push concluídos.
- [ ] Checkout limpo; `HEAD == origin/master`.
- [x] Builds locais Web/APK/AAB e iOS sem codesign `1.0.0+2` concluídos.
- [ ] Web/APK/AAB/API registram a mesma SHA final congelada.
- [x] Contrato local de checksums, SBOM, OSV e provenance validado; 936 componentes foram consultados, 226 ficaram excluídos, 60 vulnerabilidades permaneceram somente no escopo não-release/excluído e 0 vulnerabilidade atingiu a release.
- [ ] Checksums, SBOM e provenance regenerados para a SHA final promovida.
- [x] Senha da credencial versionada rotacionada; senha antiga recusada com HTTP 401 e nova aceita com HTTP 200.
- [ ] Remoção do literal publicada; novo JWT implantado e token anterior recusado.

### Banco e backend — owner de backend/DB

- [x] Precheck read-only live registrado: migration máxima 037; 038–040 permanecem pendentes.
- [ ] Precheck read-only fresco repetido a partir da SHA final antes da janela de promoção.
- [x] Dump pré-rotação e restore local isolado confirmados; plano de rollback preparado. A cópia off-site continua pendente.
- [ ] Dump fresco pós-rotação confirmado antes do apply.
- [ ] Autorização literal obtida antes de writes.
- [ ] Migrations 038–040 aplicadas e postcheck verde.
- [ ] API nova saudável e guards de conta excluída provados.
- [ ] CORS de produção contém apenas origens HTTPS exatas autorizadas; JWT e trusted proxy peers/hops estão configurados e provados.

### Produto e privacidade — owner de QA

- [ ] Cadastro/login/deep links em Web mobile/desktop.
- [ ] Home, decks, coleção, comunidade, mensagens, perfil e Life Counter.
- [x] Life Counter web isolado em desktop e 390 × 844, com persistência/reload e console limpo.
- [x] Life Counter nativo isolado no Android 36, incluindo matriz 2–6 jogadores e persistência 40→41 após fechar/reabrir.
- [x] Battle passou persistência/autorização/determinismo em PostgreSQL + sidecar nativo descartáveis.
- [x] Deckbuilder passou estados, importação, geração fail-closed e migrations 039/040 em PostgreSQL isolado.
- [ ] Battle, Deckbuilder e Life Counter percorridos no runtime publicado após as migrations.
- [ ] Exportação autenticada gera dados esperados.
- [ ] Exclusão exige confirmação/senha e só encerra sessão após sucesso.
- [ ] Pós-jogo sincroniza e uma exclusão tombstonada não ressuscita em dois clientes.
- [ ] Trocas exibem aviso P2P na criação e no detalhe.
- [ ] Planos/upgrade/checkout não oferecem cobrança durante a beta.

### Android e observabilidade — owner de mobile/ops

- [ ] APK assinado exato instalado em aparelho físico.
- [ ] Upload key confirmado como compatível com Play App Signing.
- [x] Package, versionCode/versionName, certificado e permissões dos artefatos locais conferidos.
- [x] Instalação/cold launch em emulador Android 36 sem fatal/`MissingPlugin`.
- [x] Life Counter usado, fechado, reaberto e retomado no emulador Android 36.
- [ ] O mesmo fluxo provado em aparelho físico com o artefato promovido.
- [ ] Evento Sentry correlacionado à mesma SHA/versão.
- [ ] FCM foreground e background tap provados.
- [x] Scanner continua desabilitado por padrão.

### Continuidade — owner de operações

- [ ] Backup off-site criptografado verificado.
- [x] Restore local isolado concluído em `postgres:17`/`--network none`, constraints válidas e sem writes remotos.
- [ ] Restore repetido a partir da cadeia off-site criptografada.
- [ ] Runbook, contatos, janela e critérios de rollback confirmados.
- [ ] Smoke pós-deploy e janela de monitoramento definidos.

### Decisão

- [ ] Todos os itens obrigatórios de promoção estão fechados: registrar **GO Web + Android**.
- [x] Enquanto houver item obrigatório aberto, manter o estado como **candidato local / promoção pendente**, com responsável e próxima evidência.

## 13. Documentos relacionados

- `docs/qa/MANALOOM_PRODUCT_EXPERIENCE_AUDIT_2026-07-16.md` — experiência, coerência de produto e inventário tela a tela.
- `docs/qa/MANALOOM_FREE_BETA_RELEASE_OPS_GATE_2026-07-16.md` — comandos e contratos operacionais detalhados.
- `docs/qa/MANALOOM_BATTLE_DECKBUILDER_LIFE_COUNTER_RELEASE_2026-07-17.md` — fechamento local e pendências live dos três módulos.
- `docs/MANALOOM_E2E_RELEASE_CONTRACT.md` — perfis de validação e fronteira de autorização.
- `docs/CONTEXTO_PRODUTO_ATUAL.md` — prioridade operacional vigente.
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md` — contratos app/backend.

---

**Regra de manutenção:** atualizar este documento somente com evidência fresca do mesmo SHA candidato. Um resultado parcial deve permanecer parcial; um artefato local não deve ser descrito como publicado.
