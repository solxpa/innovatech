# Changelog - Innovatech Chile - ISY1101

Documento que registra todos los cambios realizados para la Evaluación Parcial N°2.

---

## v2.0.0 - Implementación Completa DevOps (26 Mayo 2026)

### Resumen de Cambios

Esta versión implementa la arquitectura completa de contenedores y CI/CD para el proyecto Innovatech Chile, cumpliendo con todos los indicadores de evaluación de la pauta ISY1101.

---

## Cambios en Backend Ventas (`back-Ventas_SpringBoot/Springboot-API-REST/`)

#### `Dockerfile` - NUEVO
- **Multi-stage build**:
  - Etapa 1 (builder): `maven:3.9-eclipse-temurin-17` para compilar con Maven
  - Etapa 2 (production): `eclipse-temurin:17-jre-alpine` para ejecutar solo el JAR
- **Usuario no-root**: `innovatech` (UID 1001, creado específicamente)
- **Healthcheck**: Verifica `/actuator/health` cada 30s
- **Memoria JVM**: `-Xms256m -Xmx512m` para evitar consumo excesivo

#### `.dockerignore` - NUEVO
- Excluye: `.git`, `target/`, `*.log`, archivos IDE, `.env`
- Reduce el tamaño del build context

#### `.github/workflows/deploy.yml` - NUEVO
- Pipeline CI/CD completo
- Trigger en rama `deploy`
- Flujo: Build → Push a ECR → Deploy a EC2 via SSH
- Autenticación AWS con GitHub Secrets

#### `pom.xml` - MODIFICADO
- Agregado `spring-boot-starter-actuator` para healthcheck

#### `application.properties` - MODIFICADO
- Agregado configuración de Spring Boot Actuator
- Expuestos endpoints: `/actuator/health`, `/actuator/info`

---

## Cambios en Backend Despachos (`back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO/`)

#### `Dockerfile` - NUEVO
- **Multi-stage build**: Mismo patrón que backend ventas
- **Usuario no-root**: `innovatech`
- **Puerto**: 8081 (externo)
- **Healthcheck**: Verifica `/actuator/health` cada 30s

#### `.dockerignore` - NUEVO
- Mismo patrón que backend ventas

#### `.github/workflows/deploy.yml` - NUEVO
- Pipeline CI/CD completo (independiente del otro backend)

#### `pom.xml` - MODIFICADO
- Agregado `spring-boot-starter-actuator`

#### `application.properties` - MODIFICADO
- Agregado configuración de Spring Boot Actuator

---

## Cambios en Frontend (`front_despacho/`)

#### `Dockerfile` - NUEVO
- **Multi-stage build**:
  - Etapa 1 (builder): `node:20-alpine` para compilar con Vite
  - Etapa 2 (production): `nginx:alpine` para servir archivos estáticos
- **Usuario no-root**: `nginx` (usuario por defecto de nginx:alpine)
- **Healthcheck**: Verifica `http://localhost/` cada 30s

#### `nginx.conf` - NUEVO
- **Proxy reverso**:
  - `/api/v1/ventas/*` → `http://backend-ventas:8080`
  - `/api/v1/despachos/*` → `http://backend-despachos:8081`
- **SPA routing**: `try_files $uri $uri/ /index.html`
- **Headers de seguridad**: X-Frame-Options, X-Content-Type-Options, X-XSS-Protection
- **Caché**: Assets estáticos cacheados por 1 año

#### `.dockerignore` - NUEVO
- Excluye: `.git`, `node_modules/`, `dist/`, archivos IDE, logs

#### `.github/workflows/deploy.yml` - NUEVO
- Pipeline CI/CD completo para frontend

---

## Cambios en Frontend (Componentes React)

#### `TableDespachos.jsx` - CORREGIDO
- **Antes**: URL hardcodeada `http://192.168.3.20/api/v1/despachos`
- **Después**: URL relativa `/api/v1/despachos`

#### `FormDespacho.jsx` - CORREGIDO
- **Antes**: URLs mal formadas `http://192.168.30/api/v1/ventas/...` y `http://192.168.320/api/v1/despachos`
- **Después**: URLs relativas `/api/v1/ventas/...` y `/api/v1/despachos`

#### `FormCierreDespacho.jsx` - CORREGIDO
- **Antes**: URL `http://192.168.320/api/v1/despachos/${despacho.idDespacho}`
- **Después**: URL relativa `/api/v1/despachos/${despacho.idDespacho}`

#### `TableCompras.jsx` - CORREGIDO
- **Antes**: URL `http://192.168.30/api/v1/ventas`
- **Después**: URL relativa `/api/v1/ventas`

---

## Nuevo Archivo en Raíz

#### `docker-compose.yml` - NUEVO
- **Servicios**:
  - `frontend`: React + nginx (puerto 80)
  - `backend-ventas`: Spring Boot (puerto 8080)
  - `backend-despachos`: Spring Boot (puerto 8081)
  - `mysql`: MySQL 8.0 (puerto 3306)
- **Redes**: `app-network` (bridge driver)
- **Volúmenes**:
  - `mysql_data:/var/lib/mysql` (persistencia)
  - `ventas_data:/app`
  - `despachos_data:/app`
- **Healthchecks**: Configurados en todos los servicios
- **Restart policy**: `unless-stopped`

---

## Checklist de Implementación

| Componente | Estado | Descripción |
|------------|--------|-------------|
| Dockerfile Backend Ventas | ✅ Listo | Multi-stage, non-root, healthcheck, actuator |
| Dockerfile Backend Despachos | ✅ Listo | Multi-stage, non-root, healthcheck, actuator |
| Dockerfile Frontend | ✅ Listo | Multi-stage, non-root, healthcheck |
| nginx.conf | ✅ Listo | Proxy reverso, SPA routing, headers seguridad |
| .dockerignore (x3) | ✅ Listo | Build context optimizado |
| docker-compose.yml | ✅ Listo | 4 servicios, redes, volúmenes, healthchecks |
| URLs hardcodeadas | ✅ Corregido | 4 archivos corregidos |
| GitHub Actions Backend Ventas | ✅ Listo | Pipeline completo |
| GitHub Actions Backend Despachos | ✅ Listo | Pipeline completo |
| GitHub Actions Frontend | ✅ Listo | Pipeline completo |

---

##.pending de Configuración (Por hacer en AWS/GitHub)

### AWS
- [ ] Crear repositorios ECR (frontend, backend-ventas, backend-despachos)
- [ ] Obtener Access Key + Secret Key IAM
- [ ] Crear instancia EC2 Frontend (t3.micro)
- [ ] Crear instancia EC2 Backend (t3.micro)
- [ ] Crear RDS MySQL (o usar AWS Academy)
- [ ] Configurar Security Groups:
  - Frontend SG: Puerto 80 (HTTP), 443 (HTTPS)
  - Backend SG: Puerto 8080, 8081 (solo desde Frontend SG)
- [ ] Ejecutar user data para instalar Docker + AWS CLI en EC2s

### GitHub (en cada repositorio)
- [ ] Crear repository variable: `AWS_ECR_REGISTRY`
- [ ] Crear secrets:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `EC2_FRONTEND_HOST`
  - `EC2_BACKEND_HOST`
  - `EC2_SSH_KEY`
  - `DB_ENDPOINT`
  - `DB_USERNAME`
  - `DB_PASSWORD`
  - `DB_NAME_VENTAS`
  - `DB_NAME_DESPACHOS`
- [ ] Crear rama `deploy` y hacer push inicial

---

## Justificación de Decisiones Técnicas

### 1. Arquitectura de Microservicios

**Decisión**: Separar frontend y backends en contenedores independientes.

**Justificación**:
- Cada servicio puede escalarse independientemente
- Facilita el mantenimiento y actualizaciones
- Seguir patrones de la industria (Netflix, Amazon)
- La evaluación pide "separación clara Front-Back en AWS EC2"

### 2. Dos Instancias EC2 (no tres)

**Decisión**: Ejecutar ambos backends en la misma instancia EC2.

**Justificación**:
- Reduce costos (2 instancias vs 3)
- Los backends son ligeraços (t3.micro es suficiente)
- La comunicación entre ellos es rápida (localhost)
- Simplifica la configuración de red

### 3. Named Volumes para Persistencia

**Decisión**: Usar named volumes en vez de bind mounts.

**Justificación**:
- Docker administra el volumen automáticamente
- Portable entre diferentes hosts
- En EC2, no sabemos la estructura del filesystem
- Named volume es más fácil de respaldar

### 4. URLs Relativas en Frontend

**Decisión**: Cambiar URLs hardcodeadas (`http://192.168.x.x`) a URLs relativas (`/api/v1/...`).

**Justificación**:
- Funciona igual en desarrollo local, staging y producción
- No necesita cambios al desplegar
- El proxy reverso (nginx) maneja la resolución

### 5. Spring Boot Actuator para Healthcheck

**Decisión**: Agregar actuator y verificar `/actuator/health`.

**Justificación**:
- Healthcheck de Docker puede verificar si el servicio está arriba
- AWS puede monitorear la salud del contenedor
- El endpoint responde rápido y no requiere autenticación

### 6. Pipeline CI/CD con SSH a EC2

**Decisión**: En vez de usar AWS CodeDeploy, usar SSH + docker-compose.

**Justificación**:
- Más simple de implementar
- No requiere agente de CodeDeploy
- Funciona con cualquier instancia con SSH
- El profesor pidió "triggers en la rama deploy"

---

## Comandos para Verificación Local

```bash
# 1. Levantar todos los servicios
docker-compose up --build

# 2. Verificar que el frontend está activo
curl http://localhost/

# 3. Verificar backend-ventas
curl http://localhost:8080/actuator/health

# 4. Verificar backend-despachos
curl http://localhost:8081/actuator/health

# 5. Verificar logs de un servicio
docker-compose logs -f backend-ventas

# 6. Ver estado de contenedores
docker-compose ps

# 7. Ver uso de recursos
docker stats
```

---

## Glosario de Cambios

| Término | Definición |
|---------|------------|
| **Multi-stage build** | Técnica de Dockerfile que usa múltiples etapas FROM para crear imágenes más pequeñas |
| **Healthcheck** | Comando que Docker ejecuta periódicamente para verificar si el contenedor está sano |
| **Named volume** | Volumen administrado por Docker, no depende del filesystem del host |
| **Proxy reverso** | Servidor que recibe requests y las redirige a servidores backend |
| **CI/CD** | Práctica de automatizar la integración y despliegue de código |
| **GitHub Secrets** | Variables cifradas almacenadas en GitHub para usar en Actions |
| **ECR** | Elastic Container Registry - servicio de AWS para almacenar imágenes Docker |

---

## Créditos

**Institución**: Duoc UC
**Asignatura**: ISY1101 - Introducción a Herramientas DevOps
**Proyecto**: Innovatech Chile - Sistema de Gestión de Despachos
**Fecha**: 26 de Mayo de 2026

---

*Documento creado para la Evaluación Parcial N°2 - ISY1101 - Duoc UC*