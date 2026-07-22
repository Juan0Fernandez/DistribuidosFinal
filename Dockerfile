# --- ETAPA 1: Construcción y Pruebas (Builder) ---
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
# Instalamos todas las dependencias (incluyendo las de desarrollo para los tests)
RUN npm ci
COPY . .
# La rúbrica exige que si esto falla, la imagen no se construya
RUN npm test

# --- ETAPA 2: Producción (Imagen final) ---
FROM node:20-alpine AS production
WORKDIR /app
COPY package*.json ./
# Instalamos solo dependencias de producción para que la imagen sea más ligera
RUN npm ci --omit=dev

# Copiamos solo los archivos necesarios desde la etapa builder
COPY --from=builder /app/server.js ./
COPY --from=builder /app/db.js ./
COPY --from=builder /app/public ./public

# Replicamos la corrección de permisos que hiciste antes para que no falle la DB
RUN mkdir -p /app/data && chown -R node:node /app

USER node
EXPOSE 3000

CMD ["node", "server.js"]