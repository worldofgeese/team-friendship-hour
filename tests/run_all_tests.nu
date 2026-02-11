# Run all tests for Team Friendship Hour

use test_models.nu
use test_store.nu

def main [] {
    print "========================================"
    print "Team Friendship Hour - Test Suite"
    print "========================================"
    print ""

    try {
        test_models main
        print ""
        test_store main
        print ""
        print "========================================"
        print "All tests passed successfully! ✓"
        print "========================================"
    } catch { |err|
        print $"Test failed: ($err)"
        exit 1
    }
}
