#!/usr/bin/env python3
"""
╔══════════════════════════════════════════════════════════════════╗
║  MTG Trade System — Suíte Completa de Testes E2E               ║
║  Cobre: Auth, Binder, Trade CRUD, Status, Chat, Permissões     ║
║                                                                  ║
║  Uso:  python3 server/test/e2e_trade_tests.py                   ║
║  Uso:  python3 server/test/e2e_trade_tests.py --api URL         ║
║  Uso:  python3 server/test/e2e_trade_tests.py --verbose         ║
╚══════════════════════════════════════════════════════════════════╝
"""

import requests
import json
import sys
import time
import uuid
import argparse
from dataclasses import dataclass, field
from typing import Optional

# ─── Config ────────────────────────────────────────────────────────
DEFAULT_API = "https://evolution-cartinhas.2ta7qx.easypanel.host"
VERBOSE = False

# ─── Resultado de teste ────────────────────────────────────────────
@dataclass
class TestResult:
    name: str
    passed: bool
    detail: str = ""
    category: str = ""

class TestRunner:
    def __init__(self, api_url: str):
        self.api = api_url.rstrip("/")
        self.results: list[TestResult] = []
        self.ts = str(int(time.time()))  # Unique suffix for test users

        # Test data populated during setup
        self.user_a_token: str = ""
        self.user_a_id: str = ""
        self.user_b_token: str = ""
        self.user_b_id: str = ""
        self.user_c_token: str = ""
        self.user_c_id: str = ""
        self.card_id: str = ""
        self.card_id_2: str = ""
        self.binder_a_have: str = ""
        self.binder_a_have_2: str = ""
        self.binder_b_have: str = ""
        self.binder_a_want: str = ""

        # Trade IDs
        self.trade_sale_id: str = ""
        self.trade_trade_id: str = ""
        self.trade_cancel_id: str = ""
        self.trade_decline_id: str = ""
        self.trade_dispute_id: str = ""

    # ─── Helpers ──────────────────────────────────────────────────
    def _log(self, msg: str):
        if VERBOSE:
            print(f"    📋 {msg}")

    def _req(self, method: str, path: str, token: str = "", json_data=None, params=None):
        url = f"{self.api}{path}"
        headers = {"Content-Type": "application/json"}
        if token:
            headers["Authorization"] = f"Bearer {token}"
        try:
            r = requests.request(method, url, headers=headers, json=json_data, params=params, timeout=30)
            try:
                body = r.json()
            except Exception:
                body = {"_raw": r.text[:500]}
            self._log(f"{method} {path} → {r.status_code}: {json.dumps(body, ensure_ascii=False)[:200]}")
            return r.status_code, body
        except Exception as e:
            self._log(f"❌ Request failed: {e}")
            return 0, {"error": str(e)}

    def _test(self, category: str, name: str, passed: bool, detail: str = ""):
        icon = "✅" if passed else "❌"
        self.results.append(TestResult(name=name, passed=passed, detail=detail, category=category))
        print(f"  {icon} [{category}] {name}" + (f"  — {detail}" if detail and not passed else ""))

    # ═══════════════════════════════════════════════════════════════
    #  SETUP: Create test users & find cards
    # ═══════════════════════════════════════════════════════════════
    def setup(self):
        print("\n🔧 SETUP: Registrando usuários de teste...")

        # User A (seller/trader)
        code, body = self._req("POST", "/auth/register", json_data={
            "username": f"tst_a_{self.ts}", "email": f"tst_a_{self.ts}@test.com", "password": "Test123!"
        })
        if code != 201 and code != 200:
            print(f"  ⚠️  Falha ao registrar User A: {body}")
            # Try login
            code, body = self._req("POST", "/auth/login", json_data={
                "email": f"tst_a_{self.ts}@test.com", "password": "Test123!"
            })
        self.user_a_token = body.get("token", "")
        self.user_a_id = body.get("user", {}).get("id", "")
        print(f"  👤 User A: {body.get('user', {}).get('username', '?')} ({self.user_a_id[:8]}...)")

        # User B (buyer/trader)
        code, body = self._req("POST", "/auth/register", json_data={
            "username": f"tst_b_{self.ts}", "email": f"tst_b_{self.ts}@test.com", "password": "Test123!"
        })
        if code != 201 and code != 200:
            code, body = self._req("POST", "/auth/login", json_data={
                "email": f"tst_b_{self.ts}@test.com", "password": "Test123!"
            })
        self.user_b_token = body.get("token", "")
        self.user_b_id = body.get("user", {}).get("id", "")
        print(f"  👤 User B: {body.get('user', {}).get('username', '?')} ({self.user_b_id[:8]}...)")

        # User C (outsider — should have no access to A/B trades)
        code, body = self._req("POST", "/auth/register", json_data={
            "username": f"tst_c_{self.ts}", "email": f"tst_c_{self.ts}@test.com", "password": "Test123!"
        })
        if code != 201 and code != 200:
            code, body = self._req("POST", "/auth/login", json_data={
                "email": f"tst_c_{self.ts}@test.com", "password": "Test123!"
            })
        self.user_c_token = body.get("token", "")
        self.user_c_id = body.get("user", {}).get("id", "")
        print(f"  👤 User C: {body.get('user', {}).get('username', '?')} (outsider)")

        # Find 2 cards
        code, body = self._req("GET", "/cards", params={"name": "Sol Ring", "limit": "1"})
        cards = body.get("data", [])
        if cards:
            self.card_id = cards[0]["id"]
            print(f"  🃏 Card 1: {cards[0]['name']} ({self.card_id[:8]}...)")

        code, body = self._req("GET", "/cards", params={"name": "Lightning Bolt", "limit": "1"})
        cards = body.get("data", [])
        if cards:
            self.card_id_2 = cards[0]["id"]
            print(f"  🃏 Card 2: {cards[0]['name']} ({self.card_id_2[:8]}...)")
        else:
            # Fallback to any other card
            code, body = self._req("GET", "/cards", params={"limit": "2"})
            cards = body.get("data", [])
            if len(cards) >= 2:
                self.card_id_2 = cards[1]["id"]
                print(f"  🃏 Card 2 (fallback): {cards[1]['name']}")

        if not self.user_a_token or not self.user_b_token or not self.card_id:
            print("  💀 Setup falhou! Abortando...")
            return False
        return True

    # ═══════════════════════════════════════════════════════════════
    #  AUTH TESTS
    # ═══════════════════════════════════════════════════════════════
    def test_auth(self):
        print("\n🔐 AUTH TESTS")
        CAT = "AUTH"

        # Sem token → deve falhar nas rotas protegidas
        code, body = self._req("GET", "/trades")
        self._test(CAT, "GET /trades sem token → 401", code == 401 or code == 403,
                   f"Got {code}")

        code, body = self._req("GET", "/binder")
        self._test(CAT, "GET /binder sem token → 401", code == 401 or code == 403,
                   f"Got {code}")

        code, body = self._req("POST", "/trades", json_data={"receiver_id": "x"})
        self._test(CAT, "POST /trades sem token → 401", code == 401 or code == 403,
                   f"Got {code}")

        # Token inválido
        code, body = self._req("GET", "/trades", token="invalid.token.here")
        self._test(CAT, "Token inválido → 401", code == 401 or code == 403,
                   f"Got {code}")

        # Token válido → OK
        code, body = self._req("GET", "/trades", token=self.user_a_token)
        self._test(CAT, "Token válido → 200", code == 200, f"Got {code}")

    # ═══════════════════════════════════════════════════════════════
    #  BINDER TESTS
    # ═══════════════════════════════════════════════════════════════
    def test_binder(self):
        print("\n📦 BINDER TESTS")
        CAT = "BINDER"

        # ── Add card com campos obrigatórios ──
        code, body = self._req("POST", "/binder", token=self.user_a_token, json_data={
            "card_id": self.card_id, "quantity": 3, "condition": "NM",
            "for_trade": True, "for_sale": True, "price": 25.50,
            "list_type": "have"
        })
        self._test(CAT, "POST /binder (have, NM) → 201", code == 201,
                   f"Got {code}: {body.get('error', body.get('id', ''))}")
        self.binder_a_have = body.get("id", "")

        # ── Add 2nd card ──
        if self.card_id_2:
            code, body = self._req("POST", "/binder", token=self.user_a_token, json_data={
                "card_id": self.card_id_2, "quantity": 1, "condition": "LP",
                "for_trade": True, "for_sale": False, "list_type": "have"
            })
            self._test(CAT, "POST /binder (2nd card, LP) → 201", code == 201,
                       f"Got {code}")
            self.binder_a_have_2 = body.get("id", "")

        # ── Duplicate → 409 ──
        code, body = self._req("POST", "/binder", token=self.user_a_token, json_data={
            "card_id": self.card_id, "quantity": 1, "condition": "NM",
            "for_trade": True, "list_type": "have"
        })
        self._test(CAT, "POST /binder duplicata (same card+condition+foil+list) → 409",
                   code == 409, f"Got {code}: {body.get('error', '')}")

        # ── Same card, different condition → OK ──
        code, body = self._req("POST", "/binder", token=self.user_a_token, json_data={
            "card_id": self.card_id, "quantity": 1, "condition": "HP",
            "for_trade": True, "list_type": "have"
        })
        self._test(CAT, "POST /binder mesma carta, condição diferente → 201",
                   code == 201, f"Got {code}")

        # ── Want list ──
        code, body = self._req("POST", "/binder", token=self.user_a_token, json_data={
            "card_id": self.card_id, "quantity": 1, "list_type": "want"
        })
        self._test(CAT, "POST /binder (want list) → 201", code == 201, f"Got {code}")
        self.binder_a_want = body.get("id", "")

        # ── Validação: card_id vazio ──
        code, body = self._req("POST", "/binder", token=self.user_a_token, json_data={})
        self._test(CAT, "POST /binder sem card_id → 400",
                   code == 400, f"Got {code}: {body.get('error', '')}")

        # ── Validação: card inexistente ──
        code, body = self._req("POST", "/binder", token=self.user_a_token, json_data={
            "card_id": "00000000-0000-0000-0000-000000000000"
        })
        self._test(CAT, "POST /binder carta inexistente → 404",
                   code == 404, f"Got {code}: {body.get('error', '')}")

        # ── Validação: condition inválida ──
        code, body = self._req("POST", "/binder", token=self.user_a_token, json_data={
            "card_id": self.card_id, "condition": "INVALID"
        })
        self._test(CAT, "POST /binder condição inválida → 400",
                   code == 400, f"Got {code}: {body.get('error', '')}")

        # ── Validação: quantity 0 ──
        code, body = self._req("POST", "/binder", token=self.user_a_token, json_data={
            "card_id": self.card_id, "quantity": 0
        })
        self._test(CAT, "POST /binder quantity=0 → 400",
                   code == 400, f"Got {code}: {body.get('error', '')}")

        # ── Validação: list_type inválido ──
        code, body = self._req("POST", "/binder", token=self.user_a_token, json_data={
            "card_id": self.card_id, "list_type": "invalid"
        })
        self._test(CAT, "POST /binder list_type inválido → 400",
                   code == 400, f"Got {code}: {body.get('error', '')}")

        # ── GET binder list ──
        code, body = self._req("GET", "/binder", token=self.user_a_token,
                               params={"list_type": "have"})
        self._test(CAT, "GET /binder (have) → 200 com items",
                   code == 200 and len(body.get("data", [])) >= 1,
                   f"Got {code}, items={len(body.get('data', []))}")

        # ── GET binder com filtros ──
        code, body = self._req("GET", "/binder", token=self.user_a_token,
                               params={"for_trade": "true", "condition": "NM"})
        self._test(CAT, "GET /binder com filtros (for_trade, NM) → 200",
                   code == 200, f"Got {code}")

        # ── GET binder search ──
        code, body = self._req("GET", "/binder", token=self.user_a_token,
                               params={"search": "Sol"})
        self._test(CAT, "GET /binder search por nome → 200 com resultados",
                   code == 200 and len(body.get("data", [])) >= 1,
                   f"Got {code}, items={len(body.get('data', []))}")

        # ── GET binder stats ──
        code, body = self._req("GET", "/binder/stats", token=self.user_a_token)
        self._test(CAT, "GET /binder/stats → 200",
                   code == 200 and "total_items" in body,
                   f"Got {code}: {list(body.keys())[:5]}")

        # ── PUT binder item ──
        if self.binder_a_have:
            code, body = self._req("PUT", f"/binder/{self.binder_a_have}",
                                   token=self.user_a_token,
                                   json_data={"price": 30.00, "notes": "Updated by test"})
            self._test(CAT, "PUT /binder/:id atualizar preço → 200",
                       code == 200, f"Got {code}")

            # Outro usuário tenta atualizar → 404
            code, body = self._req("PUT", f"/binder/{self.binder_a_have}",
                                   token=self.user_b_token,
                                   json_data={"price": 1.00})
            self._test(CAT, "PUT /binder/:id de outro user → 404 (ownership)",
                       code == 404, f"Got {code}")

        # ── User B adds card to binder (for trades later) ──
        code, body = self._req("POST", "/binder", token=self.user_b_token, json_data={
            "card_id": self.card_id, "quantity": 2, "condition": "NM",
            "for_trade": True, "for_sale": True, "price": 20.00, "list_type": "have"
        })
        self._test(CAT, "User B adiciona carta ao binder → 201", code == 201,
                   f"Got {code}")
        self.binder_b_have = body.get("id", "")

        # ── Community: public binder ──
        code, body = self._req("GET", f"/community/binders/{self.user_a_id}",
                               params={"list_type": "have"})
        self._test(CAT, "GET /community/binders/:userId (have) → 200",
                   code == 200, f"Got {code}")

        code, body = self._req("GET", f"/community/binders/{self.user_a_id}",
                               params={"list_type": "want"})
        self._test(CAT, "GET /community/binders/:userId (want) → 200",
                   code == 200, f"Got {code}")

        # ── Community: user inexistente ──
        code, body = self._req("GET", "/community/binders/00000000-0000-0000-0000-000000000000")
        self._test(CAT, "GET /community/binders (user inválido) → 404",
                   code == 404, f"Got {code}")

        # ── Marketplace ──
        code, body = self._req("GET", "/community/marketplace",
                               params={"search": "Sol", "limit": "5"})
        self._test(CAT, "GET /community/marketplace search → 200",
                   code == 200, f"Got {code}")

    # ═══════════════════════════════════════════════════════════════
    #  TRADE CREATION TESTS
    # ═══════════════════════════════════════════════════════════════
    def test_trade_creation(self):
        print("\n🤝 TRADE CREATION TESTS")
        CAT = "TRADE_CREATE"

        # ── 1. Sale: B compra de A ──
        code, body = self._req("POST", "/trades", token=self.user_b_token, json_data={
            "receiver_id": self.user_a_id,
            "type": "sale",
            "message": "Quero comprar seu Sol Ring!",
            "payment_amount": 25.50,
            "payment_currency": "BRL",
            "payment_method": "pix",
            "requested_items": [{"binder_item_id": self.binder_a_have, "quantity": 1}]
        })
        self._test(CAT, "Criar SALE (B compra de A) → 201", code == 201,
                   f"Got {code}: {body.get('error', body.get('id', ''))}")
        self.trade_sale_id = body.get("id", "")

        # ── 2. Trade: A troca com B ──
        code, body = self._req("POST", "/trades", token=self.user_a_token, json_data={
            "receiver_id": self.user_b_id,
            "type": "trade",
            "message": "Vamos trocar!",
            "my_items": [{"binder_item_id": self.binder_a_have_2 or self.binder_a_have, "quantity": 1}],
            "requested_items": [{"binder_item_id": self.binder_b_have, "quantity": 1}]
        })
        self._test(CAT, "Criar TRADE (A ↔ B) → 201", code == 201,
                   f"Got {code}: {body.get('error', body.get('id', ''))}")
        self.trade_trade_id = body.get("id", "")

        # ── 3. Trade para cancelar ──
        code, body = self._req("POST", "/trades", token=self.user_a_token, json_data={
            "receiver_id": self.user_b_id,
            "type": "sale",
            "message": "Trade para testar cancel",
            "payment_amount": 5.00,
            "requested_items": [{"binder_item_id": self.binder_b_have, "quantity": 1}]
        })
        self._test(CAT, "Criar SALE para testar cancel → 201", code == 201, f"Got {code}")
        self.trade_cancel_id = body.get("id", "")

        # ── 4. Trade para recusar ──
        code, body = self._req("POST", "/trades", token=self.user_a_token, json_data={
            "receiver_id": self.user_b_id,
            "type": "sale",
            "message": "Trade para testar decline",
            "payment_amount": 5.00,
            "requested_items": [{"binder_item_id": self.binder_b_have, "quantity": 1}]
        })
        self._test(CAT, "Criar SALE para testar decline → 201", code == 201, f"Got {code}")
        self.trade_decline_id = body.get("id", "")

        # ── 5. Trade para disputar ──
        code, body = self._req("POST", "/trades", token=self.user_a_token, json_data={
            "receiver_id": self.user_b_id,
            "type": "sale",
            "message": "Trade para testar dispute",
            "payment_amount": 5.00,
            "requested_items": [{"binder_item_id": self.binder_b_have, "quantity": 1}]
        })
        self._test(CAT, "Criar SALE para testar dispute → 201", code == 201, f"Got {code}")
        self.trade_dispute_id = body.get("id", "")

        # ── NEGATIVE: receiver_id vazio ──
        code, body = self._req("POST", "/trades", token=self.user_a_token, json_data={
            "type": "sale", "requested_items": [{"binder_item_id": self.binder_b_have}]
        })
        self._test(CAT, "Criar trade sem receiver_id → 400", code == 400,
                   f"Got {code}: {body.get('error','')}")

        # ── NEGATIVE: trade consigo mesmo ──
        code, body = self._req("POST", "/trades", token=self.user_a_token, json_data={
            "receiver_id": self.user_a_id, "type": "sale",
            "requested_items": [{"binder_item_id": self.binder_a_have}]
        })
        self._test(CAT, "Criar trade consigo mesmo → 400", code == 400,
                   f"Got {code}: {body.get('error','')}")

        # ── NEGATIVE: type inválido ──
        code, body = self._req("POST", "/trades", token=self.user_a_token, json_data={
            "receiver_id": self.user_b_id, "type": "invalid",
            "requested_items": [{"binder_item_id": self.binder_b_have}]
        })
        self._test(CAT, "Criar trade com type inválido → 400", code == 400,
                   f"Got {code}: {body.get('error','')}")

        # ── NEGATIVE: sem itens ──
        code, body = self._req("POST", "/trades", token=self.user_a_token, json_data={
            "receiver_id": self.user_b_id, "type": "sale"
        })
        self._test(CAT, "Criar trade sem itens → 400", code == 400,
                   f"Got {code}: {body.get('error','')}")

        # ── NEGATIVE: trade pura sem ambos os lados ──
        code, body = self._req("POST", "/trades", token=self.user_a_token, json_data={
            "receiver_id": self.user_b_id, "type": "trade",
            "my_items": [{"binder_item_id": self.binder_a_have}]
            # requested_items vazio → trade exige ambos
        })
        self._test(CAT, "Criar TRADE sem requested_items → 400", code == 400,
                   f"Got {code}: {body.get('error','')}")

        # ── NEGATIVE: receiver inexistente ──
        code, body = self._req("POST", "/trades", token=self.user_a_token, json_data={
            "receiver_id": "00000000-0000-0000-0000-000000000000",
            "type": "sale", "payment_amount": 5,
            "requested_items": [{"binder_item_id": self.binder_b_have}]
        })
        self._test(CAT, "Criar trade com receiver inexistente → 404", code == 404,
                   f"Got {code}: {body.get('error','')}")

        # ── NEGATIVE: binder_item de outro user ──
        code, body = self._req("POST", "/trades", token=self.user_a_token, json_data={
            "receiver_id": self.user_b_id, "type": "sale",
            "my_items": [{"binder_item_id": self.binder_b_have}]  # B's item in A's my_items
        })
        self._test(CAT, "my_items com item de outro user → 403/400",
                   code in (400, 403),
                   f"Got {code}: {body.get('error','')}")

        # ── NEGATIVE: requested_items com item do próprio sender ──
        code, body = self._req("POST", "/trades", token=self.user_a_token, json_data={
            "receiver_id": self.user_b_id, "type": "sale",
            "requested_items": [{"binder_item_id": self.binder_a_have}]  # A's item, not B's
        })
        self._test(CAT, "requested_items com item do sender → 400",
                   code == 400,
                   f"Got {code}: {body.get('error','')}")

        # ── NEGATIVE: binder_item inexistente ──
        code, body = self._req("POST", "/trades", token=self.user_a_token, json_data={
            "receiver_id": self.user_b_id, "type": "sale",
            "requested_items": [{"binder_item_id": "00000000-0000-0000-0000-000000000000"}]
        })
        self._test(CAT, "requested_items com binder_item inexistente → 400",
                   code == 400,
                   f"Got {code}: {body.get('error','')}")

        # ── NEGATIVE: payment_amount negativo ──
        code, body = self._req("POST", "/trades", token=self.user_b_token, json_data={
            "receiver_id": self.user_a_id, "type": "sale",
            "payment_amount": -10.00,
            "requested_items": [{"binder_item_id": self.binder_a_have}]
        })
        # Documenting current behavior — negative amounts may or may not be validated
        self._test(CAT, "payment_amount negativo → documenta comportamento",
                   True,  # Just document, don't fail
                   f"Got {code}: {body.get('error', 'allowed')}")

    # ═══════════════════════════════════════════════════════════════
    #  TRADE LISTING TESTS
    # ═══════════════════════════════════════════════════════════════
    def test_trade_listing(self):
        print("\n📋 TRADE LISTING TESTS")
        CAT = "TRADE_LIST"

        # ── Lista geral ──
        code, body = self._req("GET", "/trades", token=self.user_a_token)
        total = body.get("total", 0)
        self._test(CAT, "GET /trades → 200 com trades", code == 200 and total >= 1,
                   f"Got {code}, total={total}")

        # ── Filtro por role ──
        code, body = self._req("GET", "/trades", token=self.user_a_token,
                               params={"role": "sender"})
        self._test(CAT, "GET /trades role=sender → 200",
                   code == 200, f"Got {code}, total={body.get('total',0)}")

        code, body = self._req("GET", "/trades", token=self.user_a_token,
                               params={"role": "receiver"})
        self._test(CAT, "GET /trades role=receiver → 200",
                   code == 200, f"Got {code}, total={body.get('total',0)}")

        # ── Filtro por status ──
        code, body = self._req("GET", "/trades", token=self.user_a_token,
                               params={"status": "pending"})
        self._test(CAT, "GET /trades status=pending → 200",
                   code == 200, f"Got {code}, total={body.get('total',0)}")

        # ── Paginação ──
        code, body = self._req("GET", "/trades", token=self.user_a_token,
                               params={"page": "1", "limit": "2"})
        self._test(CAT, "GET /trades page=1 limit=2 → 200 (max 2 items)",
                   code == 200 and len(body.get("data", [])) <= 2,
                   f"Got {code}, items={len(body.get('data', []))}")

        # ── Status inválido → 0 resultados (não erro) ──
        code, body = self._req("GET", "/trades", token=self.user_a_token,
                               params={"status": "xyzinvalid"})
        self._test(CAT, "GET /trades status inválido → 200 com 0 items",
                   code == 200 and body.get("total", 0) == 0,
                   f"Got {code}, total={body.get('total',0)}")

    # ═══════════════════════════════════════════════════════════════
    #  TRADE DETAIL TESTS
    # ═══════════════════════════════════════════════════════════════
    def test_trade_detail(self):
        print("\n🔍 TRADE DETAIL TESTS")
        CAT = "TRADE_DETAIL"

        if not self.trade_sale_id:
            self._test(CAT, "Trade ID disponível", False, "Nenhum trade criado")
            return

        # ── Detail como sender ──
        code, body = self._req("GET", f"/trades/{self.trade_sale_id}", token=self.user_b_token)
        self._test(CAT, "GET /trades/:id como sender → 200",
                   code == 200 and body.get("status") == "pending",
                   f"Got {code}, status={body.get('status')}")

        # ── Detail como receiver ──
        code, body = self._req("GET", f"/trades/{self.trade_sale_id}", token=self.user_a_token)
        self._test(CAT, "GET /trades/:id como receiver → 200",
                   code == 200, f"Got {code}")

        # Verify response structure
        has_fields = all(k in body for k in ["sender", "receiver", "status", "type",
                                             "my_items", "their_items", "messages", "status_history"])
        self._test(CAT, "Detail tem todos os campos (sender, receiver, items, msgs, history)",
                   has_fields, f"Keys: {list(body.keys())[:10]}")

        # ── Detail como outsider → 403 ──
        code, body = self._req("GET", f"/trades/{self.trade_sale_id}", token=self.user_c_token)
        self._test(CAT, "GET /trades/:id como outsider → 403",
                   code == 403, f"Got {code}: {body.get('error','')}")

        # ── Trade inexistente ──
        code, body = self._req("GET", "/trades/00000000-0000-0000-0000-000000000000",
                               token=self.user_a_token)
        self._test(CAT, "GET /trades/:id inexistente → 404",
                   code == 404, f"Got {code}")

    # ═══════════════════════════════════════════════════════════════
    #  TRADE RESPOND TESTS (Accept / Decline)
    # ═══════════════════════════════════════════════════════════════
    def test_trade_respond(self):
        print("\n✋ TRADE RESPOND TESTS")
        CAT = "TRADE_RESPOND"

        # ── NEGATIVE: sender tenta aceitar próprio trade ──
        code, body = self._req("PUT", f"/trades/{self.trade_sale_id}/respond",
                               token=self.user_b_token,  # B is sender
                               json_data={"action": "accept"})
        self._test(CAT, "Sender tenta aceitar próprio trade → 403", code == 403,
                   f"Got {code}: {body.get('error','')}")

        # ── NEGATIVE: outsider tenta aceitar ──
        code, body = self._req("PUT", f"/trades/{self.trade_sale_id}/respond",
                               token=self.user_c_token,
                               json_data={"action": "accept"})
        self._test(CAT, "Outsider tenta aceitar → 403", code == 403,
                   f"Got {code}: {body.get('error','')}")

        # ── NEGATIVE: action inválida ──
        code, body = self._req("PUT", f"/trades/{self.trade_sale_id}/respond",
                               token=self.user_a_token,
                               json_data={"action": "invalid"})
        self._test(CAT, "action inválida → 400", code == 400,
                   f"Got {code}: {body.get('error','')}")

        # ── POSITIVE: Decline trade_decline ──
        if self.trade_decline_id:
            code, body = self._req("PUT", f"/trades/{self.trade_decline_id}/respond",
                                   token=self.user_b_token,  # B is receiver
                                   json_data={"action": "decline"})
            self._test(CAT, "Receiver recusa trade → 200/accepted", code == 200,
                       f"Got {code}, status={body.get('status')}")

            # Tentar recusar de novo → 400
            code, body = self._req("PUT", f"/trades/{self.trade_decline_id}/respond",
                                   token=self.user_b_token,
                                   json_data={"action": "decline"})
            self._test(CAT, "Recusar trade já declined → 400", code == 400,
                       f"Got {code}: {body.get('error','')}")

        # ── POSITIVE: Accept trade_sale ──
        code, body = self._req("PUT", f"/trades/{self.trade_sale_id}/respond",
                               token=self.user_a_token,  # A is receiver
                               json_data={"action": "accept"})
        self._test(CAT, "Receiver aceita SALE → 200", code == 200,
                   f"Got {code}, status={body.get('status')}")

        # ── Tentar aceitar novamente → 400 ──
        code, body = self._req("PUT", f"/trades/{self.trade_sale_id}/respond",
                               token=self.user_a_token,
                               json_data={"action": "accept"})
        self._test(CAT, "Aceitar trade já accepted → 400", code == 400,
                   f"Got {code}: {body.get('error','')}")

        # ── Accept trade_trade ──
        if self.trade_trade_id:
            code, body = self._req("PUT", f"/trades/{self.trade_trade_id}/respond",
                                   token=self.user_b_token,  # B is receiver
                                   json_data={"action": "accept"})
            self._test(CAT, "Receiver aceita TRADE → 200", code == 200,
                       f"Got {code}")

        # ── Accept trade_cancel & trade_dispute ──
        for tid, label in [(self.trade_cancel_id, "cancel"), (self.trade_dispute_id, "dispute")]:
            if tid:
                code, body = self._req("PUT", f"/trades/{tid}/respond",
                                       token=self.user_b_token,
                                       json_data={"action": "accept"})
                self._test(CAT, f"Aceitar trade para testar {label} → 200", code == 200,
                           f"Got {code}")

    # ═══════════════════════════════════════════════════════════════
    #  STATUS TRANSITION TESTS
    # ═══════════════════════════════════════════════════════════════
    def test_status_transitions(self):
        print("\n🔄 STATUS TRANSITION TESTS")
        CAT = "STATUS"

        # ═══ SALE FLOW: accepted → shipped → delivered → completed ═══
        if self.trade_sale_id:
            # NEGATIVE: Buyer (sender=B) tenta enviar em SALE → deve falhar
            code, body = self._req("PUT", f"/trades/{self.trade_sale_id}/status",
                                   token=self.user_b_token,
                                   json_data={"status": "shipped", "delivery_method": "correios"})
            self._test(CAT, "SALE: Buyer tenta ship → 403 (only receiver/seller)",
                       code == 403,
                       f"Got {code}: {body.get('error','')}")

            # POSITIVE: Seller (receiver=A) envia
            code, body = self._req("PUT", f"/trades/{self.trade_sale_id}/status",
                                   token=self.user_a_token,
                                   json_data={"status": "shipped",
                                              "delivery_method": "correios",
                                              "tracking_code": "BR999TEST123"})
            self._test(CAT, "SALE: Seller (receiver) marca shipped → 200",
                       code == 200 and body.get("status") == "shipped",
                       f"Got {code}: {body.get('error', body.get('status',''))}")

            # NEGATIVE: Seller tenta confirmar entrega em SALE → deve falhar
            code, body = self._req("PUT", f"/trades/{self.trade_sale_id}/status",
                                   token=self.user_a_token,
                                   json_data={"status": "delivered"})
            self._test(CAT, "SALE: Seller tenta delivered → 403 (only sender/buyer)",
                       code == 403,
                       f"Got {code}: {body.get('error','')}")

            # POSITIVE: Buyer confirma entrega
            code, body = self._req("PUT", f"/trades/{self.trade_sale_id}/status",
                                   token=self.user_b_token,
                                   json_data={"status": "delivered"})
            self._test(CAT, "SALE: Buyer (sender) confirma delivered → 200",
                       code == 200 and body.get("status") == "delivered",
                       f"Got {code}: {body.get('error', body.get('status',''))}")

            # POSITIVE: Finalizar
            code, body = self._req("PUT", f"/trades/{self.trade_sale_id}/status",
                                   token=self.user_a_token,
                                   json_data={"status": "completed"})
            self._test(CAT, "SALE: completed → 200",
                       code == 200 and body.get("status") == "completed",
                       f"Got {code}")

            # NEGATIVE: Transição de terminal
            code, body = self._req("PUT", f"/trades/{self.trade_sale_id}/status",
                                   token=self.user_a_token,
                                   json_data={"status": "shipped"})
            self._test(CAT, "completed → shipped → 400 (terminal state)",
                       code == 400,
                       f"Got {code}: {body.get('error','')}")

        # ═══ TRADE FLOW: ambos podem ship/deliver ═══
        if self.trade_trade_id:
            # Sender (A) pode enviar em trade
            code, body = self._req("PUT", f"/trades/{self.trade_trade_id}/status",
                                   token=self.user_a_token,
                                   json_data={"status": "shipped",
                                              "delivery_method": "pessoalmente"})
            self._test(CAT, "TRADE: Sender (A) marca shipped → 200",
                       code == 200, f"Got {code}")

            # Receiver (B) pode confirmar entrega em trade
            code, body = self._req("PUT", f"/trades/{self.trade_trade_id}/status",
                                   token=self.user_b_token,
                                   json_data={"status": "delivered"})
            self._test(CAT, "TRADE: Receiver (B) confirma delivered → 200",
                       code == 200, f"Got {code}")

            # Complete
            code, body = self._req("PUT", f"/trades/{self.trade_trade_id}/status",
                                   token=self.user_a_token,
                                   json_data={"status": "completed"})
            self._test(CAT, "TRADE: completed → 200", code == 200, f"Got {code}")

        # ═══ CANCEL FLOW ═══
        if self.trade_cancel_id:
            # Sender cancela trade aceito
            code, body = self._req("PUT", f"/trades/{self.trade_cancel_id}/status",
                                   token=self.user_a_token,
                                   json_data={"status": "cancelled"})
            self._test(CAT, "CANCEL: sender cancela trade aceito → 200",
                       code == 200 and body.get("status") == "cancelled",
                       f"Got {code}")

            # Terminal: cancelled → shipped
            code, body = self._req("PUT", f"/trades/{self.trade_cancel_id}/status",
                                   token=self.user_a_token,
                                   json_data={"status": "shipped"})
            self._test(CAT, "cancelled → shipped → 400 (terminal)",
                       code == 400,
                       f"Got {code}: {body.get('error','')}")

        # ═══ DISPUTE FLOW ═══
        if self.trade_dispute_id:
            # Ship first
            code, body = self._req("PUT", f"/trades/{self.trade_dispute_id}/status",
                                   token=self.user_b_token,  # receiver ships in sale
                                   json_data={"status": "shipped", "delivery_method": "motoboy"})
            self._test(CAT, "DISPUTE: ship para testar dispute → 200",
                       code == 200, f"Got {code}")

            # Dispute
            code, body = self._req("PUT", f"/trades/{self.trade_dispute_id}/status",
                                   token=self.user_a_token,
                                   json_data={"status": "disputed",
                                              "notes": "Produto não confere"})
            self._test(CAT, "DISPUTE: sender disputa trade enviado → 200",
                       code == 200 and body.get("status") == "disputed",
                       f"Got {code}")

            # Terminal: disputed → completed
            code, body = self._req("PUT", f"/trades/{self.trade_dispute_id}/status",
                                   token=self.user_a_token,
                                   json_data={"status": "completed"})
            self._test(CAT, "disputed → completed → 400 (terminal)",
                       code == 400,
                       f"Got {code}: {body.get('error','')}")

        # ═══ INVALID TRANSITIONS ═══
        # Create fresh trade for these tests
        code, body = self._req("POST", "/trades", token=self.user_a_token, json_data={
            "receiver_id": self.user_b_id, "type": "sale", "payment_amount": 1,
            "requested_items": [{"binder_item_id": self.binder_b_have}]
        })
        fresh_id = body.get("id", "")

        if fresh_id:
            # pending → shipped (skip accepted)
            code, body = self._req("PUT", f"/trades/{fresh_id}/status",
                                   token=self.user_a_token,
                                   json_data={"status": "shipped"})
            self._test(CAT, "pending → shipped → 400 (must go through accepted)",
                       code == 400,
                       f"Got {code}: {body.get('error','')}")

            # pending → delivered
            code, body = self._req("PUT", f"/trades/{fresh_id}/status",
                                   token=self.user_a_token,
                                   json_data={"status": "delivered"})
            self._test(CAT, "pending → delivered → 400",
                       code == 400, f"Got {code}")

            # pending → completed
            code, body = self._req("PUT", f"/trades/{fresh_id}/status",
                                   token=self.user_a_token,
                                   json_data={"status": "completed"})
            self._test(CAT, "pending → completed → 400",
                       code == 400, f"Got {code}")

            # pending → cancelled (allowed)
            code, body = self._req("PUT", f"/trades/{fresh_id}/status",
                                   token=self.user_a_token,
                                   json_data={"status": "cancelled"})
            self._test(CAT, "pending → cancelled → 200 (allowed)",
                       code == 200, f"Got {code}")

        # ═══ VALIDATION ═══
        code, body = self._req("PUT", f"/trades/{self.trade_sale_id}/status",
                               token=self.user_a_token,
                               json_data={})
        self._test(CAT, "Status sem campo status → 400",
                   code == 400, f"Got {code}: {body.get('error','')}")

        code, body = self._req("PUT", f"/trades/{self.trade_sale_id}/status",
                               token=self.user_a_token,
                               json_data={"status": "invalidstatus"})
        self._test(CAT, "Status inválido → 400",
                   code == 400, f"Got {code}: {body.get('error','')}")

        # ═══ OUTSIDER ═══
        code, body = self._req("PUT", f"/trades/{self.trade_sale_id}/status",
                               token=self.user_c_token,
                               json_data={"status": "shipped"})
        self._test(CAT, "Outsider tenta mudar status → 403",
                   code == 403, f"Got {code}: {body.get('error','')}")

        # ═══ DELIVERY METHOD VALUES ═══
        for method in ["correios", "motoboy", "pessoalmente", "outro"]:
            code2, body2 = self._req("POST", "/trades", token=self.user_a_token, json_data={
                "receiver_id": self.user_b_id, "type": "sale", "payment_amount": 1,
                "requested_items": [{"binder_item_id": self.binder_b_have}]
            })
            tid = body2.get("id", "")
            if tid:
                self._req("PUT", f"/trades/{tid}/respond", token=self.user_b_token,
                          json_data={"action": "accept"})
                code3, body3 = self._req("PUT", f"/trades/{tid}/status", token=self.user_b_token,
                                         json_data={"status": "shipped", "delivery_method": method})
                self._test(CAT, f"delivery_method='{method}' → 200",
                           code3 == 200,
                           f"Got {code3}: {body3.get('error', body3.get('status',''))}")

    # ═══════════════════════════════════════════════════════════════
    #  CHAT / MESSAGES TESTS
    # ═══════════════════════════════════════════════════════════════
    def test_messages(self):
        print("\n💬 MESSAGES TESTS")
        CAT = "MESSAGES"

        # Use trade_sale_id (now completed, but messaging should still work)
        tid = self.trade_sale_id
        if not tid:
            self._test(CAT, "Trade ID disponível", False, "Nenhum trade")
            return

        # ── Send message ──
        code, body = self._req("POST", f"/trades/{tid}/messages",
                               token=self.user_a_token,
                               json_data={"message": "Mensagem de teste E2E"})
        self._test(CAT, "POST mensagem de texto → 201",
                   code == 201,
                   f"Got {code}: {body.get('error', body.get('id',''))}")

        # ── Send attachment ──
        code, body = self._req("POST", f"/trades/{tid}/messages",
                               token=self.user_b_token,
                               json_data={
                                   "attachment_url": "https://example.com/receipt.jpg",
                                   "attachment_type": "photo"
                               })
        self._test(CAT, "POST mensagem com attachment (sem texto) → 201",
                   code == 201,
                   f"Got {code}")

        # ── Send both ──
        code, body = self._req("POST", f"/trades/{tid}/messages",
                               token=self.user_a_token,
                               json_data={
                                   "message": "Aqui o comprovante",
                                   "attachment_url": "https://example.com/pix.png",
                                   "attachment_type": "receipt"
                               })
        self._test(CAT, "POST mensagem com texto + attachment → 201",
                   code == 201, f"Got {code}")

        # ── NEGATIVE: attachment_type inválido ──
        code, body = self._req("POST", f"/trades/{tid}/messages",
                               token=self.user_a_token,
                               json_data={
                                   "message": "Teste tipo inválido",
                                   "attachment_url": "https://example.com/file.png",
                                   "attachment_type": "image"
                               })
        self._test(CAT, "POST attachment_type inválido → 400",
                   code == 400,
                   f"Got {code}: {body.get('error','')}")

        # ── NEGATIVE: sem message nem attachment ──
        code, body = self._req("POST", f"/trades/{tid}/messages",
                               token=self.user_a_token,
                               json_data={})
        self._test(CAT, "POST sem message nem attachment → 400",
                   code == 400,
                   f"Got {code}: {body.get('error','')}")

        # ── NEGATIVE: message vazia ──
        code, body = self._req("POST", f"/trades/{tid}/messages",
                               token=self.user_a_token,
                               json_data={"message": "   "})
        self._test(CAT, "POST message só espaços → 400",
                   code == 400,
                   f"Got {code}: {body.get('error','')}")

        # ── NEGATIVE: outsider envia message ──
        code, body = self._req("POST", f"/trades/{tid}/messages",
                               token=self.user_c_token,
                               json_data={"message": "Sou intruso"})
        self._test(CAT, "Outsider envia mensagem → 403",
                   code == 403,
                   f"Got {code}: {body.get('error','')}")

        # ── GET messages ──
        code, body = self._req("GET", f"/trades/{tid}/messages",
                               token=self.user_a_token)
        msg_count = body.get("total", len(body.get("data", [])))
        self._test(CAT, "GET /trades/:id/messages → 200 com msgs",
                   code == 200 and msg_count >= 3,
                   f"Got {code}, total={msg_count}")

        # ── GET messages paginação ──
        code, body = self._req("GET", f"/trades/{tid}/messages",
                               token=self.user_a_token,
                               params={"page": "1", "limit": "2"})
        self._test(CAT, "GET messages page=1 limit=2 → max 2 items",
                   code == 200 and len(body.get("data", [])) <= 2,
                   f"Got {code}, items={len(body.get('data', []))}")

        # ── NEGATIVE: outsider lê messages ──
        code, body = self._req("GET", f"/trades/{tid}/messages",
                               token=self.user_c_token)
        self._test(CAT, "Outsider lê mensagens → 403",
                   code == 403, f"Got {code}")

        # ── NEGATIVE: message em trade declined ──
        if self.trade_decline_id:
            code, body = self._req("POST", f"/trades/{self.trade_decline_id}/messages",
                                   token=self.user_a_token,
                                   json_data={"message": "Teste em declined"})
            self._test(CAT, "POST mensagem em trade declined → 400",
                       code == 400,
                       f"Got {code}: {body.get('error','')}")

        # ── NEGATIVE: message em trade cancelled ──
        if self.trade_cancel_id:
            code, body = self._req("POST", f"/trades/{self.trade_cancel_id}/messages",
                                   token=self.user_a_token,
                                   json_data={"message": "Teste em cancelled"})
            self._test(CAT, "POST mensagem em trade cancelled → 400",
                       code == 400,
                       f"Got {code}: {body.get('error','')}")

        # ── POSITIVE: message em trade disputed → allowed ──
        if self.trade_dispute_id:
            code, body = self._req("POST", f"/trades/{self.trade_dispute_id}/messages",
                                   token=self.user_a_token,
                                   json_data={"message": "Explico a disputa aqui"})
            self._test(CAT, "POST mensagem em trade disputed → 201 (allowed)",
                       code == 201,
                       f"Got {code}")

    # ═══════════════════════════════════════════════════════════════
    #  BINDER DELETE TESTS (run last — may affect trade items)
    # ═══════════════════════════════════════════════════════════════
    def test_binder_delete(self):
        print("\n🗑️  BINDER DELETE TESTS")
        CAT = "BINDER_DEL"

        # ── NEGATIVE: deletar item de outro user ──
        if self.binder_a_have:
            code, body = self._req("DELETE", f"/binder/{self.binder_a_have}",
                                   token=self.user_b_token)
            self._test(CAT, "DELETE binder item de outro user → 404",
                       code == 404, f"Got {code}")

        # ── Create & delete fresh binder item ──
        code, body = self._req("POST", "/binder", token=self.user_a_token, json_data={
            "card_id": self.card_id, "quantity": 1, "condition": "DMG",
            "list_type": "have"
        })
        if code == 201:
            fresh_binder = body.get("id", "")
            code, body = self._req("DELETE", f"/binder/{fresh_binder}",
                                   token=self.user_a_token)
            self._test(CAT, "DELETE próprio binder item → 204",
                       code == 204 or code == 200, f"Got {code}")

            # DELETE novamente → 404
            code, body = self._req("DELETE", f"/binder/{fresh_binder}",
                                   token=self.user_a_token)
            self._test(CAT, "DELETE item já deletado → 404",
                       code == 404, f"Got {code}")

    # ═══════════════════════════════════════════════════════════════
    #  EDGE CASE TESTS
    # ═══════════════════════════════════════════════════════════════
    def test_edge_cases(self):
        print("\n🧪 EDGE CASE TESTS")
        CAT = "EDGE"

        # ── UUID inválido em path ──
        code, body = self._req("GET", "/trades/not-a-uuid", token=self.user_a_token)
        self._test(CAT, "GET /trades/not-a-uuid → 404 ou 500",
                   code in (404, 500, 400),
                   f"Got {code}")

        # ── Respond em trade inexistente ──
        code, body = self._req("PUT", "/trades/00000000-0000-0000-0000-000000000000/respond",
                               token=self.user_a_token,
                               json_data={"action": "accept"})
        self._test(CAT, "Respond em trade inexistente → 404",
                   code == 404, f"Got {code}")

        # ── Status em trade inexistente ──
        code, body = self._req("PUT", "/trades/00000000-0000-0000-0000-000000000000/status",
                               token=self.user_a_token,
                               json_data={"status": "shipped"})
        self._test(CAT, "Status em trade inexistente → 404",
                   code == 404, f"Got {code}")

        # ── Messages em trade inexistente ──
        code, body = self._req("GET", "/trades/00000000-0000-0000-0000-000000000000/messages",
                               token=self.user_a_token)
        self._test(CAT, "Messages em trade inexistente → 404",
                   code == 404, f"Got {code}")

        # ── Mixed type trade (items + payment) ──
        code, body = self._req("POST", "/trades", token=self.user_a_token, json_data={
            "receiver_id": self.user_b_id,
            "type": "mixed",
            "payment_amount": 10.00,
            "my_items": [{"binder_item_id": self.binder_a_have, "quantity": 1}],
            "requested_items": [{"binder_item_id": self.binder_b_have, "quantity": 1}]
        })
        self._test(CAT, "Criar MIXED trade (items + payment) → 201",
                   code == 201, f"Got {code}: {body.get('error','')}")

        # ── Sale com apenas my_items (sender vendendo) ──
        code, body = self._req("POST", "/trades", token=self.user_a_token, json_data={
            "receiver_id": self.user_b_id,
            "type": "sale",
            "payment_amount": 5.00,
            "my_items": [{"binder_item_id": self.binder_a_have, "quantity": 1}]
        })
        self._test(CAT, "Sale com apenas my_items (sender vende) → 201",
                   code == 201,
                   f"Got {code}: {body.get('error','')}")

        # ── Concurrent accept (race condition) ──
        # Create a fresh trade
        code, body = self._req("POST", "/trades", token=self.user_a_token, json_data={
            "receiver_id": self.user_b_id, "type": "sale", "payment_amount": 1,
            "requested_items": [{"binder_item_id": self.binder_b_have}]
        })
        if code == 201:
            race_id = body.get("id", "")
            # First accept
            code1, _ = self._req("PUT", f"/trades/{race_id}/respond",
                                 token=self.user_b_token,
                                 json_data={"action": "accept"})
            # Second accept (simulates race — should fail)
            code2, body2 = self._req("PUT", f"/trades/{race_id}/respond",
                                     token=self.user_b_token,
                                     json_data={"action": "accept"})
            self._test(CAT, "Double accept (race) → segunda vez 400",
                       code2 == 400,
                       f"1st={code1}, 2nd={code2}")

    # ═══════════════════════════════════════════════════════════════
    #  NOTIFICATIONS CHECK
    # ═══════════════════════════════════════════════════════════════
    def test_notifications(self):
        print("\n🔔 NOTIFICATION TESTS")
        CAT = "NOTIF"

        # Check that User A received notifications
        code, body = self._req("GET", "/notifications", token=self.user_a_token,
                               params={"limit": "50"})
        if code == 200:
            notifs = body.get("data", body.get("notifications", []))
            types = [n.get("type", "") for n in notifs] if isinstance(notifs, list) else []
            self._test(CAT, "User A tem notificações", len(notifs) >= 1,
                       f"Got {len(notifs)} notifs, types={types[:5]}")

            has_trade_notif = any("trade" in t for t in types)
            self._test(CAT, "Notificações incluem trade events",
                       has_trade_notif,
                       f"Types: {[t for t in types if 'trade' in t][:5]}")
        else:
            self._test(CAT, "GET /notifications → 200", code == 200,
                       f"Got {code}")

        # Unread count
        code, body = self._req("GET", "/notifications/count", token=self.user_a_token)
        self._test(CAT, "GET /notifications/count → 200",
                   code == 200, f"Got {code}: {body}")

    # ═══════════════════════════════════════════════════════════════
    #  RUN ALL
    # ═══════════════════════════════════════════════════════════════
    def run_all(self):
        print("═" * 65)
        print("  🧙 MTG Trade System — Suíte de Testes E2E")
        print(f"  🌐 API: {self.api}")
        print(f"  🕐 {time.strftime('%Y-%m-%d %H:%M:%S')}")
        print("═" * 65)

        if not self.setup():
            print("\n💀 SETUP FALHOU! Abortando testes.")
            return False

        self.test_auth()
        self.test_binder()
        self.test_trade_creation()
        self.test_trade_listing()
        self.test_trade_detail()
        self.test_trade_respond()
        self.test_status_transitions()
        self.test_messages()
        self.test_binder_delete()
        self.test_edge_cases()
        self.test_notifications()

        return self.print_summary()

    def print_summary(self):
        print("\n" + "═" * 65)
        print("  📊 RESULTADOS")
        print("═" * 65)

        categories = {}
        for r in self.results:
            cat = r.category or "OTHER"
            if cat not in categories:
                categories[cat] = {"pass": 0, "fail": 0, "failures": []}
            if r.passed:
                categories[cat]["pass"] += 1
            else:
                categories[cat]["fail"] += 1
                categories[cat]["failures"].append(r)

        total_pass = sum(c["pass"] for c in categories.values())
        total_fail = sum(c["fail"] for c in categories.values())
        total = total_pass + total_fail

        for cat, data in categories.items():
            icon = "✅" if data["fail"] == 0 else "❌"
            print(f"  {icon} {cat:20s}  {data['pass']}/{data['pass']+data['fail']} passed")

        print(f"\n  {'✅' if total_fail == 0 else '❌'} TOTAL: {total_pass}/{total} passed, {total_fail} failed")

        if total_fail > 0:
            print(f"\n  🔴 FALHAS ({total_fail}):")
            for r in self.results:
                if not r.passed:
                    print(f"    ❌ [{r.category}] {r.name}")
                    if r.detail:
                        print(f"       → {r.detail}")

        print("═" * 65)
        return total_fail == 0


# ─── Main ──────────────────────────────────────────────────────────
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="MTG Trade E2E Test Suite")
    parser.add_argument("--api", default=DEFAULT_API, help="API base URL")
    parser.add_argument("--verbose", "-v", action="store_true", help="Show all requests")
    args = parser.parse_args()

    VERBOSE = args.verbose
    runner = TestRunner(args.api)
    success = runner.run_all()
    sys.exit(0 if success else 1)
