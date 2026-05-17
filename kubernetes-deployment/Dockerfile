FROM node:20-alpine

WORKDIR /app

COPY app/package.json ./
RUN npm install --omit=dev

COPY app/server.js ./

ENV PORT=3000
ENV DATA_DIR=/data

EXPOSE 3000

USER node

CMD ["npm", "start"]
