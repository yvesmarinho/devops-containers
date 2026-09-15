<!-- Criado em: 08/01/2025 -->
<!-- Modificado em: 15/09/2026 11:44 -->

# Traefik — Reverse Proxy / Edge Router

Container Traefik com TLS automático (Let's Encrypt), dashboard protegido por
autenticação e cabeçalhos de segurança reutilizáveis por outros serviços da
rede `web`.

## Aviso de segurança (revisão 15/09/2026)

Esta pasta foi revisada e reorganizada. O que mudou:

- **Removido `--api.insecure=true`** e a publicação direta da porta `9090` —
  o dashboard só é acessível via HTTPS, roteador dedicado e `basicAuth`.
- **Removidos `traefik.toml`, `traefik.yaml` (compose duplicado) e
  `traefik_dynamic.toml`** — a config estática agora vive só no `command:` do
  `docker-compose.yaml` e a dinâmica em labels, evitando fontes de verdade
  conflitantes.
- **Removido `traefik_create_sctructure.sh`**, que continha uma chave privada
  RSA de conta ACME hardcoded em texto plano (secret leak). O arquivo nunca
  chegou a ser versionado no Git deste projeto, então não houve exposição via
  repositório remoto; ainda assim, se essa chave já tiver sido usada em
  produção, trate-a como comprometida e deixe o Traefik criar uma conta ACME
  nova (basta não reaproveitar nenhum `acme.json` antigo).
- **Removido `traefik.sh`** (dumper de certificados via `wget` sem checagem de
  integridade, apontando para uma URL de branch inexistente) — risco de
  supply-chain sem uso real neste setup baseado em labels do Docker.
- Domínio/e-mail reais foram substituídos por placeholders em `.env.example`.
- Senha do dashboard não fica mais hardcoded em nenhum arquivo de config —
  vem de `.secrets/traefik_users` (nunca versionado).

## Pré-requisitos

- Docker e Docker Compose instalados.
- DNS do domínio do dashboard apontando para o host.

## Configuração inicial

1. Copiar `.env.example` para `.env` e preencher `ACME_EMAIL` e
   `TRAEFIK_DASHBOARD_HOST` com valores reais:
   ```bash
   cp .env.example .env
   ```

2. Criar a rede Docker externa e a estrutura de pastas (`acme/`, `logs/`,
   `.secrets/`), o que já inclui preparar o `acme.json`:
   ```bash
   ./scripts/setup-network.sh
   ```
   `setup-network.sh` chama `scripts/init-acme.sh` internamente. Rode
   `init-acme.sh` sozinho só se precisar recriar/zerar o `acme.json` sem
   mexer na rede Docker (ex.: trocar de conta ACME) — ver
   "Trocando a conta ACME" abaixo.

3. Gerar o usuário/senha do dashboard (hash `bcrypt`, mais forte que `apr1`):
   ```bash
   docker run --rm --entrypoint htpasswd httpd:2 -nib admin password > .secrets/traefik_users
   ```
   Ajustar permissões: `chmod 600 .secrets/traefik_users`.

4. Subir o container:
   ```bash
   docker compose up -d
   ```

5. Verificar logs em `logs/traefik.log` e `logs/access.log` (formato JSON).

## Expondo um novo serviço

Não crie o `docker-compose.yaml` de cada aplicação à mão: use o modelo em
[containers/modelo-traefik](../modelo-traefik/README.md), que já vem com
`expose:` (nunca publica a porta da app no host), `loadbalancer.server.port`
definido e um middleware de headers de segurança próprio por serviço
(self-contained — não depende deste container `traefik` estar com uma label
específica no ar; ver o motivo dessa escolha no README do modelo).

```bash
cd ../modelo-traefik
./scripts/apply-placeholders.sh \
  -o /caminho/para/minha-app \
  -n minha-app \
  -i ghcr.io/org/minha-app:1.0.0 \
  -s minha-app \
  -d example.com \
  -p 8080
```

O único requisito deste lado é que o serviço gerado esteja na mesma rede
externa `web` (já é o padrão do modelo) — o Traefik descobre e roteia
automaticamente via `providers.docker`, sem precisar editar este
`docker-compose.yaml`.

## Trocando a conta ACME

Nem o Traefik nem este repositório "geram uma chave ACME" no sentido de criar
uma chave privada por conta própria antes do fato — isso é feito
automaticamente pelo Traefik no primeiro start, seguindo o protocolo ACME
(registro de conta + emissão via HTTP challenge), usando a config já presente
em `docker-compose.yaml` (`certificatesResolvers.letsencrypt`). O único passo
manual é garantir que `acme.json` exista com permissão `600` antes de subir o
container — é isso que `scripts/init-acme.sh` faz.

Para forçar uma conta ACME nova (ex.: suspeita de comprometimento da atual,
mudança de e-mail de contato):
```bash
docker compose down
rm -f acme/acme.json
./scripts/init-acme.sh
docker compose up -d
```
O Traefik registra uma conta nova e reemite os certificados na subida
seguinte. Nunca edite `acme.json` manualmente para inserir uma `PrivateKey`
própria — isso reintroduz o mesmo risco de secret leak já corrigido neste
projeto.

## Notas de segurança

- `acme/acme.json` e `.secrets/` **nunca** são versionados (`.gitignore`
  local) e devem ter permissão `600`/`700`.
- O Docker socket é montado **somente leitura** (`:ro`); ainda assim dá acesso
  equivalente a root no host — restrinja quem tem acesso ao servidor.
- Todo serviço público deve incluir um middleware de headers de segurança
  (HSTS, no-sniff, anti-clickjacking) nas suas próprias `middlewares` — o
  modelo em `containers/modelo-traefik` já gera isso por padrão, self-contained
  por serviço (não compartilhado entre projetos; ver o motivo no README dele).
- `security_opt: no-new-privileges:true` e limites de CPU/memória evitam que o
  container escale privilégios ou consuma recursos do host indefinidamente.
- Sem `traefik.enable=true` explícito, nenhum container é exposto
  (`providers.docker.exposedbydefault=false`).

## Referências

- [How To Use Traefik v2 as a Reverse Proxy for Docker Containers on Ubuntu 20.04](https://www.digitalocean.com/community/tutorials/how-to-use-traefik-v2-as-a-reverse-proxy-for-docker-containers-on-ubuntu-20-04)
- [Documentação oficial do Traefik — Docker provider](https://doc.traefik.io/traefik/providers/docker/)
- [Traefik — Security Headers middleware](https://doc.traefik.io/traefik/middlewares/http/headers/)
