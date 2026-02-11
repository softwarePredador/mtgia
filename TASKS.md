# 📋 ManaLoom — Tasks de Finalização

> Gerado em: 11/02/2026  
> Base: Audit completo de 50+ endpoints (todos ✅ 200), 10 providers, 22+ telas, 21 rotas, 25 testes E2E

---

## 🔴 Prioridade Alta (UX impactante)

### TASK-01: Badge de mensagens não-lidas no AppBar
**Esforço:** ~1.5h | **Arquivos:** 2 Flutter

**Problema:** O ícone de chat no AppBar (`main_scaffold.dart` L38-44) é um `IconButton` simples sem badge. O usuário não sabe que tem DMs novas a menos que clique manualmente. Compare com o ícone de notificações logo abaixo que TEM badge com `Selector<NotificationProvider, int>`.

**O que fazer:**
1. **`MessageProvider`** — Adicionar:
   - `int _unreadCount = 0` + getter
   - `Future<void> fetchUnreadCount()` → usa `totalUnread` (já existe o getter que soma `c.unreadCount` de cada conversation, mas precisa chamar `fetchConversations` primeiro — criar versão leve que faz `GET /conversations` com `limit=50` e soma os unreads)
   - `Timer? _pollingTimer` + `startPolling()` / `stopPolling()` (30s, igual NotificationProvider)
   - Iniciar polling no `set token()` (quando faz login)
   - Parar no `clearState()`
2. **`main_scaffold.dart`** — Trocar o `IconButton` do chat por:
   ```dart
   Selector<MessageProvider, int>(
     selector: (_, p) => p.unreadCount,
     builder: (_, count, __) => Badge(
       isLabelVisible: count > 0,
       label: Text(count > 99 ? '99+' : '$count'),
       child: IconButton(
         icon: const Icon(Icons.chat_bubble_outline, ...),
         onPressed: () => context.push('/messages'),
       ),
     ),
   )
   ```

**Critério de aceite:** Badge aparece quando há DMs não lidas, desaparece ao ler todas.

---

### TASK-02: Fallback no endpoint `/decks/:id/recommendations`
**Esforço:** ~30min | **Arquivos:** 1 Server

**Problema:** O endpoint retorna **500** quando `OPENAI_API_KEY` não está configurada (L23-27). Todos os outros endpoints de IA (`/ai/archetypes`, `/ai/generate`, etc.) têm fallback mock — este é o único que não tem.

**O que fazer:**
- Em `server/routes/decks/[id]/recommendations/index.dart`, adicionar bloco fallback antes do `return Response(500)`:
  ```dart
  if (apiKey == null) {
    return Response.json(body: {
      'recommendations': [
        {'card_name': 'Sol Ring', 'reason': '(mock) Staple em qualquer deck Commander'},
        {'card_name': 'Command Tower', 'reason': '(mock) Terreno essencial para Commander'},
        // ... 5-8 sugestões genéricas
      ],
      'mock': true,
      'message': 'OpenAI não configurada — usando sugestões mock'
    });
  }
  ```

**Critério de aceite:** Endpoint retorna 200 com sugestões mock em dev. UI não quebra.

---

## 🟡 Prioridade Média (melhorias de fluxo)

### TASK-03: Paginação scroll infinito no Trade Inbox
**Esforço:** ~2h | **Arquivos:** 2 Flutter

**Problema:** `_TradeListViewState._onScroll()` (trade_inbox_screen.dart L204-210) detecta "perto do fim" mas o **body do if é vazio** — nunca carrega a próxima página. O comment diz "TODO: improve with per-tab page tracking".

**O que fazer:**
1. **`TradeProvider`** — Adicionar:
   - `Map<String, int> _currentPage = {'received': 1, 'sent': 1, 'finished': 1}`
   - `fetchNextPage(String tab, {String? status, String? role})` → incrementa page, faz `GET /trades?page=N`, **appends** ao `_trades` em vez de substituir
   - `resetPages()` para pull-to-refresh
2. **`_TradeListViewState._onScroll()`** — No body do if, chamar `provider.fetchNextPage(tabAtual)`.

**Critério de aceite:** Scroll infinito carrega mais trades conforme o usuário rola. Pull-to-refresh reseta pra page 1.

---

### TASK-04: Auto-refresh no Message Inbox
**Esforço:** ~30min | **Arquivos:** 1 Flutter

**Problema:** `MessageInboxScreen` só carrega conversations no `initState`. Se o usuário fica na tela, novas mensagens não aparecem até fazer pull-to-refresh manual.

**O que fazer:**
- Adicionar `Timer.periodic(Duration(seconds: 15))` no `initState` que chama `fetchConversations()`.
- Cancelar no `dispose()`.
- Alternativa: usar `WidgetsBindingObserver` para re-fetch ao voltar do background.

**Critério de aceite:** Novas mensagens aparecem sozinhas dentro de 15s.

---

## 🟢 Prioridade Baixa (nice-to-have)

### TASK-05: Push Notifications (Firebase Cloud Messaging)
**Esforço:** ~1 dia | **Arquivos:** Server + Flutter

**Estado atual:** Polling HTTP a cada 30s funciona bem, mas consome bateria e tem delay.

**O que fazer:**
1. Firebase project + `google-services.json`
2. `firebase_messaging` package no Flutter
3. Endpoint `POST /users/me/fcm-token` no server
4. Server dispara push via Firebase Admin SDK ao criar notificação

---

### TASK-06: Melhorar Scanner OCR (accuracy)
**Esforço:** ~2-3 dias | **Arquivos:** Flutter scanner

**Estado atual:** Funciona com Google ML Kit mas accuracy pode variar com cartas em outras línguas, foils, cartas danificadas.

**O que fazer:**
- Adicionar crop/zoom manual antes de processar
- Sugestões fuzzy ("Você quis dizer...?") quando confidence é baixa
- Cache local de nomes de cartas para matching rápido

---

### TASK-07: Pipeline de ML Training
**Esforço:** ~1 semana | **Arquivos:** Novo módulo Python/Dart

**Estado atual:** `battle_simulations` e `game_log` coletam dados, mas não existe script de treinamento.

**O que fazer:**
1. Script Python que extrai features dos `game_log` JSONB
2. Modelo simples (XGBoost/LightGBM) para prever win_rate
3. Endpoint `/ai/predict-winrate` que usa o modelo treinado

---

### TASK-08: Simulação turno-a-turno real
**Esforço:** ~2 semanas | **Arquivos:** Server

**Estado atual:** Monte Carlo Goldfish (1000 sims estatísticas) + Matchup por archetype counter. Funciona bem como heurística.

**O que fazer:**
- Motor de regras simplificado (fases do turno, pilha, combate)
- Permite IA jogar contra IA com árvore de decisão
- Alimenta `battle_simulations` com game_log real

---

## ✅ Features Completas (referência)

| # | Feature | Server | Flutter | Testes |
|---|---------|:------:|:-------:|:------:|
| 1 | Auth (register/login/me/JWT) | ✅ | ✅ | ✅ |
| 2 | Decks CRUD + validação formato | ✅ | ✅ | ✅ |
| 3 | Cards (busca, printings, sync Scryfall) | ✅ | ✅ | ✅ |
| 4 | Seletor de Edição (multi-edition) | ✅ | ✅ | ✅ |
| 5 | Notificações (polling 30s, badge, navegação) | ✅ | ✅ | ✅ |
| 6 | Binder/Fichário (CRUD, Have/Want, conditions) | ✅ | ✅ | ✅ |
| 7 | Trades (criar/aceitar/recusar/shipped/chat) | ✅ | ✅ | ✅ |
| 8 | Mensagens DM (inbox, chat, bolhas) | ✅ | ✅ | ✅ |
| 9 | Comunidade (decks públicos, follow, feed) | ✅ | ✅ | ✅ |
| 10 | Marketplace (busca global trade/sale) | ✅ | ✅ | ✅ |
| 11 | IA: Gerar Deck (prompt→deck) | ✅ | ✅ | ✅ |
| 12 | IA: Otimizar Deck | ✅ | ✅ | ✅ |
| 13 | IA: Explicar Carta | ✅ | ✅ | ✅ |
| 14 | IA: Archetypes | ✅ | ✅ | ✅ |
| 15 | IA: Sinergia (score, strengths, weaknesses) | ✅ | ✅ | ✅ |
| 16 | Importação texto→deck | ✅ | ✅ | ✅ |
| 17 | Scanner OCR (câmera ao vivo) | — | ✅ | — |
| 18 | Simulador Goldfish (Monte Carlo 1000) | ✅ | ✅ | ✅ |
| 19 | Simulador Matchup (archetype counters) | ✅ | ✅ | ✅ |
| 20 | Market Movers (preços, tendências) | ✅ | ✅ | ✅ |
| 21 | Perfil (avatar, display name) | ✅ | ✅ | ✅ |
| 22 | Sets / Rules | ✅ | ✅ | ✅ |
| 23 | Sync Preços (MTGJSON cron) | ✅ | — | — |
| 24 | Sync Cartas (incremental/full) | ✅ | — | — |

**Infraestrutura:**
- 🖥️ Produção: Docker Swarm on EasyPanel (`evolution-cartinhas.8ktevp.easypanel.host`)
- 📊 ~50 endpoints ativos | 72 route files
- 🧪 25 testes E2E (14 general + 11 trade)
- 📱 10 Providers | 21 Rotas GoRouter | 5 tabs bottom nav

---

## 📅 Ordem de Execução Sugerida

```
TASK-01 (badge mensagens)     → 1.5h   ← FAZER PRIMEIRO
TASK-02 (fallback recommend.) → 30min  ← FAZER JUNTO
TASK-04 (inbox auto-refresh)  → 30min  ← COMPLEMENTO DO 01
TASK-03 (trade pagination)    → 2h     ← DEPOIS
─────────────────────────────────────
Total polish: ~4.5h para ficar 100%
─────────────────────────────────────
TASK-05 a 08: Roadmap futuro (quando priorizar)
```
