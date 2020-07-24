#
#
#

FROM 2075/builder:local as builder
LABEL maintainer "marco@one.io"

WORKDIR /builder
COPY . /builder

RUN $HOME/.cargo/bin/cargo build --release --bin node-template-archive && \
    $HOME/.cargo/bin/cargo build --release --bin polkadot-archive && \
    mkdir -p /builder/bin && \
    mv ./target/release/node-template-archive /builder/bin/substrate-archive && \
    mv ./target/release/polkadot-archive /builder/bin/polkadot-archive

#
#
#

FROM phusion/baseimage:latest-amd64
LABEL maintainer "marco@one.io"
LABEL description="substrate archive"

COPY --from=builder /builder/bin/*-archive /usr/local/bin/

RUN mv /usr/share/ca* /tmp && \
    rm -rf /usr/share/*  && \
    mv /tmp/ca-certificates /usr/share/ && \
    rm -rf /usr/lib/python* && \
    useradd -m -u 1000 -U -s /bin/sh -d /archive archive && \
    rm -rf /usr/bin /usr/sbin

USER archive
EXPOSE 30333 9933 9944
VOLUME ["/data"]

# ENTRYPOINT ["/usr/local/bin/substrate-archive"]
