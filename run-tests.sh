#!/bin/sh
# Run tests from the repo root
# Nushell parses source/use at parse time, not runtime
# Solution: inline the module code directly

cd "$(dirname "$0")"

# Inline the models module and run tests
exec nu -c '
# ===== INLINED FROM src/data/models.nu =====
def create-team-member [name: string]: nothing -> record {
    {
        id: (random uuid)
        name: $name
        active: true
        added_date: (date now | format date "%Y-%m-%d")
    }
}

def create-activity [
    host_id: string
    activity_name: string
    date: string
    cycle_number: int
]: nothing -> record {
    {
        id: (random uuid)
        host_id: $host_id
        activity_name: $activity_name
        date: $date
        cycle_number: $cycle_number
    }
}

def create-cycle [cycle_number: int]: nothing -> record {
    {
        cycle_number: $cycle_number
        started_date: (date now | format date "%Y-%m-%d")
        completed_members: []
    }
}

def create-initial-state []: nothing -> record {
    {
        members: []
        activities: []
        current_cycle: (create-cycle 1)
    }
}
# ===== END INLINED MODULE =====

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
'
