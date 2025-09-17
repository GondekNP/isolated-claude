#!/bin/bash
# Docker entrypoint for Claude Code with auth handling

set -e

# Check for API key, otherwise use OAuth
if [ -n "$ANTHROPIC_API_KEY" ]; then
    echo "Using API key authentication..."
    export ANTHROPIC_API_KEY
else
    echo "No API key found, using OAuth authentication..."
    claude-code auth login
fi

# Execute claude-code with any passed arguments
exec claude-code "$@"