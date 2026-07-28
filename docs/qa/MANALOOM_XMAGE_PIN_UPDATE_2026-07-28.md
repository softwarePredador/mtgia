# Atualização controlada do pin XMage — 2026-07-28

Status: `validated_in_source_not_deployed`.

## Decisão

O executor externo primário foi atualizado do pin histórico
`34d81ea4995ce15d7e1a788dc6d2a3595d35bcec` para o commit oficial
`2c43ec8cdb5cd475d47e6b555a4077151f476a3b` do branch `master` de
`magefree/mage`. A versão publicada pelo projeto continua `1.4.60`.

O avanço absorve 152 commits oficiais classificados antes da mudança:

- 100 commits de adição de cartas;
- 33 commits de correção de regras;
- 19 commits de engine;
- 169 cartas e 187 fixtures candidatas para revisão;
- lista de arquivos limitada aos primeiros 300 itens pela API oficial.

O pin não acompanha `master` automaticamente. O SHA foi congelado, propagado
para os seis mirrors ativos e permanece sujeito aos mesmos gates de identidade,
replay, persistência e promoção de regra.

## Compatibilidade e dependências

O upstream passou a usar `sqlite-jdbc 3.53.2.0`. O bootstrap e a imagem Docker
agora exigem essa versão exata em vez de reescrever a dependência para
`3.50.2.0`; isso evita downgrade e falha fechado se o grafo do pin revisado
divergir.

Os 47 tipos `mage.*` importados pelo sidecar e seus testes continuam presentes,
e os respectivos arquivos-fonte não mudaram entre os dois pins. O assembly
mantém os plugins `Computer - mad`, Freeform Commander, constructed e human
usados pelo contrato ManaLoom.

## Evidência executada

| Camada | Resultado |
| --- | --- |
| Build Maven `Mage.Server -am` | 33/33 módulos |
| Assembly `mage-server.zip` | PASS |
| Testes upstream focados nas regras alteradas | 72/72 |
| Testes do sidecar XMage | 28/28 |
| Contrato de execução XMage | 41/41 |
| Estratégia XMage | 29/29 |
| Capacidades XMage/Forge | 95/95, 20 capacidades |
| Gate canônico Battle | PASS, 46 checks de produto |
| Spike human vs AI | 9/9; 3/3 partidas do contrato |
| Batalha estrita v2 loopback | HTTP 200; 20 turnos; 700 eventos |
| Auditor de pins/mirrors | PASS, zero divergências |

O runtime loopback foi iniciado duas vezes a partir do artefato atualizado. Nos
dois boots, `/health` publicou o novo commit, `catalog_ready=true` e exatamente
32.561 nomes indexados, com identificadores de processo distintos. Os logs não
registraram erro de leitura de classe/JAR, plugin ausente ou fatal.

A batalha estrita v2 encerrou com vencedor, schema de learning correto e zero
erro de engine, timeout ou censura.

O endpoint `/cards/coverage` processou o snapshot canônico de 8.073 nomes:
7.820 foram reconhecidos e 253 permaneceram como lacunas estruturadas. Essa
medição é evidência de catálogo, não autorização para promover regra ou afirmar
execução semântica.

Uma comparação oficial repetida após a mudança retornou XMage com
`ahead_by=0` e o mesmo SHA no upstream. Forge permaneceu no pin separado
`a62915f500c2411484689294659c6bb84ea215f8`, com delta próprio que continua em
`review_required`; ele não foi promovido por esta atualização.

## Monitoramento semanal

Foi adicionada uma auditoria semanal somente leitura, descrita em
`docs/MANALOOM_EXTERNAL_ENGINE_DELTA_SCHEDULE.md`. Ela:

- nunca altera pins, runtime, PostgreSQL, Hermes/SQLite, regras ou decks;
- ignora o acesso de rede e registra `skipped` quando o checkout está sujo;
- grava apenas fora do checkout;
- retém somente seus relatórios timestampados por 180 dias;
- considera ausente, inválido, `fail`, `skipped` ou mais antigo que oito dias
  como estado não saudável;
- trata `review_required` como uma execução válida que exige revisão humana.

A ativação local deve ocorrer somente depois de o checkout ficar limpo:

```bash
./scripts/manaloom_install_external_engine_delta_schedule.sh --install
./scripts/manaloom_install_external_engine_delta_schedule.sh --check
```

## Limite operacional

Esta evidência valida fonte, build e runtime loopback. Ela não realizou deploy,
reinício ou mutação no ambiente de produção. O serviço publicado continua no
pin anterior até uma promoção operacional separada e explicitamente
autorizada.
