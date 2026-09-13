# --- مرحله ۱: بیلد دشبورد (React) ---
FROM node:18-alpine AS frontend-builder
WORKDIR /app/dashboard
COPY dashboard/package*.json ./
RUN npm ci
COPY dashboard/ ./
RUN VITE_BASE_API=/api/ npm run build -- --outDir=build --assetsDir=statics

# --- مرحله ۲: بیلد بک‌اند (Go) ---
FROM golang:1.22-alpine AS backend-builder
WORKDIR /app
COPY . .
# اصلاح مسیر کپی فایل‌های بیلد شده دشبورد به پوشه صحیح
COPY --from=frontend-builder /app/dashboard/build /app/dashboard/build

RUN apk add --no-cache bash
RUN bash scripts/build_binary.sh

# --- مرحله ۳: محیط نهایی اجرا (Runtime) ---
FROM alpine:latest
WORKDIR /opt/rebecca

# نصب ابزارهای شبکه، ابزار unzip و پکیج‌های ضروری
RUN apk add --no-cache ca-certificates tzdata curl bash unzip

# دانلود و استخراج مستقیم هسته Xray (بدون نیاز به systemd)
RUN mkdir -p /usr/local/share/xray && \
    curl -L -o /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip /tmp/xray.zip -d /tmp/xray/ && \
    mv /tmp/xray/xray /usr/local/bin/xray && \
    mv /tmp/xray/*.dat /usr/local/share/xray/ && \
    rm -rf /tmp/xray.zip /tmp/xray

# انتقال فایل‌های کامپایل شده سرور
COPY --from=backend-builder /app/dist/rebecca-server /opt/rebecca/rebecca-server
COPY --from=backend-builder /app/dist/rebecca-cli /opt/rebecca/rebecca-cli
COPY --from=backend-builder /app/.env.example /opt/rebecca/.env.example

# انتقال و تنظیم اسکریپت استارت‌آپ
COPY entrypoint.sh /opt/rebecca/entrypoint.sh
RUN chmod +x /opt/rebecca/entrypoint.sh

# پورت داخلی پیش‌فرض
EXPOSE 8000

# اجرا از طریق اسکریپت entrypoint
CMD ["./entrypoint.sh"]
