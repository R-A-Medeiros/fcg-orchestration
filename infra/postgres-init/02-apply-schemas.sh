#!/bin/bash
# Aplica o schema (tabelas) de cada microsserviço no banco correspondente.
# Roda automaticamente na primeira inicialização do container Postgres,
# depois que 01-create-databases.sql cria os bancos vazios.
#
# Os arquivos *.schema.sql são os db/init.sql de cada serviço, montados pelo
# docker-compose em /fcg-schemas (fora de /docker-entrypoint-initdb.d, para o
# Postgres não executá-los sozinho no banco default).
set -e

SCHEMA_DIR="/fcg-schemas"

echo "==> Aplicando schema em fcg_users"
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d fcg_users    -f "$SCHEMA_DIR/users.schema.sql"

echo "==> Aplicando schema em fcg_catalog"
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d fcg_catalog  -f "$SCHEMA_DIR/catalog.schema.sql"

echo "==> Aplicando schema em fcg_payments"
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d fcg_payments -f "$SCHEMA_DIR/payments.schema.sql"

echo "==> Schemas aplicados com sucesso."
