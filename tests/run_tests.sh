#!/bin/sh
# Run all tests for Team Friendship Hour
# This wrapper script ensures the include path is set correctly

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "========================================"
echo "Team Friendship Hour - Test Suite"
echo "========================================"
echo ""

cd "$PROJECT_ROOT"

echo "Running model tests..."
nu -I "$PROJECT_ROOT" tests/test_models.nu

echo ""
echo "Running store tests..."
nu -I "$PROJECT_ROOT" tests/test_store.nu

echo ""
echo "========================================"
echo "All tests passed successfully! ✓"
echo "========================================"
