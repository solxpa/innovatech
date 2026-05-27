# ============================================
# ETAPA 1: BUILD - Compilar aplicación React con Vite
# Esta etapa usa Node.js para instalar dependencias y compilar el proyecto
# ============================================
FROM node:20-alpine AS builder

WORKDIR /app

# Copiar primero solo package*.json para optimizar caché de Docker
# Si solo cambian package*.json, no necesita reinstallar node_modules
COPY package*.json ./

# Instalar dependencias de forma determinística (npm ci)
# No usamos --only=production porque necesitamos devDependencies para build (eslint, etc.)
RUN npm ci && npm cache clean --force

# Copiar código fuente
COPY . .

# Compilar la aplicación Vite (genera /app/dist)
RUN npm run build

# ============================================
# ETAPA 2: PRODUCCIÓN - Servir con nginx
# Imagen nginx:alpine es muy pequeña (~6MB) y serve archivos estáticos
# ============================================
FROM nginx:alpine AS production

# Copiar configuración nginx personalizada
# Esta configuración incluye:
# - Proxy reverso para /api/* hacia los backends
# - Headers de seguridad
# - Caché para assets estáticos
# - SPA routing (todas las rutas van a index.html)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copiar archivos estáticos del build (artefacto de la etapa builder)
COPY --from=builder /app/dist /usr/share/nginx/html

# Configurar permisos de forma segura
# nginx:nginx es el usuario por defecto de la imagen nginx:alpine
# Esto sigue el principio de mínimo privilegio
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid

# Cambiar a usuario no-root (nginx, no root)
# Esto es crítico para seguridad en producción
USER nginx

# Puerto que expose el contenedor (nginx escucha en 80)
EXPOSE 80

# Healthcheck para verificar que nginx está sirviendo contenido
# Usa wget que viene incluido en Alpine
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

# Ejecutar nginx en foreground (requerido para contenedores Docker)
# -g "daemon off;" evita que nginx se ejecute en segundo plano
CMD ["nginx", "-g", "daemon off;"]