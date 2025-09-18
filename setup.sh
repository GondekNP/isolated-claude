#!/bin/bash
# Setup script for Isolated Claude Code

set -e

echo "🎲 Setting up Isolated Claude Code"
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
echo ""
docker build -t claude-isolated "$REPO_DIR" --no-cache

echo "✅ Docker image built successfully!"
echo ""

# Detect shell config file
if [ -n "$BASH_VERSION" ]; then
    SHELL_RC="$HOME/.bashrc"
    SHELL_NAME="bash"
elif [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.zshrc"
    SHELL_NAME="zsh"
else
    echo "❌ Unsupported shell. Please use bash or zsh."
    exit 1
fi

# Ask about adding to PATH
echo "📝 Would you like to add 'icc' command to your $SHELL_NAME configuration?"
echo "This will add the following to $SHELL_RC:"
echo ""
echo "    export PATH=\"$REPO_DIR:\$PATH\""
echo "    alias icc='isolated_claude_code.sh'"
echo ""
read -p "Add to $SHELL_RC? (y/n): " add_to_rc

if [[ "$add_to_rc" =~ ^[Yy] ]]; then
    # Check if already added
    if grep -q "isolated_claude_code.sh" "$SHELL_RC" 2>/dev/null; then
        echo "✅ Already configured in $SHELL_RC"
    else
        echo "" >> "$SHELL_RC"
        echo "# Isolated Claude Code (icc)" >> "$SHELL_RC"
        echo "export PATH=\"$REPO_DIR:\$PATH\"" >> "$SHELL_RC"
        echo "alias icc='isolated-claude-code.sh'" >> "$SHELL_RC"
        echo "" >> "$SHELL_RC"  

        echo ""
        echo "✅ Added to $SHELL_RC"
        echo "    "
        echo "    To start using 'icc', either:"
        echo "      - Run: source $SHELL_RC"
        echo "      - Open a new terminal"
    fi

    echo ""
    echo "✅ Setup complete!"
    echo "    "
    echo "    Usage examples:"
    echo "        icc                    # Use current directory"
    echo "        icc /path/to/project   # Use specific directory"
    echo "        icc --help             # Show Claude Code help"
    echo "    "


else

    echo "    "
    echo "    To manually add 'icc' later, add this to your $SHELL_RC:"
    echo "    "
    echo "        export PATH=\"$REPO_DIR:\$PATH\""
    echo "        alias icc='isolated_claude_code.sh'"
    echo "    "
    echo "    You can always run it directly via:"
    echo "        $REPO_DIR/isolated_claude_code.sh <directory>"
    echo "    "

    echo "✅ Setup complete!"
    echo "    "
    echo "    Usage examples:"
    echo "        $REPO_DIR/isolated_claude_code.sh          # Use current directory"
    echo "        $REPO_DIR/isolated_claude_code.sh /path/to/project   # Use specific directory"
    echo "        $REPO_DIR/isolated_claude_code.sh --help             # Show Claude Code help"
    echo "    "

fi