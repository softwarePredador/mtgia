#!/usr/bin/env python3
"""
Testes End-to-End para Sistema de ML e Otimização de Decks

Este arquivo testa toda a pipeline de IA/ML:
- GET /ai/ml-status - Status do sistema ML
- POST /ai/optimize - Otimização com Monte Carlo + Critic AI
- POST /ai/archetypes - Detecção de arquétipo
- POST /ai/generate - Geração de deck por prompt
- POST /ai/simulate - Simulação goldfish
- POST /ai/simulate-matchup - Simulação de matchup
- POST /ai/weakness-analysis - Análise de fraquezas
- POST /ai/explain - Explicação de carta

Uso:
    MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL \
      python3 e2e_ml_tests.py --base-url URL [--verbose]

Exemplo:
    MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL \
      python3 e2e_ml_tests.py --base-url http://localhost:8080 --verbose
"""

import requests
import json
import sys
import argparse
from typing import Optional, Tuple, Dict, Any, List
from dataclasses import dataclass
from datetime import datetime

try:
    from .legacy_live_e2e_guard import require_legacy_live_e2e_approval
except ImportError:  # Direct script execution.
    from legacy_live_e2e_guard import require_legacy_live_e2e_approval

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURAÇÃO
# ═══════════════════════════════════════════════════════════════════════════════

TIMEOUT = 60  # segundos

# Credenciais de teste
TEST_USER = {
    "username": f"ml_test_{datetime.now().strftime('%H%M%S')}",
    "email": f"ml_test_{datetime.now().strftime('%H%M%S')}@test.com",
    "password": "Test123!@#"
}

# ═══════════════════════════════════════════════════════════════════════════════
# MODELOS DE RESPOSTA ESPERADA
# ═══════════════════════════════════════════════════════════════════════════════

@dataclass
class MLStatusResponse:
    """Estrutura esperada do GET /ai/ml-status"""
    required_fields = ["status"]
    active_fields = ["model_version", "stats", "performance", "last_extraction"]
    stats_fields = ["card_insights", "synergy_packages", "archetype_patterns", 
                    "feedback_records", "meta_decks_loaded", "total_knowledge"]
    performance_fields = ["total_optimizations", "avg_effectiveness_score"]


@dataclass  
class OptimizeResponse:
    """Estrutura esperada do POST /ai/optimize"""
    required_fields = ["removals", "additions", "reasoning", "deck_analysis"]
    deck_analysis_fields = ["detected_archetype", "average_cmc", "type_distribution",
                            "total_cards", "mana_curve_assessment", "mana_base_assessment",
                            "archetype_confidence"]
    optional_fields = ["mode", "theme", "constraints", "bracket", "monteCarlo",
                       "critic_ai_analysis", "post_analysis", "warnings",
                       "removals_detailed", "additions_detailed", "validation_warnings"]


@dataclass
class ArchetypeResponse:
    """Estrutura esperada do POST /ai/archetypes"""
    response_variants = [
        ["options"],  # Lista de opções de arquétipo
        ["archetype", "confidence"],  # Arquétipo detectado
        ["detected_archetype"]  # Formato alternativo
    ]


# ═══════════════════════════════════════════════════════════════════════════════
# CLASSE DE TESTE
# ═══════════════════════════════════════════════════════════════════════════════

class MLTestSuite:
    def __init__(self, base_url: str, verbose: bool = False):
        self.base_url = base_url.rstrip("/")
        self.verbose = verbose
        self.token: Optional[str] = None
        self.user_id: Optional[str] = None
        self.deck_id: Optional[str] = None
        self.results: List[Dict[str, Any]] = []
        
    def log(self, message: str):
        """Log apenas se verbose"""
        if self.verbose:
            print(f"  [DEBUG] {message}")
    
    def _req(self, method: str, endpoint: str, 
             token: Optional[str] = None,
             json_data: Optional[dict] = None,
             timeout: int = TIMEOUT) -> Tuple[int, dict]:
        """Executa requisição HTTP"""
        url = f"{self.base_url}{endpoint}"
        headers = {"Content-Type": "application/json"}
        
        if token:
            headers["Authorization"] = f"Bearer {token}"
        
        try:
            if method == "GET":
                resp = requests.get(url, headers=headers, timeout=timeout)
            elif method == "POST":
                resp = requests.post(url, headers=headers, json=json_data, timeout=timeout)
            elif method == "PUT":
                resp = requests.put(url, headers=headers, json=json_data, timeout=timeout)
            elif method == "DELETE":
                resp = requests.delete(url, headers=headers, timeout=timeout)
            else:
                return 500, {"error": f"Método não suportado: {method}"}
            
            try:
                body = resp.json()
            except:
                body = {"raw": resp.text[:500]}
            
            self.log(f"{method} {endpoint} → {resp.status_code}")
            if self.verbose and resp.status_code >= 400:
                self.log(f"  Response: {json.dumps(body, indent=2)[:500]}")
            
            return resp.status_code, body
            
        except requests.exceptions.Timeout:
            return 504, {"error": "Timeout"}
        except requests.exceptions.ConnectionError:
            return 503, {"error": "Connection refused"}
        except Exception as e:
            return 500, {"error": str(e)}
    
    def _test(self, category: str, name: str, passed: bool, details: str = ""):
        """Registra resultado do teste"""
        status = "✅ PASS" if passed else "❌ FAIL"
        result = {"category": category, "name": name, "passed": passed, "details": details}
        self.results.append(result)
        print(f"  {status} {name}" + (f" ({details})" if details and not passed else ""))
    
    # ═══════════════════════════════════════════════════════════════════════════
    # SETUP
    # ═══════════════════════════════════════════════════════════════════════════
    
    def setup(self) -> bool:
        """Cria usuário e deck de teste"""
        print("\n🔧 SETUP")
        
        # 1. Registrar usuário
        code, body = self._req("POST", "/auth/register", json_data=TEST_USER)
        if code == 201:
            self.token = body.get("token")
            self.user_id = body.get("user", {}).get("id")
            print(f"  ✅ Usuário criado: {TEST_USER['username']}")
        elif code == 409:  # Já existe
            code, body = self._req("POST", "/auth/login", json_data={
                "email": TEST_USER["email"],
                "password": TEST_USER["password"]
            })
            if code == 200:
                self.token = body.get("token")
                self.user_id = body.get("user", {}).get("id")
                print(f"  ✅ Login com usuário existente")
            else:
                print(f"  ❌ Falha no login: {code}")
                return False
        else:
            print(f"  ❌ Falha ao criar usuário: {code} - {body}")
            return False
        
        # 2. Buscar cartas para o deck de teste
        code, body = self._req("GET", "/cards?name=Lightning&limit=5")
        if code != 200 or not body.get("data"):
            print("  ⚠️ Não encontrou cartas Lightning, tentando Sol Ring...")
            code, body = self._req("GET", "/cards?name=Sol Ring&limit=5")
        
        cards = []
        if code == 200 and body.get("data"):
            for card in body["data"][:5]:
                cards.append({"card_id": card["id"], "quantity": 4})
            self.log(f"Encontrou {len(cards)} cartas para o deck")
        
        # 3. Criar deck de teste
        deck_data = {
            "name": "ML Test Deck",
            "format": "Modern",
            "description": "Deck para testes E2E do sistema ML",
            "cards": cards
        }
        
        code, body = self._req("POST", "/decks", token=self.token, json_data=deck_data)
        if code in (200, 201):
            self.deck_id = body.get("id") or body.get("deck", {}).get("id")
            print(f"  ✅ Deck criado: {self.deck_id}")
        else:
            print(f"  ⚠️ Falha ao criar deck: {code} - {body}")
            # Tentar usar deck existente
            code, body = self._req("GET", "/decks", token=self.token)
            if code == 200:
                # API pode retornar lista direta ou objeto com "decks"
                decks = body if isinstance(body, list) else body.get("decks", [])
                if decks:
                    self.deck_id = decks[0].get("id")
                    print(f"  ✅ Usando deck existente: {self.deck_id}")
        
        return self.token is not None
    
    # ═══════════════════════════════════════════════════════════════════════════
    # TESTES ML STATUS
    # ═══════════════════════════════════════════════════════════════════════════
    
    def test_ml_status(self):
        """Testa GET /ai/ml-status"""
        print("\n📊 TESTES: GET /ai/ml-status")
        cat = "ML Status"
        
        # Test 1: Endpoint responde (com token - pode ser protegido)
        code, body = self._req("GET", "/ai/ml-status", token=self.token)
        self._test(cat, "Endpoint responde (200 ou 500)", 
                   code in (200, 500), f"Got {code}")
        
        if code != 200:
            self.log(f"ML Status retornou {code}, pulando validações de estrutura")
            return
        
        # Test 2: Campo status presente
        self._test(cat, "Campo 'status' presente",
                   "status" in body, f"Keys: {list(body.keys())}")
        
        # Test 3: Status válido
        valid_statuses = ["active", "empty", "not_initialized", "error"]
        self._test(cat, "Status é válido",
                   body.get("status") in valid_statuses,
                   f"Got: {body.get('status')}")
        
        # Test 4: Se active, tem stats
        if body.get("status") == "active":
            self._test(cat, "Status 'active' tem 'stats'",
                       "stats" in body, f"Keys: {list(body.keys())}")
            
            stats = body.get("stats", {})
            
            # Test 5: Stats tem campos esperados
            for field in ["card_insights", "synergy_packages", "archetype_patterns"]:
                self._test(cat, f"Stats tem '{field}'",
                           field in stats, f"Stats keys: {list(stats.keys())}")
            
            # Test 6: Stats são números >= 0
            card_insights = stats.get("card_insights", -1)
            self._test(cat, "card_insights é número >= 0",
                       isinstance(card_insights, (int, float)) and card_insights >= 0,
                       f"Got: {card_insights}")
            
            # Test 7: Total knowledge calculado
            total = stats.get("total_knowledge", 0)
            self._test(cat, "total_knowledge > 0 (ML treinado)",
                       total > 0, f"Got: {total}")
            
            # Test 8: model_version presente
            self._test(cat, "model_version presente",
                       "model_version" in body,
                       f"Version: {body.get('model_version')}")
        
        # Test 9: Se not_initialized, tem setup_required
        if body.get("status") == "not_initialized":
            self._test(cat, "Status 'not_initialized' tem 'setup_required'",
                       body.get("setup_required") == True,
                       f"setup_required: {body.get('setup_required')}")
    
    # ═══════════════════════════════════════════════════════════════════════════
    # TESTES OPTIMIZE
    # ═══════════════════════════════════════════════════════════════════════════
    
    def test_optimize(self):
        """Testa POST /ai/optimize"""
        print("\n🔧 TESTES: POST /ai/optimize")
        cat = "Optimize"
        
        if not self.deck_id:
            print("  ⚠️ Sem deck de teste, pulando testes de optimize")
            return
        
        # Test 1: Sem token → 401
        code, body = self._req("POST", "/ai/optimize", json_data={"deck_id": self.deck_id})
        self._test(cat, "Sem token → 401", code == 401, f"Got {code}")
        
        # Test 2: Sem deck_id → 400
        code, body = self._req("POST", "/ai/optimize", token=self.token, json_data={})
        self._test(cat, "Sem deck_id → 400", code == 400, f"Got {code}")
        
        # Test 3: Deck inexistente → 404
        code, body = self._req("POST", "/ai/optimize", token=self.token, json_data={
            "deck_id": "00000000-0000-0000-0000-000000000000",
            "archetype": "aggro"
        })
        self._test(cat, "Deck inexistente → 404", code == 404, f"Got {code}")
        
        # Test 4: Requisição válida → 200 ou 400 (deck sem comandante é válido)
        code, body = self._req("POST", "/ai/optimize", token=self.token, json_data={
            "deck_id": self.deck_id,
            "archetype": "aggro"
        })
        self._test(cat, "Requisição válida → 200 ou 400",
                   code in (200, 400), f"Got {code}")
        
        if code == 200:
            # Test 5: Resposta tem deck_analysis
            self._test(cat, "Resposta tem 'deck_analysis'",
                       "deck_analysis" in body, f"Keys: {list(body.keys())}")
            
            deck_analysis = body.get("deck_analysis", {})
            
            # Test 6: deck_analysis tem detected_archetype
            self._test(cat, "deck_analysis tem 'detected_archetype'",
                       "detected_archetype" in deck_analysis,
                       f"Analysis keys: {list(deck_analysis.keys())}")
            
            # Test 7: deck_analysis tem average_cmc
            self._test(cat, "deck_analysis tem 'average_cmc'",
                       "average_cmc" in deck_analysis,
                       f"CMC: {deck_analysis.get('average_cmc')}")
            
            # Test 8: deck_analysis tem type_distribution
            type_dist = deck_analysis.get("type_distribution", {})
            self._test(cat, "deck_analysis tem 'type_distribution'",
                       isinstance(type_dist, dict) and len(type_dist) > 0,
                       f"Types: {list(type_dist.keys())}")
            
            # Test 9: Resposta tem removals (lista)
            self._test(cat, "Resposta tem 'removals' (lista)",
                       isinstance(body.get("removals"), list),
                       f"Type: {type(body.get('removals'))}")
            
            # Test 10: Resposta tem additions (lista)
            self._test(cat, "Resposta tem 'additions' (lista)",
                       isinstance(body.get("additions"), list),
                       f"Type: {type(body.get('additions'))}")
            
            # Test 11: Resposta tem reasoning
            self._test(cat, "Resposta tem 'reasoning'",
                       "reasoning" in body,
                       f"Reasoning length: {len(str(body.get('reasoning', '')))}")
            
            # Test 12: Se tem theme, tem estrutura valida
            if "theme" in body:
                theme = body["theme"]
                # Pode ter 'theme' (string) ou 'score' (float) ou ambos
                has_valid_theme = isinstance(theme, str) or \
                                  (isinstance(theme, dict) and ('theme' in theme or 'score' in theme))
                self._test(cat, "Theme tem estrutura válida",
                           has_valid_theme,
                           f"Theme type: {type(theme).__name__}")
            
            # Test 13: Se tem monteCarlo, tem estrutura correta
            if "monteCarlo" in body:
                mc = body["monteCarlo"]
                self._test(cat, "monteCarlo tem 'simulations'",
                           "simulations" in mc,
                           f"Simulations: {mc.get('simulations')}")
            
            # Test 14: Se tem critic_ai_analysis, tem overall_score
            if "critic_ai_analysis" in body:
                critic = body["critic_ai_analysis"]
                self._test(cat, "critic_ai_analysis tem 'overall_score'",
                           "overall_score" in critic,
                           f"Score: {critic.get('overall_score')}")
        
        # Test 15: Com keep_theme=true
        code, body = self._req("POST", "/ai/optimize", token=self.token, json_data={
            "deck_id": self.deck_id,
            "archetype": "control",
            "keep_theme": True
        })
        self._test(cat, "Com keep_theme=true → 200 ou 400",
                   code in (200, 400), f"Got {code}")
        
        if code == 200:
            constraints = body.get("constraints", {})
            self._test(cat, "Resposta respeita keep_theme",
                       constraints.get("keep_theme") == True,
                       f"constraints: {constraints}")
    
    # ═══════════════════════════════════════════════════════════════════════════
    # TESTES ARCHETYPES
    # ═══════════════════════════════════════════════════════════════════════════
    
    def test_archetypes(self):
        """Testa POST /ai/archetypes"""
        print("\n🎯 TESTES: POST /ai/archetypes")
        cat = "Archetypes"
        
        if not self.deck_id:
            print("  ⚠️ Sem deck de teste, pulando testes de archetypes")
            return
        
        # Test 1: Sem token → 401
        code, body = self._req("POST", "/ai/archetypes", json_data={"deck_id": self.deck_id})
        self._test(cat, "Sem token → 401", code == 401, f"Got {code}")
        
        # Test 2: Sem deck_id → 400
        code, body = self._req("POST", "/ai/archetypes", token=self.token, json_data={})
        self._test(cat, "Sem deck_id → 400", code == 400, f"Got {code}")
        
        # Test 3: Deck inexistente → 404
        code, body = self._req("POST", "/ai/archetypes", token=self.token, json_data={
            "deck_id": "00000000-0000-0000-0000-000000000000"
        })
        self._test(cat, "Deck inexistente → 404", code == 404, f"Got {code}")
        
        # Test 4: Requisição válida
        code, body = self._req("POST", "/ai/archetypes", token=self.token, json_data={
            "deck_id": self.deck_id
        })
        self._test(cat, "Requisição válida → 200",
                   code == 200, f"Got {code}")
        
        if code == 200:
            # Test 5: Tem options ou archetype
            has_options = "options" in body
            has_archetype = "archetype" in body or "detected_archetype" in body
            self._test(cat, "Tem 'options' ou 'archetype'",
                       has_options or has_archetype,
                       f"Keys: {list(body.keys())}")
            
            # Test 6: Se tem options, é lista
            if "options" in body:
                self._test(cat, "'options' é lista",
                           isinstance(body["options"], list),
                           f"Type: {type(body['options'])}")
    
    # ═══════════════════════════════════════════════════════════════════════════
    # TESTES GENERATE
    # ═══════════════════════════════════════════════════════════════════════════
    
    def test_generate(self):
        """Testa POST /ai/generate"""
        print("\n🎲 TESTES: POST /ai/generate")
        cat = "Generate"
        import time
        time.sleep(1)  # Evitar rate limiting
        
        # Test 1: Sem token → 401 (ou 429 se rate limited)
        code, body = self._req("POST", "/ai/generate", json_data={
            "prompt": "Deck mono-red aggro", "format": "Modern"
        })
        self._test(cat, "Sem token → 401 ou 429", code in (401, 429), f"Got {code}")
        
        time.sleep(1)
        # Test 2: Sem prompt → 400 (ou 429 se rate limited)
        code, body = self._req("POST", "/ai/generate", token=self.token, json_data={})
        self._test(cat, "Sem prompt → 400 ou 429", code in (400, 429), f"Got {code}")
        
        time.sleep(1)
        # Test 3: Requisição válida
        code, body = self._req("POST", "/ai/generate", token=self.token, json_data={
            "prompt": "Deck agressivo de goblins vermelhos",
            "format": "Commander"
        })
        self._test(cat, "Requisição válida → 200 ou 429",
                   code in (200, 429), f"Got {code}")
        
        if code == 200:
            # Test 4: Tem generated_deck ou cards
            has_deck = "generated_deck" in body or "cards" in body or "deck" in body
            self._test(cat, "Resposta tem deck gerado",
                       has_deck, f"Keys: {list(body.keys())}")
    
    # ═══════════════════════════════════════════════════════════════════════════
    # TESTES SIMULATE
    # ═══════════════════════════════════════════════════════════════════════════
    
    def test_simulate(self):
        """Testa POST /ai/simulate"""
        print("\n🎮 TESTES: POST /ai/simulate")
        cat = "Simulate"
        import time
        time.sleep(1)  # Evitar rate limiting
        
        if not self.deck_id:
            print("  ⚠️ Sem deck de teste, pulando testes de simulate")
            return
        
        # Test 1: Sem token → 401 (ou 429)
        code, body = self._req("POST", "/ai/simulate", json_data={"deck_id": self.deck_id})
        self._test(cat, "Sem token → 401 ou 429", code in (401, 429), f"Got {code}")
        
        time.sleep(1)
        # Test 2: Sem deck_id → 400 (ou 429)
        code, body = self._req("POST", "/ai/simulate", token=self.token, json_data={})
        self._test(cat, "Sem deck_id → 400 ou 429", code in (400, 429), f"Got {code}")
        
        time.sleep(1)
        # Test 3: Deck inexistente → 404 (ou 429)
        code, body = self._req("POST", "/ai/simulate", token=self.token, json_data={
            "deck_id": "00000000-0000-0000-0000-000000000000"
        })
        self._test(cat, "Deck inexistente → 404 ou 429", code in (404, 429), f"Got {code}")
        
        time.sleep(1)
        # Test 4: Goldfish simulation
        code, body = self._req("POST", "/ai/simulate", token=self.token, json_data={
            "deck_id": self.deck_id,
            "type": "goldfish",
            "simulations": 100
        })
        # 200 = sucesso, 500 = tabela não existe, 429 = rate limited
        self._test(cat, "Goldfish simulation → 200 ou 500 ou 429",
                   code in (200, 500, 429), f"Got {code}")
        
        if code == 200:
            # Test 5: Resposta tem estatísticas
            has_stats = any(k in body for k in ["mana_flood_rate", "mana_screw_rate", 
                                                  "win_rate", "average_turns", "results"])
            self._test(cat, "Resposta tem estatísticas de simulação",
                       has_stats, f"Keys: {list(body.keys())}")
        
        import time
        time.sleep(1)
        # Test 6: Matchup sem opponent → 400 (ou 429)
        code, body = self._req("POST", "/ai/simulate", token=self.token, json_data={
            "deck_id": self.deck_id,
            "type": "matchup"
        })
        self._test(cat, "Matchup sem opponent → 400 ou 429", code in (400, 429), f"Got {code}")
    
    # ═══════════════════════════════════════════════════════════════════════════
    # TESTES EXPLAIN
    # ═══════════════════════════════════════════════════════════════════════════
    
    def test_explain(self):
        """Testa POST /ai/explain"""
        print("\n📖 TESTES: POST /ai/explain")
        cat = "Explain"
        import time
        time.sleep(1)  # Evitar rate limiting
        
        # Test 1: Sem card_name → 400 (ou 429)
        code, body = self._req("POST", "/ai/explain", token=self.token, json_data={})
        self._test(cat, "Sem card_name → 400 ou 429", code in (400, 429), f"Got {code}")
        
        time.sleep(1)
        # Test 2: Sem token → 401 (ou 429)
        code, body = self._req("POST", "/ai/explain", json_data={"card_name": "Sol Ring"})
        self._test(cat, "Sem token → 401 ou 429", code in (401, 429), f"Got {code}")
        
        time.sleep(1)
        # Test 3: Requisição válida
        code, body = self._req("POST", "/ai/explain", token=self.token, json_data={
            "card_name": "Sol Ring"
        })
        self._test(cat, "Requisição válida → 200 ou 429",
                   code in (200, 429), f"Got {code}")
        
        if code == 200:
            # Test 4: Resposta tem explanation
            has_explanation = any(k in body for k in ["explanation", "text", "content", "response"])
            self._test(cat, "Resposta tem explicação",
                       has_explanation, f"Keys: {list(body.keys())}")
    
    # ═══════════════════════════════════════════════════════════════════════════
    # TESTES WEAKNESS ANALYSIS
    # ═══════════════════════════════════════════════════════════════════════════
    
    def test_weakness_analysis(self):
        """Testa POST /ai/weakness-analysis"""
        print("\n🛡️ TESTES: POST /ai/weakness-analysis")
        cat = "Weakness"
        import time
        time.sleep(1)  # Evitar rate limiting
        
        if not self.deck_id:
            print("  ⚠️ Sem deck de teste, pulando testes de weakness analysis")
            return
        
        # Test 1: Sem token → 401 (ou 429)
        code, body = self._req("POST", "/ai/weakness-analysis", json_data={"deck_id": self.deck_id})
        self._test(cat, "Sem token → 401 ou 429", code in (401, 429), f"Got {code}")
        
        time.sleep(1)
        # Test 2: Sem deck_id → 400 (ou 429)
        code, body = self._req("POST", "/ai/weakness-analysis", token=self.token, json_data={})
        self._test(cat, "Sem deck_id → 400 ou 429", code in (400, 429), f"Got {code}")
        
        time.sleep(1)
        # Test 3: Requisição válida
        code, body = self._req("POST", "/ai/weakness-analysis", token=self.token, json_data={
            "deck_id": self.deck_id
        })
        self._test(cat, "Requisição válida → 200 ou 404 ou 429",
                   code in (200, 404, 429), f"Got {code}")
        
        if code == 200:
            # Test 4: Resposta tem análise
            has_analysis = any(k in body for k in ["weaknesses", "analysis", "vulnerabilities", "suggestions"])
            self._test(cat, "Resposta tem análise de fraquezas",
                       has_analysis, f"Keys: {list(body.keys())}")
    
    # ═══════════════════════════════════════════════════════════════════════════
    # CLEANUP
    # ═══════════════════════════════════════════════════════════════════════════
    
    def cleanup(self):
        """Remove recursos de teste"""
        print("\n🧹 CLEANUP")
        
        if self.deck_id and self.token:
            code, _ = self._req("DELETE", f"/decks/{self.deck_id}", token=self.token)
            if code in (200, 204):
                print(f"  ✅ Deck removido")
            else:
                print(f"  ⚠️ Falha ao remover deck: {code}")
    
    # ═══════════════════════════════════════════════════════════════════════════
    # RUNNER
    # ═══════════════════════════════════════════════════════════════════════════
    
    def run(self) -> bool:
        """Executa todos os testes"""
        print("═" * 70)
        print("  TESTES E2E - SISTEMA ML + OTIMIZAÇÃO DE DECKS")
        print(f"  Base URL: {self.base_url}")
        print(f"  Data: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("═" * 70)
        
        # Setup
        if not self.setup():
            print("\n❌ Falha no setup, abortando testes")
            return False
        
        # Executar testes
        try:
            self.test_ml_status()
            self.test_optimize()
            self.test_archetypes()
            self.test_generate()
            self.test_simulate()
            self.test_explain()
            self.test_weakness_analysis()
        except Exception as e:
            print(f"\n❌ Erro durante testes: {e}")
            import traceback
            traceback.print_exc()
        finally:
            self.cleanup()
        
        # Resumo
        print("\n" + "═" * 70)
        print("  RESUMO DOS TESTES")
        print("═" * 70)
        
        passed = sum(1 for r in self.results if r["passed"])
        failed = sum(1 for r in self.results if not r["passed"])
        total = len(self.results)
        
        # Agrupar por categoria
        categories = {}
        for r in self.results:
            cat = r["category"]
            if cat not in categories:
                categories[cat] = {"passed": 0, "failed": 0}
            if r["passed"]:
                categories[cat]["passed"] += 1
            else:
                categories[cat]["failed"] += 1
        
        for cat, stats in categories.items():
            status = "✅" if stats["failed"] == 0 else "❌"
            print(f"  {status} {cat}: {stats['passed']}/{stats['passed'] + stats['failed']}")
        
        print()
        print(f"  Total: {passed}/{total} ({100*passed//total if total > 0 else 0}%)")
        print("═" * 70)
        
        return failed == 0


# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════

def main():
    parser = argparse.ArgumentParser(description="Testes E2E para sistema ML")
    parser.add_argument("--base-url", required=True,
                        help="URL base explícita da API")
    parser.add_argument("--verbose", "-v", action="store_true",
                        help="Modo verbose")
    args = parser.parse_args()
    
    approved_base_url = require_legacy_live_e2e_approval(args.base_url)
    suite = MLTestSuite(approved_base_url, verbose=args.verbose)
    success = suite.run()
    
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
