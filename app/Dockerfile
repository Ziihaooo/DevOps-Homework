# ---------- Build Stage ----------
FROM node:lts-alpine3.22 AS builder
WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY . .

# ---------- Runtime Stage ----------
FROM node:lts-alpine3.22 AS production
RUN adduser -D appuser

WORKDIR /app

COPY --from=builder /app .
USER appuser

EXPOSE 3000
CMD ["npm","start"]