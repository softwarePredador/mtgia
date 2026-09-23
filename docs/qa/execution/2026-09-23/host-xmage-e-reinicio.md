# Receipt: XMage desligado, reinício do host e conserto do IP do balanceador (2026-09-23)

## Autorização e execução

- **Autorização:** o dono, na conversa de coordenação de 2026-09-23. Cada resposta vale para um passo:
  - "Desligar até o Battle abrir" (D-57): os dois serviços do XMage vão para 0 réplicas. Para religar, é só voltar para 1.
  - "Pode reiniciar agora" (D-58): aplicar as atualizações de segurança, reiniciar e conferir todos os serviços, inclusive os dos outros projetos.
  - "Subir agora": promover o `master` com `--no-verify` e fazer o deploy do backend com o conserto.
- **Executado por:** sessão coordenadora (Claude).
  - O acesso ao host foi por SSH, com a mesma chave e a mesma âncora de host do deploy.
  - Das variáveis de ambiente dos contêineres, só foram lidas as duas chaves de proxy do backend (`MANALOOM_TRUSTED_PROXY_HOPS` e `MANALOOM_TRUSTED_PROXY_PEERS`), que não são segredo.
  - Não foi criado bucket nem conta.

## Leitura de capacidade (D-14, 09:13 UTC, somente leitura)

- **Máquina:** 4 vCPU; RAM de 7.941 MB, com 3.694 MB disponíveis; disco `/` em 70%, com 48 GB livres; 81 dias no ar.
- **Reinício pendente:** `libc6` e os kernels 6.8.0-134 a 6.8.0-139 já estavam instalados, mas o host rodava o 6.8.0-124.
- **Maiores consumidores:** com o Battle desligado, o XMage interativo ocupava 1,36 GiB e o XMage batch 1,00 GiB, com limite de 4 GiB cada. Depois vinham `manaloom-postgres` (212 MiB) e `easypanel` (110 MiB). Backend, ops, site, `/app` e `forge-sidecar` ficavam abaixo de 50 MiB cada.
- **Host compartilhado** com os outros projetos do dono: carmatch (com worker e redis), drivematchpost, jg-campanhas (3 serviços), revendas-web e mobile-web.

## Passos

| Hora (UTC) | Passo | Resultado |
| --- | --- | --- |
| 09:22:09 | Retrato do host, somente leitura | 20 serviços, todos 1/1. Fora do swarm havia 2 contêineres: `manaloom-local-registry` (restart `unless-stopped`) e `manaloom-pg-local-proxy` (restart **`no`**) |
| 09:22 | GET nos 19 domínios do Traefik e em `brewtact.com/app/` | 200 em todos, menos `www.brewtact.com` (301) e o painel do Traefik (403) |
| 09:23:47 | `docker service scale evolution_xmage-interactive=0 evolution_xmage-sidecar=0` | 0/0. Memória usada caiu de 4.298 para 1.851 MB; disponível subiu de 3.642 para 6.089 MB. Os dois serviços usam a imagem `localhost:5000/manaloom/xmage-sidecar@sha256:70b87efe7beb7287d7d094c8abe940e0a2f1e944cb4f064eff4f9907a11e2f67` |
| 09:24:53 | Observação do BrewTact | `healthy` em `166aaed57`, ready com a 058, Battle e IA `disabled` |
| 09:25 | `apt-get update` e simulação do `unattended-upgrade` com a política do próprio host (só `noble-security` e ESM) | Só o `sudo` estava pendente |
| 09:25:42 | `unattended-upgrade` | `sudo` em 1.9.15p5-3ubuntu5.24.04.3; `dpkg --audit` limpo; GRUB apontando para o 6.8.0-139 |
| 09:26:09 | Reinício agendado com `systemd-run --on-active=10 systemctl reboot` | — |
| 09:27:22 | SSH de volta | Kernel 6.8.0-139-generic, sem reinício pendente. O SSH ficou fora entre 09:26:40 e 09:27:22 |
| 09:27:36 | Serviços convergidos | 18 serviços 1/1 e o XMage 0/0. As unidades systemd em execução são as mesmas de antes |
| 09:28:02 | `docker start manaloom-pg-local-proxy` | De volta em `127.0.0.1:15432`. Sem ele, o backup e as migrations por `server/bin/with_new_server_pg.sh` falham |
| 09:28 | GET nos mesmos 20 endereços | **Mesmos códigos de antes** |
| 09:28:26 | Observação do BrewTact | `healthy` em `166aaed57`, ready com a 058, 29 capabilities desligadas. **Login com 503 `rate_limit_identity_unavailable`** (antes: 401) |
| 10:56:29 | Promoção do `master` com `git push --no-verify` (autorizado) | `166aaed57..22a7749a7`, avanço direto de 3 commits: `bedafe8bf` (D-56), `47dc3b698` (registro) e `22a7749a7` (conserto) |
| 10:56:35–11:01:25 | Deploy do backend (`scripts/manaloom_deploy_backend_image.sh`), com a configuração de e-mail herdada da spec sem exibir nem gravar valores | **deployed**: `cartinhas@sha256:0903537b8c6ef8142e63a88c71dea17d5db67709b589ae76deb4fa5c84ab0406`, `git_sha 22a7749a77f7316000f8cf7229bab247f1d6b9dc`, 29/29 off; o portão de topologia aceitou o par 10.11.0.14 |
| 11:01:41 | Observação externa | `healthy` em `22a7749a7`, ready com a 058, 29/29 off. **Login de conta inexistente voltou a 401 "Credenciais inválidas"**. Corpo inválido 400; relatório inexistente 404; `GET /users/me/export` 404; cadastro 404 `capability_unavailable`. Nenhum `untrusted_proxy_peer` no log depois do deploy. Os 20 endereços do Traefik mantêm os códigos de antes; os 20 serviços estão no número de réplicas pedido; memória disponível 6.484 MB |

## Regressão causada pelo reinício, e o conserto

**O que aconteceu.** No reinício, o Swarm deu outro endereço ao balanceador da rede overlay `easypanel` (`lb-easypanel`): 10.11.0.4 passou a 10.11.0.14. O backend só confiava no par de transporte fixado (`MANALOOM_TRUSTED_PROXY_PEERS=10.11.0.4/32`). Com isso, toda rota com limite de tentativas falhava fechada, e o log registrava `code=untrusted_proxy_peer`. O login ficou em 503 das 09:27 às 11:01 UTC.

**Risco de segurança: nenhum.** O 10.11.0.4 ficou sem dono no host, então nenhum outro contêiner herdou a confiança. A produção não tem uso desde 2026-08-03.

**Conserto (`22a7749a7`):**
- A constante `MANALOOM_PRODUCTION_PROXY_TRANSPORT_PEER_IPV4` em `scripts/lib/manaloom_release_runtime_contract.sh` foi fixada no endereço novo.
- Os dois testes que conferem a constante foram atualizados. Os dois falham se ela voltar a 10.11.0.4.
- O comentário do contrato agora diz que um reinício pode mover o endereço.
- O deploy levou junto a D-56 (`bedafe8bf`). Com `decks_private` desligada, as rotas de deck continuam sem responder.

**Pendência estrutural (D-59):** a confiança presa a um IP que o Swarm troca no reinício é frágil.

## O que ficou de fora

- **Pacotes não aplicados.** Depois do reinício, `apt list --upgradable` mostra 47 pacotes, nenhum de segurança. Aplicar é decisão à parte (D-61):
  - 41 de `noble-updates`, entre eles o kernel 6.8.0-142 (`linux-image-virtual`);
  - 6 do repositório da Docker, entre eles Docker 29.6.1 → 29.8.1 e containerd 2.2.5 → 2.3.5, o que troca o runtime do swarm.
- **Restart do `manaloom-pg-local-proxy`.** A política segue `no` e o contêiner não está no repositório. Mudar é configuração persistente (D-60).
- **Religar o XMage** quando o Battle abrir: `docker service scale evolution_xmage-interactive=1 evolution_xmage-sidecar=1`. O deploy do backend só exige o XMage interativo quando `MANALOOM_RELEASE_ENABLE_INTERACTIVE_BATTLE=1`.
