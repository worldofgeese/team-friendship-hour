#!/usr/bin/env nu
# Test runner - must be run from repo root
# Usage: nu run-tests.nu

# Source the modules directly using relative paths from repo root
source src/data/models.nu

use std assert

print "Running model tests..."

# Test: create-team-member
let member = create-team-member "Alice"
assert ($member.name == "Alice")
assert ($member.active == true)
assert ($member.id | is-not-empty)
print "✓ test_create_team_member passed"

# Test: create-activity
let activity = create-activity "host-123" "Bowling" "2026-02-15" 1
assert ($activity.host_id == "host-123")
assert ($activity.activity_name == "Bowling")
assert ($activity.date == "2026-02-15")
assert ($activity.cycle_number == 1)
print "✓ test_create_activity passed"

# Test: create-cycle
let cycle = create-cycle 5
assert ($cycle.cycle_number == 5)
assert ($cycle.started_date | is-not-empty)
assert ($cycle.completed_members | is-empty)
print "✓ test_create_cycle passed"

# Test: create-initial-state
let state = create-initial-state
assert ($state.members | is-empty)
assert ($state.activities | is-empty)
assert ($state.current_cycle.cycle_number == 1)
print "✓ test_create_initial_state passed"

print "All model tests passed! ✓"
