#!/bin/bash
# Isolated Claude Code - Run Claude Code in Docker with filesystem isolation

# Get the directory where this script is located (the git repo)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
UPDATE_MODE=false
FRESH_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --update)
            UPDATE_MODE=true
            shift
            ;;
        --fresh)
            FRESH_MODE=true
            shift
            ;;
        -*)
            # Keep other flags for claude-code
            break
            ;;
        *)
            # First non-flag argument is the directory
            if [ -z "$TARGET_DIR" ]; then
                TARGET_DIR=$(realpath "$1")
                shift
            else
                # Rest are arguments for claude-code
                break
            fi
            ;;
    esac
done

# Default to current directory if no directory specified
if [ -z "$TARGET_DIR" ]; then
    TARGET_DIR=$(pwd)
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

# Handle update mode
if [ "$UPDATE_MODE" = true ]; then
    echo "🔄 Updating Claude Code..."

    # Create temporary container to update
    TEMP_CONTAINER="claude-update-temp-$$"
    docker run -d --name "$TEMP_CONTAINER" claude-isolated sleep 300

    # Run update inside container
    docker exec "$TEMP_CONTAINER" npm update -g @anthropic-ai/claude-code

    # Commit the updated container as new base image
    docker commit "$TEMP_CONTAINER" claude-isolated

    # Clean up temporary container
    docker rm -f "$TEMP_CONTAINER"

    echo "✅ Claude Code updated successfully!"
    exit 0
fi

# Handle fresh mode - remove existing container if it exists
if [ "$FRESH_MODE" = true ]; then
    if docker ps -aq -f name="$CONTAINER_NAME" | grep -q .; then
        echo "🗑️  Removing existing container for fresh start..."
        docker rm -f "$CONTAINER_NAME"
    fi
fi

# Check if container already exists
if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
    # Container is running, attach to it
    echo "📦 Attaching to running container..."
    docker attach "$CONTAINER_NAME"
elif docker ps -aq -f name="$CONTAINER_NAME" | grep -q .; then
    # Container exists but is stopped, restart it
    echo "🔄 Restarting existing container..."
    docker start -ai "$CONTAINER_NAME"
else
    # Create new container (without --rm for persistence)
    echo "🆕 Creating new container..."
    docker run -it \
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
fi