<!-- Criado em: 03/03/2023 -->
<!-- Modificado em: 15/09/2026 11:32 -->

# Modelo — Serviço exposto via Traefik

Template de `docker-compose.yaml` para expor uma aplicação através do Traefik
já configurado em [containers/traefik](../traefik/README.md). Não é para subir
diretamente — é um molde com placeholders `{{...}}` a preencher por serviço.

## Revisão de segurança (15/09/2026)

O modelo anterior tinha problemas que impediam funcionamento correto ou
enfraqueciam a segurança do proxy:

- **Nome do serviço via `${PROJECT_NAME}:`** — o Docker Compose não resolve
  variáveis de ambiente em *chaves* do YAML, só em valores. O compose gerado
  literalmente criava um serviço chamado `${PROJECT_NAME}`. Trocado por
  placeholder de texto (`{{PROJECT_NAME}}`) resolvido por
  `scripts/apply-placeholders.sh` antes do `docker compose up`.
- **Porta da aplicação publicada no host** (`ports: "${PORT_DOCKER}:${PORT_APP}"`)
  — isso deixa a app acessível diretamente pela porta do host, contornando o
  Traefik (sem TLS, sem os middlewares de segurança). Trocado por `expose:`,
  que só disponibiliza a porta na rede interna do Docker; só o Traefik acessa.
- **Labels realmente obsoletas da API v1 do Traefik** (`headers.SSLRedirect`,
  `headers.SSLHost`, `traefik.port=...`) — não existem no Traefik v2/v3 atual
  (`v3.7`); eram silenciosamente ignoradas, deixando o serviço sem porta de
  backend definida (`loadbalancer.server.port`), o que torna o roteamento
  para múltiplas portas expostas indefinido.
- **Rede `app-network` e certresolver `lets-encrypt`** não batiam com o setup
  atual do Traefik (rede externa `web`, resolver `letsencrypt`). Alinhados.
- **`environment: - ""` / `volumes: - ""`** eram itens de lista inválidos
  (nome de variável vazio) em vez de blocos comentados — corrigido para
  seções comentadas, ativadas conforme a necessidade de cada serviço.

### Correção de regressão (15/09/2026, revisão 2)

A primeira revisão trocou os labels de headers por um middleware **compartilhado**
(`security-headers@docker`), definido só no compose de `containers/traefik`.
Isso quebrou aplicações na prática: o middleware só existe enquanto esse
container Traefik específico estiver no ar com essa label — se o app sobe
antes, em outra rede, ou contra outro Traefik, o router fica com um middleware
"não encontrado" e o **Traefik desativa a rota inteira** (não é só falta de
header, o serviço fica inacessível). Voltamos a middleware de headers **próprio
por serviço** (`{{PROJECT_NAME}}-headers@docker`), autocontido — não depende de
nenhum outro projeto/compose para funcionar. Também foi reinserido
`forceSTSHeader`, removido por engano na primeira revisão (esse campo continua
válido no Traefik v2/v3 — só `SSLRedirect`/`SSLHost` são deprecados).

## Pré-requisitos

- Traefik já em execução com a rede externa `web` criada (ver
  [containers/traefik](../traefik/README.md)).
- DNS do subdomínio apontando para o host.

## Uso

1. Gerar o `docker-compose.yaml` final para o novo serviço, substituindo os
   placeholders (não edite o modelo original):
   ```bash
   ./scripts/apply-placeholders.sh \
     -o /caminho/para/meu-servico \
     -n meu-projeto \
     -i ghcr.io/org/app:1.2.3 \
     -s app002 \
     -d example.com \
     -p 8080
   ```
   Sem os parâmetros `-n/-i/-s/-d/-p`, o script pergunta cada valor
   interativamente. Ele nunca sobrescreve sem confirmação.

2. No diretório gerado, revisar e ajustar o que for específico da aplicação:
   - `environment:` / `env_file:` (variáveis da app)
   - `volumes:` (dados persistentes)
   - `user:` (rodar como não-root sempre que a imagem suportar)
   - `command:` (se a imagem não tiver `ENTRYPOINT`/`CMD` adequados)

3. Validar a sintaxe antes de subir:
   ```bash
   docker compose -f docker-compose.yaml config
   ```

4. Subir o serviço (a partir do diretório gerado):
   ```bash
   docker compose up -d
   ```

## Placeholders

| Placeholder         | Descrição                                             | Exemplo                     |
|----------------------|--------------------------------------------------------|------------------------------|
| `{{PROJECT_NAME}}`  | Nome do serviço/projeto (minúsculas, dígitos, hífen)  | `meu-projeto`                |
| `{{IMAGE}}`         | Referência completa da imagem                         | `ghcr.io/org/app:1.2.3`      |
| `{{SUBDOMAIN}}`     | Subdomínio do serviço                                 | `app002`                     |
| `{{DOMAIN_NAME}}`   | Domínio raiz                                          | `example.com`                |
| `{{APP_PORT}}`      | Porta interna em que a aplicação escuta no container  | `8080`                       |

## Notas de segurança

- **Nunca publique a porta da aplicação no host** (`ports:`) quando ela já é
  roteada pelo Traefik — use `expose:`, que mantém a porta só na rede interna
  `web`.
- **Rode como usuário não-root** sempre que a imagem suportar
  (`user: "UID:GID"`).
- **`security_opt: no-new-privileges:true`** evita escalonamento de
  privilégios dentro do container.
- O middleware de headers (`{{PROJECT_NAME}}-headers@docker`) é definido no
  próprio compose do serviço — funciona mesmo se o app não subir na mesma
  stack do `containers/traefik`. Se vários serviços sempre rodam juntos na
  mesma stack e você quer uma única política central, é possível voltar a um
  middleware compartilhado, mas isso acopla a disponibilidade de cada app à
  do container que o define — avalie esse trade-off antes de fazer isso.
- Sem `traefik.enable=true`, o serviço não é exposto — reforça que a
  exposição é sempre explícita, nunca implícita.
- Segredos de runtime (tokens, senhas, strings de conexão) vão em `.env`
  (copiado de `.env.example`), nunca hardcoded no `docker-compose.yaml` nem
  versionados.
