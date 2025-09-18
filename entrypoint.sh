#!/bin/bash
# Docker entrypoint for Claude Code with auth handling

set -e

# Check for API key
if [ -n "$ANTHROPIC_API_KEY" ]; then
    echo "Using API key authentication..."
    export ANTHROPIC_API_KEY
fi

exec claude "$@"