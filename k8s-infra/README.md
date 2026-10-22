# Infraestrutura para Kubernetes (orquestração)

Manifestos da infraestrutura compartilhada que os quatro microsserviços precisam
dentro do cluster: **PostgreSQL** e **RabbitMQ**, mais um **Job** que aplica o
schema dos bancos.

Os serviços se comunicam com esta infra pelos nomes de Service do Kubernetes:
`postgres` (porta 5432) e `rabbitmq` (porta 5672), exatamente como configurado nas
ConfigMaps/Secrets de cada microsserviço.

## Arquivos

| Arquivo                      | Conteúdo                                                        |
|------------------------------|-----------------------------------------------------------------|
| `postgres.yaml`              | Deployment + Service + ConfigMap + Secret do PostgreSQL         |
| `rabbitmq.yaml`              | Deployment + Service + Secret do RabbitMQ                       |
| `db-schemas-configmap.yaml`  | ConfigMap com os schemas (cópia dos `db/init.sql` dos serviços) |
| `db-migrate-job.yaml`        | Job que espera o Postgres e aplica cada schema no banco certo   |

## Ordem de aplicação

```bash
# 1) Infra primeiro (bancos vazios + broker)
kubectl apply -f k8s-infra/postgres.yaml
kubectl apply -f k8s-infra/rabbitmq.yaml

# 2) Schema dos bancos (aguarda o Postgres e cria as tabelas)
kubectl apply -f k8s-infra/db-schemas-configmap.yaml
kubectl apply -f k8s-infra/db-migrate-job.yaml

# 3) Os quatro microsserviços
kubectl apply -f users-api/k8s/
kubectl apply -f catalog-api/k8s/
kubectl apply -f payments-api/k8s/
kubectl apply -f notifications-api/k8s/

# 4) Verificar
kubectl get pods
kubectl logs job/db-migrate
```

> Lembre de buildar as imagens e carregá-las no cluster antes do passo 3
> (ver README principal: `docker build ...` + `kind load docker-image ...`).

## Regenerar o ConfigMap de schemas

Se algum `db/init.sql` mudar, regenere `db-schemas-configmap.yaml` a partir da
fonte (uma única fonte de verdade):

```bash
kubectl create configmap db-schemas \
  --from-file=users.schema.sql=../users-api/db/init.sql \
  --from-file=catalog.schema.sql=../catalog-api/db/init.sql \
  --from-file=payments.schema.sql=../payments-api/db/init.sql \
  --dry-run=client -o yaml > db-schemas-configmap.yaml
```

## Observação sobre repositório de orquestração

O Tech Challenge permite (opcionalmente) um quinto repositório de orquestração.
Esta pasta `k8s-infra/` junto com o `docker-compose.yml` da raiz é o candidato
natural a virar esse repositório.
