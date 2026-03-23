# ManaLoom

Plataforma para Magic: The Gathering focada em um fluxo confiável de decks:

1. criar ou importar
2. validar e analisar
3. otimizar ou reconstruir
4. aplicar e validar o resultado final

## Fonte de verdade

Se você precisar entender o estado atual do projeto, a ordem correta é:

1. [docs/CONTEXTO_PRODUTO_ATUAL.md](docs/CONTEXTO_PRODUTO_ATUAL.md)
2. [docs/README.md](docs/README.md)
3. [docs/MATRIZ_TESTES_OTIMIZACAO_2026-03-23.md](docs/MATRIZ_TESTES_OTIMIZACAO_2026-03-23.md)

`docs/CONTEXTO_PRODUTO_ATUAL.md` é a fonte de verdade operacional.  
Roadmaps e handoffs antigos continuam úteis como apoio, mas não mandam mais na prioridade.

## Prioridade atual

O foco ativo do produto está no core de decks:

- onboarding
- geração
- importação
- análise
- otimização
- rebuild
- validação final

Frentes adjacentes como social, binder, trade, scanner e refinamentos cosméticos só devem avançar se não competirem com a confiabilidade desse fluxo.

## Estrutura do repositório

- `app/`: aplicativo Flutter
- `server/`: API Dart Frog, regras, IA, testes e scripts
- `docs/`: documentação ativa e auditorias atuais
- `archive_docs/`: documentação arquivada para referência histórica

## Documentação principal

- contexto operacional: [docs/CONTEXTO_PRODUTO_ATUAL.md](docs/CONTEXTO_PRODUTO_ATUAL.md)
- índice documental: [docs/README.md](docs/README.md)
- matriz de testes da otimização: [docs/MATRIZ_TESTES_OTIMIZACAO_2026-03-23.md](docs/MATRIZ_TESTES_OTIMIZACAO_2026-03-23.md)
- auditoria de UX, lógica e performance: [docs/AUDITORIA_UX_LOGICA_PERFORMANCE_2026-03-23.md](docs/AUDITORIA_UX_LOGICA_PERFORMANCE_2026-03-23.md)
- manual técnico contínuo: [server/manual-de-instrucao.md](server/manual-de-instrucao.md)

## Setup rápido

### Backend

```bash
cd server
dart pub get
dart_frog dev -p 8080
```

### Frontend

```bash
cd app
flutter pub get
flutter run
```

## Testes

### App

```bash
cd app
flutter analyze
flutter test
```

### Server

```bash
cd server
dart test
```

Para a malha mais importante do core, ver:

- [app/test/README.md](app/test/README.md)
- [server/test/README.md](server/test/README.md)

## Status

Em `2026-03-23`, o projeto está em fase de endurecimento do core de decks para atingir confiança de release no fluxo principal.
