#!/usr/bin/env bash
set -eo pipefail

check_tool_installed() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: $1 is not installed"
        exit 1
    fi
}

check_tool_installed "mkcert"

echo "Running development environment setup"
echo ""

cd server
mix setup

echo ""
echo "Setup complete!"
