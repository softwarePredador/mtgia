# 🎯 Guia Passo a Passo - MTG Deck Builder

## 📚 O que você vai construir:
Um aplicativo completo de Deck Builder para Magic: The Gathering com:
- **Backend em Dart** (Dart Frog) conectado ao PostgreSQL
- **Frontend em Flutter** 
- **Importação de cartas do MTGJSON**
- **Filtros avançados de busca**
- **Integração com OpenAI para otimizar decks**

---

## ✅ PASSO 1: Configurar o Banco de Dados PostgreSQL

### O que você vai fazer:
Criar as tabelas no seu banco de dados da DigitalOcean.

### Como fazer:

1. **Conecte-se ao seu banco de dados PostgreSQL**. Você pode usar:
   - **DBeaver** (recomendado, gratuito): https://dbeaver.io/download/
   - **pgAdmin**: https://www.pgadmin.org/
   - Ou qualquer client PostgreSQL

2. **Use estas credenciais para conectar:**
   ```
   Host: 143.198.230.247
   Port: 5433
   Database: halder
   User: postgres
   Password: c2abeef5e66f21b0ce86
   ```

3. **Execute o script SQL** que já criei para você:
   - Abra o arquivo: `server/database_setup.sql`
   - Copie todo o conteúdo
   - Cole no seu client SQL e execute

4. **Verifique se funcionou:**
   Execute este comando SQL:
   ```sql
   SELECT table_name FROM information_schema.tables 
   WHERE table_schema = 'public';
   ```
   
   Você deve ver 3 tabelas: `cards`, `decks`, `deck_cards`

---

## ✅ PASSO 2: Testar a Conexão do Backend com o Banco

### O que você vai fazer:
Rodar o servidor Dart e verificar se ele conecta ao PostgreSQL.

### Como fazer:

1. **Abra o terminal no VS Code** (Ctrl + `)

2. **Navegue até a pasta do servidor:**
   ```powershell
   cd C:\Users\rafae\mtg-deck-builder\server
   ```

3. **Instale o Dart Frog CLI globalmente** (se ainda não tiver):
   ```powershell
   dart pub global activate dart_frog_cli
   ```

4. **Inicie o servidor em modo desenvolvimento:**
   ```powershell
   dart_frog dev
   ```

5. **Teste a API:**
   Abra seu navegador e acesse: http://localhost:8080
   
   Você deve ver: "Bem-vindo a API do MTG Deck Builder (Dart)!"

---

## ✅ PASSO 3: Importar Cartas do MTGJSON

### O que você vai fazer:
Criar um script que baixa o arquivo de cartas do MTGJSON e popula o banco de dados.

### Arquivos que vou criar para você:
- `server/lib/models/card_model.dart` - Modelo da carta
- `server/lib/services/import_service.dart` - Lógica de importação
- `server/routes/import.dart` - Rota para disparar a importação

### Como testar depois que eu criar:

1. **Dispare a importação** fazendo uma requisição GET:
   ```
   http://localhost:8080/import
   ```

2. **Acompanhe o progresso no terminal** onde o servidor está rodando.

3. **Verifique quantas cartas foram importadas:**
   ```sql
   SELECT COUNT(*) FROM cards;
   ```

> ⚠️ **IMPORTANTE**: O arquivo do MTGJSON é grande (~200MB). A primeira importação pode demorar alguns minutos.

---

## ✅ PASSO 4: Criar API de Busca de Cartas

### O que você vai fazer:
Criar endpoints para buscar cartas com filtros.

### Endpoints que vou criar:

1. **`GET /cards`** - Lista cartas com paginação
   - Query params: `?page=1&limit=20`

2. **`GET /cards/search`** - Busca com filtros
   - Query params: `?name=lightning&colors=R&type=instant`

3. **`GET /cards/:id`** - Busca uma carta específica

### Como testar:
Use o **Thunder Client** (extensão do VS Code) ou **Postman**.

Exemplo:
```
GET http://localhost:8080/cards/search?name=bolt&colors=R
```

---

## ✅ PASSO 5: Criar o App Flutter

### O que você vai fazer:
Criar o projeto Flutter com arquitetura limpa.

### Estrutura de pastas que vou criar:
```
app/
  lib/
    core/        (Configurações, constantes)
    data/        (Repositórios, APIs)
    domain/      (Entidades, casos de uso)
    presentation/ (Telas, widgets, gerência de estado)
```

### Como iniciar:
```powershell
cd C:\Users\rafae\mtg-deck-builder
flutter create app
cd app
flutter pub add http cached_network_image flutter_bloc
```

---

## ✅ PASSO 6: Conectar Flutter com o Backend

### O que você vai fazer:
Criar o serviço HTTP no Flutter para consumir a API.

### Arquivos que vou criar:
- `app/lib/data/datasources/card_remote_datasource.dart`
- `app/lib/data/repositories/card_repository_impl.dart`
- `app/lib/domain/entities/card.dart`

---

## ✅ PASSO 7: Criar Tela de Busca de Cartas

### O que você vai fazer:
Criar a primeira tela funcional do app.

### Funcionalidades:
- Campo de busca
- Filtros (cores, tipo, CMC)
- Lista de cartas com imagens
- Paginação infinita

---

## ✅ PASSO 8: Implementar Construção de Deck e Regras

### O que você vai fazer:
Permitir que o usuário adicione cartas ao deck, respeitando as regras do Magic.

### Funcionalidades:
- Adicionar/remover cartas
- Controlar quantidade de cada carta
- **Validação de Formato:**
  - Verificar limite de cópias (ex: 4x para Standard/Modern, 1x para Commander).
  - Verificar legalidade (Banidas/Restritas) usando a tabela `card_legalities`.
  - Impedir adição de cartas ilegais ou mostrar alerta.
- Visualizar estatísticas (curva de mana, cores)
- Salvar deck no backend

---

## ✅ PASSO 9: Integrar OpenAI para Otimizar Deck

### O que você vai fazer:
Criar endpoint que envia o deck para a OpenAI e recebe sugestões.

### Arquivos que vou criar:
- `server/lib/services/openai_service.dart`
- `server/routes/decks/optimize.dart`

### O que a IA vai fazer:
- Analisar a curva de mana
- Verificar sinergia entre cartas
- Sugerir substituições
- Recomendar cartas ausentes

---

## 🎯 Por onde começar AGORA?

### Você está no PASSO 1 (Configurar o Banco)

**Sua próxima ação:**
1. Baixe e instale o **DBeaver** (ou use outro client SQL)
2. Conecte-se ao seu PostgreSQL usando as credenciais que mostrei
3. Execute o script `database_setup.sql`
4. Me avise quando terminar para eu te guiar no PASSO 2!

---

## 📌 Dicas Importantes

### Para não travar seu EasyPanel:
- ✅ Use `cached_network_image` no Flutter (cache local)
- ✅ Implemente paginação em todas as listas
- ✅ Use índices no PostgreSQL (já estão no script)
- ✅ Faça lazy loading das imagens

### Para economizar recursos:
- 🔄 Importe apenas cartas legais nos formatos que você vai suportar
- 🔄 Use a versão `AtomicCards.json` do MTGJSON (mais leve)
- 🔄 Configure rate limiting na API

---

## ❓ Precisa de Ajuda?

Me avise em qual passo você está e o que precisa!
