FROM mcr.microsoft.com/devcontainers/ruby:2.7-bullseye

# Install icu4c and other dependencies needed for charlock_holmes
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    libicu-dev \
    cmake \
    pkg-config \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Set environment variables for gem compilation
ENV PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig
