# Etapa de construccin (Builder)
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production --legacy-peer-deps

# Etapa de produccin
FROM node:20-alpine
ENV TZ=America/Bogota
ENV NODE_ENV=production
WORKDIR /app

# Copiar de builder a prod (cuidado con los permisos)
COPY --from=builder --chown=node:node /app/node_modules ./node_modules
COPY --chown=node:node . .

# Usar el usuario sin privilegios que provee la imagen node
USER node

EXPOSE 8080
CMD ["node", "index.js"]
