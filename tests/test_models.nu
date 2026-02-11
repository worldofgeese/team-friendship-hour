# Unit tests for data models
# Following HtDD design recipe: Signature, Purpose, Examples, Template, Implementation

use src/data/models.nu *
use std assert

# Test: create-team-member
# Purpose: Verify that create-team-member creates a valid team member record
export def test_create_team_member [] {
    let member = create-team-member "Alice"

    assert ($member.name == "Alice")
    assert ($member.active == true)
    assert ($member.id | is-not-empty)
    assert ($member.added_date | is-not-empty)

    print "✓ test_create_team_member passed"
}

# Test: create-activity
# Purpose: Verify that create-activity creates a valid activity record
export def test_create_activity [] {
    let activity = create-activity "host-123" "Bowling" "2026-02-15" 1

    assert ($activity.host_id == "host-123")
    assert ($activity.activity_name == "Bowling")
    assert ($activity.date == "2026-02-15")
    assert ($activity.cycle_number == 1)
    assert ($activity.id | is-not-empty)

    print "✓ test_create_activity passed"
}

# Test: create-cycle
# Purpose: Verify that create-cycle creates a valid cycle record
export def test_create_cycle [] {
    let cycle = create-cycle 5

    assert ($cycle.cycle_number == 5)
    assert ($cycle.started_date | is-not-empty)
    assert ($cycle.completed_members | is-empty)

    print "✓ test_create_cycle passed"
}

# Test: create-initial-state
# Purpose: Verify that create-initial-state creates a valid initial state
export def test_create_initial_state [] {
    let state = create-initial-state

    assert ($state.members | is-empty)
    assert ($state.activities | is-empty)
    assert ($state.current_cycle.cycle_number == 1)
    assert ($state.current_cycle.completed_members | is-empty)

    print "✓ test_create_initial_state passed"
}

# Run all model tests
export def main [] {
    print "Running model tests..."
    test_create_team_member
    test_create_activity
    test_create_cycle
    test_create_initial_state
    print "All model tests passed! ✓"
}
