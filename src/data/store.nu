# Data Store for Team Friendship Hour
# Following HtDF design recipe: Signature, Purpose, Examples, Template, Implementation

use models.nu *

# Constants
const STATE_FILE = "data/state.json"

# Purpose: Load application state from S3 or disk (with fallback)
# Signature: nothing -> record
export def load-state []: nothing -> record {
    # Check if S3 is configured
    if ("S3_BUCKET" in $env) {
        let bucket = $env.S3_BUCKET
        let local_path = "/tmp/state.json"
        
        # Try to download from S3
        let result = (do -i { aws s3 cp $"s3://($bucket)/state.json" $local_path --quiet } | complete)
        
        if $result.exit_code == 0 and ($local_path | path exists) {
            return (open $local_path)
        } else {
            # S3 bucket is empty or error occurred, return initial state
            return (create-initial-state)
        }
    }
    
    # Fallback to local file storage
    if ($STATE_FILE | path exists) {
        open $STATE_FILE
    } else {
        create-initial-state
    }
}

# Purpose: Save application state to S3 or disk (with fallback)
# Signature: record -> nothing
export def save-state []: record -> nothing {
    let state = $in

    # Check if S3 is configured
    if ("S3_BUCKET" in $env) {
        let bucket = $env.S3_BUCKET
        let local_path = "/tmp/state.json"
        
        # Save to temp file first
        $state | to json | save -f $local_path
        
        # Upload to S3
        aws s3 cp $local_path $"s3://($bucket)/state.json" --quiet
        
        return
    }
    
    # Fallback to local file storage
    # Ensure data directory exists
    mkdir data

    # Save state to file
    $state | to json | save -f $STATE_FILE
}

# Purpose: Add a new member to the state
# Signature: record, string -> record
export def add-member [name: string]: record -> record {
    let state = $in
    let new_member = create-team-member $name

    $state | upsert members ($state.members | append $new_member)
}

# Purpose: Remove a member from the state (marks as inactive)
# Signature: record, string -> record
export def remove-member [member_id: string]: record -> record {
    let state = $in

    $state | upsert members (
        $state.members | each {|m|
            if $m.id == $member_id {
                $m | upsert active false
            } else {
                $m
            }
        }
    )
}

# Purpose: Get all active members
# Signature: record -> list<record>
export def get-active-members []: record -> list<record> {
    let state = $in
    $state.members | where active == true
}

# Purpose: Get members who haven't hosted in the current cycle
# Signature: record -> list<record>
export def get-pending-hosts []: record -> list<record> {
    let state = $in
    let completed_ids = $state.current_cycle.completed_members

    $state | get-active-members | where {|m| $m.id not-in $completed_ids}
}

# Purpose: Check if the current cycle is complete
# Signature: record -> bool
export def is-cycle-complete []: record -> bool {
    let state = $in
    let active_members = $state | get-active-members
    let completed_count = ($state.current_cycle.completed_members | length)
    let active_count = ($active_members | length)

    $completed_count >= $active_count and $active_count > 0
}

# Purpose: Start a new cycle
# Signature: record -> record
export def start-new-cycle []: record -> record {
    let state = $in
    let new_cycle_number = $state.current_cycle.cycle_number + 1

    $state | upsert current_cycle (create-cycle $new_cycle_number)
}

# Purpose: Add an activity and update cycle state
# Signature: record, string, string, string -> record
export def add-activity [
    host_id: string
    activity_name: string
    date: string
]: record -> record {
    let state = $in

    # Create the activity
    let new_activity = create-activity $host_id $activity_name $date $state.current_cycle.cycle_number

    # Add activity to state
    let state_with_activity = $state | upsert activities ($state.activities | append $new_activity)

    # Mark host as completed in current cycle
    let state_with_completion = $state_with_activity | upsert current_cycle (
        $state_with_activity.current_cycle | upsert completed_members (
            $state_with_activity.current_cycle.completed_members | append $host_id | uniq
        )
    )

    # Check if cycle is complete and start new cycle if needed
    if ($state_with_completion | is-cycle-complete) {
        $state_with_completion | start-new-cycle
    } else {
        $state_with_completion
    }
}

# Purpose: Get all activities sorted by date (newest first)
# Signature: record -> list<record>
export def get-activities []: record -> list<record> {
    let state = $in
    $state.activities | sort-by date | reverse
}

# Purpose: Get a member by ID
# Signature: record, string -> record
export def get-member [member_id: string]: record -> record {
    let state = $in
    $state.members | where id == $member_id | first
}
