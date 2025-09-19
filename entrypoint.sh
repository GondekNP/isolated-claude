#!/bin/bash
# Docker entrypoint for Claude Code with auth handling

set -e

# Update Claude Code to latest version
echo "🔄 Updating Claude Code to latest version..."
npm update -g @anthropic-ai/claude-code

# Check for API key
if [ -n "$ANTHROPIC_API_KEY" ]; then
    echo "Using API key authentication..."
    export ANTHROPIC_API_KEY
fi

exec claude "$@"