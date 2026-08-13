# ADR 0011 — `brewtact.com` como domínio público canônico

- Status: accepted
- Date: 2026-08-11
- Scope: origem pública, SEO, CORS, links de autenticação e coordenadas de
  deploy Web
- Supersedes: a condição provisória de domínio descrita no ADR 0010, itens
  10, Consequences e Review triggers

## Context

O projeto adquiriu e configurou `brewtact.com` depois da aceitação do ADR
0010. O apex já termina TLS no proxy de produção e encaminha o site público,
`/app` e as rotas profundas para os serviços existentes. `www.brewtact.com`
redireciona permanentemente para o apex.

Manter o host EasyPanel como origem pública produziria metadata, sitemap,
links compartilháveis e e-mails de autenticação fora do domínio controlado.
Também faria o navegador bloquear o app em `brewtact.com`, porque o backend
aplica CORS por origem HTTPS exata.

## Decision

1. A origem pública canônica é `https://brewtact.com`, sem `www` e sem path.
2. `https://www.brewtact.com` existe somente como entrada compatível e
   redireciona para o apex.
3. `NEXT_PUBLIC_SITE_URL`, o fallback de links públicos do backend, metadata,
   Open Graph, robots e sitemap usam a origem canônica.
4. A allowlist CORS de produção inclui o apex, `www` e o host público EasyPanel
   legado. O apex é obrigatório; não são aceitos wildcard, HTTP, path, query ou
   credenciais.
5. Reset de senha e verificação de e-mail apontam para as rotas do app em
   `https://brewtact.com/app/`.
6. O host `evolution-manaloom-web-public.2ta7qx.easypanel.host` permanece como
   coordenada técnica para smoke, rollout e rollback. Seu nome interno não é
   identidade pública.
7. A API continua em
   `https://evolution-cartinhas.2ta7qx.easypanel.host`; adotar um subdomínio
   próprio para a API exige decisão posterior e migração independente.
8. A adoção do domínio não autoriza troca da imagem backend, migration,
   escrita PostgreSQL ou alteração de identificadores internos.

## Consequences

- Usuários, crawlers e previews recebem a mesma origem BrewTact.
- A build Flutter pode chamar a API atual a partir do novo domínio sem ser
  bloqueada por CORS.
- O alias EasyPanel continua disponível para rollback e compatibilidade, mas
  não recebe crédito de URL canônica.
- Futuros deploys backend falham quando a allowlist não inclui
  `https://brewtact.com`.
- A renovação do domínio, privacidade do registro, TLS e integridade DNS passam
  a ser dependências operacionais de produção.

## Validation

- `https://brewtact.com/`, `/app/` e rotas profundas retornam `200`;
- `https://www.brewtact.com/*` redireciona para o apex;
- título, manifest, favicon, Open Graph, robots e sitemap usam BrewTact;
- preflight `OPTIONS /auth/login` retorna a origem exata do apex;
- site público e app rodam em imagens imutáveis e convergidas `1/1`;
- backend preserva imagem, SHA, schema e migrations durante a troca de origem;
- gates de contrato, projeto lógico e release permanecem verdes.

## Rejected alternatives

- Tornar o host EasyPanel canônico: mantém dependência pública de uma
  coordenada de infraestrutura e fragmenta SEO.
- Tornar `www` canônico: adiciona uma variante sem benefício e amplia links
  duplicados.
- Usar wildcard CORS: remove a fronteira explícita exigida pelo backend.
- Migrar simultaneamente API, serviços e identificadores internos: amplia o
  risco sem ser necessário para adotar o domínio público.

## Review triggers

Revisar ao migrar a API para domínio próprio, alterar registrador/DNS, ativar
HSTS preload, remover o alias EasyPanel ou publicar aplicativos nas lojas.

## Adendo de escopo da Beta gratuita — 2026-08-13

Esta decisão fixa coordenadas e identidade pública; ela não habilita produto.
Na revisão corrente, a matriz server-authoritative permanece totalmente
`OFF`, o site é apenas informativo e não oferece CTA para `/app`. Os retornos
`200` históricos de `/app` e das rotas profundas não valem como receipt da
revisão atual. Qualquer abertura futura exige capability, artefato e prova
same-SHA próprios, conforme a decisão corrente de produto.
