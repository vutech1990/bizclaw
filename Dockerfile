# Rust Production Dockerfile
FROM rust:1.83-slim AS builder
WORKDIR /app

RUN apt-get update && apt-get install -y pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*

COPY . .
RUN cargo build --release

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app

COPY --from=builder /app/target/release/ /tmp/build/
RUN find /tmp/build -maxdepth 1 -type f -executable ! -name ".*" ! -name "*.d" | head -1 | xargs -I{} cp {} ./server && rm -rf /tmp/build

EXPOSE 8080
CMD ["./server"]