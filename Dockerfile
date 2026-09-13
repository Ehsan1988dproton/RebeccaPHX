FROM node:18-alpine AS frontend-builder
WORKDIR /app/dashboard
COPY dashboard/package*.json ./
RUN npm ci
COPY dashboard/ ./
RUN VITE_BASE_API=/api/ npm run build -- --outDir=build --assetsDir=statics

FROM golang:1.22-alpine AS backend-builder
WORKDIR /app
COPY . .
COPY --from=frontend-builder /app/dashboard/build /app/dashboard/dashboard/build

RUN apk add --no-cache bash
RUN bash scripts/build_binary.sh

FROM alpine:latest
WORKDIR /opt/rebecca

RUN apk add --no-cache ca-certificates tzdata curl bash
RUN bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

COPY --from=backend-builder /app/dist/rebecca-server /opt/rebecca/rebecca-server
COPY --from=backend-builder /app/dist/rebecca-cli /opt/rebecca/rebecca-cli
COPY --from=backend-builder /app/.env.example /opt/rebecca/.env.example

COPY entrypoint.sh /opt/rebecca/entrypoint.sh
RUN chmod +x /opt/rebecca/entrypoint.sh

EXPOSE 8000
CMD ["./entrypoint.sh"]
