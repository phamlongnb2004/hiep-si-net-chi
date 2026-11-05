# Hugging Face Space: tải mã game từ GitHub rồi chạy máy chủ online.
# Muốn cập nhật bản mới từ GitHub: Settings → Factory rebuild.
FROM node:20-slim
RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
RUN git clone --depth 1 https://github.com/phamlongnb2004/hiep-si-net-chi.git . \
 && npm install --omit=dev \
 && node tools/build-client.js \
 && mkdir -p /app/data && chown -R 1000:1000 /app/data
USER 1000
ENV PORT=7860 DATA_FILE=/app/data/db.json
EXPOSE 7860
CMD ["node", "server/index.js"]
