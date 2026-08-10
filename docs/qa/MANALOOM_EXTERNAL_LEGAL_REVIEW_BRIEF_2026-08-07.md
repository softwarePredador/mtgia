# ManaLoom — briefing para revisão jurídica externa

Data da pesquisa: 2026-08-07
Estado: `OFFICIAL_SOURCE_REVIEW_COMPLETE · LICENSED_COUNSEL_SIGNOFF_PENDING · COMMERCIAL_RELEASE_BLOCKED`

## Limite deste documento

Este é um inventário técnico-jurídico preparado a partir do produto, dos
contratos do repositório e de fontes primárias vigentes. Ele não é parecer
jurídico, não identifica advogado responsável e não libera lançamento
comercial. A aprovação final de termos, privacidade, proteção de menores,
marketplace, IA, propriedade intelectual e monetização precisa ser emitida por
profissional habilitado com acesso à entidade operadora, fornecedores,
contratos e arquitetura de produção.

## Decisão de release

- A beta pode continuar tecnicamente gratuita, desde que produto confirme com
  advogado o público permitido e remova promessas comerciais conflitantes.
- Assinatura, checkout, publicidade condicionante ou paywall continuam
  bloqueados. O backend e o app já deixam cobrança desativada por padrão, mas o
  site público ainda apresenta Free/Pro, limites e CTA de upgrade.
- Cadastro social, mensagens, perfis, fichário e trades não devem ser lançados
  ao público antes de fechar a análise de acesso provável por menores e os
  controles exigidos pelo Estatuto Digital da Criança e do Adolescente.
- A pesquisa oficial está completa para encaminhamento; o gate
  `LICENSED_COUNSEL_SIGNOFF` continua vermelho.

## Superfícies e fatos verificados

### Documentos públicos atuais

- `app/lib/features/commercial/screens/legal_screen.dart` apresenta versões,
  disclaimer de IA, IP/conteúdo de fã, trades, monetização e uma única seção
  curta de privacidade.
- `web-public/src/app/legal/privacy/page.tsx` contém três parágrafos sobre
  público/privado; não é um aviso de privacidade completo.
- `web-public/src/app/legal/terms/page.tsx` contém três parágrafos e menciona
  recursos Free/Pro.
- `web-public/src/lib/product-data.ts` divulga plano Pro, 200 ações de IA,
  upgrade e recursos sociais, enquanto
  `server/lib/billing/payment_provider.dart` bloqueia toda cobrança na beta e
  `CommercialLaunchPolicy` declara beta gratuita.
- O registro persiste aceite versionado (`Termos 2026-08-05` e `Privacidade
  2026-07-21`). Exportação de dados e exclusão de conta existem no app/backend,
  mas o aviso público não explica como exercê-las nem seus limites.

### Categorias de tratamento encontradas

- conta, e-mail, username, senha derivada, sessões, verificação e recuperação;
- perfis, follows, blocks, conteúdo publicado, comentários, denúncias e
  moderação;
- decks, coleção, fichário, disponibilidade, preços informados e identidade
  física de cartas;
- propostas de trade, itens, mensagens, histórico e notificações;
- partidas, replays, notas pós-jogo, preferências, prompts, respostas e
  telemetria de IA;
- tokens de push e métricas técnicas quando Firebase estiver habilitado;
- identificador de usuário e eventos sanitizados quando Sentry estiver
  configurado.

Fornecedores e transferências a confirmar no ambiente de produção incluem
OpenAI, Firebase/Google, Sentry, hospedagem, e-mail e demais subprocessadores.
Scryfall/Wizards participam do contrato de dados e imagens; XMage/Forge são
motores técnicos, não uma licença de IP.

## Achados prioritários

### P0-JUR-01 — controlador e canal de privacidade ausentes

O app e o site não identificam razão social/nome do controlador, CNPJ ou
equivalente, endereço, jurisdição, contato de privacidade nem canal do
encarregado. A LGPD exige informação clara sobre identidade e contato do
controlador e direitos do titular. A necessidade formal de encarregado ou
eventual dispensa para agente de pequeno porte deve ser decidida pelo advogado;
dispensa não elimina transparência nem canal para titulares.

Aceite: entidade e contatos publicados no app/site; owner operacional;
procedimento autenticado e não autenticado para solicitações; SLA e trilha de
atendimento definidos.

### P0-JUR-02 — aviso de privacidade materialmente incompleto

Faltam, no mínimo, mapa finalidade × categoria × base legal, origem, duração e
retenção, compartilhamentos e subprocessadores, transferências internacionais,
cookies/SDKs, segurança, descarte, decisões automatizadas, direitos do titular,
canal de reclamação e política para menores. O checkbox de cadastro é um aceite
global e não substitui bases legais específicas nem consentimentos destacados
quando necessários.

Aceite: Registro de Operações de Tratamento aprovado; tabela de retenção por
entidade; aviso em camadas consistente entre app e site; versão elevada e
reaceite apenas onde juridicamente exigido.

### P0-JUR-03 — menores e Estatuto Digital sem programa comprovado

A Lei 15.211/2025 está vigente desde 17 de março de 2026 e alcança serviço de
acesso provável por crianças ou adolescentes. O ManaLoom combina tema de jogo,
perfis, conteúdo público, mensagens e trades, portanto deve ser tratado como
provavelmente acessível até parecer em contrário. Não foi encontrada prova de
classificação etária, avaliação de risco infantil, privacidade protetiva por
padrão, fluxo parental, tratamento especial de denúncias, prevenção de contato
nocivo ou política própria de idade.

Aceite: decisão documentada de público/idade; DPIA/RIPD de menores; configuração
mais protetiva por padrão; desenho de aferição de idade proporcional e
minimizador; controles parentais e de segurança; termos/copy adequados à faixa
etária; validação especializada antes de liberar social/trades.

### P0-JUR-04 — promessa Pro incompatível com a beta e com o gate de IP

O site público anuncia Pro e “upgrade necessário”, apesar de checkout e
webhooks retornarem beta gratuita. Além do risco de informação comercial
inconsistente, a Política de Conteúdo de Fãs da Wizards exige acesso gratuito ao
conteúdo que usa seu IP, e as regras da API Scryfall proíbem paywall de dados de
cartas. O contrato interno já bloqueia monetização, mas a comunicação pública
não está alinhada.

Aceite: remover/rotular como roadmap não contratável toda oferta Pro enquanto a
beta for gratuita; parecer específico sobre quais recursos podem ser pagos sem
restringir IP/dados de terceiros; autorização/licença adicional se necessária;
revisão de marcas, símbolos, imagens e atribuições.

### P0-JUR-05 — fornecedores e transferências internacionais não fechados

O código permite OpenAI, Firebase e Sentry, mas os documentos públicos não
nomeiam finalidades, dados enviados, países, retenção nem mecanismos de
transferência. Desde agosto de 2025, contratos que usam o mecanismo contratual
de transferência devem incorporar as cláusulas-padrão da Resolução ANPD
19/2024, salvo outro mecanismo válido.

Aceite: inventário de produção e subprocessadores; DPA/termos; localização;
base/mecanismo por fluxo; cláusulas da ANPD quando aplicáveis; instruções de
exclusão/export; configuração para não enviar decks, mensagens ou prompts além
do necessário.

### P1-JUR-06 — termos insuficientes para conta, UGC e social/trades

Faltam elegibilidade/idade, regras de conta, licença limitada de conteúdo do
usuário, conduta, moderação, denúncia/recurso, suspensão, retirada, fraude,
autenticidade, entrega, pagamentos externos, responsabilidade de cada parte,
lei/foro, atualização de termos e contato. O disclaimer de que o ManaLoom não
garante trade ajuda, mas não define o papel jurídico da plataforma nem resolve
CDC, responsabilidade ou segurança.

### P1-JUR-07 — IA e decisões automatizadas

O produto já mostra preview e revisão humana antes de aplicar mudanças de deck,
o que é uma boa salvaguarda. Ainda faltam finalidade/base legal para prompts e
telemetria, retenção, subprocessador, transferência, opt-out quando aplicável,
explicação dos critérios e procedimento de revisão de decisão que afete
interesses do usuário.

### P1-JUR-08 — resposta a incidentes e retenção regulatória

Há sanitização técnica de logs e exclusão/exportação, mas este recorte não
comprovou matriz operacional de incidentes, responsáveis, avaliação de risco,
comunicação ou registro regulatório. A Resolução ANPD 15/2024 prevê comunicação
à ANPD e aos titulares em três dias úteis quando houver risco ou dano relevante
e guarda do registro do incidente por pelo menos cinco anos.

### P1-JUR-09 — eventual comércio eletrônico

Antes de qualquer plano pago, o fluxo precisa de identificação ostensiva do
fornecedor, preço total, renovação/cancelamento, suporte, confirmação do
contrato, arrependimento, reembolso, tributos, acessibilidade e prova de
consentimento. Disclaimers não podem afastar direitos inderrogáveis do
consumidor.

## Propriedade intelectual e arte de cartas

O contrato `MANALOOM_CARD_ART_SOURCE_CACHE_AND_RIGHTS_CONTRACT.md` está
tecnicamente coerente com as fontes consultadas: imagem completa sem crop,
distorção, filtros ou watermark; aviso não oficial; atribuição; ausência de
proxy de catálogo; acesso gratuito. Permanecem como decisões exclusivas de
advogado/licenciante:

1. se todo o produto cabe na Fan Content Policy ou requer licença escrita;
2. se login obrigatório restringe indevidamente acesso a dados/imagens;
3. quais recursos próprios podem ser monetizados sem paywall indireto;
4. uso de nomes, símbolos, frames, screenshots e materiais promocionais;
5. procedimento de retirada e resposta a titulares de IP.

## Perguntas obrigatórias ao advogado externo

1. Qual é a entidade controladora, país, endereço e foro?
2. O ManaLoom aceitará menores? Qual classificação etária e quais regiões?
3. Quais recursos serão públicos, autenticados, gratuitos e futuramente pagos?
4. Quem hospeda API/PostgreSQL/Web e em quais países?
5. OpenAI, Firebase, Sentry e e-mail estarão habilitados em produção? Com quais
   dados, retenção e contratos?
6. Que bases legais se aplicam a conta, segurança, social, trades, IA,
   marketing, métricas e conteúdo público?
7. Qual tabela de retenção e quais exceções legais sobrevivem à exclusão?
8. Qual será o canal de direitos, encarregado e resposta a incidentes?
9. O ManaLoom é mero facilitador de trades ou participa da relação de consumo?
10. Existe autorização escrita para uso comercial do IP de Wizards e dados ou
    imagens Scryfall?

## Fontes primárias consultadas

- [LGPD — Lei 13.709/2018](https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm)
- [Marco Civil da Internet — Lei 12.965/2014](https://www.planalto.gov.br/ccivil_03/_ato2011-2014/2014/lei/l12965.htm)
- [Código de Defesa do Consumidor — Lei 8.078/1990](https://www.planalto.gov.br/ccivil_03/leis/l8078compilado.htm)
- [Decreto do comércio eletrônico — Decreto 7.962/2013](https://www.planalto.gov.br/ccivil_03/_ato2011-2014/2013/decreto/d7962.htm)
- [Estatuto Digital da Criança e do Adolescente — Lei 15.211/2025](https://www.planalto.gov.br/ccivil_03/_ato2023-2026/2025/lei/l15211.htm)
- [ANPD — Aviso de Privacidade](https://www.gov.br/anpd/pt-br/acesso-a-informacao/aviso-de-privacidade)
- [ANPD — Comunicação de Incidente de Segurança](https://www.gov.br/anpd/pt-br/canais_atendimento/agente-de-tratamento/comunicado-de-incidente-de-seguranca-cis)
- [ANPD — Transferência Internacional de Dados](https://www.gov.br/anpd/pt-br/assuntos/assuntos-internacionais/transferencia-internacional-de-dados)
- [Wizards — Fan Content Policy](https://company.wizards.com/en/legal/fancontentpolicy)
- [Wizards — Terms](https://company.wizards.com/en/legal/terms)
- [Scryfall — API Overview & Rules](https://scryfall.com/docs/api)
- [Scryfall — Card Imagery](https://scryfall.com/docs/api/images)

## Próximo artefato externo esperado

O gate só muda para verde quando houver parecer ou memorando assinado que:

- responda às dez perguntas;
- aprove textos finais versionados de Termos, Privacidade, Cookies, IA,
  Comunidade/Trades e Menores;
- registre ressalvas, jurisdição, data, profissional e próxima revisão;
- autorize explicitamente ou mantenha bloqueada a monetização e o uso de IP.
