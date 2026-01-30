FROM eclipse-temurin:22-jre-jammy

# --- system deps ---
USER root

RUN apt-get update && \
    apt-get install -y \
      docker.io \
      curl \
      bash \
      ca-certificates \
      golang-go \
      python3 \
      python3-pip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# --- kestra dirs ---
RUN mkdir -p /app \
             /app/plugins \
             /app/flows \
             /app/storage \
             /app/conf

WORKDIR /app

# --- copy kestra binary ---
COPY kestra.jar .
RUN chmod +x kestra.jar

# --- copy plugins ---
COPY plugins plugins

# --- copy config (optional, can also mount) ---
COPY conf/application-prod.yaml conf/application.yaml

# --- run kestra ---
ENTRYPOINT ["java", "-jar", "/app/kestra.jar"]
CMD ["server", "standalone", "--config", "/app/conf/application.yaml", "-f", "/app/flows", "--plugins", "/app/plugins"]