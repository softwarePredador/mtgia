# ManaLoom — arquitetura gerada

> Gerado. A topologia vem do manifesto; razões arquiteturais continuam em ADRs/documentos canônicos.

```mermaid
flowchart LR
    UI["Flutter app (20 módulos)"] --> API["Dart Frog routes"]
    WEB["Next.js público (14 rotas)"] --> API
    API --> DOMAIN["Backend services (123 módulos)"]
    DOMAIN --> PG[("PostgreSQL — fonte de verdade")]
    DOMAIN --> AI["Deckbuilder / Optimize"]
    DOMAIN --> BATTLE["Battle router"]
    BATTLE --> NATIVE["ManaLoom native"]
    BATTLE --> XMAGE["XMage pinado"]
    BATTLE --> FORGE["Forge pinado para gaps"]
    PG --> HERMES[("Hermes / SQLite — cache e laboratório")]
    SRC["Código + migrations + contratos manuais"] --> GEN["manaloom_project_logic"]
    GEN --> MANIFEST["project_logic_manifest.json"]
    MANIFEST --> DOCS["Markdown + Mermaid + OpenAPI + ERD"]
    MANIFEST --> LOCAL["Hooks e gates locais gratuitos"]
    LOCAL --> TBLS["PostgreSQL descartável + tbls"]
    MCP["Dart/Flutter MCP + DTD"] --> UI
    MCP --> DOMAIN
```

## Política

- O gerador extrai estrutura; não promove hipótese histórica a verdade.
- PostgreSQL/backend prevalece sobre Hermes/SQLite.
- OpenAPI é estrutural enquanto handlers não tiverem DTOs tipados completos.
- Runtime MCP confirma árvore, erros e estado vivo; não substitui testes nem contratos.
