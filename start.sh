#!/bin/bash
# Startup script for Team Friendship Hour

set -e

echo "Team Friendship Hour - Starting..."
echo ""

# Check if Nushell is installed
if ! command -v nu &> /dev/null; then
    echo "Error: Nushell is not installed."
    echo "Please install Nushell from https://www.nushell.sh/"
    exit 1
fi

# Check if http-nu is installed
if ! command -v http-nu &> /dev/null; then
    echo "Warning: http-nu is not installed."
    echo "Please install http-nu: cargo install http-nu"
    echo ""
fi

# Create data directory if it doesn't exist
mkdir -p data

# Run tests first
echo "Running tests..."
cd tests
nu run_all_tests.nu
cd ..
echo ""

# Start the server
echo "Starting server on port 8080..."
echo "Visit http://localhost:8080 in your browser"
echo ""
cd src
nu server.nu --port 8080
