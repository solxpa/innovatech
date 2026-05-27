# Innovatech Chile - Sistema de Gestión de Despachos

## Descripción General

Este proyecto implementa un sistema de gestión de despachos para la empresa Innovatech Chile, desarrollado como parte de la Evaluación Parcial N°2 de la asignatura **ISY1101 - Introducción a Herramientas DevOps** de Duoc UC.

El sistema está diseñado con arquitectura de microservicios, contenedorizado completamente con Docker y desplegado en AWS EC2.

---

## Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                    AWS Cloud                                         │
│                                                                                     │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                        EC2 Frontend (t3.micro)                                │  │
│  │                                                                               │  │
│  │   ┌─────────────┐         ┌─────────────────┐                               │  │
│  │   │   nginx     │◀───────│    React App    │                               │  │
│  │   │   :80       │         │   (Puerto 80)   │                               │  │
│  │   │  Proxy Pass │         │   SPA Router    │                               │  │
│  │   └─────────────┘         └─────────────────┘                               │  │
│  │         │                                                                      │  │
│  │         │ /api/v1/ventas     /api/v1/despachos                               │  │
│  │         └──────────────────────────│                                        │  │
│  └────────────────────────────────────│────────────────────────────────────────┘  │
│                                       │                                           │
│                                       │ HTTP (8080, 8081)                        │
│                                       ▼                                           │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                        EC2 Backend (t3.micro)                                  │  │
│  │                                                                               │  │
│  │   ┌─────────────────┐         ┌─────────────────┐                            │  │
│  │   │ Spring Ventas   │         │Spring Despachos │                            │  │
│  │   │    :8080        │         │     :8081       │                            │  │
│  │   └────────┬────────┘         └────────┬────────┘                            │  │
│  │            │                           │                                     │  │
│  │            └───────────┬───────────────┘                                     │  │
│  │                        │                                                     │  │
│  │                        ▼                                                     │  │
│  │            ┌───────────────────────┐                                         │  │
│  │            │    AWS RDS MySQL      │                                         │  │
│  │            │    (Base de Datos)    │                                         │  │
│  │            └───────────────────────┘                                         │  │
│  │                                                                               │  │
│  │   Security Groups:                                                           │  │
│  │     - Frontend EC2: Puerto 80 (HTTP), 443 (HTTPS)                           │  │
│  │     - Backend EC2: Puerto 8080, 8081 (solo desde Frontend SG)               │  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Componentes del Proyecto

### 1. Frontend (`front_despacho/`)
- **Tecnología**: React 18 + Vite 5 + Tailwind CSS
- **Puerto**: 80 (interno), mapeado a 80 para producción
- **Funcionalidad**: Interfaz de usuario para gestión de despachos
- **Proxy Reverso**: nginx que redirige `/api/v1/*` a los backends

### 2. Backend Ventas (`back-Ventas_SpringBoot/Springboot-API-REST`)
- **Tecnología**: Spring Boot 3.4.4 + Java 17
- **Puerto**: 8080
- **Base de datos**: MySQL (configurado para AWS RDS)
- **Endpoints**:
  - `GET /api/v1/ventas` - Listar todas las ventas
  - `GET /api/v1/ventas/{id}` - Obtener venta por ID
  - `PUT /api/v1/ventas/{id}` - Actualizar venta
  - `POST /api/v1/ventas` - Crear nueva venta

### 3. Backend Despachos (`back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO`)
- **Tecnología**: Spring Boot 3.4.4 + Java 17
- **Puerto**: 8081
- **Base de datos**: MySQL (configurado para AWS RDS)
- **Endpoints**:
  - `GET /api/v1/despachos` - Listar todos los despachos
  - `POST /api/v1/despachos` - Crear nuevo despacho
  - `PUT /api/v1/despachos/{id}` - Actualizar despacho
  - `DELETE /api/v1/despachos/{id}` - Eliminar despacho

---

## Volúmenes y Persistencia

### Decisión de Diseño: Named Volumes vs Bind Mounts

| Aspecto | Named Volume | Bind Mount |
|---------|--------------|------------|
| Administración | Docker administra automáticamente | Usuario administra manualmente |
| Ubicación | Docker elige (/var/lib/docker/volumes) | Usuario especifica (/home/user/data) |
| Portabilidad | Muy portable, funciona en cualquier host | Depende de la estructura del host |
| Respaldo | Fácil con `docker volume backup` | Requiere scripting manual |
| Permisos | Docker maneja permisos automáticamente | Puede requerir ajustes manuales |
| Uso en producción | Recomendado para databases | Bueno para código fuente o configs |

**Justificación**: Se utilizan **named volumes** para:
1. **Base de datos MySQL**: Los datos deben sobrevivir al reinicio del contenedor y no dependen de la estructura del filesystem del host.
2. **Datos de aplicación**: Los microservicios pueden necesitar almacenar archivos temporales o datos de sesión.

---

## Requisitos

### Para Desarrollo Local
- Docker Desktop (o Docker Engine)
- Docker Compose v2.0+
- Mínimo 4GB de RAM disponible
- Puerto 80, 3306, 8080, 8081 disponibles

### Para Despliegue en AWS
- Cuenta AWS Academy o AWS activa
- Instancia EC2 t3.micro (o superior)
- AWS RDS MySQL 8.0 (o MariaDB)
- ECR (Elastic Container Registry) para almacenar imágenes

---

## Desarrollo Local

### Paso 1: Clonar el repositorio

```bash
git clone <repository-url>
cd proyecto_entregado_por_el_profesor
```

### Paso 2: Configurar variables de entorno (opcional)

Crear archivo `.env` en la raíz del proyecto:

```env
MYSQL_ROOT_PASSWORD=innovatech2025
```

### Paso 3: Levantar todos los servicios

```bash
docker-compose up --build
```

### Paso 4: Verificar que todo funciona

- **Frontend**: http://localhost:80
- **Backend Ventas**: http://localhost:8080/actuator/health
- **Backend Despachos**: http://localhost:8081/actuator/health

---

## Dockerfiles - Decisiones Técnicas

### Multi-Stage Build

Cada Dockerfile tiene dos etapas:

1. **Builder Stage**: Usa imagen con Maven + JDK para compilar el proyecto
2. **Production Stage**: Usa imagen JRE más pequeña para ejecutar solo el JAR

**Beneficios**:
- Imagen final más pequeña (no incluye Maven ni JDK)
- Mayor seguridad (herramientas de build no están en producción)
- Build reproducible (dependencias cacheadas)

### Usuario No-Root

Todos los contenedores se ejecutan con usuarios no-root:

- **Backend**: Usuario `innovatech` (UID 1001)
- **Frontend**: Usuario `nginx` (usuario por defecto de nginx:alpine)

**Por qué es importante**: Si un atacante compromete el contenedor, no tendrá permisos de administrador del sistema.

### Healthcheck

Cada contenedor tiene un healthcheck configurado:
- **Backend**: `wget http://localhost:{puerto}/actuator/health`
- **Frontend**: `wget http://localhost/`

Esto permite que Docker y AWS monitoreen la salud de los contenedores.

---

## Pipeline CI/CD

### Trigger

El pipeline se ejecuta automáticamente cuando se hace push a la rama `deploy`:

```yaml
on:
  push:
    branches:
      - deploy
  workflow_dispatch:  # Permite ejecución manual
```

### Flujo del Pipeline

```
┌─────────────┐    ┌──────────────┐    ┌────────────┐    ┌──────────────┐
│   Push a    │───▶│   GitHub     │───▶│   Build    │───▶│   Push a     │
│   deploy    │    │   Actions    │    │   Docker   │    │   ECR        │
│   branch    │    │   detecta    │    │   Images   │    │             │
└─────────────┘    └──────────────┘    └────────────┘    └──────────────┘
                                                                │
                                                                ▼
                                                        ┌──────────────┐
                                                        │   SSH a      │
                                                        │   EC2        │
                                                        └──────────────┘
                                                                │
                                                                ▼
                                                        ┌──────────────┐
                                                        │   Pull y     │
                                                        │   Deploy     │
                                                        └──────────────┘
```

### Secrets Requeridos (GitHub Actions)

| Secret | Descripción |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | Access Key de IAM para AWS |
| `AWS_SECRET_ACCESS_KEY` | Secret Key de IAM para AWS |
| `EC2_BACKEND_HOST` | DNS público o IP del EC2 backend |
| `EC2_FRONTEND_HOST` | DNS público o IP del EC2 frontend |
| `EC2_SSH_KEY` | Private key SSH para conexión |
| `DB_ENDPOINT` | Endpoint del RDS MySQL |
| `DB_USERNAME` | Usuario de la base de datos |
| `DB_PASSWORD` | Contraseña de la base de datos |
| `DB_NAME_VENTAS` | Nombre de la base de datos de ventas |
| `DB_NAME_DESPACHOS` | Nombre de la base de datos de despachos |

### Variables de Repositorio (GitHub Variables)

| Variable | Descripción |
|----------|-------------|
| `AWS_ECR_REGISTRY` | URL del registro ECR (ej: 123456789.dkr.ecr.us-east-1.amazonaws.com) |

---

## Seguridad Implementada

### A nivel de Contenedor
- ✅ Usuario no-root en todos los contenedores
- ✅ Mínimo privileged en capacidades de Docker
- ✅ Healthchecks para monitoreo de estado

### A nivel de Red
- ✅ Security Groups con puertos mínimos necesarios
- ✅ Frontend solo expone puerto 80 (HTTP)
- ✅ Backend expone puertos 8080, 8081 (solo desde Frontend SG)
- ✅ Proxy reverso en nginx filtra rutas

### A nivel de Aplicación
- ✅ Headers de seguridad en nginx (X-Frame-Options, X-Content-Type-Options, etc.)
- ✅ Variables de entorno para secretos (no hardcoded)
- ✅ CORS configurado en Spring Boot
- ✅ Tokens y credenciales en GitHub Secrets

---

## Comandos Útiles

### Development Local

```bash
# Levantar todos los servicios
docker-compose up --build

# Ver logs de un servicio específico
docker-compose logs -f backend-ventas

# Detener todos los servicios
docker-compose down

# Reconstruir un servicio específico
docker-compose up --build backend-ventas

# Ver estado de los contenedores
docker-compose ps

# Ver uso de recursos
docker stats
```

### Verificación

```bash
# Ver imágenes Docker
docker images | grep innovatech

# Ver redes Docker
docker network ls

# Ver volúmenes Docker
docker volume ls

# Ver logs de un contenedor específico
docker logs innovatech-frontend
docker logs innovatech-backend-ventas
docker logs innovatech-backend-despachos

# Ver health de un contenedor
docker inspect --format='{{.State.Health.Status}}' innovatech-frontend
```

### Troubleshooting

```bash
# Ver logs de Spring Boot
docker logs innovatech-backend-ventas
docker logs innovatech-backend-despachos

# Verificar que los servicios están escuchando
docker exec innovatech-backend-ventas wget -qO- http://localhost:8080/actuator/health
docker exec innovatech-backend-despachos wget -qO- http://localhost:8081/actuator/health

# Acceder a la base de datos MySQL
docker exec -it innovatech-mysql mysql -uroot -p
```

---

## Estructura de Archivos

```
proyecto_entregado_por_el_profesor/
├── docker-compose.yml              # Define todos los servicios
├── README.md                       # Este archivo
├── CHANGELOG.md                    # Registro de cambios
│
├── back-Ventas_SpringBoot/
│   └── Springboot-API-REST/
│       ├── Dockerfile              # Multi-stage build
│       ├── .dockerignore           # Archivos excluidos
│       ├── pom.xml                 # Dependencias Maven
│       ├── src/                    # Código fuente
│       └── .github/
│           └── workflows/
│               └── deploy.yml      # Pipeline CI/CD
│
├── back-Despachos_SpringBoot/
│   └── Springboot-API-REST-DESPACHO/
│       ├── Dockerfile              # Multi-stage build
│       ├── .dockerignore           # Archivos excluidos
│       ├── pom.xml                 # Dependencias Maven
│       ├── src/                    # Código fuente
│       └── .github/
│           └── workflows/
│               └── deploy.yml      # Pipeline CI/CD
│
└── front_despacho/
    ├── Dockerfile                  # Multi-stage build
    ├── .dockerignore               # Archivos excluidos
    ├── nginx.conf                  # Configuración de nginx
    ├── package.json                # Dependencias Node
    ├── vite.config.js              # Configuración de Vite
    ├── src/                        # Código fuente React
    └── .github/
        └── workflows/
            └── deploy.yml          # Pipeline CI/CD
```

---

## Justificación de Decisiones Técnicas

### 1. ¿Por qué Multi-Stage Build?

**Problema**: Las imágenes de producción no deberían incluir herramientas de desarrollo.

**Solución**: El Dockerfile tiene dos etapas:
- Etapa 1 (builder): Compila el código con Maven + JDK
- Etapa 2 (production): Solo copia el JAR compilado, usa JRE más pequeño

**Resultado**: Imagen final de ~200MB vs ~800MB si se usara JDK completo.

### 2. ¿Por qué Usuario No-Root?

**Problema**: Ejecutar contenedores como root es un riesgo de seguridad.

**Solución**: Crear usuario específico (`innovatech` para backend, `nginx` para frontend)

**Beneficio**: Si hay una vulnerabilidad, el atacante no puede modificar el sistema operativo host.

### 3. ¿Por qué Named Volumes?

**Problema**: Bind mounts dependen de la estructura del filesystem del host.

**Solución**: Usar named volumes (`mysql_data:/var/lib/mysql`)

**Beneficio**:
- Docker administra el volumen automáticamente
- Es portable entre diferentes hosts
- Fácil de hacer backup con `docker volume backup`

### 4. ¿Por qué Proxy Reverso en nginx?

**Problema**: El frontend no puede conocer las IPs de los backends en producción.

**Solución**: nginx recibe todas las requests y redirige según la ruta:
- `/api/v1/ventas/*` → `http://backend-ventas:8080`
- `/api/v1/despachos/*` → `http://backend-despachos:8081`

**Beneficio**: El frontend usa URLs relativas (`/api/v1/ventas`), no necesita configuración por entorno.

### 5. ¿Por qué ECR y no Docker Hub?

**Problema**: Docker Hub requiere tokens y tiene límites de pulls.

**Solución**: Amazon ECR (Elastic Container Registry)

**Beneficio**:
- Integración nativa con AWS (mismas credenciales)
- Sin costos de egress (todo está en la misma región)
- IAM controla permisos de acceso
- Sin límites de pulls en tier gratuita

---

## Glosario DevOps

| Término | Definición |
|---------|------------|
| **Contenedor** | Tecnología que empaqueta código y dependencias para que una aplicación corra de forma consistente en cualquier ambiente. |
| **Imagen Docker** | Plantilla de solo lectura que define cómo crear un contenedor. |
| **Dockerfile** | Archivo de texto que contiene instrucciones para construir una imagen Docker. |
| **Multi-Stage Build** | Técnica de Dockerfile que usa múltiples etapas para crear imágenes más pequeñas y seguras. |
| **Volumen** | Mecanismo para persistir datos generados por un contenedor. |
| **Bridge Network** | Tipo de red Docker que permite a los contenedores comunicarse en el mismo host. |
| **Proxy Reverso** | Servidor que recibe requests y las redirige a uno o más servidores backend. |
| **CI/CD** | Continuous Integration / Continuous Deployment: práctica de automatizar builds y despliegues. |
| **ECR** | Elastic Container Registry: servicio de AWS para almacenar imágenes Docker. |
| **EC2** | Elastic Compute Cloud: servicio de AWS para crear instancias virtuales. |
| **Healthcheck** | Comando que verifica si un contenedor está funcionando correctamente. |
| **Spring Boot Actuator** | Biblioteca de Spring Boot que expone endpoints de monitoreo y salud. |

---

## Contacto y Recursos

**Institución**: Duoc UC
**Asignatura**: ISY1101 - Introducción a Herramientas DevOps
**Evaluación**: Parcial N°2 (30% de ponderación)

**Recursos adicionales**:
- [Documentación de Docker](https://docs.docker.com/)
- [Documentación de Spring Boot](https://spring.io/projects/spring-boot)
- [Documentación de AWS EC2](https://docs.aws.amazon.com/ec2/)
- [GitHub Actions Documentation](https://docs.github.com/actions)

---

**Nota**: Este proyecto fue desarrollado como parte de una evaluación académica. La arquitectura y decisiones técnicas buscan cumplir con los indicadores de evaluación de la pauta.

*Última actualización: Mayo 2026*