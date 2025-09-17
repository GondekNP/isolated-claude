#!/bin/bash
# Setup script for Isolated Claude Code

set -e

echo "🚀 Setting up Isolated Claude Code"
echo ""

# Check Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first:"
    echo "   https://docs.docker.com/get-docker/"
    exit 1
fi

# Get repo directory
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Build the Docker image
echo "📦 Building Docker image..."
docker build -t claude-isolated "$REPO_DIR"

echo ""
echo "✅ Setup complete!"
echo ""
echo "To use 'icc' from anywhere, add this to your ~/.bashrc or ~/.zshrc:"
echo ""
echo "    export PATH=\"$REPO_DIR:\$PATH\""
echo "    alias icc='isolated_claude_code.sh'"
echo ""
echo "Then reload your shell:"
echo "    source ~/.bashrc  # or ~/.zshrc"
echo ""
echo "Usage examples:"
echo "    icc                    # Use current directory"
echo "    icc /path/to/project   # Use specific directory"
echo "    icc --help             # Show Claude Code help"
echo ""
echo "To use with API key:"
echo "    export ANTHROPIC_API_KEY=sk-ant-..."
echo "    icc"