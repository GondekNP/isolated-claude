FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# Install essentials
RUN apt-get update && apt-get install -y \
    curl git sudo ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code via the native installer (no Node.js / npm required)
RUN curl -fsSL https://claude.ai/install.sh | bash

# Make the native install location available on PATH
ENV PATH="/root/.local/bin:${PATH}"

# Set up workspace
RUN mkdir -p /workspace

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Run entrypoint to handle API key or OAuth path
WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]