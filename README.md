# FIAP Cloud Games (FCG) — Orquestração

Repositório de **orquestração** da FCG: reúne o `docker-compose.yml`, os scripts de
inicialização do banco e os manifestos de infraestrutura do Kubernetes para subir a
plataforma completa (4 microsserviços + PostgreSQL + RabbitMQ).

A FCG foi refatorada de um monolito para **microsserviços orientados a eventos**,
comunicando-se de forma assíncrona via RabbitMQ (MassTransit). Cada microsserviço
vive em seu próprio repositório Git.

## Repositórios dos microsserviços

| Serviço | Responsabilidade | Repositório |
|---|---|---|
| **UsersAPI** | Cadastro, login (JWT), autorização | https://github.com/R-A-Medeiros/fcg-users-api |
| **CatalogAPI** | CRUD de jogos, biblioteca, início da compra | https://github.com/R-A-Medeiros/fcg-catalog-api |
| **PaymentsAPI** | Processa (simula) o pagamento | https://github.com/R-A-Medeiros/fcg-payments-api |
| **NotificationsAPI** | "Envia" e-mails (log no console) | https://github.com/R-A-Medeiros/fcg-notifications-api |

## Fluxos orientados a eventos

**Cadastro de usuário**
```
UsersAPI --(UserCreatedEvent)--> NotificationsAPI  ->  "e-mail" de boas-vindas
```

**Compra de jogo**
```
CatalogAPI  --(OrderPlacedEvent)-->      PaymentsAPI
PaymentsAPI --(PaymentProcessedEvent)--> CatalogAPI       (se Approved: adiciona à biblioteca)
                                     \-> NotificationsAPI  (se Approved: "e-mail" de confirmação)
```

---

## Como executar com Docker Compose

### Pré-requisito: estrutura de pastas
Os 4 repositórios de serviço devem estar clonados como **pastas irmãs** deste repositório:

```
<pasta-pai>/
├── fcg-orchestration/        (este repositório)
├── fcg-users-api/
├── fcg-catalog-api/
├── fcg-payments-api/
└── fcg-notifications-api/
```

Clonando tudo do zero:
```bash
mkdir fcg && cd fcg
git clone https://github.com/R-A-Medeiros/fcg-orchestration.git
git clone https://github.com/R-A-Medeiros/fcg-users-api.git
git clone https://github.com/R-A-Medeiros/fcg-catalog-api.git
git clone https://github.com/R-A-Medeiros/fcg-payments-api.git
git clone https://github.com/R-A-Medeiros/fcg-notifications-api.git
```

### Subir a aplicação
```bash
cd fcg-orchestration
docker compose up --build
```

Isso sobe RabbitMQ, PostgreSQL e os 4 serviços. Os bancos e o schema (tabelas) são
criados automaticamente na primeira subida do Postgres (scripts em `infra/postgres-init`).

### Endpoints
| Recurso | URL |
|---|---|
| UsersAPI | http://localhost:5001 (docs: `/swagger` e `/scalar/v1`) |
| CatalogAPI | http://localhost:5002 (docs: `/swagger` e `/scalar/v1`) |
| PaymentsAPI | http://localhost:5003 (`/health`) |
| NotificationsAPI | http://localhost:5004 (`/health`) |
| RabbitMQ Management | http://localhost:15672 (guest / guest) |

### Credenciais de exemplo
- Admin semeado: `admin@fcg.com` / `Admin@123`
- Senha de novos usuários: mínimo 8 caracteres, com maiúscula, minúscula, número e caractere especial (ex.: `Secret@123`).

### Recriar do zero (zera o banco)
```bash
docker compose down -v && docker compose up --build
```

---

## Como fazer deploy no Kubernetes

Pré-requisitos: cluster local (Docker Desktop, Kind, Minikube ou k3d) e `kubectl`.

Os manifestos de **cada serviço** ficam na pasta `k8s/` do respectivo repositório.
A **infraestrutura compartilhada** (PostgreSQL, RabbitMQ e o Job de schema) está em
`k8s-infra/` neste repositório.

### 1. Build e carga das imagens no cluster
```bash
docker build -t fcg/users-api:latest         ../fcg-users-api
docker build -t fcg/catalog-api:latest       ../fcg-catalog-api
docker build -t fcg/payments-api:latest      ../fcg-payments-api
docker build -t fcg/notifications-api:latest ../fcg-notifications-api
# Com Kind, por exemplo:
# kind load docker-image fcg/users-api:latest fcg/catalog-api:latest fcg/payments-api:latest fcg/notifications-api:latest
```

### 2. Aplicar os manifestos (infra → schema → serviços)
```bash
kubectl apply -f k8s-infra/postgres.yaml
kubectl apply -f k8s-infra/rabbitmq.yaml
kubectl apply -f k8s-infra/db-schemas-configmap.yaml
kubectl apply -f k8s-infra/db-migrate-job.yaml

kubectl apply -f ../fcg-users-api/k8s/
kubectl apply -f ../fcg-catalog-api/k8s/
kubectl apply -f ../fcg-payments-api/k8s/
kubectl apply -f ../fcg-notifications-api/k8s/
```

### 3. Verificar
```bash
kubectl get pods
kubectl logs job/db-migrate
```

Os serviços se comunicam dentro do cluster pelos nomes de Service do Kubernetes
(`postgres`, `rabbitmq`, `users-api`, `catalog-api`, etc.).

---

## Estrutura deste repositório

```
fcg-orchestration/
├── docker-compose.yml            # sobe infra + 4 serviços (build a partir dos repos irmãos)
├── infra/postgres-init/          # cria os bancos e aplica o schema na 1ª subida do Postgres
└── k8s-infra/                    # infra para Kubernetes
    ├── postgres.yaml             # Deployment + Service + ConfigMap + Secret
    ├── rabbitmq.yaml             # Deployment + Service + Secret
    ├── db-schemas-configmap.yaml # ConfigMap com os schemas
    ├── db-migrate-job.yaml       # Job que cria as tabelas
    └── README.md
```

## Notas de segurança

As credenciais neste repositório (`admin@fcg.com`/`Admin@123`, a chave JWT
`CHANGE_ME_...`, `guest`/`guest` do RabbitMQ) são **placeholders de exemplo** para
ambiente local/acadêmico. Em um ambiente real, use variáveis de ambiente ou um
cofre de segredos e **nunca** versione segredos reais.
