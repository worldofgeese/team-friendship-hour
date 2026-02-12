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

# Purpose: Main request handler entry point for http-nu
# http-nu pipes each request as JSON into this script's pipeline
# Signature: nothing -> nothing
def main []: nothing -> nothing {
    $in | from json | handle-request
}
