# Script de Automatización - Innovatech Chile
# Infraestrutura AWS para evaluación ISY1101
# Este script documenta y automatiza la configuración completa

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Innovatech Chile - Setup de Infraestructura" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# ============================================
# CONFIGURACIÓN ACTUAL (ya configurado)
# ============================================

$Config = @{
    # AWS Account
    AccountId = "435760010350"
    Region = "us-east-1"

    # ECR Repositorios (ya creados)
    ECR = @{
        Registry = "435760010350.dkr.ecr.us-east-1.amazonaws.com"
        Frontend = "innovatech-frontend"
        BackendVentas = "innovatech-backend-ventas"
        BackendDespachos = "innovatech-backend-despachos"
    }

    # VPC
    VPC = @{
        Id = "vpc-00229a710764a1af0"
        CIDR = "10.0.0.0/24"
    }

    # Subnets
    Subnets = @{
        Frontend = "subnet-013c98ffa71ffc07f"  # us-east-1a
        Backend = "subnet-0260b25a61333497d"   # us-east-1a
        DBa = "subnet-013c98ffa71ffc07f"        # us-east-1a
        DBb = "subnet-0aa59933b4359517f"        # us-east-1b
    }

    # Security Groups
    SecurityGroups = @{
        Frontend = "sg-0385fbb9b37dc80c6"
        Backend = "sg-0b28f0d0f5a00085c"
        Data = "sg-0ea449c1c85fe05b4"
        RDS = "sg-0c62c8436df4fd328"
    }

    # EC2 Instances
    EC2 = @{
        Frontend = @{
            InstanceId = "i-01a2b702ab13b9d53"
            PublicDNS = "ec2-44-201-29-177.compute-1.amazonaws.com"
            PrivateIP = "10.0.0.6"
        }
        Backend1 = @{
            InstanceId = "i-01e517858c512d2c3"
            PrivateIP = "10.0.0.133"
        }
        Backend2 = @{
            InstanceId = "i-0226995a8fc92285c"
            PrivateIP = "10.0.0.142"
        }
    }

    # RDS MySQL
    RDS = @{
        InstanceId = "innovatech-mysql"
        Endpoint = "innovatech-mysql.cbdcmle0rxno.us-east-1.rds.amazonaws.com"
        Port = 3306
        MasterUser = "admin"
        MasterPassword = "Innovatech2026!"
        DBNameVentas = "innovatech_ventas"
        DBNameDespachos = "innovatech_despachos"
    }

    # NAT Gateway
    NATGateway = @{
        Id = "nat-090da9001c050ebcd"
        Subnet = "subnet-013c98ffa71ffc07f"
    }

    # Internet Gateway
    IGW = "igw-010ce3e504d0cd46e"

    # SSH Key
    SSHKey = @{
        Path = "C:\Users\so.padilla\Downloads\innovatech-keys.pem"
        Name = "innovatech-keys"
    }
}

# ============================================
# 1. CONFIGURAR GITHUB SECRETS
# ============================================

Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "Paso 1: Configurar GitHub Secrets" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

Write-Host @"

Para configurar los GitHub Secrets, ve a:
https://github.com/solxpa/innovatech/settings/secrets/actions

Crea los siguientes secrets:

┌─────────────────────────────────────────────────────────────────┐
│ SECRET NAME               │ VALUE                                │
├─────────────────────────────────────────────────────────────────┤
│ AWS_ACCESS_KEY_ID         │ ASIAWK5KSCRXNHKM6PQ2                 │
│ AWS_SECRET_ACCESS_KEY    │ (tu secret key de AWS Academy)        │
│ AWS_SESSION_TOKEN         │ (token de sesion AWS Academy)        │
│ EC2_FRONTEND_HOST         │ ec2-44-201-29-177.compute-1.amazonaws.com│
│ EC2_BACKEND_HOST         │ 10.0.0.142                           │
│ EC2_SSH_KEY              │ (contenido del archivo .pem)          │
│ DB_ENDPOINT              │ innovatech-mysql.cbdcmle0rxno.us-east-1.rds.amazonaws.com│
│ DB_USERNAME              │ admin                                │
│ DB_PASSWORD              │ Innovatech2026!                      │
│ DB_NAME_VENTAS           │ innovatech_ventas                    │
│ DB_NAME_DESPACHOS        │ innovatech_despachos                 │
└─────────────────────────────────────────────────────────────────┘

Tambien crea una variable de repositorio (no secret):
┌─────────────────────────────────────────────────────────────────┐
│ VARIABLE NAME          │ VALUE                                   │
├─────────────────────────────────────────────────────────────────┤
│ AWS_ECR_REGISTRY       │ 435760010350.dkr.ecr.us-east-1.amazonaws.com│
└─────────────────────────────────────────────────────────────────┘

"@

# ============================================
# 2. CREAR BASES DE DATOS EN RDS
# ============================================

Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "Paso 2: Crear bases de datos en RDS" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

Write-Host @"

Ejecuta estos comandos en AWS CLI para crear las bases de datos:

# Conectar a RDS MySQL
mysql -h innovatech-mysql.cbdcmle0rxno.us-east-1.rds.amazonaws.com ^
     -u admin -pInnovatech2026!

# En MySQL, ejecutar:
CREATE DATABASE IF NOT EXISTS innovatech_ventas;
CREATE DATABASE IF NOT EXISTS innovatech_despachos;
SHOW DATABASES;
EXIT;

"@

# ============================================
# 3. CONFIGURAR SSH KEY EN EC2
# ============================================

Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "Paso 3: Configurar SSH" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

Write-Host @"

El key ya esta configurado en:
$($Config.SSHKey.Path)

Prueba de conectividad:
ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ^
    -i `"$($Config.SSHKey.Path)`" ^
    ec2-user@$($Config.EC2.Frontend.PublicDNS)

"@

# ============================================
# 4. PREPARAR IMÁGENES EN ECR
# ============================================

Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "Paso 4: Login a ECR y preparar imágenes" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

Write-Host @"

Ejecuta en tu maquina local (no en EC2):

# Login a ECR
aws ecr get-login-password --region us-east-1 | ^
    docker login --username AWS --password-stdin ^
    $($Config.ECR.Registry)

# Etiquetar imágenes locales para ECR
docker tag innovatech-frontend:latest ^
    $($Config.ECR.Registry)/$($Config.ECR.Frontend):latest
docker tag innovatech-backend-ventas:latest ^
    $($Config.ECR.Registry)/$($Config.ECR.BackendVentas):latest
docker tag innovatech-backend-despachos:latest ^
    $($Config.ECR.Registry)/$($Config.ECR.BackendDespachos):latest

# Push a ECR
docker push $($Config.ECR.Registry)/$($Config.ECR.Frontend):latest
docker push $($Config.ECR.Registry)/$($Config.ECR.BackendVentas):latest
docker push $($Config.ECR.Registry)/$($Config.ECR.BackendDespachos):latest

"@

# ============================================
# 5. CREAR RAMA DEPLOY Y PROBAR PIPELINE
# ============================================

Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "Paso 5: Crear rama deploy para CI/CD" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

Write-Host @"

Desde el directorio del proyecto:

git checkout -b deploy
git push origin deploy

Esto disparara los workflows de GitHub Actions automaticamente.

Puedes monitorear en:
https://github.com/solxpa/innovatech/actions

"@

# ============================================
# 6. CONFIGURAR VARIABLES DE APP EN SPRING BOOT
# ============================================

Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "Paso 6: Configurar application.properties" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

Write-Host @"

Los archivos application.properties ya tienen configurado:

# Backend Ventas (puerto 8080)
spring.datasource.url=jdbc:mysql://${DB_HOST}:3306/${DB_NAME}?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC
spring.datasource.username=${DB_USERNAME}
spring.datasource.password=${DB_PASSWORD}

# Backend Despachos (puerto 8081)
spring.datasource.url=jdbc:mysql://${DB_HOST}:3306/${DB_NAME}?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC

"@

# ============================================
# RESUMEN DE ARQUITECTURA
# ============================================

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "ARQUITECTURA CONFIGURADA" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host @"

    ┌─────────────────────────────────────────────────────────────┐
    │                        INTERNET                             │
    └────────────────────────────┬────────────────────────────────┘
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │   EC2 Frontend         │
                    │   (t3.micro)          │
                    │   Nginx + React       │
                    │   Puerto 80, 443      │
                    │   SG: sg-0385fbb9b37dc80c6│
                    └────────────┬───────────┘
                                 │
              ┌──────────────────┼──────────────────┐
              │                  │                  │
              ▼                  ▼                  ▼
    ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
    │  EC2 Backend 1  │ │  EC2 Backend 2  │ │     RDS         │
    │  Ventas:8080    │ │  Despachos:8081  │ │   MySQL 8.0    │
    │  SG: sg-0ea449..│ │  SG: sg-0b28f0..│ │  Puerto 3306   │
    │  10.0.0.133     │ │  10.0.0.142      │ │  sg-0c62c8436..│
    └─────────────────┘ └─────────────────┘ └─────────────────┘

    ECR Registry: $($Config.ECR.Registry)

    Repositorios:
    - $($Config.ECR.Frontend)
    - $($Config.ECR.BackendVentas)
    - $($Config.ECR.BackendDespachos)

"@

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "CONFIGURACIÓN COMPLETA" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host @"

El infrastructure esta configurado. Ahora necesitas:

1. Configurar GitHub Secrets
2. Crear las bases de datos en RDS
3. Hacer push a rama 'deploy' para probar CI/CD

"@