# API Routes for Team Friendship Hour
# RESTful endpoints for managing team members and activities

use ../data/store.nu *

# Purpose: Handle GET /api/state - return current application state
# Signature: record -> record
export def "api get-state" [req: record]: nothing -> record {
    let state = load-state
    $state
}

# Purpose: Handle GET /api/members - return all team members
# Signature: record -> list
export def "api get-members" [req: record]: nothing -> list {
    let state = load-state
    $state.members
}

# Purpose: Handle GET /api/members/active - return active team members
# Signature: record -> list
export def "api get-active-members" [req: record]: nothing -> list {
    let state = load-state
    $state | get-active-members
}

# Purpose: Handle GET /api/members/pending - return members who haven't hosted
# Signature: record -> list
export def "api get-pending-hosts" [req: record]: nothing -> list {
    let state = load-state
    $state | get-pending-hosts
}

# Purpose: Handle POST /api/members - add a new team member
# Signature: record -> any
export def "api add-member" [req: record]: string -> any {
    try {
        let body = ($in | from json)
        let name = $body.name

        if ($name | is-empty) {
            return ({error: "Name is required"} | metadata set --merge {'http.response': {status: 400}})
        }

        let state = load-state | add-member $name
        $state | save-state
        $state | metadata set --merge {'http.response': {status: 201}}
    } catch {
        {error: "Invalid request body"} | metadata set --merge {'http.response': {status: 400}}
    }
}

# Purpose: Handle DELETE /api/members/:id - remove a team member
# Signature: record -> record
export def "api remove-member" [req: record]: nothing -> record {
    let member_id = $req.params.id

    let state = load-state | remove-member $member_id
    $state | save-state
    $state
}

# Purpose: Handle GET /api/activities - return all activities
# Signature: record -> list
export def "api get-activities" [req: record]: nothing -> list {
    let state = load-state
    let activities = ($state | get-activities)

    # Enrich activities with member names
    $activities | each {|a|
        let member = ($state | get-member $a.host_id)
        $a | insert host_name $member.name
    }
}

# Purpose: Handle POST /api/activities - add a new activity
# Signature: record -> any
export def "api add-activity" [req: record]: string -> any {
    try {
        let body = ($in | from json)
        let host_id = $body.host_id
        let activity_name = $body.activity_name
        let date = $body.date

        if ($host_id | is-empty) or ($activity_name | is-empty) or ($date | is-empty) {
            return ({error: "host_id, activity_name, and date are required"} | metadata set --merge {'http.response': {status: 400}})
        }

        let state = load-state | add-activity $host_id $activity_name $date
        $state | save-state
        $state | metadata set --merge {'http.response': {status: 201}}
    } catch {
        {error: "Invalid request body"} | metadata set --merge {'http.response': {status: 400}}
    }
}

# Purpose: Handle GET /api/cycle - return current cycle info
# Signature: record -> record
export def "api get-cycle" [req: record]: nothing -> record {
    let state = load-state

    {
        current_cycle: $state.current_cycle
        active_members_count: ($state | get-active-members | length)
        pending_hosts_count: ($state | get-pending-hosts | length)
        is_complete: ($state | is-cycle-complete)
    }
}

# Purpose: Route API requests to appropriate handlers
# Signature: record -> any
export def route-api []: record -> any {
    let req = $in
    let method = $req.method
    let path = $req.path

    match [$method, $path] {
        ["GET", "/api/state"] => { api get-state $req }
        ["GET", "/api/members"] => { api get-members $req }
        ["GET", "/api/members/active"] => { api get-active-members $req }
        ["GET", "/api/members/pending"] => { api get-pending-hosts $req }
        ["POST", "/api/members"] => { $in | api add-member $req }
        ["DELETE", $path] if ($path | str starts-with "/api/members/") => {
            let id = ($path | str replace "/api/members/" "")
            api remove-member ($req | insert params {id: $id})
        }
        ["GET", "/api/activities"] => { api get-activities $req }
        ["POST", "/api/activities"] => { $in | api add-activity $req }
        ["GET", "/api/cycle"] => { api get-cycle $req }
        _ => {
            {error: "Not found"} | metadata set --merge {'http.response': {status: 404}}
        }
    }
}
