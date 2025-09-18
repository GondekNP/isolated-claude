#!/bin/bash
# Isolated Claude Code - Run Claude Code in Docker with filesystem isolation

# Get the directory where this script is located (the git repo)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments - if first arg isn't a flag, treat it as directory
if [ -z "$1" ] || [[ "$1" == -* ]]; then
    TARGET_DIR=$(pwd)
else
    TARGET_DIR=$(realpath "$1")
    shift
fi

# Validate directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ Error: Directory '$TARGET_DIR' does not exist"
    exit 1
fi

# Confirm with user
echo "⚠️  You're about to give claude-code access to the '$TARGET_DIR' directory."
read -p "Proceed? (y/n): " confirm
if [[ ! "$confirm" =~ ^[Yy] ]]; then
    echo "Cancelled."
    exit 1
fi

# Build image if it doesn't exist
if ! docker images | grep -q "claude-isolated"; then
    echo "Building Docker image..."
    docker build -t claude-isolated "$REPO_DIR"
fi

echo ""
echo "🔒 Running Isolated Claude Code"
echo "📁 Access restricted to: $TARGET_DIR"
echo ""

# Run container with isolation - 
# -it: interactive terminal
# --rm: remove container after exit
# --name: container name
# -v: mount target directory to /workspace in container
# -e: pass through ANTHROPIC_API_KEY if set
# --security-opt no-new-privileges:true: prevent privilege escalation
# --cap-drop=ALL: drop all capabilities
# --cap-add=CHOWN,DAC_OVERRIDE,SETUID,SETGID: add only necessary capabilities
# claude-isolated: use the built image
# "$@": pass through any additional arguments to claude-code 

docker run -it --rm \
    --name claude-code-isolated \
    -v "$TARGET_DIR:/workspace" \
    -e ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}" \
    --security-opt no-new-privileges:true \
    --cap-drop=ALL \
    --cap-add=CHOWN \
    --cap-add=DAC_OVERRIDE \
    --cap-add=SETUID \
    --cap-add=SETGID \
    claude-isolated "$@"