# Team Friendship Hour Server
# Main http-nu server entry point

use routes/api.nu route-api
use routes/pages.nu route-pages

# Purpose: Main request handler - routes requests to API or page handlers
# Signature: record -> string
def handle-request []: record -> string {
    let req = $in
    let path = $req.path

    if ($path | str starts-with "/api/") {
        $req | route-api
    } else {
        $req | route-pages
    }
}

# Purpose: Start the http-nu server
# Signature: nothing -> nothing
def main [
    --port (-p): int = 8080  # Port to listen on
]: nothing -> nothing {
    print $"Starting Team Friendship Hour server on port ($port)..."
    print $"Visit http://localhost:($port) in your browser"

    # Start http-nu server
    http-nu listen $port | each { |req|
        $req | from json | handle-request
    }
}
