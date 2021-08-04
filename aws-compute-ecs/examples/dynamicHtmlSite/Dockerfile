# This file is a pre-cooked sample for the Docker session

FROM alpine:latest

RUN apk add --update nodejs npm

RUN mkdir -p /app
COPY ./app/* /app
RUN cd /app && npm install

EXPOSE 8080

ENTRYPOINT ["node", "/app/server.js"]
