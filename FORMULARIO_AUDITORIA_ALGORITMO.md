# 📋 Formulário de Auditoria de Lógica de Algoritmo
## ManaLoom - MTG Deck Optimizer

**Data:** ___/___/______  
**Desenvolvedor Responsável:** _______________  
**Versão do Sistema:** _______________

---

## 🎯 Objetivo deste Formulário

Este formulário foi projetado para auditar e documentar a lógica exata dos algoritmos de otimização de decks implementados no ManaLoom. Ao responder cada pergunta, você irá expor as decisões técnicas do código atual, identificar possíveis falhas lógicas e criar uma base para melhorias futuras.

**Instruções:**
1. Responda cada pergunta com detalhes técnicos específicos.
2. Inclua trechos de código, fórmulas ou referências a arquivos quando relevante.
3. Se a lógica não está implementada, escreva "NÃO IMPLEMENTADO" e descreva o comportamento atual.
4. Marque áreas de incerteza com "⚠️ VERIFICAR".

---

## 1. 📥 Entrada e Parsing de Dados

### 1.1 Recebimento do Deck

**P1.1.1:** Como o deck é recebido pelo sistema?
- [ ] Via API REST (JSON)
- [ ] Via importação de texto
- [ ] Via banco de dados

**Arquivo de referência:** `_______________`

**Detalhes técnicos:**
```
Formato esperado do payload:
_____________________________________________
_____________________________________________
_____________________________________________
```

---

**P1.1.2:** Como identificamos o **Comandante** vs **Maindeck**?

| Método de Detecção | Implementado? | Arquivo/Linha |
|-------------------|---------------|---------------|
| Campo `is_commander` no JSON | ☐ Sim / ☐ Não | |
| Tag no texto (ex: `[Commander]`, `*CMDR*`) | ☐ Sim / ☐ Não | |
| Posição na lista (primeira carta) | ☐ Sim / ☐ Não | |
| Detecção automática por tipo (Legendary Creature) | ☐ Sim / ☐ Não | |

**Descreva a lógica exata:**
```
_____________________________________________
_____________________________________________
```

**⚠️ Possível Bug:** O que acontece se nenhum comandante for detectado? 
```
_____________________________________________
```

---

**P1.1.3:** Como tratamos **cartas dupla-face (DFC)** ou **split cards** na contagem e identificação?

**Exemplo de DFCs:** "Delver of Secrets // Insectile Aberration", "Jace, Vryn's Prodigy // Jace, Telepath Unbound"

**Exemplo de Split Cards:** "Fire // Ice", "Commit // Memory"

| Tipo de Carta | Como é tratada na busca? | Como é tratada no CMC? |
|---------------|--------------------------|------------------------|
| DFC (Dupla-Face) | | |
| Split Card | | |
| Adventure Card | | |
| Modal DFC (MDFC) | | |

**Código de referência:**
```dart
// Cole o trecho de código que faz o parse de nomes de cartas:
_____________________________________________
_____________________________________________
```

---

### 1.2 Parser de Texto (Importação)

**P1.2.1:** Qual é a expressão regular (regex) usada para fazer o parse de linhas de deck?

```regex
Regex atual: _____________________________________________
```

**Teste com os seguintes inputs. O regex captura corretamente?**

| Input | Quantidade | Nome | Set Code | Resultado |
|-------|------------|------|----------|-----------|
| `1x Sol Ring (cmm)` | | | | ☐ OK / ☐ FALHA |
| `4 Lightning Bolt` | | | | ☐ OK / ☐ FALHA |
| `1 Jace, Vryn's Prodigy // Jace, Telepath Unbound` | | | | ☐ OK / ☐ FALHA |
| `2x Fire // Ice (mh2)` | | | | ☐ OK / ☐ FALHA |
| `1 Forest 96` | | | | ☐ OK / ☐ FALHA |
| `1 Who // What // When // Where // Why` | | | | ☐ OK / ☐ FALHA |

---

**P1.2.2:** Como tratamos o **fallback** quando uma carta não é encontrada pelo nome exato?

- [ ] Busca LIKE (substring)
- [ ] Fuzzy matching (Levenshtein distance)
- [ ] Busca por prefixo (split cards: "Fire // %")
- [ ] Nenhum fallback

**Detalhes da implementação:**
```
_____________________________________________
_____________________________________________
```

---

## 2. 📊 Cálculos Matemáticos (Stat Engine)

### 2.1 Curva de Mana (CMC)

**P2.1.1:** Como é calculada a **Curva de Mana (CMC)** de cada carta?

**Fórmula atual:**
```
CMC = _____________________________________________
```

**Considerações especiais:**

| Caso Especial | Como é tratado? |
|---------------|-----------------|
| Custo `{X}` | ☐ Conta como 0 / ☐ Conta como X / ☐ Outro: _____ |
| Custo Híbrido `{2/W}` | ☐ Conta como 2 / ☐ Conta como 1 / ☐ Outro: _____ |
| Custo Phyrexian `{B/P}` | ☐ Conta como 1 / ☐ Conta como 0 / ☐ Outro: _____ |
| Terrenos (Land) | ☐ Incluído na curva (CMC=0) / ☐ Excluído da curva |
| Custos Alternativos (Evoke, Overload) | ☐ Considerados / ☐ Ignorados |

**Código de referência:**
```dart
// Cole a função que calcula CMC:
_____________________________________________
_____________________________________________
```

---

**P2.1.2:** Como é calculado o **CMC Médio** do deck?

**Fórmula:**
```
CMC Médio = (Σ CMC de todas as cartas) / (quantidade de cartas)
```

**Perguntas críticas:**

- Terrenos são **incluídos** ou **excluídos** do cálculo? `_____________`
- Se uma carta tem `quantity = 4`, ela conta 4 vezes ou 1 vez? `_____________`
- Cartas do sideboard são incluídas? `_____________`

---

### 2.2 Distribuição de Tipos

**P2.2.1:** Como é feita a contagem de tipos de cartas?

**Regra de Contagem para Tipos Múltiplos:**

Exemplo: "Artifact Creature - Golem"

| Estratégia | Implementado? |
|------------|---------------|
| Conta +1 para Artifact E +1 para Creature (soma) | ☐ |
| Conta apenas no tipo principal (Creature) | ☐ |
| Usa sistema de prioridade (se é X, não conta Y) | ☐ |

**Descreva o sistema de prioridade (se aplicável):**
```
1. Land > 2. Creature > 3. ___ > 4. ___ > 5. ___
```

---

**P2.2.2:** Como classificamos cada tipo?

| Tipo | Substring usada para detecção | Exemplo de carta |
|------|-------------------------------|------------------|
| Creature | `type_line.contains('creature')` | |
| Instant | | |
| Sorcery | | |
| Enchantment | | |
| Artifact | | |
| Planeswalker | | |
| Land | | |
| Battle | | |

---

### 2.3 Base de Mana (Manabase)

**P2.3.1:** Como calculamos a **quantidade ideal de terrenos**?

**Fórmula atual:**
```
Terrenos Recomendados = _____________________________________________
```

**Parâmetros utilizados:**

| Parâmetro | Usado? | Valor/Fórmula |
|-----------|--------|---------------|
| CMC Médio do deck | ☐ Sim / ☐ Não | |
| Formato (Commander, Standard) | ☐ Sim / ☐ Não | |
| Arquétipo (Aggro, Control) | ☐ Sim / ☐ Não | |
| Quantidade de ramp | ☐ Sim / ☐ Não | |

**Fórmulas por arquétipo (se aplicável):**
```
Aggro:     ___ terrenos
Midrange:  ___ terrenos
Control:   ___ terrenos
```

---

**P2.3.2:** Como calculamos a **distribuição de cores** nos terrenos?

**Método usado:**

- [ ] Pip count (contar símbolos de mana coloridos)
- [ ] Proporção fixa baseada nas cores do comandante
- [ ] Heurística simples (dividir igualmente)
- [ ] Não implementado

**Fórmula de Pip Count (se aplicável):**
```
Se o deck tem 50 símbolos de mana:
  - 30 {B} (60%)
  - 15 {G} (30%)
  - 5 {W} (10%)

Então, dos 36 terrenos, devemos ter:
  - 21 fontes de Black (60%)
  - 11 fontes de Green (30%)
  - 4 fontes de White (10%)

Implementado dessa forma? ☐ Sim / ☐ Não

Descreva a lógica real:
_____________________________________________
```

---

## 3. ⚖️ Lógica de "Scoring" (O que é bom e o que é ruim)

### 3.1 Identificação de Cartas Fracas

**P3.1.1:** Qual é a **fórmula matemática exata** para decidir que uma carta é "FRACA"?

**Fórmula atual:**
```
weakness_score = _____________________________________________
```

**Fatores considerados:**

| Fator | Peso | Como é obtido? |
|-------|------|----------------|
| EDHREC Rank | ___% | Campo `edhrec_rank` na tabela `cards`? ☐ Sim / ☐ Não |
| CMC (custo alto = ruim?) | ___% | |
| Preço de mercado | ___% | |
| Sinergia com comandante | ___% | |
| Popularidade em Meta Decks | ___% | |

---

**P3.1.2:** Como tratamos **cartas sem dados de rank** (EDHREC rank = null)?

- [ ] Assumimos rank máximo (impopular)
- [ ] Ignoramos a carta
- [ ] Usamos média do deck
- [ ] Outro: _______________

**Código de referência:**
```dart
// Cole a linha que trata o caso de rank null:
_____________________________________________
```

---

**P3.1.3:** Como evitamos cortar **Staples** acidentalmente?

| Staple | Protegido pelo sistema? | Como? |
|--------|-------------------------|-------|
| Sol Ring | ☐ Sim / ☐ Não | |
| Mana Crypt | ☐ Sim / ☐ Não | |
| Rhystic Study | ☐ Sim / ☐ Não | |
| Demonic Tutor | ☐ Sim / ☐ Não | |

**Existe uma lista hardcoded de staples protegidos?** 
- [ ] Sim → Arquivo: _______________
- [ ] Não

---

### 3.2 Identificação de Cartas Boas

**P3.2.1:** Qual é a **fórmula** para decidir que uma carta é "BOA/STAPLE"?

**Fórmula atual:**
```
staple_score = _____________________________________________
```

---

**P3.2.2:** Como diferenciamos uma carta "ruim" de uma carta "de nicho/sinergia"?

**Exemplo:** "Goblin Guide" tem EDHREC Rank baixíssimo em Commander, mas é STAPLE em Mono-Red Aggro.

**O sistema considera o arquétipo do deck?**
- [ ] Sim → Como? _______________
- [ ] Não

**O sistema analisa sinergia com o comandante?**
- [ ] Sim → Método: _______________
- [ ] Não

---

### 3.3 Análise de Composição (Vegetables Check)

**P3.3.1:** Como detectamos se o deck tem **Ramp suficiente**?

**Critérios de detecção de "Ramp":**

| Palavra-chave no `oracle_text` | Detecta como Ramp? |
|--------------------------------|-------------------|
| `add {` | ☐ Sim / ☐ Não |
| `search your library for a land` | ☐ Sim / ☐ Não |
| `create a Treasure` | ☐ Sim / ☐ Não |
| `put a land card from your hand` | ☐ Sim / ☐ Não |

**Quantidade mínima recomendada:** ___ cartas de ramp

---

**P3.3.2:** Como detectamos **Card Draw**?

| Palavra-chave | Detecta? |
|---------------|----------|
| `draw a card` | ☐ Sim / ☐ Não |
| `draw cards` | ☐ Sim / ☐ Não |
| `draw X cards` | ☐ Sim / ☐ Não |
| `look at the top` (impulse draw) | ☐ Sim / ☐ Não |

**Quantidade mínima recomendada:** ___ cartas de draw

---

**P3.3.3:** Como detectamos **Removal**?

| Tipo | Palavra-chave | Detecta? |
|------|---------------|----------|
| Single Target | `destroy target` | ☐ |
| Single Target | `exile target` | ☐ |
| Single Target | `deal X damage to target` | ☐ |
| Board Wipe | `destroy all` | ☐ |
| Board Wipe | `exile all` | ☐ |

**Quantidade mínima recomendada:** 
- Single Target: ___ cartas
- Board Wipes: ___ cartas

---

## 4. 🔍 Busca e Recomendação (Source of Truth)

### 4.1 Origem das Sugestões

**P4.1.1:** De onde vêm as **sugestões de cartas novas**?

| Fonte | Usado? | Prioridade |
|-------|--------|------------|
| Listas hardcoded no código | ☐ Sim / ☐ Não | |
| Query dinâmica no Scryfall API | ☐ Sim / ☐ Não | |
| Banco de dados interno (tabela `cards`) | ☐ Sim / ☐ Não | |
| Meta decks (tabela `meta_decks`) | ☐ Sim / ☐ Não | |
| OpenAI (GPT) com liberdade criativa | ☐ Sim / ☐ Não | |

---

### 4.2 Integração com Scryfall

**P4.2.1:** Se usa Scryfall, quais **parâmetros de busca exatos** são usados?

**Query base:**
```
_____________________________________________
```

**Parâmetros adicionais:**

| Parâmetro | Valor | Propósito |
|-----------|-------|-----------|
| `format:` | | Garantir legalidade |
| `is:` | | |
| `order:` | | Ordenar por popularidade |
| `id<=` | | Filtrar por identidade de cor |

**Exemplo de query completa:**
```
q=format:commander -is:banned id<=UBG order:edhrec
```

---

**P4.2.2:** Como garantimos que **NÃO sugerimos cartas banidas**?

- [ ] Filtro `-is:banned` na query do Scryfall
- [ ] Verificação pós-fetch contra tabela `card_legalities`
- [ ] Ambos
- [ ] Não verificamos

---

**P4.2.3:** Como garantimos que **NÃO sugerimos cartas fora da identidade de cor**?

**Método utilizado:**

- [ ] Filtro `id<=` na query do Scryfall (ex: `id<=UBG` para Sultai)
- [ ] Verificação pós-fetch comparando `colors` da carta com `colors` do deck
- [ ] Nenhuma verificação

**Possíveis bugs:**
- O que acontece com cartas híbridas? _______________
- O que acontece com cartas colorless com ativações coloridas? _______________

---

### 4.3 Validação Anti-Hallucination

**P4.3.1:** Como validamos cartas sugeridas pela IA contra o banco de dados?

**Fluxo de validação:**
```
1. IA sugere: ["Lightning Bolt", "ManaRock999", "Sol Rig"]
2. Sistema valida:
   - "Lightning Bolt" → _______________ (encontrado?)
   - "ManaRock999" → _______________ (não existe?)
   - "Sol Rig" → _______________ (typo de "Sol Ring"?)
3. Resultado final: _______________
```

---

**P4.3.2:** Existe **fuzzy matching** para corrigir typos da IA?

- [ ] Sim → Algoritmo usado: _______________
- [ ] Não

**Threshold de similaridade (se aplicável):** ___% 

---

## 5. 🤖 Integração com IA (LLM)

### 5.1 Dados Enviados no Prompt

**P5.1.1:** Quais **dados exatos** são enviados no prompt para a IA?

| Dado | Incluído? | Exemplo |
|------|-----------|---------|
| Nome do deck | ☐ Sim / ☐ Não | |
| Formato (Commander, Standard) | ☐ Sim / ☐ Não | |
| Nome do Comandante | ☐ Sim / ☐ Não | |
| Lista completa de cartas | ☐ Sim / ☐ Não | |
| Lista de cartas "fracas" (candidatas a corte) | ☐ Sim / ☐ Não | |
| CMC Médio calculado | ☐ Sim / ☐ Não | |
| Arquétipo detectado | ☐ Sim / ☐ Não | |
| Pool de cartas sinérgicas (Scryfall) | ☐ Sim / ☐ Não | |
| Lista de staples do formato | ☐ Sim / ☐ Não | |
| Contexto de Meta Decks | ☐ Sim / ☐ Não | |

---

**P5.1.2:** Cole o **System Prompt** exato enviado à IA:

```
_____________________________________________
_____________________________________________
_____________________________________________
_____________________________________________
_____________________________________________
```

**Arquivo de referência:** `_______________`

---

### 5.2 Liberdade Criativa vs Controle

**P5.2.1:** A IA tem **liberdade criativa** ou escolhe de uma **lista pré-aprovada**?

- [ ] Liberdade total (pode inventar qualquer carta)
- [ ] Escolhe apenas de uma lista fornecida no prompt (pool de sinergia + staples)
- [ ] Misto (liberdade, mas validamos depois)

---

**P5.2.2:** Se a IA sugere uma carta que **não existe**, o que acontece?

- [ ] Erro fatal (sistema quebra)
- [ ] Carta é silenciosamente ignorada
- [ ] Sistema sugere alternativas similares
- [ ] Usuário recebe warning

---

**P5.2.3:** Qual é o parâmetro de **temperature** usado?

```
temperature = _______
```

**Justificativa:** `_____________________________________________`

---

### 5.3 Formato de Resposta

**P5.3.1:** Qual é o **formato JSON esperado** da resposta da IA?

```json
{
  _____________________________________________
  _____________________________________________
  _____________________________________________
}
```

---

**P5.3.2:** O que acontece se a IA retornar **JSON inválido** ou com **markdown**?

**Tratamento atual:**
```
_____________________________________________
_____________________________________________
```

---

## 6. 🎮 Lógica de Arquétipo

### 6.1 Detecção de Arquétipo

**P6.1.1:** Como o sistema sabe se o deck é **Aggro, Control, Midrange ou Combo**?

- [ ] Input explícito do usuário
- [ ] Detecção automática baseada em estatísticas
- [ ] Detecção automática baseada em palavras-chave
- [ ] Não detectamos (assumimos genérico)

---

**P6.1.2:** Se a detecção é automática, quais são os **critérios exatos**?

| Arquétipo | CMC Médio | % Criaturas | % Instants/Sorceries | Outros Critérios |
|-----------|-----------|-------------|----------------------|------------------|
| Aggro | < ___ | > ___% | | |
| Control | > ___ | < ___% | > ___% | |
| Combo | | < ___% | > ___% | |
| Midrange | ___ a ___ | ___ a ___% | | |
| Stax | | | | > ___% Enchantments |

---

**P6.1.3:** Existe um sistema de **confiança** na detecção?

- [ ] Sim → Como é calculado? _______________
- [ ] Não

---

### 6.2 Recomendações por Arquétipo

**P6.2.1:** Existem **staples pré-definidos** por arquétipo?

| Arquétipo | Staples Recomendados | Arquivo/Localização |
|-----------|---------------------|---------------------|
| Aggro | | |
| Control | | |
| Combo | | |
| Midrange | | |

---

**P6.2.2:** Existem **cartas a evitar** por arquétipo?

| Arquétipo | Cartas/Padrões a Evitar | Por quê? |
|-----------|------------------------|----------|
| Aggro | | |
| Control | | |
| Combo | | |

---

## 7. 🐛 Identificação de Possíveis Bugs

### Baseado nas respostas acima, marque possíveis problemas:

- [ ] **Parser não trata DFCs corretamente** (P1.1.3)
- [ ] **CMC de cartas com X é calculado incorretamente** (P2.1.1)
- [ ] **Terrenos são incluídos no CMC médio** (P2.1.2)
- [ ] **Tipos múltiplos são contados duas vezes** (P2.2.1)
- [ ] **Cartas sem EDHREC rank são tratadas como ruins** (P3.1.2)
- [ ] **Staples não são protegidos de corte** (P3.1.3)
- [ ] **Cartas de nicho são marcadas como ruins** (P3.2.2)
- [ ] **Cartas banidas podem ser sugeridas** (P4.2.2)
- [ ] **IA pode sugerir cartas fora da identidade de cor** (P4.2.3)
- [ ] **IA pode inventar cartas que não existem** (P5.2.2)
- [ ] **Arquétipo não é detectado corretamente** (P6.1.2)
- [ ] **Outro:** _______________________________________________

---

## 8. 📝 Notas Adicionais

**Espaço para observações do auditor:**

```
_____________________________________________
_____________________________________________
_____________________________________________
_____________________________________________
_____________________________________________
```

---

## 9. ✅ Assinaturas

**Auditor:**  
Nome: _______________  
Data: ___/___/______  
Assinatura: _______________

**Desenvolvedor:**  
Nome: _______________  
Data: ___/___/______  
Assinatura: _______________

---

_Este formulário deve ser revisado sempre que houver mudanças significativas nos algoritmos de otimização._

**Versão do Formulário:** 1.0  
**Última Atualização:** Novembro 2025
