#!/bin/bash
# Teste de fluxo: 3 decks diferentes

API="https://evolution-cartinhas.2ta7qx.easypanel.host"
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJkNTVjNzRjNi04ZTJlLTQ2ZDktODc1ZC0yMzY5ZmE3ZmMyNGYiLCJ1c2VybmFtZSI6ImRlY2t0ZXN0MTczOSIsImlhdCI6MTc3MDkyNDM0MiwiZXhwIjoxNzcxMDEwNzQyfQ.tEgJdsGI_OxXMac6UpAww_00Ch3cJbQ-FPxL5DiWHRA"

echo "══════════════════════════════════════════════════════════════"
echo "  TESTE DE FLUXO: 3 DECKS"
echo "══════════════════════════════════════════════════════════════"

# Buscar IDs de cartas
echo ""
echo "Buscando cartas..."
GOBLIN_IDS=$(curl -s "$API/cards?name=goblin&limit=8" | jq -r '.data[].id' | head -8)
COUNTER_IDS=$(curl -s "$API/cards?name=counterspell&limit=8" | jq -r '.data[].id' | head -8)
DRAGON_IDS=$(curl -s "$API/cards?name=dragon&limit=8" | jq -r '.data[].id' | head -8)

# Função para criar JSON de cartas
make_cards_json() {
    local ids="$1"
    local qty="$2"
    local result="["
    local first=true
    for id in $ids; do
        if [ "$first" = "true" ]; then
            first=false
        else
            result="$result,"
        fi
        result="$result{\"card_id\":\"$id\",\"quantity\":$qty}"
    done
    result="$result]"
    echo "$result"
}

# ═══════════════════════════════════════════════════════════════════
# DECK 1: Goblin Aggro
# ═══════════════════════════════════════════════════════════════════
echo ""
echo "📦 DECK 1: Goblin Aggro (Modern)"
echo "────────────────────────────────"

CARDS1=$(make_cards_json "$GOBLIN_IDS" 4)
DECK1_RESPONSE=$(curl -s -X POST "$API/decks" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Test Goblin Aggro\",\"format\":\"Modern\",\"cards\":$CARDS1}")

DECK1_ID=$(echo "$DECK1_RESPONSE" | jq -r '.id')
echo "✅ Deck criado: $DECK1_ID"

echo ""
echo "🔧 Otimizando deck 1..."
OPT1=$(curl -s -X POST "$API/ai/optimize" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"deck_id\":\"$DECK1_ID\",\"archetype\":\"aggro\"}")

echo "   Arquétipo detectado: $(echo "$OPT1" | jq -r '.deck_analysis.detected_archetype')"
echo "   CMC médio: $(echo "$OPT1" | jq -r '.deck_analysis.average_cmc')"
echo "   Tema: $(echo "$OPT1" | jq -r '.theme.theme // .theme')"
echo "   Removals: $(echo "$OPT1" | jq -r '.removals | length') cartas"
echo "   Additions: $(echo "$OPT1" | jq -r '.additions | length') cartas"

sleep 2

# ═══════════════════════════════════════════════════════════════════
# DECK 2: Blue Control
# ═══════════════════════════════════════════════════════════════════
echo ""
echo "📦 DECK 2: Blue Control (Standard)"
echo "────────────────────────────────"

CARDS2=$(make_cards_json "$COUNTER_IDS" 4)
DECK2_RESPONSE=$(curl -s -X POST "$API/decks" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Test Blue Control\",\"format\":\"Standard\",\"cards\":$CARDS2}")

DECK2_ID=$(echo "$DECK2_RESPONSE" | jq -r '.id')
echo "✅ Deck criado: $DECK2_ID"

echo ""
echo "🔧 Otimizando deck 2..."
OPT2=$(curl -s -X POST "$API/ai/optimize" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"deck_id\":\"$DECK2_ID\",\"archetype\":\"control\"}")

echo "   Arquétipo detectado: $(echo "$OPT2" | jq -r '.deck_analysis.detected_archetype')"
echo "   CMC médio: $(echo "$OPT2" | jq -r '.deck_analysis.average_cmc')"
echo "   Tema: $(echo "$OPT2" | jq -r '.theme.theme // .theme')"
echo "   Removals: $(echo "$OPT2" | jq -r '.removals | length') cartas"
echo "   Additions: $(echo "$OPT2" | jq -r '.additions | length') cartas"

sleep 2

# ═══════════════════════════════════════════════════════════════════
# DECK 3: Dragon Tribal (Midrange)
# ═══════════════════════════════════════════════════════════════════
echo ""
echo "📦 DECK 3: Dragon Tribal (Modern)"
echo "────────────────────────────────"

CARDS3=$(make_cards_json "$DRAGON_IDS" 4)
DECK3_RESPONSE=$(curl -s -X POST "$API/decks" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Test Dragon Tribal\",\"format\":\"Modern\",\"cards\":$CARDS3}")

DECK3_ID=$(echo "$DECK3_RESPONSE" | jq -r '.id')
echo "✅ Deck criado: $DECK3_ID"

echo ""
echo "🔧 Otimizando deck 3..."
OPT3=$(curl -s -X POST "$API/ai/optimize" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"deck_id\":\"$DECK3_ID\",\"archetype\":\"midrange\"}")

echo "   Arquétipo detectado: $(echo "$OPT3" | jq -r '.deck_analysis.detected_archetype')"
echo "   CMC médio: $(echo "$OPT3" | jq -r '.deck_analysis.average_cmc')"
echo "   Tema: $(echo "$OPT3" | jq -r '.theme.theme // .theme')"
echo "   Removals: $(echo "$OPT3" | jq -r '.removals | length') cartas"
echo "   Additions: $(echo "$OPT3" | jq -r '.additions | length') cartas"

# ═══════════════════════════════════════════════════════════════════
# RESUMO
# ═══════════════════════════════════════════════════════════════════
echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  RESUMO"
echo "══════════════════════════════════════════════════════════════"
echo "Deck 1 (Goblin Aggro):   $DECK1_ID"
echo "Deck 2 (Blue Control):   $DECK2_ID"
echo "Deck 3 (Dragon Tribal):  $DECK3_ID"
echo ""
echo "✅ Teste concluído!"
