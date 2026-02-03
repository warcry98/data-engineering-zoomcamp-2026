FROM ubuntu:24.04

WORKDIR /app

RUN apt-get update && apt-get install -y \
    ca-certificates \ 
    golang-go \ 
    build-essential \ 
    postgresql-client \
    openjdk-21-jdk \
    unzip \
    curl \ 
    libssl3 \
    python3 \ 
    python3-pip \ 
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fL \
    https://github.com/coursier/coursier/releases/download/v2.1.24/cs-x86_64-pc-linux-container.gz \
    | gzip -d > coursier \
    && chmod +x coursier \
    && ./coursier setup -y --install-dir=/usr/bin

RUN coursier --version

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:$PATH"
RUN rustup update

# Download the latest installer
ADD https://astral.sh/uv/install.sh /uv-installer.sh

# Run the installer then remove it
RUN curl -Ls https://astral.sh/uv/install.sh | \
    UV_INSTALL_DIR=/usr/local/bin sh

# Sanity check (fail build if missing)
RUN uv --version

RUN curl -fsSL https://bun.com/install | bash
ENV PATH="/root/.bun/bin:$PATH"
RUN bun --version

RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
RUN apt-get install -y nodejs
RUN node -v

RUN npm install -g windmill-cli

COPY windmill-amd64 /app/windmill
RUN chmod +x /app/windmill

ENV WMILL_UV_PATH=/usr/local/bin/uv

# COPY scripts ./scripts
# COPY flows ./flows
# COPY wmill.yaml ./wmill.yaml
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8000
VOLUME ["/data"]

ENTRYPOINT ["/entrypoint.sh"]