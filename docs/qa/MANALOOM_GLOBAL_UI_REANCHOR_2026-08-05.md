# ManaLoom — reancoragem global de evidência UI

Data de fechamento: 2026-08-06
Digest UI: `f45f96e34ca6b00c34952b25631c6ff3157e85e39afc06e1f8394e1484f0e90e`
Estado: `PASS_AUTOMATED · PASS_RUNTIME · PASS_VISUAL_REVIEWED`
Aggregate canônico: [ui-live/latest.json](ui-live/latest.json)

## Resultado

A reancoragem global foi concluída no mesmo digest com `26/26` manifests e
`453/453` PNGs. Cada imagem foi aberta individualmente e seus bytes, dimensões
e SHA-256 foram reconciliados com o manifest de captura correspondente. Não
foi encontrado bloqueador visual, tela em branco, stack trace exposto, imagem
quebrada, overflow destrutivo, campo mobile espremido ou perda permanente de
CTA/navegação.

| Superfície | Perfis | Capturas |
|---|---:|---:|
| Matriz P0 Web mobile/desktop/wide + Samsung físico | 4 | 214 |
| Battle Live Web | 1 | 5 |
| Binder Import Web | 3 | 21 |
| Deck Workshop Web | 3 | 24 |
| Battle Learning Web | 3 | 30 |
| Social/Trade Web | 3 | 48 |
| Onboarding Intent Web | 3 | 15 |
| Visual System Workspace Web | 3 | 30 |
| Critical Overlays and States Web | 3 | 66 |
| **Total** | **26** | **453** |

Os perfis Web usaram build release real em Chrome 150. O Samsung SM-A135M
físico, Android 14, concluiu `54/54` checkpoints em 1080×2408, incluindo
capturas ADB nativas de busca/teclado e Life Counter em landscape 2408×1080.
Fixtures ficaram restritas a loopback ou memória e foram encerradas sem
escrita em dados live.

## Parecer visual

Os dez critérios obrigatórios passaram: hierarquia visual, identidade
ManaLoom/Magic, cor e contraste, tipografia, spacing/densidade, responsividade,
clareza de interação, cobertura de estados, acessibilidade visual e
atratividade.

A tese Obsidian/Frost/Brass está coesa. Home, detalhe de carta, decks, Binder,
Oficina, Battle Learning, trocas, onboarding e perfis usam carta, comandante,
deck, partida ou pessoa como contexto real; não dependem apenas de cards
genéricos. Loading, validação, saving, erro, retry, offline, histórico,
reconnect, timeout, conclusão, sessão expirada e permissão negada possuem
estados distinguíveis e recuperáveis.

A reclamação anterior de campos estreitos não reapareceu. Formulários mobile,
incluindo proposta de troca e Profile, preservam largura útil e gutters.

## Backlog visual priorizado

1. **P1 — abas mobile do detalhe de deck:** `Visão Geral` aparece como
   `Visão Ge` em Web mobile e Android. O conteúdo continua acessível, mas a aba
   precisa de compactação ou affordance horizontal mais clara.
2. **P1 — densidade desktop/wide:** vazios, resultados únicos e algumas telas
   administrativas subutilizam o canvas e ainda parecem uma composição mobile
   ampliada.
3. **P2 — carrosséis mobile:** cartas, printings e evidências expõem parte do
   próximo item sem comunicar suficientemente a rolagem horizontal.
4. **P2 — identidade longa:** nomes extensos no Profile quebram em muitas
   linhas; é necessário padronizar wrap/ellipsis sem perder o nome acessível.
5. **P2 — qualidade da fixture/evidência:** substituir `Revisão aaaaaaaa
   preservada` por texto realista e capturar a recuperação de comandante com
   o contexto do CTA pai. O checkpoint atual monta deliberadamente apenas o
   seletor; não prova ausência funcional do CTA na tela real.
6. **P2/governança — Legal/Privacy:** reduzir áreas vazias quando o conteúdo é
   curto e obter revisão jurídica externa antes de lançamento comercial.

Nenhum item acima bloqueia a evidência no digest corrente. Qualquer mudança
app-facing que os corrija invalida esta aprovação e exige nova captura no novo
digest.

## Rastreabilidade

O [aggregate canônico](ui-live/latest.json) registra os 26 caminhos de
manifest, seus SHA-256 exatos, perfis, contagens, comandos automatizados,
teses visuais, notas dos dez critérios e os follow-ups. A validação estrutural
recalculou todos os hashes e dimensões: `453 válidos; 0 inválidos`.

O `ui-audit` final detectou dois goldens comerciais ainda ancorados no modelo
antigo de quota. Eles foram regenerados exclusivamente para refletir a mudança
intencional do Pack 07 — `ações usadas`, percentual e disponibilidade —,
abertos e revisados. A repetição do gate concluiu com analyzer limpo, `56/56`
testes e o `ui-proof` interno em `PASS`. Goldens não participam do digest da
prova runtime; o digest `f45f96e3…` permaneceu estável.

## Limites de release

Esta reancoragem conclui a prova visual global; ela não aprova release. Ainda
permanecem verificações separadas:

- TalkBack humano no Android físico;
- smoke de hardware/release no Samsung;
- teclado Web de hardware real;
- VoiceOver/iOS, deferido pelo escopo atual;
- revisão jurídica externa para Legal/Privacy.

Também não autoriza migration, deploy, alteração de pins, regras, decks,
PostgreSQL, Hermes/SQLite, commit ou push. O checkout sujo preexistente foi
preservado.

## Próxima decisão recomendada

Abrir um pacote de polish responsivo começando pelas duas dívidas `P1`: abas
mobile do detalhe de deck e recomposição de densidade desktop/wide. Em
paralelo, executar os três gates humanos/de hardware de release sem misturá-los
com o crédito visual já concluído.
