# ============================================
# ETAPA 1: BUILD - Compilar aplicación Spring Boot con Maven
# Esta etapa usa imagen con Maven + JDK para compilar el proyecto
# ============================================
FROM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /app

# Copiar primero solo pom.xml para optimizar caché de Docker
# Si solo cambia pom.xml, no necesita recompilar las dependencias
COPY pom.xml ./
RUN mvn dependency:go-offline -B

# Copiar código fuente y compilar
COPY src ./src
RUN mvn package -DskipTests -B

# ============================================
# ETAPA 2: PRODUCCIÓN - Runtime optimizado
# Imagen mucho más pequeña que el JDK (solo JRE)
# No incluye herramientas de desarrollo
# ============================================
FROM eclipse-temurin:17-jre-alpine AS production

# Crear usuario no-root específico para la aplicación
# Esto sigue el principio de mínimo privilegio (Principle of Least Privilege)
# Si un atacante compromete el contenedor, no tendrá permisos de administrador
RUN addgroup -g 1001 -S innovatech && \
    adduser -S innovatech -u 1001 -G innovatech

WORKDIR /app

# Copiar solo el JAR compilado desde la etapa builder
# No copiamos todo el código fuente, solo el artefacto final
COPY --from=builder /app/target/*.jar app.jar

# Cambiar ownership de archivos al usuario no-root
RUN chown -R innovatech:innovatech /app

# Cambiar a usuario no-root (NO root en producción)
USER innovatech

# Puerto que expose el contenedor (Spring Boot usa 8081)
EXPOSE 8081

# Healthcheck para verificar que el servicio está activo y respondiendo
# Usa wget que viene incluido en Alpine
# Spring Boot Actuator expone /actuator/health que retorna {"status":"UP"} cuando está sano
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8081/actuator/health || exit 1

# Variables de memoria JVM optimizadas para contenedores
# -Xms256m: memoria inicial mínima
# -Xmx512m: memoria máxima
# Esto evita que Java consuma toda la RAM del contenedor
ENTRYPOINT ["java", "-jar", "-Xms256m", "-Xmx512m", "app.jar"]