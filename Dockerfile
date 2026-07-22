# --- Etapa 1: instalar dependencias y correr las pruebas (fail fast) ---
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm test

# --- Etapa 2: imagen final, minima, solo lo necesario para ejecutar ---
FROM node:20-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production

# Variables de entorno por defecto (las puedes sobreescribir luego)
ENV APP_VERSION=v1
ENV APP_COLOR=blue

COPY package*.json ./
RUN npm ci --omit=dev

COPY --from=build /app/server.js ./server.js
COPY --from=build /app/db.js ./db.js
COPY --from=build /app/public ./public

# NUEVO: Creamos la carpeta data y le damos permisos al usuario node
RUN mkdir -p /app/data && chown -R node:node /app

USER node
EXPOSE 3000
HEALTHCHECK --interval=10s --timeout=3s CMD node -e "require('http').get('http://localhost:3000/health', r => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"
CMD ["node", "server.js"]