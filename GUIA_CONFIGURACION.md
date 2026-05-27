# Guía de Configuración - Credenciales y Secrets

## Paso 1: Configurar Secrets en GitHub

### 1.1 Acceder al repositorio

1. Ir a: https://github.com/solxpa/innovatech
2. Click en **Settings** ( Configuración )
3. En el menú lateral izquierdo, click en **Secrets and variables** → **Actions**

### 1.2 Crear los siguientes Secrets

Haz click en **New repository secret** para cada uno:

| Nombre del Secret | Valor | Descripción |
|-------------------|-------|-------------|
| `AWS_ACCESS_KEY_ID` | `TU_ACCESS_KEY_ID` | Access Key de AWS IAM |
| `AWS_SECRET_ACCESS_KEY` | `TU_SECRET_ACCESS_KEY` | Secret Key de AWS IAM |
| `EC2_FRONTEND_HOST` | `ec2-XX-XX-XX-XX.compute-1.amazonaws.com` | DNS público EC2 Frontend |
| `EC2_BACKEND_HOST` | `ec2-YY-YY-YY-YY.compute-1.amazonaws.com` | DNS público EC2 Backend |
| `EC2_SSH_KEY` | `-----BEGIN OPENSSH PRIVATE KEY-----...` | Contenido de tu key .pem |
| `DB_ENDPOINT` | `innovatech-db.xxxx.us-east-1.rds.amazonaws.com` | Endpoint del RDS MySQL |
| `DB_USERNAME` | `root` | Usuario de la base de datos |
| `DB_PASSWORD` | `TuPasswordSegura123` | Contraseña del root MySQL |
| `DB_NAME_VENTAS` | `innovatech_ventas` | Nombre BD Ventas |
| `DB_NAME_DESPACHOS` | `innovatech_despachos` | Nombre BD Despachos |

### 1.3 Crear Variables de Repositorio

1. En **Settings** → **Secrets and variables** → **Actions**
2. Click en **Variables** tab
3. Click en **New repository variable**

| Nombre | Valor | Descripción |
|--------|-------|-------------|
| `AWS_ECR_REGISTRY` | `123456789.dkr.ecr.us-east-1.amazonaws.com` | URL del registro ECR (sin slash final) |

---

## Paso 2: Configurar AWS

### 2.1 ECR - Crear repositorios de imágenes

Ejecuta estos comandos en AWS CLI:

```bash
# Login a ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin TU_CUENTA.dkr.ecr.us-east-1.amazonaws.com

# Crear repositorio para frontend
aws ecr create-repository --repository-name innovatech-frontend --region us-east-1

# Crear repositorio para backend-ventas
aws ecr create-repository --repository-name innovatech-backend-ventas --region us-east-1

# Crear repositorio para backend-despachos
aws ecr create-repository --repository-name innovatech-backend-despachos --region us-east-1
```

### 2.2 EC2 - Instancias

**Instancia Frontend:**
- AMI: Amazon Linux 2023
- Tipo: t3.micro
- Puerto 80 abierto (HTTP)
- Puerto 443 abierto (HTTPS)
- Security Group: permite desde internet solo 80 y 443

**Instancia Backend:**
- AMI: Amazon Linux 2023
- Tipo: t3.micro
- Puerto 8080 abierto (desde SG del Frontend)
- Puerto 8081 abierto (desde SG del Frontend)
- Security Group: permite desde Frontend SG solo 8080 y 8081

### 2.3 User Data para EC2 (instalar Docker al arrancar)

En la configuración de la instancia, en **Advanced details** → **User data**:

```bash
#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
```

### 2.4 RDS - MySQL

- Motor: MySQL 8.0
- Clase: db.t3.micro
- credenciales root configuradas
- Dos bases de datos: `innovatech_ventas` e `innovatech_despachos`
- Acceso público: NO (solo desde EC2 via Security Group)

---

## Paso 3: Hacer push a rama deploy

```bash
cd proyecto_entregado_por_el_profesor
git checkout -b deploy
git push origin deploy
```

Esto disparará los workflows de GitHub Actions automáticamente.

---

## Paso 4: Monitorear el pipeline

1. Ve a https://github.com/solxpa/innovatech/actions
2. Verás el workflow ejecutándose
3. Si falla, revisa los logs de cada paso

---

## Comandos de verificación en EC2

```bash
# Ver contenedores corriendo
docker ps

# Ver logs de un contenedor
docker logs innovatech-frontend
docker logs innovatech-backend-ventas
docker logs innovatech-backend-despachos

# Ver estado de salud
curl http://localhost/actuator/health
curl http://localhost:8080/actuator/health
curl http://localhost:8081/actuator/health

# Reiniciar un contenedor
docker restart innovatech-frontend
docker restart innovatech-backend-ventas
docker restart innovatech-backend-despachos

# Ver uso de recursos
docker stats
```

---

## Solución de problemas comunes

### Error: "no basic auth credentials"
**Causa:** No estás logueado en ECR
**Solución:** Ejecuta `aws ecr get-login-password...` antes de hacer pull

### Error: "connection refused" al backend
**Causa:** El backend no puede conectar a MySQL
**Solución:** Verificar que `DB_ENDPOINT` sea el hostname interno del RDS (no público)

### Error: "port is already allocated"
**Causa:** Otro contenedor está usando el puerto
**Solución:** `docker stop $(docker ps -q)` y luego `docker-compose up -d`

### Error: "health check failed"
**Causa:** El servicio no está respondiendo
**Solución:** Revisar logs con `docker logs <container>`

---

## Arquitectura esperada en AWS

```
Internet
   │
   ▼
┌─────────────────┐
│  EC2 Frontend   │ :80 (HTTP)
│  (t3.micro)     │ :443 (HTTPS)
└────────┬────────┘
         │ /api/v1/...
         ▼
┌─────────────────┐
│  EC2 Backend   │ :8080 (Ventas)
│  (t3.micro)     │ :8081 (Despachos)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  RDS MySQL      │ :3306
│  (db.t3.micro)  │
└─────────────────┘
```

---

*Documento creado para la evaluación ISY1101 - Mayo 2026*