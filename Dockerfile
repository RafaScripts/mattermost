# Mattermost ARM64-compatible image
# Uses the official Mattermost release tarball compiled natively for linux/arm64.
#
# Build args:
#   MATTERMOST_VERSION  – e.g. 10.11.8  (matches MATTERMOST_IMAGE_TAG in .env)
#   MATTERMOST_EDITION  – full edition name as in MATTERMOST_IMAGE env var
#                         e.g. "mattermost-team-edition" or "mattermost-enterprise-edition"
#
# Build command (run on the EasyPanel / ARM64 server, or via buildx on x86):
#   docker buildx build --platform linux/arm64 \
#     --build-arg MATTERMOST_VERSION=10.11.8 \
#     --build-arg MATTERMOST_EDITION=mattermost-team-edition \
#     -t mattermost-arm64:10.11.8 --load .

ARG MATTERMOST_VERSION=10.11.8
ARG MATTERMOST_EDITION=mattermost-team-edition

# ── Stage 1: download the official ARM64 release tarball ─────────────────────
FROM --platform=linux/arm64 alpine:3.19 AS downloader

ARG MATTERMOST_VERSION
ARG MATTERMOST_EDITION

RUN apk add --no-cache curl ca-certificates

WORKDIR /tmp

# Mattermost publishes linux-arm64 tarballs at releases.mattermost.com.
# The tarball name pattern is:  mattermost-<edition>-<version>-linux-arm64.tar.gz
# where <edition> is e.g. "team-edition" (extracted from MATTERMOST_EDITION below).
RUN EDITION_SLUG=$(echo "${MATTERMOST_EDITION}" | sed 's/^mattermost-//') \
 && curl -sSL \
    "https://releases.mattermost.com/${MATTERMOST_VERSION}/mattermost-${EDITION_SLUG}-${MATTERMOST_VERSION}-linux-arm64.tar.gz" \
    -o mattermost.tar.gz \
 && tar -xzf mattermost.tar.gz

# ── Stage 2: minimal runtime image ───────────────────────────────────────────
FROM --platform=linux/arm64 alpine:3.19

ARG MATTERMOST_VERSION
ARG MATTERMOST_EDITION

LABEL maintainer="mattermost" \
      org.opencontainers.image.version="${MATTERMOST_VERSION}" \
      org.opencontainers.image.title="Mattermost ${MATTERMOST_EDITION} (ARM64)" \
      org.opencontainers.image.source="https://github.com/mattermost/mattermost-server"

# Runtime dependencies
RUN apk add --no-cache \
      ca-certificates \
      curl \
      libc6-compat \
      libffi \
      tzdata \
 && addgroup -g 2000 mattermost \
 && adduser  -u 2000 -G mattermost -h /mattermost -D mattermost

COPY --from=downloader --chown=mattermost:mattermost /tmp/mattermost /mattermost

# Mattermost expects these directories to be writable
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

CMD ["/mattermost/bin/mattermost"]
