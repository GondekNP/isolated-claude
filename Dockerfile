FROM ubuntu:22.04

# Install essentials and Claude Code (without post-install scripts)
RUN apt-get update && apt-get install -y \
    curl git sudo ca-certificates nodejs npm \
    && npm config set ignore-scripts true \ 
    && npm install -g @anthropic/claude-code --no-optional \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -s /bin/bash user && \
    echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set up workspace
RUN mkdir -p /workspace && chown -R user:user /workspace

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Switch to non-root user
USER user
WORKDIR /workspace

# Run entrypoint to handle API key or OAuth path
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]