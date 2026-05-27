# RESUMEN FINAL - Innovatech Chile DevOps Setup

## Lo que se ha configurado en AWS

### ECR (Elastic Container Registry) ✅
- `435760010350.dkr.ecr.us-east-1.amazonaws.com/innovatech-frontend`
- `435760010350.dkr.ecr.us-east-1.amazonaws.com/innovatech-backend-ventas`
- `435760010350.dkr.ecr.us-east-1.amazonaws.com/innovatech-backend-despachos`

### EC2 Instances
| Instancia | ID | IP Privada | DNS Público |
|-----------|-----|------------|-------------|
| Frontend | i-01a2b702ab13b9d53 | 10.0.0.6 | ec2-44-201-29-177.compute-1.amazonaws.com |
| Backend-1 | i-01e517858c512d2c3 | 10.0.0.133 | (sin pública) |
| Backend-2 | i-0226995a8fc92285c | 10.0.0.142 | (sin pública) |

### RDS MySQL 8.0 ✅
- **Endpoint:** `innovatech-mysql.cbdcmle0rxno.us-east-1.rds.amazonaws.com`
- **Puerto:** 3306
- **Master User:** admin
- **Backups:** 7 días retention
- **Versión:** MySQL 8.0.40
- **Clase:** db.t3.micro
- **Almacenamiento:** 20GB gp3

### Security Groups Configurados
| SG | Nombre | Puertos |
|----|---------|---------|
| sg-0385fbb9b37dc80c6 | launch-wizard-front-end | 22 (SSH) |
| sg-0b28f0d0f5a00085c | launch-wizard-1-backend | 22 |
| sg-0ea449c1c85fe05b4 | launch-wizard-1-data | 3306 (desde backend) |
| sg-0c62c8436df4fd328 | innovatech-rds-sg | 3306 (desde data SG) |

### Estructura de Red
- **VPC:** 10.0.0.0/24 (vpc-00229a710764a1af0)
- **Subnets:**
  - Frontend: subnet-013c98ffa71ffc07f (us-east-1a)
  - Backend: subnet-0260b25a61333497d (us-east-1a)
  - DB-a: subnet-013c98ffa71ffc07f (us-east-1a)
  - DB-b: subnet-0aa59933b4359517f (us-east-1b)
- **NAT Gateway:** nat-090da9001c050ebcd
- **IGW:** igw-010ce3e504d0cd46e

---

## Lo que falta hacer

### 1. Configurar GitHub Secrets

Ve a: https://github.com/solxpa/innovatech/settings/secrets/actions

Crea estos **Secrets**:

```
AWS_ACCESS_KEY_ID = ASIAWK5KSCRXNHKM6PQ2
AWS_SECRET_ACCESS_KEY = (tu secret de AWS Academy)
AWS_SESSION_TOKEN = (tu session token de AWS Academy)
EC2_FRONTEND_HOST = ec2-44-201-29-177.compute-1.amazonaws.com
EC2_BACKEND_HOST = 10.0.0.142
EC2_SSH_KEY = (contenido del archivo C:\Users\so.padilla\Downloads\innovatech-keys.pem)
DB_ENDPOINT = innovatech-mysql.cbdcmle0rxno.us-east-1.rds.amazonaws.com
DB_USERNAME = admin
DB_PASSWORD = Innovatech2026!
DB_NAME_VENTAS = innovatech_ventas
DB_NAME_DESPACHOS = innovatech_despachos
```

Crea esta **Variable** (no es secret):
```
AWS_ECR_REGISTRY = 435760010350.dkr.ecr.us-east-1.amazonaws.com
```

### 2. Hacer push a rama deploy

```bash
cd proyecto_entregado_por_el_profesor
git checkout -b deploy
git push origin deploy
```

Esto disparará automáticamente los workflows de GitHub Actions.

---

## Archivos en GitHub

https://github.com/solxpa/innovatech

```
README.md                    - Documentación técnica completa
CHANGELOG.md                 - Registro de cambios
GUIA_ESTUDIO.md              - Guía para la presentación
GUIA_CONFIGURACION.md        - Configuración de credenciales paso a paso
SETUP_AWS.ps1                - Script de automatización de infraestructura
docker-compose.yml           - Desarrollo local
docker-compose.prod.yml      - Producción AWS
Dockerfile (x3)              - Multi-stage builds
nginx.conf                   - Proxy reverso para frontend
.github/workflows/deploy.yml (x3) - CI/CD pipelines
```

---

## Arquitectura Esperada

```
                            Internet
                               │
                               ▼
                    ┌────────────────────────┐
                    │   EC2 Frontend          │
                    │   ec2-44-201-29-177    │
                    │   Puerto 80 (HTTP)     │
                    │   Puerto 443 (HTTPS)   │
                    └────────────┬───────────┘
                                 │
              ┌──────────────────┼──────────────────┐
              │                  │                  │
              ▼                  ▼                  ▼
    ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
    │  EC2 Backend-1   │ │  EC2 Backend-2   │ │      RDS        │
    │  Puerto 8080    │ │  Puerto 8081    │ │    MySQL 8.0    │
    │  (Ventas)       │ │  (Despachos)    │ │   Puerto 3306   │
    └─────────────────┘ └─────────────────┘ └─────────────────┘
```

---

## Comandos de Verificación

```bash
# Login a ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 435760010350.dkr.ecr.us-east-1.amazonaws.com

# Ver estado de contenedores en EC2
ssh -o StrictHostKeyChecking=no -i innovatech-keys.pem ec2-user@ec2-44-201-29-177.compute-1.amazonaws.com "sudo docker ps -a"

# Ver logs de contenedor
ssh -o StrictHostKeyChecking=no -i innovatech-keys.pem ec2-user@ec2-44-201-29-177.compute-1.amazonaws.com "sudo docker logs innovatech-frontend"

# Health check
curl http://ec2-44-201-29-177.compute-1.amazonaws.com/actuator/health
```

---

## Nota sobre Conexión a RDS

La conexión desde las EC2 al RDS puede tomar tiempo en establecerse después de la creación inicial. Si hay timeout, esperar 2-5 minutos y reintentar.

Los backends Spring Boot tienen `spring.jpa.hibernate.ddl-auto=update` lo que significa que:
1. Crearán automáticamente las tablas en las bases de datos
2. No necesitan que las bases de datos existan de antemano
3. Se conectarán exitosamente una vez que la red esté completamente operativa

---

*Documento creado para evaluación ISY1101 - Mayo 2026*