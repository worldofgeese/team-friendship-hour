#!/usr/bin/env nu
# Run all tests for Team Friendship Hour
# Run from project root with: nu -I "$(pwd)" tests/run_all_tests.nu

use tests/test_models.nu
use tests/test_store.nu

def main [] {
    print "========================================"
    print "Team Friendship Hour - Test Suite"
    print "========================================"
    print ""

    try {
        test_models
        print ""
        test_store
        print ""
        print "========================================"
        print "All tests passed successfully! ✓"
        print "========================================"
    } catch { |err|
        print $"Test failed: ($err)"
        exit 1
    }
}

main
