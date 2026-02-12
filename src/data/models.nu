# Data Models for Team Friendship Hour
# Following HtDD design recipe: Signature, Purpose, Examples, Template, Implementation

# Purpose: Create a new team member record
# Signature: string -> record
export def create-team-member [name: string]: nothing -> record {
    {
        id: (random uuid)
        name: $name
        active: true
        added_date: (date now | format date "%Y-%m-%d")
    }
}

# Purpose: Create a new activity record
# Signature: string, string, string, int -> record
export def create-activity [
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

# Purpose: Create a new cycle record
# Signature: int -> record
export def create-cycle [cycle_number: int]: nothing -> record {
    {
        cycle_number: $cycle_number
        started_date: (date now | format date "%Y-%m-%d")
        completed_members: []
    }
}

# Purpose: Create the initial application state
# Signature: nothing -> record
export def create-initial-state []: nothing -> record {
    {
        members: []
        activities: []
        current_cycle: (create-cycle 1)
    }
}
