#!/bin/bash
# -------------------------------------------------------------------------
# TITULO: Prepara o acme.json usado pelo Traefik para armazenar a conta e
#         os certificados do Let's Encrypt (ACME)
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
# Este script NÃO gera nenhuma chave/conta ACME. A chave de conta e os
# certificados são criados pelo próprio Traefik, automaticamente, no primeiro
# start (definido em docker-compose.yaml via `certificatesResolvers.letsencrypt`).
#
# O único pré-requisito manual é o arquivo existir com permissão 600 antes do
# Traefik montá-lo — senão o Traefik recusa usá-lo como storage ACME. É só
# isso que este script faz.
#
# Nunca crie/edite acme.json manualmente com uma "Account"/"PrivateKey" já
# preenchida — isso é um secret e reintroduz o mesmo risco já corrigido neste
# projeto (chave privada hardcoded em texto plano).
# -------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACME_FILE="${SCRIPT_DIR}/acme/acme.json"

mkdir -p "${SCRIPT_DIR}/acme"

if [ -f "${ACME_FILE}" ] && [ -s "${ACME_FILE}" ]; then
  echo "Aviso: ${ACME_FILE} já existe e não está vazio — mantido sem alterações."
  echo "Se você quer forçar o Traefik a registrar uma conta ACME nova (ex.: a"
  echo "atual foi revogada/comprometida), pare o Traefik, apague o arquivo e"
  echo "rode este script de novo antes de subir o container."
else
  touch "${ACME_FILE}"
  echo "Criado ${ACME_FILE} vazio."
fi

chmod 600 "${ACME_FILE}"
echo "Permissão 600 aplicada em ${ACME_FILE}."
echo "Pronto — suba o Traefik (docker compose up -d) para que ele registre a conta ACME."
