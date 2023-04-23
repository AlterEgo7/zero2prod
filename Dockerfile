# syntax=docker/dockerfile:1.4-labs
FROM lukemathwalker/cargo-chef:latest-rust-1.69-bookworm as chef

WORKDIR /app

RUN apt update && apt install mold clang -y

FROM chef as planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef as builder

COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json

RUN mkdir -p "$HOME/.cargo"

COPY <<EOF $HOME/.cargo/config.toml
[target.x86_64-unknown-linux-gnu]
linker = "/usr/bin/clang"
rustflags = ["-C", "link-arg=--ld-path=/usr/bin/mold"]
EOF

COPY . .

ENV SQLX_OFFLINE true
RUN cargo build --release --bin zero2prod

FROM debian:bookworm-slim AS runtime

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends openssl ca-certificates && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/target/release/zero2prod zero2prod
COPY configuration configuration
ENV APP_ENVIRONMENT production

ENTRYPOINT ["./zero2prod"]