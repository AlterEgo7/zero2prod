# syntax=docker/dockerfile:1.4-labs
FROM rust:1.69.0-slim-bookworm

WORKDIR /app

RUN apt update && apt install libssl-dev pkg-config mold clang openssl -y

RUN mkdir -p "$HOME/.cargo"

COPY <<EOF $HOME/.cargo/config.toml
[target.x86_64-unknown-linux-gnu]
linker = "/usr/bin/clang"
rustflags = ["-C", "link-arg=--ld-path=/usr/bin/mold"]
EOF

COPY . .

ENV SQLX_OFFLINE true
RUN cargo build --release

ENTRYPOINT ["./target/release/zero2prod"]