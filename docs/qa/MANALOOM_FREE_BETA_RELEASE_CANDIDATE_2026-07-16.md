# Candidato de release da beta gratuita do ManaLoom

**Data de corte:** 2026-07-16

**Alvo:** Web + Android

**Versão selecionada:** `1.0.0+2`

**SHA final:** pendente de congelamento após commit, push e checkout limpo

**Estado:** implementação local consolidada; validação final e promoção para produção pendentes

**Decisão atual:** **NO-GO para publicação**, até fechar os itens P0 deste documento

Este é o documento operacional do candidato final da beta gratuita. Ele separa o que existe no código, o que já teve prova local, o que ainda depende de ambiente externo e o que foi efetivamente promovido. Não é autorização implícita para migration, deploy, upload, publicação ou mutação de dados.

## 1. Veredito executivo

O candidato cobre as frentes essenciais de produto, segurança e operação para uma beta Web + Android: acesso gratuito, armazenamento seguro de sessão, exportação/exclusão de conta, sincronização pós-jogo com tombstones, Life Counter unificado, disclosure de trocas P2P, billing desabilitado, CORS restrito, artefatos de supply chain e scripts de backup/restore/observabilidade fail-closed.

O gate `full` integrado passou com exit 0, somando-se a E2E, resolution preflight, Patrol, builds locais, runtime do Life Counter web, host nativo Android isolado e restore. O estado ainda não é publicável porque a SHA final não foi congelada e permanecem abertas a migration 038, o backup off-site criptografado, Sentry/FCM, o runtime autenticado completo e a instalação do APK assinado exato em aparelho físico.

## 2. Escopo de produto da beta

### Incluído

- cadastro, login e continuidade de deep link;
- Home, decks, coleção, comunidade, mensagens, notificações e perfil;
- ciclo `generate/import → analyze → optimize/rebuild → apply → validate`;
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
- scanner em produção: `ENABLE_SCANNER_RELEASE=false` até prova física fresca;
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
| Android hardening | Backup desabilitado; permissões de áudio/storage/media removidas; allowlist de permissões | APK/AAB `1.0.0+2` passaram pacote, assinatura, release mode e permissões; Android 36 instalou/abriu sem fatal/`MissingPlugin` e o debug host nativo do Life Counter passou funcional/visualmente | Congelar mesma SHA e instalar/exercitar o APK exato em aparelho físico |
| iOS hardening | ATS arbitrário e anúncio de rede local removidos | Build release no-codesign passou como probe | Cadeia Apple e runtime instalável; fora do alvo Web+Android |
| CORS da API | Allowlist exata HTTPS, sem wildcard/localhost/path/credenciais | Validador e contratos locais passaram | Configurar `MANALOOM_ALLOWED_ORIGINS` no serviço e comprovar spec + runtime |
| Exportação de conta | Cliente e endpoint implementados | 6/6 testes focados de privacidade/perfil | Prova autenticada contra backend migrado |
| Exclusão/anonimização | Confirmação exata + senha; sessão limpa somente após `account_deleted: true`; guards de conta excluída | Testes focados e servidor all-local verdes | Migration 038, prova live controlada e auditoria de dados residuais |
| Pós-jogo cross-device | Revisão, cursor, watermark e tombstones no cliente/servidor | Testes cliente e servidor all-local | Migration 038 e cenário em dois clientes |
| Trocas P2P | Aviso de segurança na criação/detalhe; sem promessa financeira | Testes de UI/contratos do cliente no ciclo de subsistema | Runtime autenticado e monitoramento de estados bilaterais |
| Billing | Beta gratuita; checkout não anunciado; backend fail-closed | Contratos locais | Smoke de rotas comerciais no candidato final |
| Contas excluídas | Visibilidade e interações bloqueadas no servidor | Suite all-local | Verificação pós-migration |
| Supply chain | SHA/version manifests, checksums, CycloneDX SBOM e provenance in-toto/SLSA | Contratos release/DR 10/10 | Gerar pacote final a partir de checkout limpo |
| CI | Workflow com permissões read-only e evidência de APK/SBOM/provenance | Sintaxe/contratos locais | Execução verde no commit final |
| Sentry | Gate rejeita `not_proven` e exige evidência do mesmo SHA/versão | Fail-closed implementado | DSN, token, org/project e evento do candidato |
| FCM | Gate exige foreground e background tap | Fail-closed implementado | Device, credenciais e log com ambas as provas |
| Backup off-site | Criptografia `age`, S3, hashes e manifest; dry-run por padrão | Contrato local passou; `age 1.3.1` e Docker 28.1.1 estão prontos | Configurar destino/recipient, executar upload criptografado e verificar |
| Restore isolado | Decripta em diretório efêmero, Postgres 17 sem rede, constraints/contagens e cleanup | Restore local passou com `postgres:17`, rede desabilitada, constraints válidas e zero writes remotos | Repetir a partir da cópia off-site criptografada; a prova atual teve `encryption_chain=false` |
| Scanner | Desabilitado por padrão | Flag/redirect cobertos | Device/câmera/OCR/correção manual antes de habilitar |

## 6. Evidências locais confirmadas

As linhas abaixo são evidência de estágio. Nenhuma delas, isoladamente, significa deploy ou aprovação do candidato final.

| Comando ou gate | Resultado confirmado | Limite |
|---|---|---|
| `flutter pub get` | Passou após o bump `1.0.0+2` | Não compila nem executa o produto |
| Análise do cliente | 0 issues | Confirmado no `full` final |
| Suíte completa do cliente | 909 passaram, 1 web-only pulado | Confirmado no `full` final |
| Testes focados de privacidade/perfil | 6/6 passaram | Não substitui backend migrado/runtime autenticado |
| `RUN_INTEGRATION_TESTS=0 ... dart test -P all-local --reporter compact` | 1494 passaram | Sem PostgreSQL live |
| Testes focados de sets/Basic Land | 12/12 passaram | Cobertura local |
| `scripts/manaloom_release_ops_contract_test.sh` | 10/10 contratos passaram | Sem upload, restore real, device ou deploy |
| Testes Dart focados de operação | 9/9 passaram | Cobertura de contrato |
| `./scripts/quality_gate.sh deps` | Passou | Não é gate funcional completo |
| `./scripts/quality_gate.sh custom-lint` | Passou; 5/5 testes | Subsistema de lint |
| `./scripts/quality_gate.sh ui-audit` | Passou; análise 0 issues e 13 testes | Auditoria automatizada, não jornada visual autenticada completa |
| Build Web/Android/iOS | Passou localmente para `1.0.0+2` | Não equivale a publicação nem prova de mesma SHA congelada |
| AAB Android | 75,1 MB; SHA-256 `3b501a0f6656c7f85ef6928326a73290dc6fe4f8218605ec74b606aacb02046a` | Artefato local, ainda não publicado |
| APK Android | 114,4 MB; SHA-256 `6eba1ea198e8e0d264bdbdcb69a4af5d37a065bbee641629eaa4e2c0152bb752` | `com.mtgia.mtg_app`, `1.0.0+2`, assinatura igual ao upload keystore e permissões mínimas |
| Android 36 emulador | Instalação e cold launch passaram, sem fatal/`MissingPlugin` | Não substitui aparelho físico |
| Life Counter web | Desktop e 390 × 844 passaram; vida 40→41 persistiu no reload, menu/histórico/rota direta válidos, console 0 erros/0 warnings | Prova local; jornada autenticada completa continua aberta |
| Life Counter nativo isolado | Android 36 debug host: quatro jogadores, vida 40→41, menu, histórico e evento persistido passaram; overlap de “Todas as partidas” com fechar/header corrigido e revalidado visualmente + teste estático | Não substitui aparelho físico nem o APK release assinado |
| Patrol smoke | 9/9 passaram | Smoke local |
| `./scripts/quality_gate.sh full` | **PASS** | Exit 0: backend 1494/1494, Flutter analyze 0, Flutter 909 pass + 1 skip, Web ESLint/build de 12 páginas/smoke PASS e npm 0 vulnerabilidades; smoke `/tmp/manaloom_public_web_smoke/20260717T005350Z_97473_2517619098` |
| `./scripts/quality_gate.sh e2e` | **PASS** | 14 etapas executadas e 5 opt-in em SKIP; revalidação pós-correções em `/tmp/manaloom_e2e_suite_reports/manaloom_e2e_suite_20260717T005439Z/summary.md` |
| `VALIDATION_PREFLIGHT_ONLY=1 ./scripts/quality_gate.sh resolution` | **PASS** | 19/19 Commander; sem writes |
| Restore PostgreSQL isolado | **PASS LOCAL** | Dump `/tmp/manaloom-final-backup-20260716/manaloom-postgres-20260717T001442Z.dump`, SHA-256 `d45b6ef30e974a4f01035f18804e605da0ce29c2ace782e17ad0833a4603c470`; `postgres:17`, `--network none`, 83 tabelas, 63 FKs, `users=1133`, `cards=34331`, `decks=311`, `deck_cards=8579`, constraints válidas, `remote_writes=false`, `encryption_chain=false` |
| Backup off-site criptografado | **PENDENTE** | Ferramentas prontas; faltam destino e recipient |

## 7. Estado local versus produção

| Área | Checkout/candidato | Produção atualmente | Conclusão permitida |
|---|---|---|---|
| App Web | Build `1.0.0+2` e runtime do Life Counter passaram localmente | Instalação já existente não contém este candidato | Não dizer “está no ar” |
| Android | APK/AAB `1.0.0+2` validados localmente; emulador passou; aparelho físico pendente | Publicação anterior não prova este candidato | Não distribuir antes da identidade final e prova física |
| API | Privacidade, guards, sync e CORS implementados localmente | API atual ainda não tem os contratos novos/migration 038 | Não subir backend novo antes da migration |
| PostgreSQL | Migration 038 preparada | Status anterior permanece até precheck/apply explícito | Não inferir schema novo |
| iOS | Build no-codesign probe | Sem distribuição nativa habilitada | Fora do alvo desta beta |
| Observabilidade | Gates fail-closed implementados | Credenciais/evidência do SHA final não disponíveis | Publicação bloqueada |
| Backup/DR | Restore local isolado passou; `age`/Docker prontos | Cópia off-site criptografada ainda não existe/provou restore | Continuidade externa ainda aberta |

## 8. Bloqueios P0 e condição de fechamento

1. **Congelamento:** commit/push intencional, checkout limpo e `HEAD == origin/master`.
2. **Banco:** executar precheck read-only da migration 038; preparar backup/rollback; obter autorização literal antes de qualquer write.
3. **Backend:** configurar CORS exato e validar health/contratos após deploy.
4. **Privacidade e sync:** provar export/delete e tombstone/reconciliação contra o backend migrado.
5. **Web autenticada:** percorrer as áreas críticas em mobile e desktop; o Life Counter isolado já passou.
6. **Android físico:** instalar o APK assinado exato, conferir versão/certificado e executar login, navegação, Life Counter/retomada e push; emulador não substitui esta prova.
7. **Observabilidade:** evento Sentry do SHA final e FCM foreground/background tap.
8. **DR off-site:** enviar backup criptografado para destino externo e repetir a verificação/restore a partir dessa cadeia.

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

1. Preservar a evidência verde do `full`, E2E, resolution preflight e Patrol; fechar formatação, `git diff --check` e secret scan.
2. Revisar o diff completo, definir versão e congelar a SHA em `origin/master`.
3. Rodar precheck read-only da migration 038 e capturar contagens/compatibilidade/`pgcrypto`.
4. Confirmar backup e rollback; somente então solicitar a autorização literal de PostgreSQL.
5. Aplicar migration 038 e registrar postcheck. A migration é aditiva e deve permanecer compatível com o backend anterior.
6. Construir e promover a API da SHA congelada, com CORS exato e health checks.
7. Construir o pacote Web/APK/AAB pelo orquestrador de mesma SHA.
8. Executar smoke autenticado Web e Android físico; fechar Sentry/FCM.
9. Fechar backup off-site criptografado e repetir o restore a partir dessa cadeia; o restore local isolado já passou.
10. Publicar Web e promover Android de forma controlada; monitorar erros, auth, privacidade, sync e filas.

## 11. Rollback

### Backend/API

- Preservar a imagem anterior identificada por SHA.
- Se health, auth, export/delete ou sync falhar, reverter o serviço para a imagem anterior.
- A migration 038 é aditiva; rollback do backend pode deixar o schema novo sem uso.
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
- Se Sentry/FCM ou a cadeia off-site de backup/restore não produzir evidência válida, permanecer em NO-GO.
- Nunca registrar DSN, tokens, URLs de banco, senhas, keystore ou conteúdo sensível nos artefatos versionados.

## 12. Checklist final de go/no-go

### Código e identidade — owner de release

- [x] `quality_gate.sh full` verde: backend 1494/1494, Flutter analyze 0, Flutter 909 + 1 skip, Web ESLint/build/smoke e npm 0 vulnerabilidades.
- [x] E2E verde: 14 etapas executadas, 5 opt-in em SKIP.
- [x] Resolution preflight verde: 19/19, sem writes.
- [x] Patrol smoke verde: 9/9.
- [ ] `git diff --check`, formatação e secret scan verdes.
- [ ] Revisão do diff concluída sem arquivos alheios ou segredos.
- [ ] Checkout limpo; `HEAD == origin/master`.
- [x] Builds locais Web/APK/AAB/iOS `1.0.0+2` concluídos.
- [ ] Web/APK/AAB/API registram a mesma SHA final congelada.
- [ ] Checksums, SBOM e provenance validados.

### Banco e backend — owner de backend/DB

- [ ] Precheck read-only da migration 038 registrado.
- [ ] Backup e rollback confirmados.
- [ ] Autorização literal obtida antes de writes.
- [ ] Migration 038 aplicada e postcheck verde.
- [ ] API nova saudável e guards de conta excluída provados.
- [ ] CORS de produção contém apenas origens HTTPS exatas autorizadas.

### Produto e privacidade — owner de QA

- [ ] Cadastro/login/deep links em Web mobile/desktop.
- [ ] Home, decks, coleção, comunidade, mensagens, perfil e Life Counter.
- [x] Life Counter web isolado em desktop e 390 × 844, com persistência/reload e console limpo.
- [x] Life Counter nativo isolado no Android 36, incluindo quatro jogadores, 40→41, menu, histórico/evento persistido e correção de overlap.
- [ ] Exportação autenticada gera dados esperados.
- [ ] Exclusão exige confirmação/senha e só encerra sessão após sucesso.
- [ ] Pós-jogo sincroniza e uma exclusão tombstonada não ressuscita em dois clientes.
- [ ] Trocas exibem aviso P2P na criação e no detalhe.
- [ ] Planos/upgrade/checkout não oferecem cobrança durante a beta.

### Android e observabilidade — owner de mobile/ops

- [ ] APK assinado exato instalado em aparelho físico.
- [x] Package, versionCode/versionName, certificado e permissões dos artefatos locais conferidos.
- [x] Instalação/cold launch em emulador Android 36 sem fatal/`MissingPlugin`.
- [ ] Life Counter usado, fechado, reaberto e retomado.
- [ ] Evento Sentry correlacionado à mesma SHA/versão.
- [ ] FCM foreground e background tap provados.
- [ ] Scanner continua desabilitado.

### Continuidade — owner de operações

- [ ] Backup off-site criptografado verificado.
- [x] Restore local isolado concluído em `postgres:17`/`--network none`, constraints válidas e sem writes remotos.
- [ ] Restore repetido a partir da cadeia off-site criptografada.
- [ ] Runbook, contatos, janela e critérios de rollback confirmados.
- [ ] Smoke pós-deploy e janela de monitoramento definidos.

### Decisão

- [ ] Todos os itens P0 estão fechados: **GO Web + Android**.
- [ ] Qualquer P0 aberto: **NO-GO**, registrar responsável e próxima evidência.

## 13. Documentos relacionados

- `docs/qa/MANALOOM_PRODUCT_EXPERIENCE_AUDIT_2026-07-16.md` — experiência, coerência de produto e inventário tela a tela.
- `docs/qa/MANALOOM_FREE_BETA_RELEASE_OPS_GATE_2026-07-16.md` — comandos e contratos operacionais detalhados.
- `docs/MANALOOM_E2E_RELEASE_CONTRACT.md` — perfis de validação e fronteira de autorização.
- `docs/CONTEXTO_PRODUTO_ATUAL.md` — prioridade operacional vigente.
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md` — contratos app/backend.

---

**Regra de manutenção:** atualizar este documento somente com evidência fresca do mesmo SHA candidato. Um resultado parcial deve permanecer parcial; um artefato local não deve ser descrito como publicado.
