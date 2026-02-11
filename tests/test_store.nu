# Unit tests for data store
# Following HtDF design recipe: Signature, Purpose, Examples, Template, Implementation

use ../src/data/store.nu *
use ../src/data/models.nu *
use std assert

# Test: add-member
# Purpose: Verify that add-member adds a new member to the state
export def test_add_member [] {
    let state = create-initial-state | add-member "Alice"

    assert ($state.members | length) == 1
    assert ($state.members.0.name == "Alice")
    assert ($state.members.0.active == true)

    print "✓ test_add_member passed"
}

# Test: add multiple members
# Purpose: Verify that multiple members can be added
export def test_add_multiple_members [] {
    let state = create-initial-state
        | add-member "Alice"
        | add-member "Bob"
        | add-member "Charlie"

    assert ($state.members | length) == 3
    assert ($state.members.0.name == "Alice")
    assert ($state.members.1.name == "Bob")
    assert ($state.members.2.name == "Charlie")

    print "✓ test_add_multiple_members passed"
}

# Test: remove-member
# Purpose: Verify that remove-member marks a member as inactive
export def test_remove_member [] {
    let state = create-initial-state | add-member "Alice"
    let member_id = $state.members.0.id

    let updated_state = $state | remove-member $member_id

    assert ($updated_state.members | length) == 1
    assert ($updated_state.members.0.active == false)

    print "✓ test_remove_member passed"
}

# Test: get-active-members
# Purpose: Verify that get-active-members returns only active members
export def test_get_active_members [] {
    let state = create-initial-state
        | add-member "Alice"
        | add-member "Bob"
        | add-member "Charlie"

    let alice_id = $state.members.0.id
    let state_with_removal = $state | remove-member $alice_id

    let active = $state_with_removal | get-active-members

    assert ($active | length) == 2
    assert ($active.0.name == "Bob")
    assert ($active.1.name == "Charlie")

    print "✓ test_get_active_members passed"
}

# Test: get-pending-hosts
# Purpose: Verify that get-pending-hosts returns members who haven't hosted
export def test_get_pending_hosts [] {
    let state = create-initial-state
        | add-member "Alice"
        | add-member "Bob"
        | add-member "Charlie"

    let alice_id = $state.members.0.id

    # Mark Alice as completed
    let state_with_completed = $state | upsert current_cycle (
        $state.current_cycle | upsert completed_members [$alice_id]
    )

    let pending = $state_with_completed | get-pending-hosts

    assert ($pending | length) == 2
    assert ($pending.0.name == "Bob")
    assert ($pending.1.name == "Charlie")

    print "✓ test_get_pending_hosts passed"
}

# Test: is-cycle-complete
# Purpose: Verify that is-cycle-complete correctly identifies when all members have hosted
export def test_is_cycle_complete [] {
    let state = create-initial-state
        | add-member "Alice"
        | add-member "Bob"

    # Not complete initially
    assert (not ($state | is-cycle-complete))

    let alice_id = $state.members.0.id
    let bob_id = $state.members.1.id

    # Complete after both have hosted
    let completed_state = $state | upsert current_cycle (
        $state.current_cycle | upsert completed_members [$alice_id, $bob_id]
    )

    assert ($completed_state | is-cycle-complete)

    print "✓ test_is_cycle_complete passed"
}

# Test: start-new-cycle
# Purpose: Verify that start-new-cycle increments cycle number and resets completed members
export def test_start_new_cycle [] {
    let state = create-initial-state
        | add-member "Alice"
        | add-member "Bob"

    let alice_id = $state.members.0.id

    let state_with_completed = $state | upsert current_cycle (
        $state.current_cycle | upsert completed_members [$alice_id]
    )

    let new_cycle_state = $state_with_completed | start-new-cycle

    assert ($new_cycle_state.current_cycle.cycle_number == 2)
    assert ($new_cycle_state.current_cycle.completed_members | is-empty)

    print "✓ test_start_new_cycle passed"
}

# Test: add-activity
# Purpose: Verify that add-activity adds activity and marks host as completed
export def test_add_activity [] {
    let state = create-initial-state | add-member "Alice"
    let alice_id = $state.members.0.id

    let updated_state = $state | add-activity $alice_id "Bowling" "2026-02-15"

    assert ($updated_state.activities | length) == 1
    assert ($updated_state.activities.0.activity_name == "Bowling")
    assert ($updated_state.activities.0.host_id == $alice_id)
    assert ($updated_state.current_cycle.completed_members | length) == 1
    assert ($updated_state.current_cycle.completed_members.0 == $alice_id)

    print "✓ test_add_activity passed"
}

# Test: add-activity auto-cycles
# Purpose: Verify that add-activity starts a new cycle when all members have hosted
export def test_add_activity_auto_cycles [] {
    let state = create-initial-state
        | add-member "Alice"
        | add-member "Bob"

    let alice_id = $state.members.0.id
    let bob_id = $state.members.1.id

    # Alice hosts
    let state_after_alice = $state | add-activity $alice_id "Bowling" "2026-02-01"

    assert ($state_after_alice.current_cycle.cycle_number == 1)

    # Bob hosts - should trigger new cycle
    let state_after_bob = $state_after_alice | add-activity $bob_id "Game Night" "2026-02-15"

    assert ($state_after_bob.current_cycle.cycle_number == 2)
    assert ($state_after_bob.current_cycle.completed_members | is-empty)
    assert ($state_after_bob.activities | length) == 2

    print "✓ test_add_activity_auto_cycles passed"
}

# Test: get-activities
# Purpose: Verify that get-activities returns activities sorted by date
export def test_get_activities [] {
    let state = create-initial-state | add-member "Alice"
    let alice_id = $state.members.0.id

    let state_with_activities = $state
        | add-activity $alice_id "Activity 1" "2026-01-01"
        | add-activity $alice_id "Activity 2" "2026-02-01"
        | add-activity $alice_id "Activity 3" "2026-03-01"

    let activities = $state_with_activities | get-activities

    assert ($activities | length) == 3
    # Should be sorted newest first
    assert ($activities.0.date == "2026-03-01")
    assert ($activities.1.date == "2026-02-01")
    assert ($activities.2.date == "2026-01-01")

    print "✓ test_get_activities passed"
}

# Test: new member joins mid-cycle
# Purpose: Verify that new members added mid-cycle are included in pending hosts
export def test_new_member_mid_cycle [] {
    let state = create-initial-state
        | add-member "Alice"
        | add-member "Bob"

    let alice_id = $state.members.0.id

    # Alice hosts
    let state_after_alice = $state | add-activity $alice_id "Bowling" "2026-02-01"

    # Charlie joins mid-cycle
    let state_with_charlie = $state_after_alice | add-member "Charlie"

    let pending = $state_with_charlie | get-pending-hosts

    # Bob and Charlie should be pending
    assert ($pending | length) == 2

    print "✓ test_new_member_mid_cycle passed"
}

# Run all store tests
export def main [] {
    print "Running store tests..."
    test_add_member
    test_add_multiple_members
    test_remove_member
    test_get_active_members
    test_get_pending_hosts
    test_is_cycle_complete
    test_start_new_cycle
    test_add_activity
    test_add_activity_auto_cycles
    test_get_activities
    test_new_member_mid_cycle
    print "All store tests passed! ✓"
}
