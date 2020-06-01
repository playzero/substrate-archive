#
#
#

FROM phusion/baseimage:latest-amd64 as builder
LABEL maintainer "marco@one.io"

ARG PROFILE=release

WORKDIR /builder
COPY . /builder

## base system
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y curl cmake pkg-config libssl-dev git gcc build-essential clang libclang-dev && \
    curl https://sh.rustup.rs -sSf | sh -s -- -y && \
    export PATH=$PATH:$HOME/.cargo/bin && \
    rustup update nightly && \
    rustup update stable && \
    rustup target add wasm32-unknown-unknown --toolchain nightly

## setup toolchain + build
RUN $HOME/.cargo/bin/cargo build --$PROFILE

#
#
#

FROM phusion/baseimage:latest-amd64
LABEL maintainer "marco@one.io"
LABEL description="substrate archive"

ARG PROFILE=release

COPY --from=builder /builder/target/$PROFILE/kusama-archive /usr/local/bin/subgraph
COPY --from=builder /builder/config /config

RUN mv /usr/share/ca* /tmp && \
    rm -rf /usr/share/*  && \
    mv /tmp/ca-certificates /usr/share/ && \
    rm -rf /usr/lib/python* && \
    useradd -m -u 1000 -U -s /bin/sh -d /subgraph subgraph && \
    mkdir -p /subgraph/.local/share/subgraph && \
    mv /config /subgraph/config && \
    chown -R subgraph:subgraph /subgraph/config && \
    chown -R subgraph:subgraph /subgraph/.local && \
    ln -s /subgraph/.local/share/subgraph /data && \
    rm -rf /usr/bin /usr/sbin

USER subgraph
EXPOSE 30333 9933 9944
VOLUME ["/data"]

ENTRYPOINT ["/usr/local/bin/subgraph"]
