FROM node:18.19.1-alpine3.19
EXPOSE 8080
RUN addgroup -S robokart && adduser -S robokart -G robokart
WORKDIR /opt/server
ENV MONGO=true
RUN chown robokart:robokart /opt/server
USER robokart
COPY package.json /opt/server/
COPY server.js /opt/server/
RUN npm install
CMD ["node", "server.js"]