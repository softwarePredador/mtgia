# ManaLoom Flutter Web App Runbook

Data: 2026-07-01
Status: `READY_FOR_LOCAL_QA_AND_REACT_INTEGRATION`

## Objetivo

Preparar a camada Flutter Web logada do ManaLoom para rodar como `/app` dentro
do mesmo dominio da web publica React/Next.

```text
manaloom.com/*
React/Next publico

manaloom.com/app/*
Flutter Web logado
```

## Build validado

Comando executado em `app/`:

```sh
flutter build web --base-href /app/
```

Resultado em 2026-07-01:

- Build `PASS`.
- Saida gerada em `app/build/web`.
- `app/build/web/index.html` contem `<base href="/app/">`.
- Wasm dry run passou, entao um build futuro com `--wasm` pode ser testado em
  uma etapa separada.

## Build com Sentry

O codigo do app inicializa Sentry somente quando o build recebe `SENTRY_DSN`.
Sem esse define, o app segue funcionando e registra no console:

```text
[Observability] Sentry desabilitado: SENTRY_DSN vazio.
```

Para build web com Sentry ativo:

```sh
flutter build web \
  --base-href /app/ \
  --dart-define=SENTRY_DSN=<sentry-web-dsn> \
  --dart-define=SENTRY_ENVIRONMENT=staging \
  --dart-define=SENTRY_RELEASE=manaloom-web@<versao>
```

Nao versionar DSN, token Sentry, JWT ou payloads de auth.

## QA local

Depois do build, servir o bundle no mesmo prefixo final:

```sh
python3 tool/serve_flutter_web_app.py --port 8088
```

Abrir:

```text
http://127.0.0.1:8088/app/
```

O helper serve `build/web` em `/app/` e faz fallback de rotas profundas para
`index.html`, permitindo testar refresh direto em URLs do app.

Checks rapidos:

```sh
curl -I http://127.0.0.1:8088/app/
curl -I http://127.0.0.1:8088/app/main.dart.js
curl -I http://127.0.0.1:8088/app/decks
```

Esperado:

- `/app/` retorna `200`.
- `/app/main.dart.js` retorna `200`.
- `/app/decks` retorna `200` com `index.html`, para o router do Flutter assumir.

## Contrato de deploy

O deploy precisa publicar o conteudo de `app/build/web` sob o prefixo `/app/`.
Tambem precisa aplicar fallback SPA:

```text
/app/* -> app/build/web/<asset se existir>
/app/* -> app/build/web/index.html se asset nao existir
```

Exemplo conceitual de reverse proxy:

```text
location /app/ {
  try_files $uri $uri/ /app/index.html;
}
```

Se React/Next estiver no dominio raiz, os assets do Flutter nao devem ser
movidos para `/`; eles devem continuar sob `/app/` para combinar com o
`base-href`.

## Estado das rotas

As rotas internas ainda continuam declaradas no Flutter sem prefixo no codigo
(`/home`, `/decks`, `/profile`, etc.). O build com `--base-href /app/` permite
servir o app sob `/app/`; a decisao de migrar nomes internos para `/app/home`
deve ser tomada apenas se o roteador/proxy exigir URLs sem hash e com path
externo completo.

Para a primeira integracao com React:

- CTAs publicos devem apontar para `/app`.
- Links profundos para telas internas devem esperar a validacao final de
  roteamento web.

## Recursos nativos no Flutter Web

Neste corte:

- Push Firebase fica desabilitado no web durante o startup.
- Firebase Performance fica desabilitado no web.
- Scanner fica protegido pela feature flag existente e cai para busca.
- Contador Lotus/WebView abre um fallback web em vez de instanciar WebView no
  navegador.

Isso mantem a web logada funcional para deck builder, IA, colecao, planos,
perfil, comunidade, trade e retencao, sem prometer suporte web completo para
recursos nativos.

## Proximos passos

1. Rodar QA visual com o helper local.
2. Testar login e rotas principais contra backend esperado.
3. Repetir build com `SENTRY_DSN` real quando houver DSN seguro no ambiente.
4. Configurar o deploy real com `/app/` e fallback SPA.
5. Integrar CTAs do React publico para `/app`.
6. Depois de estabilizar o proxy, decidir se links publicos profundos devem
   apontar para `/app/#/...` ou para caminhos diretos via path strategy.
