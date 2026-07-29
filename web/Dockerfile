FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:22-alpine
WORKDIR /app
ENV NODE_ENV=production PORT=3025 DATA_FILE=/data/tracker.json
COPY --from=build /app/dist ./dist
COPY server ./server
COPY package.json ./
RUN mkdir -p /data && chown -R node:node /data
USER node
VOLUME ["/data"]
EXPOSE 3025
CMD ["node", "server/index.js"]
