# Localized Import Names — 2026-05-18

## Status

**PASS WITH RISKS.**

O import de decks passou a suportar nomes localizados por tabela backend
sincronizada, sem chamadas externas por carta durante o fluxo do usuario.

## Mudancas

- Criada tabela operacional `card_localized_names` via helper em
  `server/lib/import_card_lookup_service.dart`.
- Criado `server/bin/sync_localized_card_names.dart` para popular aliases da
  Scryfall por idioma usando busca paginada `lang:<idioma>`.
- `POST /import`, `POST /import/validate` e `POST /import/to-deck` agora tentam:
  - nome canonico em `cards.name`;
  - aliases manuais legados;
  - `card_localized_names.normalized_printed_name`, quando a tabela existe.
- Respostas app-facing ganharam campos aditivos:
  - `localized_matches`;
  - `localized_matches_count`.
- App preserva esses campos e mostra quando nomes localizados foram convertidos.

## Prova local

Servidor local em `127.0.0.1:8082`, banco configurado no ambiente atual:

```text
POST /import/validate
list:
1 Dragao Pira Funesta
1 Kaalia da Vastidao
```

Resultado sanitizado:

```json
{
  "found": ["Balefire Dragon", "Kaalia of the Vast"],
  "not_found_lines": [],
  "localized_matches_count": 2
}
```

## Sync aplicado

Foi aplicado o sync de portugues:

```bash
cd server
dart run bin/sync_localized_card_names.dart --apply --langs=pt
```

Resultado:

```text
38594 aliases sincronizados
```

Para demais idiomas, executar em janela operacional controlada:

```bash
cd server
dart run bin/sync_localized_card_names.dart --apply --langs=es
dart run bin/sync_localized_card_names.dart --apply --langs=fr
dart run bin/sync_localized_card_names.dart --apply --langs=de
dart run bin/sync_localized_card_names.dart --apply --langs=it
dart run bin/sync_localized_card_names.dart --apply --langs=ja
dart run bin/sync_localized_card_names.dart --apply --langs=ko
dart run bin/sync_localized_card_names.dart --apply --langs=ru
dart run bin/sync_localized_card_names.dart --apply --langs=zhs,zht
```

O script respeita `429` com espera minima de 60s.

## Riscos

- Backend publico so passara a resolver nomes localizados depois do deploy deste
  commit.
- Apenas `pt` foi populado nesta rodada. O script ja suporta demais idiomas,
  mas eles devem ser aplicados separadamente por causa de rate limit da
  Scryfall.
- Se uma carta localizada nao tiver correspondencia em `cards` por `card_id`,
  `scryfall_id`, `oracle_id` ou `canonical_name`, ela permanece fora do match.
