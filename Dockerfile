# Mattermost ARM64-compatible image
# Build natively from official Mattermost release tarballs for linux/arm64.

ARG MATTERMOST_VERSION=10.11.8
ARG MATTERMOST_EDITION=mattermost-team-edition

# ── Stage 1: downloader ──────────────────────────────────────────────────────
FROM --platform=linux/arm64 alpine:3.19 AS downloader

ARG MATTERMOST_VERSION
ARG MATTERMOST_EDITION

RUN apk add --no-cache curl ca-certificates

WORKDIR /tmp

# Map edition to URL slug:
# mattermost-team-edition -> mattermost-team-<version>-linux-arm64.tar.gz
# mattermost-enterprise-edition -> mattermost-<version>-linux-arm64.tar.gz
RUN if [ "$MATTERMOST_EDITION" = "mattermost-team-edition" ]; then \
      URL="https://releases.mattermost.com/${MATTERMOST_VERSION}/mattermost-team-${MATTERMOST_VERSION}-linux-arm64.tar.gz"; \
    else \
      URL="https://releases.mattermost.com/${MATTERMOST_VERSION}/mattermost-${MATTERMOST_VERSION}-linux-arm64.tar.gz"; \
    fi && \
    curl -sSL "$URL" -o mattermost.tar.gz && \
    tar -xzf mattermost.tar.gz

# ── Stage 2: runtime ──────────────────────────────────────────────────────────
FROM --platform=linux/arm64 alpine:3.19

ARG MATTERMOST_VERSION
ARG MATTERMOST_EDITION

LABEL maintainer="mattermost" \
      org.opencontainers.image.version="${MATTERMOST_VERSION}" \
      org.opencontainers.image.title="Mattermost ${MATTERMOST_EDITION} (ARM64)" \
      org.opencontainers.image.source="https://github.com/mattermost/mattermost-server"

# Install runtime dependencies
RUN apk add --no-cache \
      ca-certificates \
      curl \
      libc6-compat \
      libffi \
      tzdata \
 && addgroup -g 2000 mattermost \
 && adduser  -u 2000 -G mattermost -h /mattermost -D mattermost

COPY --from=downloader --chown=mattermost:mattermost /tmp/mattermost /mattermost

# Ensure required directories exist and have correct permissions
RUN mkdir -p \
      /mattermost/config \
      /mattermost/data \
      /mattermost/logs \
      /mattermost/plugins \
      /mattermost/client/plugins \
      /mattermost/bleve-indexes \
 && chown -R mattermost:mattermost /mattermost

USER mattermost
WORKDIR /mattermost

EXPOSE 8065 8067 8074 8075

# Mattermost binary location
CMD ["/mattermost/bin/mattermost"]
