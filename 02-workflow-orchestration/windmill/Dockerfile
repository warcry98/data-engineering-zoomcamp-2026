FROM debian:bookworm-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY windmill-amd64 /app/windmill
RUN chmod +x /app/windmill

EXPOSE 8000
VOLUME ["/data"]

ENTRYPOINT ["/app/windmill"]