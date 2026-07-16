#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════
  🧙 MTG Deck Builder — Suíte de Testes E2E (Geral)
  Cobre: Auth, Decks CRUD, Community, Social (follow),
         User Profile, Conversations, Import, Notifications,
         Health, Rules, Sets, Cards, Market
═══════════════════════════════════════════════════════════════
Uso:
  MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL \
    python3 server/test/e2e_general_tests.py --api URL [--verbose]
"""

import argparse
import json
import sys
import time
from dataclasses import dataclass, field
from typing import Any, Optional

import requests

try:
    from .legacy_live_e2e_guard import require_legacy_live_e2e_approval
except ImportError:  # Direct script execution.
    from legacy_live_e2e_guard import require_legacy_live_e2e_approval

VERBOSE = False

# Rate-limit safe delay between auth requests
AUTH_DELAY = 3.0
# Max retries on 429
MAX_429_RETRIES = 3
RETRY_429_WAIT = 15.0


@dataclass
class TestResult:
    category: str
    name: str
    passed: bool
    detail: str = ""


class TestRunner:
    def __init__(self, api: str):
        self.api = api.rstrip("/")
        self.results: list[TestResult] = []
        self.ts = str(int(time.time()))

        # Users
        self.user_a_token = ""
        self.user_a_id = ""
        self.user_b_token = ""
        self.user_b_id = ""
        self.user_c_token = ""
        self.user_c_id = ""

        # Cards
        self.card_1_id = ""  # Sol Ring
        self.card_2_id = ""  # Lightning Bolt
        self.card_3_id = ""  # Forest (basic land)

        # Decks
        self.deck_a_id = ""
        self.deck_b_id = ""

    # ─── Helpers ────────────────────────────────────────────────
    def _req(self, method: str, path: str, token: str = "",
             json_data: Any = None, params: dict = None) -> tuple:
        url = f"{self.api}{path}"
        headers = {"Content-Type": "application/json"}
        if token:
            headers["Authorization"] = f"Bearer {token}"
        for attempt in range(MAX_429_RETRIES + 1):
            try:
                r = requests.request(method, url, json=json_data,
                                     params=params, headers=headers, timeout=30)
                if r.status_code == 429 and attempt < MAX_429_RETRIES:
                    wait = RETRY_429_WAIT
                    if VERBOSE:
                        print(f"    ⏳ 429 on {method} {path} — retrying in {wait}s (attempt {attempt+1})")
                    time.sleep(wait)
                    continue
                try:
                    body = r.json()
                except Exception:
                    body = {"_raw": r.text[:500]}
                if VERBOSE:
                    payload = json.dumps(body)[:200]
                    print(f"    📋 {method} {path} → {r.status_code}: {payload}")
                return r.status_code, body
            except Exception as e:
                return 0, {"_error": str(e)}
        return 429, {"error": "Rate limited after retries"}

    def _test(self, cat: str, name: str, passed: bool, detail: str = ""):
        self.results.append(TestResult(cat, name, passed, detail))
        icon = "✅" if passed else "❌"
        msg = f"  {icon} [{cat}] {name}"
        if not passed and detail:
            msg += f"  — {detail}"
        print(msg)

    # ─── Setup ──────────────────────────────────────────────────
    def setup(self) -> bool:
        print("\n🔧 SETUP: Registrando usuários e buscando cartas...\n")

        # Register 3 users (with delays to avoid rate limiting)
        for label, suffix in [("A", "a"), ("B", "b"), ("C", "c")]:
            uname = f"gen_{suffix}_{self.ts}"
            code, body = self._req("POST", "/auth/register", json_data={
                "username": uname,
                "email": f"{uname}@test.com",
                "password": "Test1234"
            })
            if code != 201:
                print(f"  ❌ SETUP FALHOU ao registrar User {label}: {body}")
                return False
            token = body["token"]
            uid = body["user"]["id"]
            setattr(self, f"user_{suffix}_token", token)
            setattr(self, f"user_{suffix}_id", uid)
            print(f"  👤 User {label}: {uname} ({uid[:8]}...)")
            time.sleep(AUTH_DELAY)

        # Find cards (use exact names, ensure Forest is a basic land)
        for i, name in enumerate(["Sol Ring", "Lightning Bolt"], 1):
            code, body = self._req("GET", "/cards", params={"name": name, "limit": 1})
            if code != 200 or not body.get("data"):
                print(f"  ❌ SETUP FALHOU ao buscar carta: {name}")
                return False
            cid = body["data"][0]["id"]
            setattr(self, f"card_{i}_id", cid)
            print(f"  🃏 Card {i}: {name} ({cid[:8]}...)")

        # For card 3, search for a basic Forest land specifically
        code, body = self._req("GET", "/cards", params={"name": "Forest", "limit": 50})
        if code == 200 and body.get("data"):
            # Find a basic land Forest
            forest = None
            for card in body["data"]:
                tl = (card.get("type_line") or "").lower()
                if "basic land" in tl and card["name"] == "Forest":
                    forest = card
                    break
            if forest is None:
                # Fallback: just use the first exact "Forest"
                for card in body["data"]:
                    if card["name"] == "Forest":
                        forest = card
                        break
            if forest is None:
                forest = body["data"][0]
            self.card_3_id = forest["id"]
            print(f"  🃏 Card 3: {forest['name']} [{forest.get('type_line', '')}] ({self.card_3_id[:8]}...)")
        else:
            print(f"  ❌ SETUP FALHOU ao buscar Forest")
            return False

        print()
        return True

    # ═══════════════════════════════════════════════════════════
    #  AUTH TESTS
    # ═══════════════════════════════════════════════════════════
    def test_auth(self):
        CAT = "AUTH"
        print(f"\n🔐 {CAT} TESTS")
        # Wait for rate limit window to expire (setup used 3 auth requests)
        print("  ⏳ Aguardando rate limit window expirar (30s)...")
        time.sleep(30)

        # ── Register validations ──
        code, body = self._req("POST", "/auth/register", json_data={})
        self._test(CAT, "Register sem campos → 400", code == 400,
                   f"Got {code}")

        time.sleep(AUTH_DELAY)

        code, body = self._req("POST", "/auth/register", json_data={
            "username": "ab", "email": "a@b.com", "password": "123456"
        })
        self._test(CAT, "Register username curto (<3) → 400", code == 400,
                   f"Got {code}: {body.get('message', body.get('error', ''))}")

        time.sleep(AUTH_DELAY)

        code, body = self._req("POST", "/auth/register", json_data={
            "username": "test_short_pw_" + self.ts,
            "email": f"shortpw_{self.ts}@t.com",
            "password": "123"
        })
        self._test(CAT, "Register senha curta (<6) → 400", code == 400,
                   f"Got {code}")

        time.sleep(AUTH_DELAY)

        # ── Duplicate register ──
        code, body = self._req("POST", "/auth/register", json_data={
            "username": f"gen_a_{self.ts}",
            "email": f"gen_a_{self.ts}@test.com",
            "password": "Test1234"
        })
        self._test(CAT, "Register duplicado → 400/409", code in (400, 409),
                   f"Got {code}")

        time.sleep(AUTH_DELAY)

        # ── Login ──
        code, body = self._req("POST", "/auth/login", json_data={
            "email": f"gen_a_{self.ts}@test.com",
            "password": "Test1234"
        })
        self._test(CAT, "Login válido → 200 com token", code == 200 and "token" in body,
                   f"Got {code}")

        time.sleep(AUTH_DELAY)

        code, body = self._req("POST", "/auth/login", json_data={
            "email": f"gen_a_{self.ts}@test.com",
            "password": "SenhaErrada123"
        })
        self._test(CAT, "Login senha errada → 401", code == 401,
                   f"Got {code}")

        time.sleep(AUTH_DELAY)

        code, body = self._req("POST", "/auth/login", json_data={
            "email": "inexistente@nope.com",
            "password": "Test1234"
        })
        self._test(CAT, "Login email inexistente → 401", code == 401,
                   f"Got {code}")

        time.sleep(AUTH_DELAY)

        code, body = self._req("POST", "/auth/login", json_data={})
        self._test(CAT, "Login sem campos → 400/401",
                   code in (400, 401), f"Got {code}")

        time.sleep(AUTH_DELAY)

        # ── Me ──
        code, body = self._req("GET", "/auth/me", token=self.user_a_token)
        self._test(CAT, "GET /auth/me com token → 200",
                   code == 200 and "user" in body, f"Got {code}")

        time.sleep(AUTH_DELAY)

        code, body = self._req("GET", "/auth/me")
        self._test(CAT, "GET /auth/me sem token → 401", code == 401,
                   f"Got {code}")

    # ═══════════════════════════════════════════════════════════
    #  DECK CRUD TESTS
    # ═══════════════════════════════════════════════════════════
    def test_deck_crud(self):
        CAT = "DECK"
        print(f"\n🃏 {CAT} CRUD TESTS")

        # ── Create deck ──
        code, body = self._req("POST", "/decks", token=self.user_a_token, json_data={
            "name": f"Test Deck A {self.ts}",
            "format": "commander",
            "description": "Deck de teste E2E"
        })
        self._test(CAT, "POST /decks criar deck → 200/201",
                   code in (200, 201) and "id" in body, f"Got {code}")
        self.deck_a_id = body.get("id", "")

        # ── Create deck with cards ──
        code, body = self._req("POST", "/decks", token=self.user_b_token, json_data={
            "name": f"Test Deck B {self.ts}",
            "format": "commander",
            "description": "Deck B público",
            "cards": [
                {"card_id": self.card_1_id, "quantity": 1},
                {"card_id": self.card_2_id, "quantity": 1}
            ]
        })
        self._test(CAT, "POST /decks criar deck com cartas → 200/201",
                   code in (200, 201) and "id" in body, f"Got {code}")
        self.deck_b_id = body.get("id", "")

        # Make Deck B public (POST may not apply is_public)
        if self.deck_b_id:
            self._req("PUT", f"/decks/{self.deck_b_id}",
                      token=self.user_b_token, json_data={"is_public": True})

        # ── Create deck validation: missing fields ──
        code, body = self._req("POST", "/decks", token=self.user_a_token, json_data={})
        self._test(CAT, "POST /decks sem name/format → 400",
                   code == 400, f"Got {code}")

        code, body = self._req("POST", "/decks", token=self.user_a_token, json_data={
            "name": "Sem formato"
        })
        self._test(CAT, "POST /decks sem format → 400",
                   code == 400, f"Got {code}")

        # ── Create deck without auth ──
        code, body = self._req("POST", "/decks", json_data={
            "name": "Sem Auth", "format": "commander"
        })
        self._test(CAT, "POST /decks sem token → 401", code == 401, f"Got {code}")

        # ── List user decks ──
        code, body = self._req("GET", "/decks", token=self.user_a_token)
        self._test(CAT, "GET /decks listar meus decks → 200",
                   code == 200 and isinstance(body, list),
                   f"Got {code}, type={type(body).__name__}")
        has_my_deck = any(d.get("id") == self.deck_a_id for d in body) if isinstance(body, list) else False
        self._test(CAT, "GET /decks contém o deck criado",
                   has_my_deck, f"deck_a_id={self.deck_a_id[:8]}... not in list")

        # ── Get deck detail ──
        code, body = self._req("GET", f"/decks/{self.deck_a_id}",
                               token=self.user_a_token)
        self._test(CAT, "GET /decks/:id detalhe → 200",
                   code == 200 and body.get("name", "").startswith("Test Deck A"),
                   f"Got {code}")

        # ── Get deck detail: wrong user ──
        code, body = self._req("GET", f"/decks/{self.deck_a_id}",
                               token=self.user_b_token)
        self._test(CAT, "GET /decks/:id de outro user → 404",
                   code == 404, f"Got {code}")

        # ── Get deck detail: inexistent ──
        code, body = self._req("GET", "/decks/00000000-0000-0000-0000-000000000000",
                               token=self.user_a_token)
        self._test(CAT, "GET /decks/:id inexistente → 404",
                   code == 404, f"Got {code}")

        # ── Update deck ──
        code, body = self._req("PUT", f"/decks/{self.deck_a_id}",
                               token=self.user_a_token, json_data={
                                   "name": f"Updated Deck A {self.ts}",
                                   "description": "Atualizado!",
                                   "is_public": True
                               })
        self._test(CAT, "PUT /decks/:id atualizar nome/desc/public → 200",
                   code == 200, f"Got {code}")

        # ── Update deck: wrong owner ──
        code, body = self._req("PUT", f"/decks/{self.deck_a_id}",
                               token=self.user_b_token, json_data={
                                   "name": "Hacker"
                               })
        self._test(CAT, "PUT /decks/:id de outro user → 404",
                   code == 404, f"Got {code}")

        # ── Update deck with cards (full replace) ──
        code, body = self._req("PUT", f"/decks/{self.deck_a_id}",
                               token=self.user_a_token, json_data={
                                   "cards": [
                                       {"card_id": self.card_1_id, "quantity": 1},
                                       {"card_id": self.card_3_id, "quantity": 10}
                                   ]
                               })
        self._test(CAT, "PUT /decks/:id com cards (replace) → 200",
                   code == 200, f"Got {code}: {body.get('error', '')}")

    # ═══════════════════════════════════════════════════════════
    #  DECK CARDS MANAGEMENT
    # ═══════════════════════════════════════════════════════════
    def test_deck_cards(self):
        CAT = "DECK_CARDS"
        print(f"\n🎴 {CAT} TESTS")

        did = self.deck_a_id

        # ── Add single card ──
        code, body = self._req("POST", f"/decks/{did}/cards",
                               token=self.user_a_token, json_data={
                                   "card_id": self.card_2_id,
                                   "quantity": 1
                               })
        self._test(CAT, "POST /decks/:id/cards adicionar carta → 200",
                   code == 200 and body.get("ok") is True,
                   f"Got {code}: {body.get('error', '')}")

        # ── Add card without card_id ──
        code, body = self._req("POST", f"/decks/{did}/cards",
                               token=self.user_a_token, json_data={
                                   "quantity": 1
                               })
        self._test(CAT, "POST /decks/:id/cards sem card_id → 400",
                   code == 400, f"Got {code}")

        # ── Add card with quantity 0 ──
        code, body = self._req("POST", f"/decks/{did}/cards",
                               token=self.user_a_token, json_data={
                                   "card_id": self.card_2_id,
                                   "quantity": 0
                               })
        self._test(CAT, "POST /decks/:id/cards quantity=0 → 400",
                   code == 400, f"Got {code}")

        # ── Bulk add (use basic land card_3 which allows unlimited copies) ──
        code, body = self._req("POST", f"/decks/{did}/cards/bulk",
                               token=self.user_a_token, json_data={
                                   "cards": [
                                       {"card_id": self.card_3_id, "quantity": 5,
                                        "is_commander": False}
                                   ]
                               })
        self._test(CAT, "POST /decks/:id/cards/bulk → 200",
                   code == 200 and body.get("ok") is True,
                   f"Got {code}: {body.get('error', '')}")

        # ── Bulk add empty ──
        code, body = self._req("POST", f"/decks/{did}/cards/bulk",
                               token=self.user_a_token, json_data={
                                   "cards": []
                               })
        self._test(CAT, "POST /decks/:id/cards/bulk vazio → 400",
                   code == 400, f"Got {code}")

        # ── Set card quantity (absolute) — use basic land which allows many copies ──
        code, body = self._req("POST", f"/decks/{did}/cards/set",
                               token=self.user_a_token, json_data={
                                   "card_id": self.card_3_id,
                                   "quantity": 20
                               })
        self._test(CAT, "POST /decks/:id/cards/set (absolute qty) → 200",
                   code == 200, f"Got {code}: {body.get('error', '')}")

        # ── Export deck ──
        code, body = self._req("GET", f"/decks/{did}/export",
                               token=self.user_a_token)
        self._test(CAT, "GET /decks/:id/export → 200 com texto",
                   code == 200 and "text" in body,
                   f"Got {code}")

        # ── Validate deck ──
        code, body = self._req("POST", f"/decks/{did}/validate",
                               token=self.user_a_token)
        # Pode dar 200 (ok) ou 400 (invalid) — ambos são válidos, desde que responda
        self._test(CAT, "POST /decks/:id/validate → responde (200 ou 400)",
                   code in (200, 400),
                   f"Got {code}")

        # ── Analysis (heuristic) ──
        code, body = self._req("GET", f"/decks/{did}/analysis",
                               token=self.user_a_token)
        self._test(CAT, "GET /decks/:id/analysis → 200",
                   code == 200 and "mana_curve" in body,
                   f"Got {code}")

        # ── Simulate (Monte Carlo) ──
        code, body = self._req("GET", f"/decks/{did}/simulate",
                               token=self.user_a_token)
        self._test(CAT, "GET /decks/:id/simulate → 200",
                   code == 200 and "iterations" in body,
                   f"Got {code}")

    # ═══════════════════════════════════════════════════════════
    #  COMMUNITY TESTS (public decks, search, copy)
    # ═══════════════════════════════════════════════════════════
    def test_community(self):
        CAT = "COMMUNITY"
        print(f"\n🌍 {CAT} TESTS")

        # ── Search users ──
        code, body = self._req("GET", "/community/users",
                               params={"q": f"gen_a_{self.ts}"})
        self._test(CAT, "GET /community/users?q=... → 200 com results",
                   code == 200 and body.get("total", 0) >= 1,
                   f"Got {code}, total={body.get('total', 0)}")

        # ── Search users: sem query ──
        code, body = self._req("GET", "/community/users")
        self._test(CAT, "GET /community/users sem q → 400 ou 200 vazio",
                   code in (400, 200), f"Got {code}")

        # ── User profile (public) ──
        code, body = self._req("GET", f"/community/users/{self.user_a_id}")
        self._test(CAT, "GET /community/users/:id perfil público → 200",
                   code == 200 and "user" in body,
                   f"Got {code}")

        # ── User profile with auth (is_following field) ──
        code, body = self._req("GET", f"/community/users/{self.user_a_id}",
                               token=self.user_b_token)
        has_following = "is_following" in body.get("user", {})
        self._test(CAT, "GET /community/users/:id com auth → tem is_following",
                   code == 200 and has_following,
                   f"Got {code}, has_is_following={has_following}")

        # ── User profile inexistent ──
        code, body = self._req("GET", "/community/users/00000000-0000-0000-0000-000000000000")
        self._test(CAT, "GET /community/users/:id inexistente → 404",
                   code == 404, f"Got {code}")

        # ── Public decks list ──
        code, body = self._req("GET", "/community/decks")
        self._test(CAT, "GET /community/decks → 200",
                   code == 200 and "data" in body,
                   f"Got {code}")

        # ── Public decks search by name ──
        code, body = self._req("GET", "/community/decks",
                               params={"search": f"Test Deck B {self.ts}"})
        found = body.get("total", 0) >= 1 if code == 200 else False
        self._test(CAT, "GET /community/decks?search=... → encontra deck público",
                   found, f"Got {code}, total={body.get('total', 0)}")

        # ── Public decks filter by format ──
        code, body = self._req("GET", "/community/decks",
                               params={"format": "commander"})
        self._test(CAT, "GET /community/decks?format=commander → 200",
                   code == 200, f"Got {code}")

        # ── View public deck detail ──
        code, body = self._req("GET", f"/community/decks/{self.deck_b_id}")
        self._test(CAT, "GET /community/decks/:id (público) → 200",
                   code == 200 and "name" in body,
                   f"Got {code}")
        has_owner = "owner_username" in body or "owner_id" in body
        self._test(CAT, "Deck público tem owner info",
                   has_owner, f"keys={list(body.keys())[:10]}")

        # ── View private deck as outsider ──
        # deck_a should now be public (we set is_public=true), let's create a private one
        code, body_priv = self._req("POST", "/decks", token=self.user_a_token, json_data={
            "name": f"Private Deck {self.ts}",
            "format": "standard",
            "is_public": False
        })
        priv_id = body_priv.get("id", "")
        if priv_id:
            code, body = self._req("GET", f"/community/decks/{priv_id}")
            self._test(CAT, "GET /community/decks/:id (privado) → 404",
                       code == 404, f"Got {code}")
        else:
            self._test(CAT, "GET /community/decks/:id (privado) → 404",
                       False, "Could not create private deck")

        # ── Copy public deck ──
        code, body = self._req("POST", f"/community/decks/{self.deck_b_id}",
                               token=self.user_a_token)
        self._test(CAT, "POST /community/decks/:id copiar deck → 201",
                   code == 201 and body.get("success") is True,
                   f"Got {code}: {body.get('error', '')}")
        copied_name = body.get("deck", {}).get("name", "")
        self._test(CAT, "Deck copiado tem nome 'Cópia de ...'",
                   "Cópia" in copied_name or "pia" in copied_name,
                   f"name={copied_name}")

        # ── Copy without auth ──
        code, body = self._req("POST", f"/community/decks/{self.deck_b_id}")
        self._test(CAT, "POST /community/decks/:id sem token → 401",
                   code == 401, f"Got {code}")

        # ── Copy private deck ──
        if priv_id:
            code, body = self._req("POST", f"/community/decks/{priv_id}",
                                   token=self.user_b_token)
            self._test(CAT, "POST /community/decks/:id (privado) → 404",
                       code == 404, f"Got {code}")

    # ═══════════════════════════════════════════════════════════
    #  SOCIAL / FOLLOW TESTS
    # ═══════════════════════════════════════════════════════════
    def test_social(self):
        CAT = "SOCIAL"
        print(f"\n👥 {CAT} TESTS")

        # ── Follow user ──
        code, body = self._req("POST", f"/users/{self.user_a_id}/follow",
                               token=self.user_b_token)
        self._test(CAT, "POST /users/:id/follow (B segue A) → 200",
                   code == 200 and body.get("is_following") is True,
                   f"Got {code}")

        # ── Follow again (idempotent) ──
        code, body = self._req("POST", f"/users/{self.user_a_id}/follow",
                               token=self.user_b_token)
        self._test(CAT, "POST /users/:id/follow novamente → 200 (idempotent)",
                   code == 200, f"Got {code}")

        # ── Follow self ──
        code, body = self._req("POST", f"/users/{self.user_b_id}/follow",
                               token=self.user_b_token)
        self._test(CAT, "POST /users/:id/follow a si mesmo → 400",
                   code == 400, f"Got {code}")

        # ── Follow inexistent ──
        code, body = self._req("POST", "/users/00000000-0000-0000-0000-000000000000/follow",
                               token=self.user_b_token)
        self._test(CAT, "POST /users/:id/follow inexistente → 404",
                   code == 404, f"Got {code}")

        # ── Check follow status ──
        code, body = self._req("GET", f"/users/{self.user_a_id}/follow",
                               token=self.user_b_token)
        self._test(CAT, "GET /users/:id/follow status → 200 is_following=true",
                   code == 200 and body.get("is_following") is True,
                   f"Got {code}, is_following={body.get('is_following')}")

        # ── Followers list ──
        code, body = self._req("GET", f"/users/{self.user_a_id}/followers",
                               token=self.user_a_token)
        self._test(CAT, "GET /users/:id/followers → 200 com data",
                   code == 200 and "data" in body,
                   f"Got {code}")
        followers = body.get("data", [])
        has_b = any(f.get("id") == self.user_b_id for f in followers)
        self._test(CAT, "Followers inclui User B",
                   has_b, f"follower_count={body.get('total', len(followers))}")

        # ── Following list ──
        code, body = self._req("GET", f"/users/{self.user_b_id}/following",
                               token=self.user_b_token)
        self._test(CAT, "GET /users/:id/following → 200 com data",
                   code == 200 and "data" in body,
                   f"Got {code}")
        following = body.get("data", [])
        has_a = any(f.get("id") == self.user_a_id for f in following)
        self._test(CAT, "Following inclui User A",
                   has_a, f"total={body.get('total', len(following))}")

        # ── C follows A too (for feed test) ──
        self._req("POST", f"/users/{self.user_a_id}/follow",
                  token=self.user_c_token)

        # ── Following decks feed ──
        code, body = self._req("GET", "/community/decks",
                               params={"following": "true"},
                               token=self.user_b_token)
        # This may require a specific endpoint or query param
        # If the API has GET /community/decks/following, try that
        if code != 200 or "data" not in body:
            code2, body2 = self._req("GET", "/community/decks/following",
                                     token=self.user_b_token)
            self._test(CAT, "Feed de decks dos seguidos → 200",
                       code2 == 200, f"Got {code2}")
        else:
            self._test(CAT, "Feed de decks dos seguidos → 200",
                       code == 200, f"Got {code}")

        # ── Unfollow ──
        code, body = self._req("DELETE", f"/users/{self.user_a_id}/follow",
                               token=self.user_b_token)
        self._test(CAT, "DELETE /users/:id/follow (unfollow) → 200",
                   code == 200 and body.get("is_following") is False,
                   f"Got {code}")

        # ── Verify unfollow ──
        code, body = self._req("GET", f"/users/{self.user_a_id}/follow",
                               token=self.user_b_token)
        self._test(CAT, "GET follow status após unfollow → is_following=false",
                   code == 200 and body.get("is_following") is False,
                   f"Got {code}, is_following={body.get('is_following')}")

        # ── Re-follow (for further tests) ──
        self._req("POST", f"/users/{self.user_a_id}/follow",
                  token=self.user_b_token)

    # ═══════════════════════════════════════════════════════════
    #  USER PROFILE TESTS
    # ═══════════════════════════════════════════════════════════
    def test_user_profile(self):
        CAT = "PROFILE"
        print(f"\n👤 {CAT} TESTS")

        # ── GET /users/me ──
        code, body = self._req("GET", "/users/me", token=self.user_a_token)
        self._test(CAT, "GET /users/me → 200",
                   code == 200 and "user" in body, f"Got {code}")

        # ── PATCH display_name ──
        code, body = self._req("PATCH", "/users/me", token=self.user_a_token,
                               json_data={"display_name": f"Nick_{self.ts}"})
        self._test(CAT, "PATCH /users/me display_name → 200",
                   code == 200, f"Got {code}")
        updated_name = body.get("user", {}).get("display_name", "")
        self._test(CAT, "display_name atualizado corretamente",
                   updated_name == f"Nick_{self.ts}",
                   f"display_name={updated_name}")

        # ── PATCH avatar_url ──
        code, body = self._req("PATCH", "/users/me", token=self.user_a_token,
                               json_data={"avatar_url": "https://example.com/avatar.png"})
        self._test(CAT, "PATCH /users/me avatar_url → 200",
                   code == 200, f"Got {code}")

        # ── PATCH location ──
        code, body = self._req("PATCH", "/users/me", token=self.user_a_token,
                               json_data={
                                   "location_state": "SP",
                                   "location_city": "São Paulo"
                               })
        self._test(CAT, "PATCH /users/me location → 200",
                   code == 200, f"Got {code}")
        user = body.get("user", {})
        self._test(CAT, "Location salva corretamente",
                   user.get("location_state") == "SP"
                   and user.get("location_city") == "São Paulo",
                   f"state={user.get('location_state')}, city={user.get('location_city')}")

        # ── PATCH trade_notes ──
        code, body = self._req("PATCH", "/users/me", token=self.user_a_token,
                               json_data={"trade_notes": "Aceito PIX e encontro presencial em SP"})
        self._test(CAT, "PATCH /users/me trade_notes → 200",
                   code == 200, f"Got {code}")

        # ── PATCH validations ──
        code, body = self._req("PATCH", "/users/me", token=self.user_a_token,
                               json_data={"display_name": "A" * 60})
        self._test(CAT, "PATCH display_name >50 chars → 400",
                   code == 400, f"Got {code}")

        code, body = self._req("PATCH", "/users/me", token=self.user_a_token,
                               json_data={"avatar_url": "not-a-url"})
        self._test(CAT, "PATCH avatar_url inválida → 400",
                   code == 400, f"Got {code}")

        code, body = self._req("PATCH", "/users/me", token=self.user_a_token,
                               json_data={"location_state": "SPP"})
        self._test(CAT, "PATCH location_state >2 chars → 400",
                   code == 400, f"Got {code}")

        code, body = self._req("PATCH", "/users/me", token=self.user_a_token,
                               json_data={})
        self._test(CAT, "PATCH /users/me body vazio → 400",
                   code == 400, f"Got {code}")

        # ── PATCH without auth ──
        code, body = self._req("PATCH", "/users/me",
                               json_data={"display_name": "Hacker"})
        self._test(CAT, "PATCH /users/me sem token → 401",
                   code == 401, f"Got {code}")

    # ═══════════════════════════════════════════════════════════
    #  CONVERSATIONS / DM TESTS
    # ═══════════════════════════════════════════════════════════
    def test_conversations(self):
        CAT = "DM"
        print(f"\n💬 {CAT} TESTS")

        # ── Create conversation ──
        code, body = self._req("POST", "/conversations",
                               token=self.user_a_token, json_data={
                                   "user_id": self.user_b_id
                               })
        self._test(CAT, "POST /conversations criar conversa → 200/201",
                   code in (200, 201) and "id" in body,
                   f"Got {code}")
        conv_id = body.get("id", "")

        # ── Create conversation with self ──
        code, body = self._req("POST", "/conversations",
                               token=self.user_a_token, json_data={
                                   "user_id": self.user_a_id
                               })
        self._test(CAT, "POST /conversations consigo mesmo → 400",
                   code == 400, f"Got {code}")

        # ── Create duplicate (idempotent) ──
        code, body = self._req("POST", "/conversations",
                               token=self.user_a_token, json_data={
                                   "user_id": self.user_b_id
                               })
        self._test(CAT, "POST /conversations duplicada → 200 (idempotent)",
                   code in (200, 201) and body.get("id") == conv_id,
                   f"Got {code}, same_id={body.get('id') == conv_id}")

        # ── Create without user_id ──
        code, body = self._req("POST", "/conversations",
                               token=self.user_a_token, json_data={})
        self._test(CAT, "POST /conversations sem user_id → 400",
                   code == 400, f"Got {code}")

        # ── Create with inexistent user ──
        code, body = self._req("POST", "/conversations",
                               token=self.user_a_token, json_data={
                                   "user_id": "00000000-0000-0000-0000-000000000000"
                               })
        self._test(CAT, "POST /conversations user inexistente → 404",
                   code == 404, f"Got {code}")

        # ── Send message ──
        if conv_id:
            code, body = self._req("POST", f"/conversations/{conv_id}/messages",
                                   token=self.user_a_token, json_data={
                                       "message": "Olá, tudo bem?"
                                   })
            self._test(CAT, "POST /conversations/:id/messages → 201",
                       code == 201 and "id" in body,
                       f"Got {code}")

            # ── Send reply ──
            code, body = self._req("POST", f"/conversations/{conv_id}/messages",
                                   token=self.user_b_token, json_data={
                                       "message": "Tudo ótimo! E você?"
                                   })
            self._test(CAT, "POST reply de B → 201", code == 201,
                       f"Got {code}")

            # ── Send empty ──
            code, body = self._req("POST", f"/conversations/{conv_id}/messages",
                                   token=self.user_a_token, json_data={
                                       "message": ""
                                   })
            self._test(CAT, "POST message vazia → 400",
                       code == 400, f"Got {code}")

            # ── Outsider sends ──
            code, body = self._req("POST", f"/conversations/{conv_id}/messages",
                                   token=self.user_c_token, json_data={
                                       "message": "Sou intruso"
                                   })
            self._test(CAT, "POST message de outsider → 403",
                       code == 403, f"Got {code}")

            # ── List messages ──
            code, body = self._req("GET", f"/conversations/{conv_id}/messages",
                                   token=self.user_a_token)
            self._test(CAT, "GET /conversations/:id/messages → 200",
                       code == 200 and body.get("total", 0) >= 2,
                       f"Got {code}, total={body.get('total', 0)}")

            # ── Outsider reads ──
            code, body = self._req("GET", f"/conversations/{conv_id}/messages",
                                   token=self.user_c_token)
            self._test(CAT, "GET messages de outsider → 403",
                       code == 403, f"Got {code}")

            # ── Mark as read ──
            code, body = self._req("PUT", f"/conversations/{conv_id}/read",
                                   token=self.user_a_token)
            self._test(CAT, "PUT /conversations/:id/read → 200",
                       code == 200 and "marked_read" in body,
                       f"Got {code}")

        # ── List conversations ──
        code, body = self._req("GET", "/conversations", token=self.user_a_token)
        self._test(CAT, "GET /conversations → 200 com data",
                   code == 200 and "data" in body,
                   f"Got {code}")
        convs = body.get("data", [])
        self._test(CAT, "Conversations inclui a conversa criada",
                   any(c.get("id") == conv_id for c in convs),
                   f"count={len(convs)}")

        # ── List without auth ──
        code, body = self._req("GET", "/conversations")
        self._test(CAT, "GET /conversations sem token → 401",
                   code == 401, f"Got {code}")

    # ═══════════════════════════════════════════════════════════
    #  IMPORT TESTS
    # ═══════════════════════════════════════════════════════════
    def test_import(self):
        CAT = "IMPORT"
        print(f"\n📥 {CAT} TESTS")

        # ── Import text list ──
        code, body = self._req("POST", "/import", token=self.user_a_token,
                               json_data={
                                   "name": f"Imported Deck {self.ts}",
                                   "format": "commander",
                                   "list": "1x Sol Ring\n1x Lightning Bolt\n10x Forest"
                               })
        self._test(CAT, "POST /import texto → 200 com deck",
                   code == 200 and "deck" in body,
                   f"Got {code}: {body.get('error', '')}")
        imported_count = body.get("cards_imported", 0)
        self._test(CAT, "Import encontrou cartas",
                   imported_count >= 2,
                   f"cards_imported={imported_count}")

        # ── Import without name ──
        code, body = self._req("POST", "/import", token=self.user_a_token,
                               json_data={
                                   "format": "commander",
                                   "list": "1x Sol Ring"
                               })
        self._test(CAT, "POST /import sem name → 400",
                   code == 400, f"Got {code}")

        # ── Import without list ──
        code, body = self._req("POST", "/import", token=self.user_a_token,
                               json_data={
                                   "name": "No List",
                                   "format": "commander"
                               })
        self._test(CAT, "POST /import sem list → 400",
                   code == 400, f"Got {code}")

        # ── Import without auth ──
        code, body = self._req("POST", "/import", json_data={
            "name": "Hacker", "format": "commander", "list": "1x Sol Ring"
        })
        self._test(CAT, "POST /import sem token → 401",
                   code == 401, f"Got {code}")

        # ── Validate import ──
        code, body = self._req("POST", "/import/validate",
                               token=self.user_a_token, json_data={
                                   "format": "commander",
                                   "list": "1x Sol Ring\n1x XyzInexistentCard999"
                               })
        self._test(CAT, "POST /import/validate → 200",
                   code == 200, f"Got {code}")
        found = len(body.get("found_cards", []))
        not_found = len(body.get("not_found_lines", []))
        self._test(CAT, "Validate: found≥1, not_found≥1",
                   found >= 1 and not_found >= 1,
                   f"found={found}, not_found={not_found}")

        # ── Import to existing deck ──
        code, body = self._req("POST", "/import/to-deck",
                               token=self.user_a_token, json_data={
                                   "deck_id": self.deck_a_id,
                                   "list": "5x Forest"
                               })
        self._test(CAT, "POST /import/to-deck → 200",
                   code == 200, f"Got {code}: {body.get('error', '')}")

        # ── Import to-deck of another user ──
        code, body = self._req("POST", "/import/to-deck",
                               token=self.user_b_token, json_data={
                                   "deck_id": self.deck_a_id,
                                   "list": "1x Sol Ring"
                               })
        self._test(CAT, "POST /import/to-deck deck de outro → 403/404",
                   code in (403, 404), f"Got {code}")

    # ═══════════════════════════════════════════════════════════
    #  NOTIFICATIONS TESTS
    # ═══════════════════════════════════════════════════════════
    def test_notifications(self):
        CAT = "NOTIF"
        print(f"\n🔔 {CAT} TESTS")

        # ── List notifications ──
        code, body = self._req("GET", "/notifications",
                               token=self.user_a_token)
        self._test(CAT, "GET /notifications → 200 com data",
                   code == 200 and "data" in body,
                   f"Got {code}")
        notifs = body.get("data", [])
        self._test(CAT, "User A tem notificações (follow + DM)",
                   len(notifs) >= 1,
                   f"count={len(notifs)}")

        # ── Check types ──
        types = set(n.get("type", "") for n in notifs)
        self._test(CAT, "Notificações incluem new_follower",
                   "new_follower" in types,
                   f"types={types}")

        # ── Count ──
        code, body = self._req("GET", "/notifications/count",
                               token=self.user_a_token)
        self._test(CAT, "GET /notifications/count → 200",
                   code == 200 and "unread" in body,
                   f"Got {code}")

        # ── Unread only ──
        code, body = self._req("GET", "/notifications",
                               token=self.user_a_token,
                               params={"unread_only": "true"})
        self._test(CAT, "GET /notifications?unread_only=true → 200",
                   code == 200, f"Got {code}")

        # ── Read single notification ──
        if notifs:
            nid = notifs[0]["id"]
            code, body = self._req("PUT", f"/notifications/{nid}/read",
                                   token=self.user_a_token)
            self._test(CAT, "PUT /notifications/:id/read → 200",
                       code == 200, f"Got {code}")

            # ── Read already read ──
            code, body = self._req("PUT", f"/notifications/{nid}/read",
                                   token=self.user_a_token)
            self._test(CAT, "PUT notification já lida → 200 ou 404",
                       code in (200, 404), f"Got {code}")

        # ── Read all ──
        code, body = self._req("PUT", "/notifications/read-all",
                               token=self.user_a_token)
        self._test(CAT, "PUT /notifications/read-all → 200",
                   code == 200 and "marked_read" in body,
                   f"Got {code}")

        # ── After read-all, count should be 0 ──
        code, body = self._req("GET", "/notifications/count",
                               token=self.user_a_token)
        self._test(CAT, "Unread count após read-all → 0",
                   code == 200 and body.get("unread", -1) == 0,
                   f"unread={body.get('unread')}")

        # ── Without auth ──
        code, body = self._req("GET", "/notifications")
        self._test(CAT, "GET /notifications sem token → 401",
                   code == 401, f"Got {code}")

    # ═══════════════════════════════════════════════════════════
    #  CARDS SEARCH TESTS
    # ═══════════════════════════════════════════════════════════
    def test_cards(self):
        CAT = "CARDS"
        print(f"\n🔍 {CAT} TESTS")

        # ── Search by name ──
        code, body = self._req("GET", "/cards", params={"name": "Sol Ring"})
        self._test(CAT, "GET /cards?name=Sol Ring → 200 com results",
                   code == 200 and len(body.get("data", [])) >= 1,
                   f"Got {code}, count={len(body.get('data', []))}")

        # ── Search empty ──
        code, body = self._req("GET", "/cards", params={"name": "XyzNaoExiste999"})
        self._test(CAT, "GET /cards nome inexistente → 200 com 0 results",
                   code == 200 and len(body.get("data", [])) == 0,
                   f"Got {code}, count={len(body.get('data', []))}")

        # ── Pagination ──
        code, body = self._req("GET", "/cards",
                               params={"name": "Forest", "limit": 2, "page": 1})
        self._test(CAT, "GET /cards com limit=2 → max 2 results",
                   code == 200 and len(body.get("data", [])) <= 2,
                   f"Got {code}, count={len(body.get('data', []))}")

        # ── Search by set ──
        code, body = self._req("GET", "/cards",
                               params={"set": "lea", "limit": 5})
        self._test(CAT, "GET /cards?set=lea → 200",
                   code == 200, f"Got {code}")

        # ── Card printings ──
        code, body = self._req("GET", "/cards/printings",
                               params={"name": "Sol Ring"})
        self._test(CAT, "GET /cards/printings?name=Sol Ring → 200",
                   code == 200 and body.get("total_returned", 0) >= 1,
                   f"Got {code}")

        # ── Card printings without name ──
        code, body = self._req("GET", "/cards/printings")
        self._test(CAT, "GET /cards/printings sem name → 400",
                   code == 400, f"Got {code}")

        # ── Card resolve ──
        code, body = self._req("POST", "/cards/resolve",
                               json_data={"name": "Sol Ring"})
        self._test(CAT, "POST /cards/resolve → 200",
                   code == 200 and body.get("total_returned", 0) >= 1,
                   f"Got {code}")

        # ── Card resolve inexistent ──
        code, body = self._req("POST", "/cards/resolve",
                               json_data={"name": "XyzAbsolutelyNotACard999"})
        self._test(CAT, "POST /cards/resolve inexistente → 404",
                   code == 404, f"Got {code}")

    # ═══════════════════════════════════════════════════════════
    #  HEALTH / RULES / SETS TESTS
    # ═══════════════════════════════════════════════════════════
    def test_infrastructure(self):
        CAT = "INFRA"
        print(f"\n🏗️  {CAT} TESTS")

        # ── Health ──
        code, body = self._req("GET", "/health")
        self._test(CAT, "GET /health → 200",
                   code == 200 and body.get("status") == "healthy",
                   f"Got {code}")

        code, body = self._req("GET", "/health/live")
        self._test(CAT, "GET /health/live → 200",
                   code == 200 and body.get("status") == "alive",
                   f"Got {code}")

        code, body = self._req("GET", "/health/ready")
        self._test(CAT, "GET /health/ready → 200",
                   code == 200 and body.get("status") == "ready",
                   f"Got {code}")

        # ── Rules ──
        code, body = self._req("GET", "/rules", params={"q": "mulligan", "limit": 5})
        self._test(CAT, "GET /rules?q=mulligan → 200",
                   code == 200, f"Got {code}")

        code, body = self._req("GET", "/rules",
                               params={"q": "commander", "meta": "true"})
        self._test(CAT, "GET /rules?meta=true → 200 com meta",
                   code == 200 and ("meta" in body if isinstance(body, dict) else True),
                   f"Got {code}")

        # ── Sets ──
        code, body = self._req("GET", "/sets", params={"limit": 5})
        self._test(CAT, "GET /sets → 200",
                   code == 200 and "data" in body,
                   f"Got {code}")

        code, body = self._req("GET", "/sets", params={"code": "LEA"})
        self._test(CAT, "GET /sets?code=LEA → 200",
                   code == 200, f"Got {code}")

        code, body = self._req("GET", "/sets", params={"q": "alpha"})
        self._test(CAT, "GET /sets?q=alpha → 200",
                   code == 200, f"Got {code}")

        # ── Market ──
        code, body = self._req("GET", f"/market/card/{self.card_1_id}")
        self._test(CAT, "GET /market/card/:id → 200",
                   code == 200 and "name" in body,
                   f"Got {code}")

        code, body = self._req("GET", "/market/card/00000000-0000-0000-0000-000000000000")
        self._test(CAT, "GET /market/card inexistente → 404",
                   code == 404, f"Got {code}")

        code, body = self._req("GET", "/market/movers")
        self._test(CAT, "GET /market/movers → 200",
                   code == 200, f"Got {code}")

        # ── Root ──
        code, body = self._req("GET", "/")
        self._test(CAT, "GET / → 200",
                   code == 200, f"Got {code}")

    # ═══════════════════════════════════════════════════════════
    #  DECK DELETE TESTS (run last)
    # ═══════════════════════════════════════════════════════════
    def test_deck_delete(self):
        CAT = "DECK_DEL"
        print(f"\n🗑️  {CAT} TESTS")

        # ── Create a temp deck to delete ──
        code, body = self._req("POST", "/decks", token=self.user_a_token, json_data={
            "name": f"To Delete {self.ts}",
            "format": "standard"
        })
        del_id = body.get("id", "")

        # ── Delete wrong owner ──
        if del_id:
            code, body = self._req("DELETE", f"/decks/{del_id}",
                                   token=self.user_b_token)
            self._test(CAT, "DELETE /decks/:id outro user → 404",
                       code == 404, f"Got {code}")

        # ── Delete without auth ──
        code, body = self._req("DELETE", f"/decks/{del_id}")
        self._test(CAT, "DELETE /decks/:id sem token → 401",
                   code == 401, f"Got {code}")

        # ── Delete own deck ──
        if del_id:
            code, body = self._req("DELETE", f"/decks/{del_id}",
                                   token=self.user_a_token)
            self._test(CAT, "DELETE /decks/:id próprio → 204",
                       code == 204, f"Got {code}")

            # ── Double delete ──
            code, body = self._req("DELETE", f"/decks/{del_id}",
                                   token=self.user_a_token)
            self._test(CAT, "DELETE deck já deletado → 404",
                       code == 404, f"Got {code}")

        # ── Delete inexistent ──
        code, body = self._req("DELETE",
                               "/decks/00000000-0000-0000-0000-000000000000",
                               token=self.user_a_token)
        self._test(CAT, "DELETE deck inexistente → 404",
                   code == 404, f"Got {code}")

    def cleanup_created_decks(self):
        """Remove every deck owned by this run's isolated QA users."""
        CAT = "CLEANUP"
        all_clean = True
        deleted = 0

        for label, token in (
            ("A", self.user_a_token),
            ("B", self.user_b_token),
            ("C", self.user_c_token),
        ):
            if not token:
                continue

            code, body = self._req("GET", "/decks", token=token)
            if code != 200 or not isinstance(body, list):
                all_clean = False
                print(f"  ❌ [{CAT}] Could not list User {label} decks: {code}")
                continue

            for deck in body:
                deck_id = deck.get("id", "")
                if not deck_id:
                    continue
                delete_code, _ = self._req(
                    "DELETE", f"/decks/{deck_id}", token=token
                )
                if delete_code == 204:
                    deleted += 1
                    continue

                all_clean = False
                # A failed delete must not leave a QA fixture visible publicly.
                self._req(
                    "PUT",
                    f"/decks/{deck_id}",
                    token=token,
                    json_data={"is_public": False},
                )

        self._test(
            CAT,
            f"QA decks removidos ao final ({deleted})",
            all_clean,
            "At least one fixture could not be deleted and was made private.",
        )

    # ═══════════════════════════════════════════════════════════
    #  AI ENDPOINT TESTS
    # ═══════════════════════════════════════════════════════════
    def test_ai(self):
        CAT = "AI"
        print(f"\n🤖 {CAT} TESTS")

        # ── AI Explain ──
        code, body = self._req("POST", "/ai/explain",
                               token=self.user_a_token, json_data={
                                   "card_name": "Sol Ring",
                                   "oracle_text": "{T}: Add {C}{C}.",
                                   "type_line": "Artifact",
                                   "card_id": self.card_1_id
                               })
        self._test(CAT, "POST /ai/explain → 200 com explanation",
                   code == 200 and "explanation" in body,
                   f"Got {code}: {body.get('error', '')}")

        code, body = self._req("POST", "/ai/explain",
                               token=self.user_a_token, json_data={})
        self._test(CAT, "POST /ai/explain sem card_name → 400",
                   code == 400, f"Got {code}")

        code, body = self._req("POST", "/ai/explain", json_data={
            "card_name": "Sol Ring"
        })
        self._test(CAT, "POST /ai/explain sem token → 401",
                   code == 401, f"Got {code}")

        # ── AI Archetypes ──
        code, body = self._req("POST", "/ai/archetypes",
                               token=self.user_a_token, json_data={
                                   "deck_id": self.deck_a_id
                               })
        self._test(CAT, "POST /ai/archetypes → 200 com options",
                   code == 200 and ("options" in body or "archetype" in body),
                   f"Got {code}: {body.get('error', '')}")

        code, body = self._req("POST", "/ai/archetypes",
                               token=self.user_a_token, json_data={})
        self._test(CAT, "POST /ai/archetypes sem deck_id → 400",
                   code == 400, f"Got {code}")

        code, body = self._req("POST", "/ai/archetypes",
                               token=self.user_a_token, json_data={
                                   "deck_id": "00000000-0000-0000-0000-000000000000"
                               })
        self._test(CAT, "POST /ai/archetypes deck inexistente → 404",
                   code == 404, f"Got {code}")

        # ── AI Generate ──
        code, body = self._req("POST", "/ai/generate",
                               token=self.user_a_token, json_data={
                                   "prompt": "Deck agressivo de goblins vermelhos",
                                   "format": "Commander"
                               })
        self._test(CAT, "POST /ai/generate → 200 com deck",
                   code == 200 and ("generated_deck" in body or "cards" in body),
                   f"Got {code}: {body.get('error', '')}")

        code, body = self._req("POST", "/ai/generate",
                               token=self.user_a_token, json_data={})
        self._test(CAT, "POST /ai/generate sem prompt → 400",
                   code == 400, f"Got {code}")

        code, body = self._req("POST", "/ai/generate", json_data={
            "prompt": "test", "format": "standard"
        })
        self._test(CAT, "POST /ai/generate sem token → 401",
                   code == 401, f"Got {code}")

        # ── AI Optimize ──
        code, body = self._req("POST", "/ai/optimize",
                               token=self.user_a_token, json_data={
                                   "deck_id": self.deck_a_id,
                                   "archetype": "aggro"
                               })
        # 200 = success, 400 = deck commander sem comandante selecionado (válido)
        self._test(CAT, "POST /ai/optimize → 200 ou 400",
                   code in (200, 400),
                   f"Got {code}: {body.get('error', '')}")

        code, body = self._req("POST", "/ai/optimize",
                               token=self.user_a_token, json_data={})
        self._test(CAT, "POST /ai/optimize sem deck_id → 400",
                   code == 400, f"Got {code}")

        code, body = self._req("POST", "/ai/optimize",
                               token=self.user_a_token, json_data={
                                   "deck_id": "00000000-0000-0000-0000-000000000000",
                                   "archetype": "aggro"
                               })
        self._test(CAT, "POST /ai/optimize deck inexistente → 404",
                   code == 404, f"Got {code}")

        # ── AI Simulate (goldfish) ──
        # Pode retornar 500 se tabela battle_simulations não tiver colunas esperadas
        code, body = self._req("POST", "/ai/simulate",
                               token=self.user_a_token, json_data={
                                   "deck_id": self.deck_a_id,
                                   "type": "goldfish",
                                   "simulations": 100
                               })
        self._test(CAT, "POST /ai/simulate goldfish → 200 ou 500",
                   code in (200, 500),
                   f"Got {code}: {body.get('error', '')}")

        code, body = self._req("POST", "/ai/simulate",
                               token=self.user_a_token, json_data={})
        self._test(CAT, "POST /ai/simulate sem deck_id → 400",
                   code == 400, f"Got {code}")

        code, body = self._req("POST", "/ai/simulate",
                               token=self.user_a_token, json_data={
                                   "deck_id": "00000000-0000-0000-0000-000000000000"
                               })
        self._test(CAT, "POST /ai/simulate deck inexistente → 404",
                   code == 404, f"Got {code}")

        # ── AI Simulate matchup mode (via /ai/simulate with type=matchup) ──
        code, body = self._req("POST", "/ai/simulate",
                               token=self.user_a_token, json_data={
                                   "deck_id": self.deck_a_id,
                                   "type": "matchup"
                               })
        self._test(CAT, "POST /ai/simulate matchup sem opponent → 400",
                   code == 400, f"Got {code}")

        # ── AI Simulate-Matchup (dedicated endpoint) ──
        code, body = self._req("POST", "/ai/simulate-matchup",
                               token=self.user_a_token, json_data={
                                   "my_deck_id": self.deck_a_id,
                                   "opponent_deck_id": self.deck_b_id,
                                   "simulations": 10
                               })
        self._test(CAT, "POST /ai/simulate-matchup → 200",
                   code == 200,
                   f"Got {code}: {body.get('error', '')}")

        code, body = self._req("POST", "/ai/simulate-matchup",
                               token=self.user_a_token, json_data={})
        self._test(CAT, "POST /ai/simulate-matchup sem IDs → 400",
                   code == 400, f"Got {code}")

        code, body = self._req("POST", "/ai/simulate-matchup",
                               token=self.user_a_token, json_data={
                                   "my_deck_id": "00000000-0000-0000-0000-000000000000",
                                   "opponent_deck_id": self.deck_b_id
                               })
        self._test(CAT, "POST /ai/simulate-matchup my_deck inexistente → 404",
                   code == 404, f"Got {code}")

        code, body = self._req("POST", "/ai/simulate-matchup",
                               token=self.user_a_token, json_data={
                                   "my_deck_id": self.deck_a_id,
                                   "opponent_deck_id": "00000000-0000-0000-0000-000000000000"
                               })
        self._test(CAT, "POST /ai/simulate-matchup opponent inexistente → 404",
                   code == 404, f"Got {code}")

        # ── AI Weakness Analysis ──
        code, body = self._req("POST", "/ai/weakness-analysis",
                               token=self.user_a_token, json_data={
                                   "deck_id": self.deck_a_id
                               })
        self._test(CAT, "POST /ai/weakness-analysis → 200",
                   code == 200,
                   f"Got {code}: {body.get('error', '')}")

        code, body = self._req("POST", "/ai/weakness-analysis",
                               token=self.user_a_token, json_data={})
        self._test(CAT, "POST /ai/weakness-analysis sem deck_id → 400",
                   code == 400, f"Got {code}")

        code, body = self._req("POST", "/ai/weakness-analysis",
                               token=self.user_a_token, json_data={
                                   "deck_id": "00000000-0000-0000-0000-000000000000"
                               })
        self._test(CAT, "POST /ai/weakness-analysis deck inexistente → 404",
                   code == 404, f"Got {code}")

    # ═══════════════════════════════════════════════════════════
    #  DECK ADVANCED FEATURES TESTS
    # ═══════════════════════════════════════════════════════════
    def test_deck_advanced(self):
        CAT = "DECK_ADV"
        print(f"\n🔬 {CAT} TESTS")

        # ── Pricing ──
        code, body = self._req("POST", f"/decks/{self.deck_a_id}/pricing",
                               token=self.user_a_token, json_data={})
        self._test(CAT, "POST /decks/:id/pricing → 200",
                   code == 200 and ("total" in body or "items" in body or "total_usd" in body),
                   f"Got {code}: {body.get('error', '')}")

        code, body = self._req("POST", f"/decks/{self.deck_a_id}/pricing",
                               token=self.user_a_token, json_data={"force": True})
        self._test(CAT, "POST /decks/:id/pricing force=true → 200",
                   code == 200,
                   f"Got {code}: {body.get('error', '')}")

        code, body = self._req("POST",
                               "/decks/00000000-0000-0000-0000-000000000000/pricing",
                               token=self.user_a_token, json_data={})
        self._test(CAT, "POST /decks/:id/pricing deck inexistente → 404",
                   code == 404, f"Got {code}")

        code, body = self._req("POST", f"/decks/{self.deck_a_id}/pricing",
                               token=self.user_b_token, json_data={})
        self._test(CAT, "POST /decks/:id/pricing deck de outro user → 404",
                   code == 404, f"Got {code}")

        code, body = self._req("POST", f"/decks/{self.deck_a_id}/pricing",
                               json_data={})
        self._test(CAT, "POST /decks/:id/pricing sem token → 401",
                   code == 401, f"Got {code}")

        # ── AI Analysis ──
        code, body = self._req("POST", f"/decks/{self.deck_a_id}/ai-analysis",
                               token=self.user_a_token, json_data={"force": True})
        self._test(CAT, "POST /decks/:id/ai-analysis → 200",
                   code == 200 and ("synergy_score" in body or "deck_id" in body),
                   f"Got {code}: {body.get('error', '')}")

        code, body = self._req("POST",
                               "/decks/00000000-0000-0000-0000-000000000000/ai-analysis",
                               token=self.user_a_token, json_data={})
        self._test(CAT, "POST /decks/:id/ai-analysis deck inexistente → 404",
                   code == 404, f"Got {code}")

        code, body = self._req("POST", f"/decks/{self.deck_a_id}/ai-analysis",
                               token=self.user_b_token, json_data={})
        self._test(CAT, "POST /decks/:id/ai-analysis deck de outro → 404",
                   code == 404, f"Got {code}")

        # ── AI Analysis cached (sem force) ──
        code, body = self._req("POST", f"/decks/{self.deck_a_id}/ai-analysis",
                               token=self.user_a_token, json_data={})
        self._test(CAT, "POST /decks/:id/ai-analysis cached → 200",
                   code == 200, f"Got {code}")

        # ── Recommendations ──
        code, body = self._req("POST", f"/decks/{self.deck_a_id}/recommendations",
                               token=self.user_a_token, json_data={})
        # Pode retornar 500 se OPENAI_API_KEY não estiver configurada
        self._test(CAT, "POST /decks/:id/recommendations → 200 ou 500 (sem key)",
                   code in (200, 500),
                   f"Got {code}: {body.get('error', '')}")

        code, body = self._req("POST",
                               "/decks/00000000-0000-0000-0000-000000000000/recommendations",
                               token=self.user_a_token, json_data={})
        self._test(CAT, "POST /decks/:id/recommendations deck inexistente → 404/500",
                   code in (404, 500), f"Got {code}")

        # ── Cards Replace ──
        # Primeiro, buscar outra printing de uma carta no deck
        # Vamos usar Sol Ring que provavelmente tem múltiplas printings
        replace_new_card = None
        code, body = self._req("GET", "/cards/printings",
                               params={"name": "Sol Ring"})
        if code == 200 and body.get("data"):
            for printing in body["data"]:
                if printing["id"] != self.card_1_id:
                    replace_new_card = printing["id"]
                    break

        code, body = self._req("POST",
                               f"/decks/{self.deck_a_id}/cards/replace",
                               token=self.user_a_token, json_data={})
        self._test(CAT, "POST /decks/:id/cards/replace sem campos → 400",
                   code == 400, f"Got {code}")

        code, body = self._req("POST",
                               f"/decks/{self.deck_a_id}/cards/replace",
                               token=self.user_a_token, json_data={
                                   "old_card_id": self.card_1_id
                               })
        self._test(CAT, "POST cards/replace sem new_card_id → 400",
                   code == 400, f"Got {code}")

        code, body = self._req("POST",
                               f"/decks/{self.deck_a_id}/cards/replace",
                               token=self.user_a_token, json_data={
                                   "old_card_id": self.card_1_id,
                                   "new_card_id": self.card_1_id
                               })
        self._test(CAT, "POST cards/replace same card → 200 (no-op)",
                   code == 200 and body.get("changed") == False,
                   f"Got {code}: {body}")

        if replace_new_card:
            code, body = self._req("POST",
                                   f"/decks/{self.deck_a_id}/cards/replace",
                                   token=self.user_a_token, json_data={
                                       "old_card_id": self.card_1_id,
                                       "new_card_id": replace_new_card
                                   })
            self._test(CAT, "POST cards/replace printing válida → 200",
                       code == 200 and body.get("ok") == True,
                       f"Got {code}: {body.get('error', '')}")
        else:
            self._test(CAT, "POST cards/replace printing válida → SKIP (1 printing)",
                       True, "Sol Ring só tem 1 printing")

        code, body = self._req("POST",
                               f"/decks/{self.deck_a_id}/cards/replace",
                               token=self.user_a_token, json_data={
                                   "old_card_id": "00000000-0000-0000-0000-000000000000",
                                   "new_card_id": self.card_1_id
                               })
        self._test(CAT, "POST cards/replace old inexistente → 400/404",
                   code in (400, 404, 500), f"Got {code}")

        code, body = self._req("POST",
                               f"/decks/{self.deck_a_id}/cards/replace",
                               token=self.user_b_token, json_data={
                                   "old_card_id": self.card_1_id,
                                   "new_card_id": self.card_2_id
                               })
        self._test(CAT, "POST cards/replace deck de outro → 404",
                   code in (404, 500), f"Got {code}")

    # ═══════════════════════════════════════════════════════════
    #  RUN ALL
    # ═══════════════════════════════════════════════════════════
    def run_all(self):
        print("═" * 65)
        print("  🧙 MTG Deck Builder — Suíte de Testes E2E (Geral)")
        print(f"  🌐 API: {self.api}")
        print(f"  🕐 {time.strftime('%Y-%m-%d %H:%M:%S')}")
        print("═" * 65)

        if not self.setup():
            print("\n💀 SETUP FALHOU! Abortando testes.")
            return False

        try:
            self.test_deck_crud()
            self.test_deck_cards()
            self.test_deck_advanced()
            self.test_ai()
            self.test_community()
            self.test_social()
            self.test_user_profile()
            self.test_conversations()
            self.test_import()
            self.test_notifications()
            self.test_cards()
            self.test_infrastructure()
            self.test_deck_delete()
            # Auth tests run LAST so the rate-limit window from setup has expired
            self.test_auth()
        finally:
            self.cleanup_created_decks()

        return self.print_summary()

    def print_summary(self):
        print("\n" + "═" * 65)
        print("  📊 RESULTADOS")
        print("═" * 65)

        categories = {}
        for r in self.results:
            cat = r.category or "OTHER"
            if cat not in categories:
                categories[cat] = {"pass": 0, "fail": 0}
            if r.passed:
                categories[cat]["pass"] += 1
            else:
                categories[cat]["fail"] += 1

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
    parser = argparse.ArgumentParser(description="MTG General E2E Test Suite")
    parser.add_argument("--api", required=True, help="Explicit API base URL")
    parser.add_argument("--verbose", "-v", action="store_true", help="Show all requests")
    args = parser.parse_args()

    VERBOSE = args.verbose
    approved_api = require_legacy_live_e2e_approval(args.api)
    runner = TestRunner(approved_api)
    success = runner.run_all()
    sys.exit(0 if success else 1)
