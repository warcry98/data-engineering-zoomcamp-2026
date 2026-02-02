FROM ubuntu:24.04

WORKDIR /app

RUN apt-get update && apt-get install -y \
    ca-certificates \ 
    golang-go \ 
    build-essential \ 
    curl \ 
    libssl3 \
    python3 \ 
    python3-pip \ 
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:$PATH"
RUN rustup update

# Download the latest installer
ADD https://astral.sh/uv/install.sh /uv-installer.sh

# Run the installer then remove it
RUN sh /uv-installer.sh && rm /uv-installer.sh

ENV PATH="/root/.local/bin/:$PATH"

# Sanity check (fail build if missing)
RUN uv --version

COPY windmill-amd64 /app/windmill
RUN chmod +x /app/windmill

EXPOSE 8000
VOLUME ["/data"]

ENTRYPOINT ["/app/windmill"]