FROM alpine:3.15 as base

RUN apk --no-cache add ca-certificates git curl bash

RUN mkdir -p /tmp
WORKDIR /tmp

# install chart-releaser
RUN curl -LO https://github.com/helm/chart-releaser/releases/download/v1.4.0/chart-releaser_1.4.0_linux_amd64.tar.gz && \
    tar -xvvf chart-releaser_1.4.0_linux_amd64.tar.gz && \
    mv cr /usr/local/bin/ && \
    rm -rf ./*

# install helm
RUN curl -LO https://get.helm.sh/helm-v3.9.0-linux-amd64.tar.gz && \
    tar -xvvf helm-v3.9.0-linux-amd64.tar.gz && \
    mv linux-amd64/helm /usr/local/bin/ && \
    rm -rf ./*

RUN mkdir -p /opt/nikkelma/helm-chart-builder/
WORKDIR /opt/nikkelma/helm-chart-builder/

---
FROM base as runner

COPY scripts/hcb.sh /usr/local/bin/hcb.sh

ENTRYPOINT ["hcb.sh"]

# ---
FROM base as tester

RUN apk --no-cache add yq make

RUN mkdir -p /opt/nikkelma/helm-chart-builder-test/tests/
WORKDIR /opt/nikkelma/helm-chart-builder-test/

COPY Makefile /opt/nikkelma/helm-chart-builder-test/
COPY tests /opt/nikkelma/helm-chart-builder-test/tests/

RUN make build-tests

ENTRYPOINT ["bash"]
