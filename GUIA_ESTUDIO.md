# Guía de Estudio - Presentación ISY1101 - Innovatech Chile

## Documentación Disponible

| Documento | Ubicación | Propósito |
|------------|-----------|-----------|
| `README.md` | Raíz del proyecto | Documentación técnica completa |
| `CHANGELOG.md` | Raíz del proyecto | Registro de todos los cambios |

---

## Preguntas Frecuentes de la Presentación

### IE1: Contenedorización (20%)

**P: ¿Por qué usaste multi-stage build?**
R: Para reducir el tamaño de la imagen final. La etapa 1 (builder)compila el código, la etapa 2 (production) solo copia el artefacto final. La imagen de producción no incluye Maven/JDK/Node.js, solo JRE o nginx.

**P: ¿Por qué usuario no-root?**
R: Principio de mínimo privilegio. Si un atacante compromete el contenedor, no puede ejecutar comandos como root ni modificar el sistema operativo host.

**P: ¿Qué limpieza haces en los Dockerfiles?**
R:
- `npm cache clean --force` después de instalar dependencias
- `.dockerignore` excluye archivos innecesarios (logs, .git, node_modules)
- Solo copio el artefacto final (JAR o dist) a la imagen de producción

**P: ¿Cómo separates Front y Back en AWS EC2?**
R: Dos instancias EC2 separadas:
- EC2 Frontend: puerto 80 (HTTP), 443 (HTTPS)
- EC2 Backend: puertos 8080, 8081 (solo accesible desde Frontend SG)

---

### IE2: docker-compose (10%)

**P: ¿Qué servicios defines en docker-compose.yml?**
R:
- `frontend`: React + nginx (puerto 80)
- `backend-ventas`: Spring Boot (puerto 8080)
- `backend-despachos`: Spring Boot (puerto 8081)
- `mysql`: MySQL 8.0 (puerto 3306)

**P: ¿Qué redes configuras?**
R: Una red bridge llamada `app-network`. Los contenedores se comunican por nombre de servicio (ej: `http://backend-ventas:8080`).

**P: ¿Qué variables de entorno configuras?**
R:
- `SPRING_PROFILES_ACTIVE=prod`
- `DB_ENDPOINT`, `DB_PORT`, `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD`
- `NODE_ENV=production`

---

### IE3: Persistencia (10%)

**P: ¿Qué volúmenes defines?**
R:
- `mysql_data:/var/lib/mysql` - datos de la base de datos
- `ventas_data:/app` - datos del backend de ventas
- `despachos_data:/app` - datos del backend de despachos

**P: ¿Bind mount o named volume? ¿Por qué?**
R: **Named volume** porque:
1. Docker administra el volumen automáticamente
2. No depende de la estructura del filesystem del host
3. En EC2 no sabemos dónde están los archivos
4. Fácil de respaldar con `docker volume backup`

**P: ¿Cómo garantizas que los datos persisten?**
R: Los named volumes sobreviven al reinicio de contenedores. Si ejecutas `docker-compose down` y luego `docker-compose up`, los datos siguen ahí.

---

### IE4: Pipeline CI/CD (20%)

**P: ¿Cómo está configurado el trigger?**
R:
```yaml
on:
  push:
    branches:
      - deploy
  workflow_dispatch:  # Permite ejecución manual
```

**P: ¿Cuál es el flujo del pipeline?**
R:
1. Push a rama `deploy`
2. GitHub Actions detecta el trigger
3. Checkout del código
4. Configurar credenciales AWS
5. Login a Amazon ECR
6. Build de imagen Docker
7. Taggear imagen para ECR
8. Push imagen a ECR
9. SSH a EC2
10. Pull imagen de ECR
11. Detener y eliminar contenedor anterior
12. Ejecutar nuevo contenedor
13. Limpiar imágenes antiguas

**P: ¿Cómo manejas los secrets?**
R: Usando GitHub Secrets (Settings → Secrets):
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `EC2_HOST`, `EC2_SSH_KEY`
- `DB_ENDPOINT`, `DB_USERNAME`, `DB_PASSWORD`

---

### IE5 e IE6: Funcionamiento en EC2 (30%)

**P: ¿Cómo verificas que el frontend funciona?**
R:
```bash
curl http://localhost/actuator/health  # o solo http://localhost/
docker ps  # debe mostrar "healthy"
```

**P: ¿Cómo verificas que el backend funciona?**
R:
```bash
curl http://localhost:8080/actuator/health
curl http://localhost:8081/actuator/health
docker ps  # debe mostrar "healthy"
```

**P: ¿Cómo verificas la conectividad Front → Back?**
R:
1. Frontend llama a `/api/v1/despachos`
2. nginx recibe la request en puerto 80
3. nginx redirige a `http://backend-despachos:8081/api/v1/despachos`
4. Backend responde con JSON

---

### IE7: Integración Front → Back (5%)

**P: ¿Cómo se comunican Front y Back?**
R: A través de proxy reverso en nginx. El frontend usa URLs relativas (`/api/v1/despachos`), no IPs hardcodeadas. nginx redirige las requests a los backends según la ruta.

**P: ¿Qué errores tenía el código original y cómo los corregiste?**
R:
- `TableDespachos.jsx`: `http://192.168.3.20/api/v1/despachos` → `/api/v1/despachos`
- `FormDespacho.jsx`: `http://192.168.30/api/v1/ventas/...` → `/api/v1/ventas/...`
- `FormCierreDespacho.jsx`: `http://192.168.320/api/v1/despachos/...` → `/api/v1/despachos/...`
- `TableCompras.jsx`: `http://192.168.30/api/v1/ventas` → `/api/v1/ventas`

---

### IE8: Documentación (5%)

**P: ¿Qué documentas en el README?**
R:
- Arquitectura del sistema (diagramas ASCII)
- Decisiones técnicas (por qué multi-stage, no-root, named volumes)
- Instrucciones de desarrollo local
- Instrucciones de despliegue en AWS
- Pipeline CI/CD completo
- Comandos útiles
- Glosario DevOps

---

## Escenarios de Prueba para la Presentación

### Escenario 1: Levantar todos los servicios localmente

```bash
cd proyecto_entregado_por_el_profesor
docker-compose up --build

# Verificar en navegador:
# - Frontend: http://localhost:80
# - Backend Ventas: http://localhost:8080/actuator/health
# - Backend Despachos: http://localhost:8081/actuator/health
```

### Escenario 2: Ver logs de un servicio

```bash
docker-compose logs -f backend-ventas
docker-compose logs -f backend-despachos
docker-compose logs -f frontend
```

### Escenario 3: Verificar estado de contenedores

```bash
docker-compose ps
# Debe mostrar:
# NAME                     STATUS          PORTS
# innovatech-frontend       running (healthy)   0.0.0.0:80->80/tcp
# innovatech-backend-ventas running (healthy)   0.0.0.0:8080->8080/tcp
# innovatech-backend-despachos running (healthy) 0.0.0.0:8081->8081/tcp
# innovatech-mysql          running (healthy)   0.0.0.0:3306->3306/tcp
```

### Escenario 4: Verificar volúmenes

```bash
docker volume ls
# Debe mostrar:
# innovatech_mysql_data
# innovatech_ventas_data
# innovatech_despachos_data
```

### Escenario 5: Probar API del backend

```bash
# Crear una venta
curl -X POST http://localhost:8080/api/v1/ventas \
  -H "Content-Type: application/json" \
  -d '{"direccionCompra":"Av. Principal 123","fechaCompra":"2026-05-26","valorCompra":29990}'

# Listar ventas
curl http://localhost:8080/api/v1/ventas

# Listar despachos
curl http://localhost:8081/api/v1/despachos
```

### Escenario 6: Simular deploy

```bash
# Hacer un cambio cualquiera
echo "# test" >> /tmp/test.txt
git add . && git commit -m "test: trigger deploy"
git checkout -b deploy
git push origin deploy

# Verificar que el pipeline se ejecuta en GitHub Actions
# Settings → Actions → ver los workflows
```

---

## Respuestas para el Profesor (defensa técnica)

### Sobre Multi-Stage Build

"El Dockerfile usa dos etapas para seguir el principio de imagen mínima. La primera etapa (builder)compila el código usando Maven + JDK. La segunda etapa solo copia el JAR compilado y usa JRE (no JDK). El resultado es una imagen de ~200MB en vez de ~800MB. Además, las herramientas de build no están disponibles en producción, lo cual reduce la superficie de ataque."

### Sobre Usuario No-Root

"Todos los contenedores se ejecutan con usuario no-root. El backend usa el usuario `innovatech` (creado específicamente) y el frontend usa `nginx`. Esto sigue el principio de mínimo privilegio: si un atacante logra acceder al contenedor, no puede modificar archivos del sistema operativo host."

### Sobre Named Volumes

"Elegimos named volumes sobre bind mounts porque son más portátiles. En EC2, no controlamos la estructura del filesystem del host. Los named volumes son administrados por Docker y sobreviven al reinicio de contenedores. Para la base de datos MySQL, esto es crítico porque los datos deben persistir incluso si el contenedor se elimina y se crea uno nuevo."

### Sobre Pipeline CI/CD

"El pipeline se ejecuta automáticamente cuando hacemos push a la rama `deploy`. Primero构建 la imagen Docker, luego la sube a Amazon ECR, y finalmente se conecta por SSH a la instancia EC2 para hacer el deploy. Todo el proceso es automático y no requiere intervención manual. Los secrets (credenciales AWS, claves SSH) están almacenados en GitHub Secrets, nunca en el código."

### Sobre Seguridad

"La seguridad está implementada en múltiples capas: (1) Contenedores con usuario no-root y sin herramientas de build en producción; (2) Red con Security Groups que solo abren los puertos necesarios; (3) Aplicación con headers de seguridad en nginx y variables de entorno para secretos."

### Sobre Microservicios

"Separamos los componentes en microservicios para poder escalarlos independientemente. El frontend puede escalar sin afectar a los backends. Cada backend tiene su propia base de datos (en el caso real, tablas separadas en el mismo RDS). La comunicación entre ellos es vía HTTP a través del proxy reverso de nginx."

---

## Checklist Antes de la Presentación

- [ ] README.md leído y entendido
- [ ] CHANGELOG.md revuecido (todos los cambios documentados)
- [ ] docker-compose up --build funciona localmente
- [ ] Todos los healthchecks responden correctamente
- [ ] Los volúmenes se crean y persisten datos
- [ ] Las URLs del frontend no tienen IPs hardcodeadas
- [ ] El pipeline CI/CD está configurado en GitHub
- [ ] Los secrets están configurados en GitHub
- [ ] La rama `deploy` existe y está funcional
- [ ] Cada miembro del equipo sabe explicar su parte

---

## glosario Rápido para la Presentación

| Término | Definición Simple |
|---------|-------------------|
| **Contenedor** | Empaquetado que incluye código + dependencias, funciona igual en cualquier lugar |
| **Imagen** | Plantilla para crear contenedores |
| **Multi-stage** | Técnica para hacer imágenes más pequeñas |
| **No-root** | Ejecutar como usuario normal, no administrador |
| **Volumen** | Forma de guardar datos que sobrevive al contenedor |
| **Bridge network** | Red privada donde los contenedores hablan entre sí |
| **Proxy reverso** | Servidor que recibe requests y las envía a otros servicios |
| **CI/CD** | Automatización de build y deploy |
| **ECR** | Lugar en AWS donde guardamos imágenes Docker |
| **EC2** | Computador virtual en AWS |
| **Healthcheck** | Verificación de que el servicio está funcionando |

---

*Documento creado para estudiar para la presentación - ISY1101 - Duoc UC - Mayo 2026*