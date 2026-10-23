-- Aplica o schema (tabelas) de cada microsserviço no banco correspondente.
-- Roda automaticamente na primeira inicialização do container Postgres, depois
-- que 01-create-databases.sql cria os bancos vazios.
--
-- Usamos um .sql (executado nativamente pelo Postgres via psql) em vez de um
-- script .sh: assim não há shebang nem bit de execução, e o init fica imune a
-- conversão de fim de linha (CRLF) ao clonar no Windows.
--
-- Os arquivos *.schema.sql são os db/init.sql de cada serviço, montados pelo
-- docker-compose em /fcg-schemas (fonte única de verdade).

\echo '==> Aplicando schema em fcg_users'
\connect fcg_users
\i /fcg-schemas/users.schema.sql

\echo '==> Aplicando schema em fcg_catalog'
\connect fcg_catalog
\i /fcg-schemas/catalog.schema.sql

\echo '==> Aplicando schema em fcg_payments'
\connect fcg_payments
\i /fcg-schemas/payments.schema.sql

\echo '==> Schemas aplicados com sucesso.'
