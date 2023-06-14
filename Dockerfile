FROM rust:1 AS chef
RUN cargo install cargo-chef
WORKDIR hdrcopier

FROM chef as planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef as builder
COPY --from=planner /hdrcopier/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json
COPY . .
RUN cargo build --all-features --release --bin hdrcopier

FROM debian:12-slim as runtime
RUN apt-get update \
 && apt-get -y install --no-install-recommends \
        mkvtoolnix \
        mediainfo  \
        ffmpeg \
 && rm -rf /var/lib/apt/lists/*
WORKDIR hdrcopier
COPY --from=builder /hdrcopier/target/release/hdrcopier /usr/local/bin
ENTRYPOINT [ "/usr/local/bin/hdrcopier" ]
