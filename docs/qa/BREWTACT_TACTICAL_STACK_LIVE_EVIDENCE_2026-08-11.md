# BrewTact Tactical Stack — evidência visual integrada (2026-08-11)

## Escopo

Esta rodada valida a transição pública de ManaLoom para **BrewTact**, usando a
direção visual **Tactical Stack**, sem renomear identificadores internos de
compatibilidade (`manaloom`, `MANALOOM_*`, package/bundle IDs, storage keys,
bridges, headers e protocolos).

Digest de UI revisado nesta rodada:

```text
643fa0af0cbf0c99d3fcdef7355b17f1b89d04ece14934a02946214c5957d6af
```

## Resultado por nível

| Nível | Resultado | Evidência |
|---|---|---|
| `PASS_AUTOMATED` | PASS | `quality_gate.sh quick`: 752 testes backend aprovados e 3 snapshots históricos explicitamente ignorados; `flutter analyze`; build Flutter Web release; build APK debug; contratos focados; geração determinística dos assets; compilação de recursos Android; `actool`/`ibtool` iOS; lint/build/audit e smoke do Web público; Patrol CLI + Playwright no Chrome headless real com 9/9 fluxos críticos aprovados. |
| `PASS_RUNTIME` global | PASS | 26 manifests no digest atual, com 456 capturas reais: 402 Web executadas em Chrome/WebDriver headless e 54 no Samsung SM-A135M físico. Todos os manifests registram `PASS_RUNTIME`; os runtimes Web registram zero entrada proibida de console. |
| `PASS_VISUAL_REVIEWED` global | PASS | As 456 capturas foram abertas e revisadas em 42 pranchas após a recaptura final. Não houve achado visual bloqueante. |
| `quality_gate.sh ui-proof` | PASS | O aggregate `latest.json` foi promovido no digest atual e confirmou `PASS_AUTOMATED`, `PASS_RUNTIME` e `PASS_VISUAL_REVIEWED` para a matriz Web + Android físico. |

Golden histórico não recebeu crédito de prova viva. O runtime Android foi
capturado no aparelho físico, sem substituição por simulador ou golden.

## Matriz final Web + Android físico

| Grupo | Manifests | Capturas | Resultado |
|---|---:|---:|---|
| P0 mobile, desktop e wide | 3 | 160 | `PASS_RUNTIME` |
| Battle Live | 1 | 5 | `PASS_RUNTIME` |
| Pack 02 — coleção/importação | 3 | 21 | `PASS_RUNTIME` |
| Pack 03 — oficina do deck | 3 | 27 | `PASS_RUNTIME` |
| Pack 04 — Battle Learning | 3 | 30 | `PASS_RUNTIME` |
| Pack 05 — social/trocas | 3 | 48 | `PASS_RUNTIME` |
| Pack 06 — onboarding por intenção | 3 | 15 | `PASS_RUNTIME` |
| Pack 07 — sistema visual | 3 | 30 | `PASS_RUNTIME` |
| Pack 08 — overlays críticos | 3 | 66 | `PASS_RUNTIME` |
| P0 Android físico — Samsung SM-A135M | 1 | 54 | `PASS_RUNTIME` |
| **Total** | **26** | **456** | **PASS** |

Todos os 26 manifests usam o digest acima. A soma de
`runtime_console.forbidden_entries` dos runtimes Web é zero. O OCR PT/EN das 456 imagens não
encontrou `ManaLoom` nem `Mana Loom` em conteúdo visível.

O modo headless é usado somente para execução e captura. A aprovação visual não
é automática: as 456 imagens resultantes foram abertas e inspecionadas em 42
pranchas antes da promoção para `PASS_VISUAL_REVIEWED`.

## Builds reais

Flutter Web:

```bash
flutter build web --release \
  --base-href /app/ \
  --no-web-resources-cdn \
  --dart-define=API_BASE_URL=http://127.0.0.1:8088/api \
  --dart-define=ENABLE_INTERACTIVE_BATTLE=true
```

Resultado: `app/build/web` compilado com sucesso e reaberto em
`http://127.0.0.1:8088/app/#/login`. O título foi
`BrewTact — MTG Deck Builder`; a tela carregou a identidade Tactical Stack e o
console permaneceu sem warnings ou erros.

Android debug:

```text
app/build/app/outputs/flutter-apk/app-debug.apk
bytes: 220001442
sha256: 30b1aa4d55f0d3a936127f4b62729739dd0a76c01f9018d54c5332da7fef7618
```

O Web público foi recompilado e aberto em `http://127.0.0.1:3000/`: título
`BrewTact`, conteúdo público sem a marca antiga e console limpo. O smoke
automatizado também passou com auditoria de produção em zero vulnerabilidades.

E2E Web headless real:

```bash
MANALOOM_RUN_PATROL_DEVICE_TESTS=1 \
MANALOOM_PATROL_DEVICE=chrome \
MANALOOM_PATROL_WEB_HEADLESS=true \
./scripts/quality_gate.sh patrol-smoke
```

Resultado: Patrol CLI compilou o Flutter Web, iniciou o servidor loopback e
executou 9/9 fluxos pelo Playwright no Chrome headless, sem falhas nem skips,
em 1m10s. O relatório HTML foi gerado em `app/playwright-report`.

Android físico:

```text
Samsung SM-A135M • Android 14 • serial R58T300SREH • 1080x2408
54/54 checkpoints PASS_RUNTIME
Life Counter validado também em sua orientação horizontal nativa
```

## Evidência revisada

- Capturas P0: [`app/test/ui/goldens/runtime`](../../app/test/ui/goldens/runtime)
- Capturas focais: [`docs/qa/ui-live/current`](ui-live/current)
- Pranchas P0 Web e Android físico: [`contact_sheets`](evidence/brewtact_brand_2026-08-11/contact_sheets)
- Pranchas focais: [`contact_sheets_focused`](evidence/brewtact_brand_2026-08-11/contact_sheets_focused)
- Login desktop: [`web_login_desktop_1440x900.png`](evidence/brewtact_brand_2026-08-11/web_login_desktop_1440x900.png)
- Login mobile: [`web_login_mobile_390x844.png`](evidence/brewtact_brand_2026-08-11/web_login_mobile_390x844.png)
- Cadastro mobile completo: [`web_register_mobile_bottom_390x844.png`](evidence/brewtact_brand_2026-08-11/web_register_mobile_bottom_390x844.png)
- Termos mobile: [`web_terms_mobile_390x844.png`](evidence/brewtact_brand_2026-08-11/web_terms_mobile_390x844.png)
- Landing pública desktop: [`public_home_desktop_1440x900.png`](evidence/brewtact_brand_2026-08-11/public_home_desktop_1440x900.png)
- Landing pública mobile: [`public_home_mobile_390x844.png`](evidence/brewtact_brand_2026-08-11/public_home_mobile_390x844.png)

## Revisão visual

- O símbolo Tactical Stack permanece identificável em fundo Abyss e em
  redução de 16/32 px; favicon, adaptive icon e maskable usam ajustes ópticos
  próprios.
- Brass e Frost Blue permanecem dentro da linguagem cromática do produto, sem
  criar uma terceira paleta desconectada.
- Login, cadastro e consentimento preservam hierarquia, contraste, largura e
  rolagem mobile; Termos e Privacidade permanecem dentro do fluxo.
- Home, decks, coleção, importação, carta, Battle, pós-jogo, perfis e trocas
  mantêm contexto de jogo, próxima ação e estados de recuperação legíveis.
- Os modais críticos permanecem contidos, com fundo corretamente bloqueado e
  ações destrutivas visualmente distintas.
- Não houve overflow, corte de CTA, sobreposição ou perda de navegação
  bloqueante nos três breakpoints Web.
- As 54 capturas do SM-A135M confirmam splash, autenticação, home, decks,
  cadastro, legal e Life Counter coerentes com a nova identidade; o Life
  Counter preserva sua experiência horizontal nativa.
- A composição wide mantém bastante espaço negativo em estados vazios e
  jornadas de coluna única. É polish futuro, não falha funcional do rebrand.

## Assets e plataformas

- Vetores e exports: 105 arquivos inventariados com SHA-256.
- Reexecução do gerador: byte a byte determinística.
- Android: adaptive, legacy, monochrome, notification icon e splash; recursos
  e APK compilados com sucesso.
- iOS: 19 AppIcons, LaunchImage e LaunchScreen validados por `actool`/`ibtool`.
- Web/PWA: ícones normal e maskable distintos, favicon PNG/ICO e metadados
  BrewTact.
- Fundos nativos e Web usam Abyss `#0B0D12`.

## Pendências de release

Não há recaptura visual pendente para o rebrand. TalkBack humano no aparelho e
teclado Web físico permanecem verificações manuais separadas de release,
conforme o contrato; não são substituídas pelas provas visuais automatizadas.

As fixtures usadas na captura foram limitadas a PostgreSQL loopback e gateways
de teste. Banco, API e Web efêmeros foram encerrados; nenhuma escrita atingiu o
PostgreSQL live, Hermes ou SQLite.
