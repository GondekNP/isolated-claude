FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# Install essentials and Claude Code (without post-install scripts)
RUN apt-get update && apt-get install -y \
    curl git sudo ca-certificates 
    
# Install Node.js 18.x (LTS) from NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - \
    && apt-get install -y nodejs

# Install Claude Code globally, disabling post-install scripts
RUN npm config set ignore-scripts true \ 
    && npm install -g @anthropic-ai/claude-code --no-optional \
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