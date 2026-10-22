-- Cria os bancos (um por microsserviço) na primeira inicialização do container Postgres.
-- Os SCHEMAS (tabelas) são aplicados logo em seguida pelo script 02-apply-schemas.sh.
CREATE DATABASE fcg_users;
CREATE DATABASE fcg_catalog;
CREATE DATABASE fcg_payments;
