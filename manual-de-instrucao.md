# Manual de Instrução e Documentação Técnica - MTG Deck Builder (Backend)

Este documento serve como guia definitivo para o entendimento, manutenção e expansão do backend do projeto MTG Deck Builder. Ele é atualizado continuamente conforme o desenvolvimento avança.

---

## 1. Visão Geral e Arquitetura

### O que estamos construindo?
Um **Deck Builder de Magic: The Gathering (MTG)** revolucionário, focado em inteligência artificial e automação.
O backend em Dart (Dart Frog) serve como o cérebro da aplicação, gerenciando dados, regras e integrações com IA.

### Funcionalidades Chave (Roadmap)
1.  **Deck Builder:** Criação, edição e importação inteligente de decks (texto -> cartas).
2.  **Regras e Legalidade:** Validação de decks contra regras oficiais e listas de banidas.
3.  **IA Generativa:** Criação de decks a partir de descrições em linguagem natural e autocompletar inteligente.
4.  **Simulador de Batalha:** Testes automatizados de decks (User vs Meta) para treinamento de IA.

### Por que Dart no Backend?
Para manter a stack unificada (Dart no Front e no Back), facilitando o compartilhamento de modelos (DTOs), lógica de validação e reduzindo a carga cognitiva de troca de contexto entre linguagens.

### Estrutura de Pastas (Convenção Dart Frog)
- `routes/`: Define os endpoints da API. A estrutura de pastas aqui reflete a URL (ex: `routes/index.dart` -> `/`).
- `lib/`: Código compartilhado, lógica de negócios, conexão com banco de dados.
- `bin/`: Scripts utilitários (setup de banco, seeds, tarefas agendadas).
- `public/`: Arquivos estáticos (se necessário).

---

## 2. Tecnologias e Bibliotecas (Dependências)

As dependências são gerenciadas no arquivo `pubspec.yaml`.

| Biblioteca | Versão | Para que serve? | Por que escolhemos? |
| :--- | :--- | :--- | :--- |
| **dart_frog** | ^1.0.0 | Framework web minimalista e rápido para Dart. | Simplicidade, hot-reload e fácil deploy. |
| **postgres** | ^3.0.0 | Driver para conectar ao PostgreSQL. | Versão mais recente, suporta chamadas assíncronas modernas e pool de conexões. |
| **dotenv** | ^4.0.0 | Carrega variáveis de ambiente de arquivos `.env`. | **Segurança**. Evita deixar senhas hardcoded no código fonte. |
| **http** | ^1.2.1 | Cliente HTTP para fazer requisições web. | Necessário para baixar o JSON de cartas do MTGJSON. |
| **bcrypt** | ^1.1.3 | Criptografia de senhas (hashing). | Padrão de mercado para segurança de senhas. Transforma a senha em um código irreversível. |
| **dart_jsonwebtoken** | ^2.12.0 | Geração e validação de JSON Web Tokens (JWT). | Essencial para autenticação stateless. O usuário faz login uma vez e usa o token para se autenticar. |
| **collection** | ^1.18.0 | Funções utilitárias para coleções (listas, mapas). | Facilita manipulação de dados complexos. |

---

## 3. Implementações Realizadas (Passo a Passo)

### 3.1. Conexão com o Banco de Dados (`lib/database.dart`)

**Lógica:**
Precisamos de uma forma única e centralizada de acessar o banco de dados em toda a aplicação. Se cada rota abrisse uma nova conexão sem controle, o banco cairia rapidamente.

**Padrão Utilizado: Singleton**
O padrão Singleton garante que a classe `Database` tenha apenas **uma instância** rodando durante a vida útil da aplicação.

**Código Explicado:**
```dart
class Database {
  // Construtor privado: ninguém fora dessa classe pode dar "new Database()"
  Database._internal();
  
  // A única instância que existe
  static final Database _instance = Database._internal();
  
  // Factory: quando alguém pede "Database()", devolvemos a instância já criada
  factory Database() => _instance;

  // ... lógica de conexão ...
}
```

**Por que usamos variáveis de ambiente?**
No método `connect()`, usamos `DotEnv` para ler `DB_HOST`, `DB_PASS`, etc. Isso segue o princípio de **12-Factor App** (Configuração separada do Código). Isso permite que você mude o banco de dados sem tocar em uma linha de código, apenas alterando o arquivo `.env`.

### 3.2. Setup Inicial do Banco (`bin/setup_database.dart`)

**Objetivo:**
Automatizar a criação das tabelas. Rodar comandos SQL manualmente no terminal é propenso a erro.

**Como funciona:**
1.  Lê o arquivo `database_setup.sql` como texto.
2.  Separa o texto em comandos individuais (usando `;` como separador).
3.  Executa cada comando sequencialmente no banco.

**Exemplo de Uso:**
Para recriar a estrutura do banco (cuidado, isso pode não apagar dados existentes dependendo do SQL, mas cria se não existir):
```bash
dart run bin/setup_database.dart
```

### 3.3. Populando o Banco (Seed) - `bin/seed_database.dart`

**Objetivo:**
Preencher a tabela `cards` com dados reais de Magic: The Gathering.

**Fonte de Dados:**
Utilizamos o arquivo `AtomicCards.json` do MTGJSON.
- **Por que Atomic?** Contém o texto "Oracle" (oficial) de cada carta, ideal para buscas e construção de decks agnóstica de edição.
- **Imagens:** Construímos a URL da imagem baseada no `scryfall_id` (`https://api.scryfall.com/cards/{id}?format=image`). O frontend fará o cache.

**Lógica de Implementação:**
1.  **Download:** Baixa o JSON (aprox. 100MB+) se não existir localmente.
2.  **Parsing:** Lê o JSON em memória (cuidado: requer RAM disponível).
3.  **Batch Insert:** Inserimos cartas em lotes de 500.
    - **Por que Lotes?** Inserir 30.000 cartas uma por uma levaria horas (round-trip de rede). Em lotes, leva segundos/minutos.
    - **Transações:** Cada lote roda em uma transação (`runTx`). Se falhar, não corrompe o banco pela metade.
    - **Idempotência:** Usamos `ON CONFLICT (scryfall_id) DO UPDATE` no SQL. Isso significa que podemos rodar o script várias vezes sem duplicar cartas ou dar erro.
    - **Parâmetros Posicionais:** Utilizamos `$1`, `$2`, etc. na query SQL preparada para garantir compatibilidade total com o driver `postgres` v3 e evitar erros de parsing de parâmetros nomeados.

**Como Rodar:**
```bash
dart run bin/seed_database.dart
```

### 3.4. Atualização do Schema (Evolução do Banco)

**Mudança:**
Adicionamos tabelas para `users`, `rules` e `card_legalities`, e atualizamos a tabela `decks` para pertencer a um usuário.

**Estratégia de Migração:**
Como ainda estamos em desenvolvimento, optamos por uma estratégia destrutiva para as tabelas sem dados importantes (`decks`), mas preservativa para a tabela populada (`cards`).
Criamos o script `bin/update_schema.dart` que:
1.  Remove `deck_cards` e `decks`.
2.  Roda o `database_setup.sql` completo.
    -   Cria `users`, `rules`, `card_legalities`.
    -   Recria `decks` (agora com `user_id`) e `deck_cards`.
    -   Mantém `cards` intacta (graças ao `IF NOT EXISTS`).

### 3.5. Estrutura para IA e Machine Learning

**Objetivo:**
Preparar o banco de dados para armazenar o conhecimento gerado pela IA e permitir o aprendizado contínuo (Reinforcement Learning).

**Novas Tabelas e Colunas:**
1.  **`decks.synergy_score`:** Um número de 0 a 100 que indica o quão "fechado" e sinérgico o deck está.
2.  **`decks.strengths` / `weaknesses`:** Campos de texto para a IA descrever em linguagem natural os pontos fortes e fracos do deck (ex: "Fraco contra decks rápidos").
3.  **`deck_matchups`:** Tabela que relaciona Deck A vs Deck B. Armazena o `win_rate`. É aqui que sabemos quais são os "Counters" de um deck.
4.  **`battle_simulations`:** A tabela mais importante para o ML. Ela guarda o `game_log` (JSON) de cada batalha simulada.
    -   **Por que JSONB?** O log de uma partida de Magic é complexo e variável. JSONB no PostgreSQL permite armazenar essa estrutura flexível e ainda fazer queries eficientes sobre ela se necessário.

## 5. Implementações da API (Rotas)

### 5.1. Rota de Busca de Cartas (`GET /cards`)

**Local:** `routes/cards/index.dart`

**Objetivo:**
Fornecer um endpoint para o frontend e a IA pesquisarem cartas no banco de dados.

**Lógica e Padrões:**
1.  **Middleware de Conexão (`routes/_middleware.dart`):**
    -   **O que faz?** Intercepta todas as requisições. Na primeira, ele abre a conexão com o banco de dados e a mantém aberta.
    -   **Por que?** Evita o custo de abrir e fechar uma conexão a cada busca de carta. É muito mais performático.
    -   **Dependency Injection:** Ele "injeta" a conexão no contexto da requisição, para que a rota final (`index.dart`) possa simplesmente "pedir" por ela usando `context.read<Connection>()`.
2.  **Query Dinâmica (`_buildQuery`):**
    -   A função constrói a query SQL dinamicamente com base nos filtros passados na URL (ex: `?name=sol`).
    -   **Segurança:** Usa parâmetros nomeados (`@name`, `@limit`) para prevenir **SQL Injection**.
3.  **Paginação:**
    -   Aceita `?page=` e `?limit=` na URL.
    -   Retorna um número limitado de resultados, essencial para a performance do app.

**Exemplo de Uso:**
- `GET /cards` -> Retorna as primeiras 50 cartas.
- `GET /cards?name=sol&page=1&limit=10` -> Retorna os 10 primeiros resultados que contenham "sol" no nome.

### 5.2. Rota de Cadastro de Usuário (`POST /users/register`)

**Local:** `routes/users/register.dart`

**Objetivo:**
Permitir que novos usuários criem uma conta no sistema.

**Lógica e Padrões:**
1.  **Validação:** Verifica se `username`, `email` e `password` foram enviados no corpo (JSON) da requisição.
2.  **Segurança (Hashing):** Usa a biblioteca `bcrypt` para criar um hash da senha. **NUNCA** salvamos a senha original.
3.  **Inserção no Banco:** Insere o novo usuário na tabela `users`.
4.  **Tratamento de Erro:** Captura o erro específico do PostgreSQL para "violação de chave única" (`23505`) e retorna uma mensagem amigável (`409 Conflict`) se o email ou username já existirem.

**Exemplo de Uso (com uma ferramenta de API):**
- **Método:** `POST`
- **URL:** `http://localhost:8080/users/register`
- **Corpo (JSON):**
  ```json
  {
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123"
  }
  ```

### 5.3. Rota de Login de Usuário (`POST /users/login`)

**Local:** `routes/users/login.dart`

**Objetivo:**
Autenticar um usuário e fornecer um token de acesso para requisições futuras.

**Lógica e Padrões:**
1.  **Busca:** Procura o usuário no banco de dados pelo `email`.
2.  **Verificação de Senha:** Usa `BCrypt.checkpw()` para comparar a senha enviada com o hash salvo no banco. Isso é seguro, pois a senha original nunca é exposta.
3.  **Geração de Token (JWT):** Se a senha estiver correta, um JSON Web Token é gerado.
    -   **Payload:** O token contém o `id` do usuário.
    -   **Segredo:** O token é assinado com uma chave secreta (`JWT_SECRET`) definida no arquivo `.env`. Isso garante que apenas o nosso servidor pode criar tokens válidos.
    -   **Expiração:** O token expira em 7 dias, forçando o usuário a fazer login novamente após esse período.
4.  **Resposta:** O servidor devolve o token para o cliente (o app Flutter). O app deve salvar esse token e enviá-lo no cabeçalho `Authorization` de todas as requisições futuras que exigem autenticação.

**Exemplo de Uso:**
- **Método:** `POST`
- **URL:** `http://localhost:8080/users/login`
- **Corpo (JSON):**
  ```json
  {
    "email": "test@example.com",
    "password": "password123"
  }
  ```
- **Resposta de Sucesso:**
  ```json
  {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
  ```

### 5.4. Rota de Criação de Decks (`POST /decks`)

**Local:** `routes/decks/index.dart`

**Objetivo:**
Permitir que um usuário autenticado crie um novo deck.

**Lógica e Padrões:**
1.  **Autenticação via Middleware:** A rota é automaticamente protegida pelo `routes/decks/_middleware.dart`. Se o usuário não enviar um token válido, a requisição nem chega aqui. O ID do usuário é lido do contexto com `context.read<String>()`.
2.  **Transação de Banco de Dados:** A criação do deck e a inserção das cartas são envolvidas em uma transação (`conn.runTx`). Isso garante que, se a inserção de uma carta falhar, a criação do deck é desfeita (rollback). Ou tudo funciona, ou nada é salvo, mantendo o banco consistente.
3.  **Validação de Entrada:** Verifica se os campos essenciais (`name`, `format`, `cards`) foram enviados.

**Exemplo de Uso:**
- **Método:** `POST`
- **URL:** `http://localhost:8080/decks`
- **Cabeçalho (Header):**
  - `Authorization`: `Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` (O token obtido no login)
- **Corpo (JSON):**
  ```json
  {
    "name": "My Awesome Deck",
    "format": "Commander",
    "description": "A deck for fun.",
    "cards": [
      { "card_id": "a3b4c5d6-...", "quantity": 1 },
      { "card_id": "e7f8g9h0-...", "quantity": 1 },
      { "card_id": "i1j2k3l4-...", "quantity": 98 }
    ]
  }
  ```

---

## 6. Guia para Desenvolvimento Futuro

### Como adicionar uma nova funcionalidade?
1.  **Defina a Rota:** Crie um arquivo em `routes/`. Ex: `routes/cards/index.dart` para listar cartas.
2.  **Acesse o Banco:** Importe `lib/database.dart` e use `Database().connection`.
3.  **Execute a Query:** Use `await connection.execute(...)`.
4.  **Retorne a Resposta:** Retorne um objeto `Response.json(...)`.

### Padrões de Clean Code a Seguir
- **Nomes Significativos:** Evite `var x = ...`. Use `final cardsList = ...`.
- **Funções Pequenas:** Se sua rota tem 100 linhas, extraia a lógica para uma classe em `lib/`. As rotas devem ser apenas "controladores" que recebem o pedido e devolvem a resposta.
- **Tratamento de Erros:** Sempre envolva chamadas de banco ou rede em `try-catch` para não derrubar o servidor se algo der errado.

---
*Última atualização: Criação do Manual e Configuração Inicial.*
