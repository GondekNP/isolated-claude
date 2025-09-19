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

# Generate unique container name based on directory name and path hash
# Extract the folder name and create a short hash for uniqueness
FOLDER_NAME=$(basename "$TARGET_DIR")
# Sanitize folder name for Docker (replace spaces and special chars with dash)
SAFE_FOLDER_NAME=$(echo "$FOLDER_NAME" | sed 's/[^a-zA-Z0-9_.-]/-/g' | tr '[:upper:]' '[:lower:]')

# Create a short hash of the full path for uniqueness
if command -v md5sum &> /dev/null; then
    DIR_HASH=$(echo -n "$TARGET_DIR" | md5sum | cut -c1-6)
elif command -v md5 &> /dev/null; then
    DIR_HASH=$(echo -n "$TARGET_DIR" | md5 -q | cut -c1-6)
else
    # Fallback: use timestamp if no md5 available
    DIR_HASH="$(date +%s)"
fi

CONTAINER_NAME="claude-code-${SAFE_FOLDER_NAME}-${DIR_HASH}"
echo "🏷️  Container name: $CONTAINER_NAME"

# Run container with isolation -
# -it: interactive terminal
# --rm: remove container after exit
# --name: container name (now unique per directory with meaningful name)
# -v: mount target directory to /workspace in container
# -e: pass through ANTHROPIC_API_KEY if set
# --security-opt no-new-privileges:true: prevent privilege escalation
# --cap-drop=ALL: drop all capabilities
# --cap-add=CHOWN,DAC_OVERRIDE,SETUID,SETGID: add only necessary capabilities
# claude-isolated: use the built image
# "$@": pass through any additional arguments to claude-code

docker run -it --rm \
    --name "$CONTAINER_NAME" \
    -v "$TARGET_DIR:/workspace" \
    -e ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}" \
    --security-opt no-new-privileges:true \
    --cap-drop=ALL \
    --cap-add=CHOWN \
    --cap-add=DAC_OVERRIDE \
    --cap-add=SETUID \
    --cap-add=SETGID \
    claude-isolated "$@"