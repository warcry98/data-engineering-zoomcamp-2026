FROM ubuntu:24.04

WORKDIR /app

RUN apt-get update && apt-get install -y \
    ca-certificates golang-go build-essential curl \
    && rm -rf /var/lib/apt/lists/*

RUN curl --proto '=https' --tlsv1.3 https://sh.rustup.rs -sSf | sh

RUN source "$HOME/.cargo/env"
RUN rustup update

COPY windmill-amd64 /app/windmill
RUN chmod +x /app/windmill

EXPOSE 8000
VOLUME ["/data"]

ENTRYPOINT ["/app/windmill"]