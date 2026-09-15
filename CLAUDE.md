# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Visão Geral do Projeto

**Projeto**: `devops-containers`
**Descrição**: Central de configurações de containers, Dockerfiles e arquivos Docker Compose para infraestrutura e serviços.
**Domínio**: infrastructure | **Linguagem**: python
**Criado em**: 2026-09-15T13:56:40Z

## Comandos Frequentes

```bash
# Instalar dependências
make install-deps

# Rodar testes
make test

# Lint e formatação
make lint && make format

# Encerrar sessão (valida integridade do projeto)
make session-end

# Carregar MCP servers
make mcp

# Limpar arquivos gerados
make clean
```

## Ambiente

- Python 3.12+ gerenciado por `uv`
- Ambiente virtual em `.venv/`
- Dependências em `pyproject.toml`

## Estrutura do Projeto

```
devops-containers/
├── .claude/            # Claude Code: commands e skills
├── .github/            # CI/CD, agentes SpecKit
├── .secrets/           # Credenciais locais (não versionado, chmod 700)
├── .vscode/            # VS Code: settings, MCP, extensions
├── containers/         # Dockerfiles, docker-compose.yml e afins, um subdiretório por serviço
│   └── <servico>/
│       ├── Dockerfile
│       ├── docker-compose.yml
│       └── .env.example
├── docs/               # Documentação (INDEX, TODO, SESSIONS)
├── scripts/            # Scripts de automação
└── src/                # Código-fonte Python (automação/tooling, não configs de container)
```

`containers/` é o diretório central deste projeto: concentra as definições de
imagens e orquestração (Dockerfiles, `docker-compose.yml`, `.env.example`) por
serviço, mantendo `src/` reservado a código Python de apoio (scripts de build,
validação de compose, etc.), conforme a regra global de organização por
responsabilidade.

## Memória Persistente — Vault Obsidian

Este projeto segue a regra global de memória persistente (`~/.claude/CLAUDE.md`):
o vault `/home/yves_marinho/Documentos/DevOps/claude_memory/claude_memory` é a
memória entre sessões, acessada via MCP `obsidian-rest` (escopo `user`).

- `memory/profile.md` — perfil do usuário
- `memory/preferences.md` — preferências de comportamento
- `memory/infra-stack.md` — stack de infraestrutura administrada
- `00-index.md` — índice mestre (MOC)
- `projects/devops-containers.md` — nota temática deste projeto (arquitetura,
  decisões, integração com `graphify-out/` quando existir)

Fatos duráveis aprendidos neste projeto (decisões técnicas, mudanças
arquiteturais) devem ser gravados nesse vault, nunca em `docs/SESSIONS/`
apenas — seguir as regras de append/edição pontual do `CLAUDE.md` do vault
(nunca sobrescrever nota inteira sem confirmar).

## Sessões de Trabalho

Documentar atividades em `docs/SESSIONS/YYYY-MM-DD/`:
- `SESSION_RECOVERY_YYYY-MM-DD.md` — contexto inicial
- `DAILY_ACTIVITIES_YYYY-MM-DD.md` — log incremental
- `FINAL_STATUS_YYYY-MM-DD.md` — estado ao encerrar

## Regras de Desenvolvimento

- Nunca commitar arquivos em `.secrets/`
- Seguir Conventional Commits: `feat`, `fix`, `docs`, `chore`, etc.
- Rodar `make lint` antes de cada commit
- Credenciais HTTP sempre via Python + requests (nunca curl com tokens)

<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
<!-- SPECKIT END -->
