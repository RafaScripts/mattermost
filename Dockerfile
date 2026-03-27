# Mattermost ARM64-compatible image
#
# Strategy: re-tag the official Mattermost multi-arch image.
# The official Docker Hub image already ships a linux/arm64 variant.
# Building with --platform linux/arm64 makes buildx select the ARM64 layer.
#
# Build args:
#   MATTERMOST_VERSION  – e.g. 10.11.8  (matches MATTERMOST_IMAGE_TAG in .env)
#   MATTERMOST_EDITION  – full image name, e.g. mattermost-team-edition
#                         or mattermost-enterprise-edition

ARG MATTERMOST_VERSION=10.11.8
ARG MATTERMOST_EDITION=mattermost-team-edition

# Use the official image directly — buildx will pick the linux/arm64 layer.
# No tarball download needed; Mattermost's Docker image is already multi-arch.
FROM mattermost/${MATTERMOST_EDITION}:${MATTERMOST_VERSION}
