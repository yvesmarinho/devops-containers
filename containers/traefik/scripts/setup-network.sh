#!/bin/bash
# -------------------------------------------------------------------------
# TITULO: Cria a rede Docker externa e a estrutura de pastas usadas pelo Traefik
# DATA..: 23/11/2023
# MODIFICADO: 15/09/2026
# VERSAO: 2.1.00
# -------------------------------------------------------------------------
# Copyright (c) 2023 - Vya.Digital - Yves Marinho
# This script is licensed under MIT version 3.0 or above
# -------------------------------------------------------------------------
# Modifications.....:
#  Date          Rev    Author           Description
#  23/11/2023     0     Yves             Elaboracao
#  15/09/2026     1     Yves             Remove chave privada ACME hardcoded do
#                                        script (secret leak); acme.json passa a
#                                        ser criado vazio e o Traefik registra a
#                                        conta ACME sozinho no primeiro start.
#  15/09/2026     2     Yves             Extrai a preparação do acme.json para
#                                        scripts/init-acme.sh (reaproveitável
#                                        isoladamente, ex.: ao trocar de conta
#                                        ACME sem recriar a rede).
# -------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "========================================================="
echo "         TRAEFIK - CRIADOR DA ESTRUTURA DE PASTAS"
echo "========================================================="
mkdir -p "${SCRIPT_DIR}/logs" "${SCRIPT_DIR}/acme" "${SCRIPT_DIR}/.secrets"

"${SCRIPT_DIR}/scripts/init-acme.sh"

echo "========================================================="
echo "         TRAEFIK - CRIADOR DA REDE DOCKER"
echo "========================================================="
if ! docker network inspect web >/dev/null 2>&1; then
  docker network create \
    --driver=bridge \
    --subnet=172.18.0.0/24 \
    --gateway=172.18.0.1 \
    web
else
  echo "Rede 'web' já existe, pulando."
fi

echo "Concluído. Gere o arquivo de usuários do dashboard com:"
echo "  htpasswd -nB admin > ${SCRIPT_DIR}/.secrets/traefik_users"
