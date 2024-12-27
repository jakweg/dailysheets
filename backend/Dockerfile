FROM node:23
WORKDIR /app
COPY package*.json ./
RUN npm i --registry=https://registry.npmjs.org/
COPY src src/
COPY account.key.json account.key.json
CMD node src/main.js