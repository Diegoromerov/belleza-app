FROM node:20-alpine

# Configurar Zona Horaria de Colombia globalmente en el contenedor
ENV TZ=America/Bogota

WORKDIR /app

COPY package*.json ./

RUN npm install --only=production --legacy-peer-deps

COPY . .

EXPOSE 8080

CMD ["node", "index.js"]
