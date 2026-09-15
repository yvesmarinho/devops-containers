#!/bin/bash
# -------------------------------------------------------------------------
# TITULO: Preenche os placeholders do modelo docker-compose.yaml do Traefik
# DATA..: 15/09/2026
# VERSAO: 1.0.00
# -------------------------------------------------------------------------
# Copyright (c) 2026 - Vya.Digital - Yves Marinho
# This script is licensed under MIT version 3.0 or above
# -------------------------------------------------------------------------
# Modifications.....:
#  Date          Rev    Author           Description
#  15/09/2026     0     Yves             Elaboração
# -------------------------------------------------------------------------
# Uso:
#   ./scripts/apply-placeholders.sh -o /caminho/para/novo-servico \
#       -n meu-projeto -i ghcr.io/org/app:1.2.3 \
#       -s app002 -d example.com -p 8080
#
# Sem argumentos, o script pergunta cada valor interativamente. Nunca edita
# o modelo original: copia docker-compose.yaml (e .env.example, se existir)
# para o diretório de destino e substitui os placeholders lá.
# -------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_COMPOSE="${SCRIPT_DIR}/docker-compose.yaml"
TEMPLATE_ENV="${SCRIPT_DIR}/.env.example"

usage() {
  echo "Uso: $0 -o <diretorio_destino> [-n PROJECT_NAME] [-i IMAGE] [-s SUBDOMAIN] [-d DOMAIN_NAME] [-p APP_PORT]"
  exit 1
}

OUT_DIR=""
PROJECT_NAME=""
IMAGE=""
SUBDOMAIN=""
DOMAIN_NAME=""
APP_PORT=""

while getopts "o:n:i:s:d:p:h" opt; do
  case "${opt}" in
    o) OUT_DIR="${OPTARG}" ;;
    n) PROJECT_NAME="${OPTARG}" ;;
    i) IMAGE="${OPTARG}" ;;
    s) SUBDOMAIN="${OPTARG}" ;;
    d) DOMAIN_NAME="${OPTARG}" ;;
    p) APP_PORT="${OPTARG}" ;;
    h|*) usage ;;
  esac
done

[ -z "${OUT_DIR}" ] && usage

prompt_if_empty() {
  local var_name="$1" prompt_text="$2"
  local current_value="${!var_name}"
  if [ -z "${current_value}" ]; then
    read -r -p "${prompt_text}: " current_value
    printf -v "${var_name}" '%s' "${current_value}"
  fi
}

prompt_if_empty PROJECT_NAME "Nome do projeto/serviço (minúsculas, dígitos, hífen)"
prompt_if_empty IMAGE "Imagem completa (ex.: ghcr.io/org/app:1.2.3)"
prompt_if_empty SUBDOMAIN "Subdomínio (ex.: app002)"
prompt_if_empty DOMAIN_NAME "Domínio raiz (ex.: example.com)"
prompt_if_empty APP_PORT "Porta interna da aplicação (ex.: 8080)"

if ! [[ "${PROJECT_NAME}" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]; then
  echo "Erro: PROJECT_NAME deve conter apenas minúsculas, dígitos e hífen (ex.: meu-projeto)." >&2
  exit 1
fi

if ! [[ "${APP_PORT}" =~ ^[0-9]+$ ]] || [ "${APP_PORT}" -lt 1 ] || [ "${APP_PORT}" -gt 65535 ]; then
  echo "Erro: APP_PORT deve ser um número entre 1 e 65535." >&2
  exit 1
fi

if [ -z "${IMAGE}" ] || [ -z "${SUBDOMAIN}" ] || [ -z "${DOMAIN_NAME}" ]; then
  echo "Erro: IMAGE, SUBDOMAIN e DOMAIN_NAME não podem ser vazios." >&2
  exit 1
fi

mkdir -p "${OUT_DIR}"

DEST_COMPOSE="${OUT_DIR}/docker-compose.yaml"
if [ -e "${DEST_COMPOSE}" ]; then
  read -r -p "Arquivo ${DEST_COMPOSE} já existe. Sobrescrever? [s/N] " confirm
  [[ "${confirm}" =~ ^[sS]$ ]] || { echo "Cancelado."; exit 1; }
fi

cp "${TEMPLATE_COMPOSE}" "${DEST_COMPOSE}"
[ -f "${TEMPLATE_ENV}" ] && cp "${TEMPLATE_ENV}" "${OUT_DIR}/.env.example"

sed -i \
  -e "s#{{PROJECT_NAME}}#${PROJECT_NAME}#g" \
  -e "s#{{IMAGE}}#${IMAGE}#g" \
  -e "s#{{SUBDOMAIN}}#${SUBDOMAIN}#g" \
  -e "s#{{DOMAIN_NAME}}#${DOMAIN_NAME}#g" \
  -e "s#{{APP_PORT}}#${APP_PORT}#g" \
  "${DEST_COMPOSE}"

if grep -q '{{' "${DEST_COMPOSE}"; then
  echo "Aviso: ainda há placeholders não substituídos em ${DEST_COMPOSE}:" >&2
  grep -n '{{' "${DEST_COMPOSE}" >&2
  exit 1
fi

echo "Gerado: ${DEST_COMPOSE}"
echo "Revise o arquivo, ajuste volumes/environment/user conforme a aplicação e rode:"
echo "  docker compose -f ${DEST_COMPOSE} config"
