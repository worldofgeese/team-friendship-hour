# Team Friendship Hour Main Handler
# Direct http-nu script

use routes/api.nu route-api
use routes/pages.nu route-pages

# Purpose: Main request handler - routes requests to API or page handlers
# Signature: record -> string
{|req|
    let path = $req.path

    if ($path | str starts-with "/api/") {
        $req | route-api
    } else {
        $req | route-pages
    }
}
