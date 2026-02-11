# API Routes for Team Friendship Hour
# RESTful endpoints for managing team members and activities

use ../data/store.nu *

# Purpose: Handle GET /api/state - return current application state
# Signature: record -> string
export def "api get-state" []: record -> string {
    let req = $in
    let state = load-state

    {
        status: 200
        headers: {"Content-Type": "application/json"}
        body: ($state | to json)
    } | to json
}

# Purpose: Handle GET /api/members - return all team members
# Signature: record -> string
export def "api get-members" []: record -> string {
    let req = $in
    let state = load-state

    {
        status: 200
        headers: {"Content-Type": "application/json"}
        body: ($state.members | to json)
    } | to json
}

# Purpose: Handle GET /api/members/active - return active team members
# Signature: record -> string
export def "api get-active-members" []: record -> string {
    let req = $in
    let state = load-state
    let active = ($state | get-active-members)

    {
        status: 200
        headers: {"Content-Type": "application/json"}
        body: ($active | to json)
    } | to json
}

# Purpose: Handle GET /api/members/pending - return members who haven't hosted
# Signature: record -> string
export def "api get-pending-hosts" []: record -> string {
    let req = $in
    let state = load-state
    let pending = ($state | get-pending-hosts)

    {
        status: 200
        headers: {"Content-Type": "application/json"}
        body: ($pending | to json)
    } | to json
}

# Purpose: Handle POST /api/members - add a new team member
# Signature: record -> string
export def "api add-member" []: record -> string {
    let req = $in

    try {
        let body = ($req.body | from json)
        let name = $body.name

        if ($name | is-empty) {
            return ({
                status: 400
                headers: {"Content-Type": "application/json"}
                body: ({error: "Name is required"} | to json)
            } | to json)
        }

        let state = load-state | add-member $name
        $state | save-state

        {
            status: 201
            headers: {"Content-Type": "application/json"}
            body: ($state | to json)
        } | to json
    } catch {
        {
            status: 400
            headers: {"Content-Type": "application/json"}
            body: ({error: "Invalid request body"} | to json)
        } | to json
    }
}

# Purpose: Handle DELETE /api/members/:id - remove a team member
# Signature: record -> string
export def "api remove-member" []: record -> string {
    let req = $in
    let member_id = $req.params.id

    let state = load-state | remove-member $member_id
    $state | save-state

    {
        status: 200
        headers: {"Content-Type": "application/json"}
        body: ($state | to json)
    } | to json
}

# Purpose: Handle GET /api/activities - return all activities
# Signature: record -> string
export def "api get-activities" []: record -> string {
    let req = $in
    let state = load-state
    let activities = ($state | get-activities)

    # Enrich activities with member names
    let enriched = $activities | each {|a|
        let member = ($state | get-member $a.host_id)
        $a | insert host_name $member.name
    }

    {
        status: 200
        headers: {"Content-Type": "application/json"}
        body: ($enriched | to json)
    } | to json
}

# Purpose: Handle POST /api/activities - add a new activity
# Signature: record -> string
export def "api add-activity" []: record -> string {
    let req = $in

    try {
        let body = ($req.body | from json)
        let host_id = $body.host_id
        let activity_name = $body.activity_name
        let date = $body.date

        if ($host_id | is-empty) or ($activity_name | is-empty) or ($date | is-empty) {
            return ({
                status: 400
                headers: {"Content-Type": "application/json"}
                body: ({error: "host_id, activity_name, and date are required"} | to json)
            } | to json)
        }

        let state = load-state | add-activity $host_id $activity_name $date
        $state | save-state

        {
            status: 201
            headers: {"Content-Type": "application/json"}
            body: ($state | to json)
        } | to json
    } catch {
        {
            status: 400
            headers: {"Content-Type": "application/json"}
            body: ({error: "Invalid request body"} | to json)
        } | to json
    }
}

# Purpose: Handle GET /api/cycle - return current cycle info
# Signature: record -> string
export def "api get-cycle" []: record -> string {
    let req = $in
    let state = load-state

    let cycle_info = {
        current_cycle: $state.current_cycle
        active_members_count: ($state | get-active-members | length)
        pending_hosts_count: ($state | get-pending-hosts | length)
        is_complete: ($state | is-cycle-complete)
    }

    {
        status: 200
        headers: {"Content-Type": "application/json"}
        body: ($cycle_info | to json)
    } | to json
}

# Purpose: Route API requests to appropriate handlers
# Signature: record -> string
export def route-api []: record -> string {
    let req = $in
    let method = $req.method
    let path = $req.path

    match [$method, $path] {
        ["GET", "/api/state"] => { $req | api get-state }
        ["GET", "/api/members"] => { $req | api get-members }
        ["GET", "/api/members/active"] => { $req | api get-active-members }
        ["GET", "/api/members/pending"] => { $req | api get-pending-hosts }
        ["POST", "/api/members"] => { $req | api add-member }
        ["DELETE", $path] if ($path | str starts-with "/api/members/") => {
            let id = ($path | str replace "/api/members/" "")
            $req | insert params {id: $id} | api remove-member
        }
        ["GET", "/api/activities"] => { $req | api get-activities }
        ["POST", "/api/activities"] => { $req | api add-activity }
        ["GET", "/api/cycle"] => { $req | api get-cycle }
        _ => {
            {
                status: 404
                headers: {"Content-Type": "application/json"}
                body: ({error: "Not found"} | to json)
            } | to json
        }
    }
}
