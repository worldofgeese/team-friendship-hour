# Team Friendship Hour

A webapp for DevRel's Team Friendship Hour: bi-weekly team activities where members take turns hosting. The app tracks who hosted, what activity, and who's next.

## Features

- **Team Management**: Add/remove team members dynamically with automatic adaptation
- **Rotation Logic**: Everyone hosts once, then the cycle resets automatically
- **Activity Tracking**: Record activities with host, date, and description
- **Visual Calendar**: View past activities and upcoming schedule
- **Cycle Management**: Visual indication of who's done vs who still needs to host
- **Data Persistence**: File-based JSON storage that persists across container restarts

## Architecture

### Technical Stack

- **Backend**: [http-nu](https://github.com/cablehead/http-nu) - HTTP server in Nushell
- **Frontend**: [Datastar](https://github.com/starfederation/datastar) - Reactive frontend framework
- **Data**: File-based JSON storage
- **Language**: Nushell scripts

### Data Model

```nushell
# TeamMember
{
    id: string
    name: string
    active: bool
    added_date: string  # ISO 8601
}

# Activity
{
    id: string
    host_id: string
    activity_name: string
    date: string  # ISO 8601
    cycle_number: int
}

# Cycle
{
    cycle_number: int
    started_date: string  # ISO 8601
    completed_members: list<string>  # member IDs
}
```

## Project Structure

```
team-friendship-hour/
├── src/
│   ├── server.nu              # Main http-nu server
│   ├── data/
│   │   ├── models.nu          # Data type definitions
│   │   └── store.nu           # Data persistence layer
│   └── routes/
│       ├── api.nu             # REST API endpoints
│       └── pages.nu           # HTML pages with Datastar
├── tests/
│   ├── test_models.nu         # Model unit tests
│   ├── test_store.nu          # Store unit tests
│   └── run_all_tests.nu       # Test runner
├── data/                      # Data directory (created at runtime)
│   └── state.json             # Application state
├── Containerfile              # Container image definition
├── compose.yaml               # Docker Compose configuration
└── .forgejo/
    └── workflows/
        └── ci.yaml            # CI/CD pipeline
```

## Getting Started

### Prerequisites

- [Nushell](https://www.nushell.sh/) (v0.99+)
- [http-nu](https://github.com/cablehead/http-nu)
- Docker/Podman (for containerized deployment)

### Local Development

1. Clone the repository:
```bash
git clone <repository-url>
cd team-friendship-hour
```

2. Install http-nu:
```bash
cargo install http-nu
```

3. Run the server:
```bash
cd src
nu server.nu --port 8080
```

4. Open your browser to `http://localhost:8080`

### Running Tests

```bash
cd tests
nu run_all_tests.nu
```

All tests follow the design recipe approach (HtDF/HtDD):
- Signature
- Purpose
- Examples
- Template
- Implementation

### Container Deployment

#### Using Docker Compose (Recommended)

```bash
# Build and start the container
docker compose up -d

# View logs
docker compose logs -f

# Stop the container
docker compose down
```

#### Using Podman

```bash
# Build the image
podman build -t team-friendship-hour -f Containerfile .

# Run the container
podman run -d \
  --name team-friendship-hour \
  -p 8080:8080 \
  -v ./data:/app/data:Z \
  team-friendship-hour

# View logs
podman logs -f team-friendship-hour
```

The container follows Red Hat best practices:
- Non-root user (UID 1001)
- Group 0 (root group) for OpenShift compatibility
- Group-writable directories for data persistence
- Health checks included
- Security hardening

## API Endpoints

### Team Members

- `GET /api/members` - Get all team members
- `GET /api/members/active` - Get active team members
- `GET /api/members/pending` - Get members who haven't hosted in current cycle
- `POST /api/members` - Add a new team member
  ```json
  {"name": "Alice"}
  ```
- `DELETE /api/members/:id` - Remove a team member (marks as inactive)

### Activities

- `GET /api/activities` - Get all activities (sorted by date, newest first)
- `POST /api/activities` - Record a new activity
  ```json
  {
    "host_id": "member-id",
    "activity_name": "Bowling",
    "date": "2026-02-15"
  }
  ```

### Cycle Information

- `GET /api/cycle` - Get current cycle information
- `GET /api/state` - Get complete application state

## How It Works

### Rotation Logic

1. **Initial State**: When the app starts, cycle 1 begins with no completed members
2. **Recording Activities**: When an activity is recorded, the host is marked as completed for the current cycle
3. **Cycle Completion**: When all active members have hosted, a new cycle automatically starts
4. **New Members**: Members added mid-cycle are included in the current rotation
5. **Removed Members**: Inactive members don't affect cycle completion

### Example Flow

```
Cycle 1 starts with members: Alice, Bob, Charlie
├─ Alice hosts "Bowling" → Alice marked complete
├─ Bob hosts "Game Night" → Bob marked complete
├─ Charlie joins the team → Charlie added to pending
├─ Charlie hosts "Karaoke" → Charlie marked complete
└─ All members complete → Cycle 2 starts automatically

Cycle 2 starts with members: Alice, Bob, Charlie
└─ All completion markers reset
```

## Data Persistence

Application state is stored in `data/state.json` and persists across:
- Server restarts
- Container restarts (when using volume mounts)
- Application updates

The data file is automatically created on first run with an initial empty state.

## CI/CD

The project includes a Forgejo CI workflow (`.forgejo/workflows/ci.yaml`) that:
- Runs all unit tests
- Builds the container image
- Tests container startup
- Performs syntax checking

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality (following the design recipe)
4. Implement the feature
5. Ensure all tests pass
6. Submit a pull request

## License

[Add your license here]

## Support

For issues and questions, please open an issue on the repository.
