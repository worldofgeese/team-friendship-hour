# Team Friendship Hour Main Handler
# Direct http-nu script

use data/store.nu *

# Purpose: Main request handler - routes requests to API or page handlers
# Signature: record -> any
{|req|
    let method = $req.method
    let path = $req.path
    let body = $in

    # HTML Pages
    if $path == "/" or $path == "/index.html" {
        return ("
<!DOCTYPE html>
<html lang=\"en\">
<head>
    <meta charset=\"UTF-8\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
    <title>Team Friendship Hour</title>
    <script type=\"module\" src=\"https://cdn.jsdelivr.net/npm/@sudodevnull/datastar@latest\"></script>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        .header {
            background: white;
            padding: 30px;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            margin-bottom: 30px;
            text-align: center;
        }
        .header h1 {
            color: #667eea;
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        .header p {
            color: #666;
            font-size: 1.1em;
        }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .card {
            background: white;
            padding: 25px;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
        }
        .card h2 {
            color: #667eea;
            margin-bottom: 20px;
            font-size: 1.5em;
            border-bottom: 2px solid #667eea;
            padding-bottom: 10px;
        }
        .form-group {
            margin-bottom: 15px;
        }
        .form-group label {
            display: block;
            margin-bottom: 5px;
            color: #333;
            font-weight: 500;
        }
        .form-group input, .form-group select {
            width: 100%;
            padding: 10px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 1em;
            transition: border-color 0.3s;
        }
        .form-group input:focus, .form-group select:focus {
            outline: none;
            border-color: #667eea;
        }
        .btn {
            background: #667eea;
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 8px;
            font-size: 1em;
            cursor: pointer;
            transition: background 0.3s;
            width: 100%;
            font-weight: 600;
        }
        .btn:hover {
            background: #5568d3;
        }
        .btn-danger {
            background: #e74c3c;
        }
        .btn-danger:hover {
            background: #c0392b;
        }
        .member-list, .activity-list {
            list-style: none;
        }
        .member-item, .activity-item {
            padding: 15px;
            margin-bottom: 10px;
            background: #f8f9fa;
            border-radius: 8px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .member-item.completed {
            background: #d4edda;
            border-left: 4px solid #28a745;
        }
        .member-item.pending {
            background: #fff3cd;
            border-left: 4px solid #ffc107;
        }
        .member-name {
            font-weight: 600;
            color: #333;
        }
        .member-status {
            font-size: 0.9em;
            color: #666;
            margin-left: 10px;
        }
        .activity-item {
            flex-direction: column;
            align-items: flex-start;
        }
        .activity-header {
            display: flex;
            justify-content: space-between;
            width: 100%;
            margin-bottom: 5px;
        }
        .activity-name {
            font-weight: 600;
            color: #667eea;
        }
        .activity-date {
            color: #666;
            font-size: 0.9em;
        }
        .activity-host {
            color: #666;
            font-size: 0.9em;
        }
        .cycle-info {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
            text-align: center;
        }
        .cycle-info h3 {
            font-size: 1.3em;
            margin-bottom: 10px;
        }
        .cycle-stats {
            display: flex;
            justify-content: space-around;
            margin-top: 15px;
        }
        .stat {
            text-align: center;
        }
        .stat-number {
            font-size: 2em;
            font-weight: bold;
        }
        .stat-label {
            font-size: 0.9em;
            opacity: 0.9;
        }
        .empty-state {
            text-align: center;
            padding: 30px;
            color: #999;
        }
        .btn-small {
            padding: 6px 12px;
            font-size: 0.9em;
            width: auto;
        }
        .calendar {
            background: white;
            padding: 25px;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
        }
        .calendar h2 {
            color: #667eea;
            margin-bottom: 20px;
            font-size: 1.5em;
        }
        .calendar-grid {
            display: grid;
            gap: 10px;
        }
        .calendar-event {
            padding: 15px;
            background: #f8f9fa;
            border-radius: 8px;
            border-left: 4px solid #667eea;
        }
        .calendar-event.past {
            opacity: 0.6;
        }
    </style>
</head>
<body>
    <div class=\"container\" data-store='\{\"state\": \{\}, \"newMember\": \"\", \"newActivity\": \{\"host_id\": \"\", \"activity_name\": \"\", \"date\": \"\"\}\}'>
        <div class=\"header\">
            <h1>🎉 Team Friendship Hour</h1>
            <p>Bi-weekly team activities where everyone takes turns hosting</p>
        </div>

        <!-- Load initial state -->
        <div data-on-load=\"\$\$get('/api/state').then(r => r.json()).then(d => state = d)\"></div>

        <!-- Cycle Information -->
        <div class=\"cycle-info\" data-show=\"state.current_cycle\">
            <h3>Cycle #<span data-text=\"state.current_cycle.cycle_number\"></span></h3>
            <p>Started: <span data-text=\"state.current_cycle.started_date\"></span></p>
            <div class=\"cycle-stats\">
                <div class=\"stat\">
                    <div class=\"stat-number\" data-text=\"state.current_cycle.completed_members?.length || 0\"></div>
                    <div class=\"stat-label\">Completed</div>
                </div>
                <div class=\"stat\">
                    <div class=\"stat-number\" data-text=\"state.members?.filter(m => m.active && !state.current_cycle.completed_members?.includes(m.id)).length || 0\"></div>
                    <div class=\"stat-label\">Pending</div>
                </div>
            </div>
        </div>

        <div class=\"grid\">
            <!-- Add Team Member -->
            <div class=\"card\">
                <h2>Add Team Member</h2>
                <form data-on-submit.prevent=\"\$\$fetch('/api/members', \{method: 'POST', body: JSON.stringify(\{name: newMember\})\}).then(r => r.json()).then(d => \{state = d; newMember = ''\})\">
                    <div class=\"form-group\">
                        <label for=\"member-name\">Name</label>
                        <input type=\"text\" id=\"member-name\" data-model=\"newMember\" placeholder=\"Enter member name\" required>
                    </div>
                    <button type=\"submit\" class=\"btn\">Add Member</button>
                </form>
            </div>

            <!-- Team Members -->
            <div class=\"card\">
                <h2>Team Members</h2>
                <div data-show=\"!state.members || state.members.filter(m => m.active).length === 0\" class=\"empty-state\">
                    No team members yet. Add your first member!
                </div>
                <ul class=\"member-list\" data-show=\"state.members && state.members.filter(m => m.active).length > 0\">
                    <template data-for=\"member in state.members?.filter(m => m.active) || []\">
                        <li class=\"member-item\" data-class-completed=\"state.current_cycle?.completed_members?.includes(member.id)\" data-class-pending=\"!state.current_cycle?.completed_members?.includes(member.id)\">
                            <div>
                                <span class=\"member-name\" data-text=\"member.name\"></span>
                                <span class=\"member-status\" data-show=\"state.current_cycle?.completed_members?.includes(member.id)\">✓ Hosted</span>
                                <span class=\"member-status\" data-show=\"!state.current_cycle?.completed_members?.includes(member.id)\">⏳ Pending</span>
                            </div>
                            <button class=\"btn btn-danger btn-small\" data-on-click=\"\$\$fetch('/api/members/' + member.id, \{method: 'DELETE'\}).then(r => r.json()).then(d => state = d)\">Remove</button>
                        </li>
                    </template>
                </ul>
            </div>

            <!-- Add Activity -->
            <div class=\"card\">
                <h2>Record Activity</h2>
                <form data-on-submit.prevent=\"\$\$fetch('/api/activities', \{method: 'POST', body: JSON.stringify(newActivity)\}).then(r => r.json()).then(d => \{state = d; newActivity = \{host_id: '', activity_name: '', date: ''\}\})\">
                    <div class=\"form-group\">
                        <label for=\"host\">Host</label>
                        <select id=\"host\" data-model=\"newActivity.host_id\" required>
                            <option value=\"\">Select a host</option>
                            <template data-for=\"member in state.members?.filter(m => m.active) || []\">
                                <option data-value=\"member.id\" data-text=\"member.name\"></option>
                            </template>
                        </select>
                    </div>
                    <div class=\"form-group\">
                        <label for=\"activity\">Activity</label>
                        <input type=\"text\" id=\"activity\" data-model=\"newActivity.activity_name\" placeholder=\"e.g., Bowling, Game Night\" required>
                    </div>
                    <div class=\"form-group\">
                        <label for=\"date\">Date</label>
                        <input type=\"date\" id=\"date\" data-model=\"newActivity.date\" required>
                    </div>
                    <button type=\"submit\" class=\"btn\">Record Activity</button>
                </form>
            </div>
        </div>

        <!-- Activity History -->
        <div class=\"calendar\">
            <h2>Activity History</h2>
            <div data-show=\"!state.activities || state.activities.length === 0\" class=\"empty-state\">
                No activities recorded yet. Record your first Team Friendship Hour!
            </div>
            <div class=\"calendar-grid\" data-show=\"state.activities && state.activities.length > 0\">
                <template data-for=\"activity in state.activities?.sort((a, b) => new Date(b.date) - new Date(a.date)) || []\">
                    <div class=\"calendar-event\" data-class-past=\"new Date(activity.date) < new Date()\">
                        <div class=\"activity-header\">
                            <span class=\"activity-name\" data-text=\"activity.activity_name\"></span>
                            <span class=\"activity-date\" data-text=\"activity.date\"></span>
                        </div>
                        <div class=\"activity-host\">
                            Hosted by: <span data-text=\"state.members?.find(m => m.id === activity.host_id)?.name || 'Unknown'\"></span>
                            • Cycle #<span data-text=\"activity.cycle_number\"></span>
                        </div>
                    </div>
                </template>
            </div>
        </div>
    </div>
</body>
</html>
")
    }

    # API Routes
    match [$method, $path] {
        # GET /api/state
        ["GET", "/api/state"] => {
            load-state
        }

        # GET /api/members
        ["GET", "/api/members"] => {
            let state = load-state
            $state.members
        }

        # GET /api/members/active
        ["GET", "/api/members/active"] => {
            let state = load-state
            $state | get-active-members
        }

        # GET /api/members/pending
        ["GET", "/api/members/pending"] => {
            let state = load-state
            $state | get-pending-hosts
        }

        # POST /api/members
        ["POST", "/api/members"] => {
            try {
                let parsed = ($body | from json)
                let name = $parsed.name

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

        # DELETE /api/members/:id
        ["DELETE", $path] if ($path | str starts-with "/api/members/") => {
            let id = ($path | str replace "/api/members/" "")
            let state = load-state | remove-member $id
            $state | save-state
            $state
        }

        # GET /api/activities
        ["GET", "/api/activities"] => {
            let state = load-state
            let activities = ($state | get-activities)

            # Enrich activities with member names
            $activities | each {|a|
                let member = ($state | get-member $a.host_id)
                $a | insert host_name $member.name
            }
        }

        # POST /api/activities
        ["POST", "/api/activities"] => {
            try {
                let parsed = ($body | from json)
                let host_id = $parsed.host_id
                let activity_name = $parsed.activity_name
                let date = $parsed.date

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

        # GET /api/cycle
        ["GET", "/api/cycle"] => {
            let state = load-state

            {
                current_cycle: $state.current_cycle
                active_members_count: ($state | get-active-members | length)
                pending_hosts_count: ($state | get-pending-hosts | length)
                is_complete: ($state | is-cycle-complete)
            }
        }

        # 404 Not Found
        _ => {
            {error: "Not found"} | metadata set --merge {'http.response': {status: 404}}
        }
    }
}
