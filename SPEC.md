# Team Friendship Hour Tracker — Specification

## Overview

A webapp for DevRel's Team Friendship Hour: bi-weekly team activities where members take turns hosting. The app tracks who hosted, what activity, and who's next.

## Core Requirements

### Team Management
- **Team size:** ~7 members currently
- **Configurable roster:** Add/remove members dynamically
- **Automatic adaptation:** When members join/leave, rotation adjusts

### Rotation Logic
- Everyone hosts once, then cycle resets
- When someone hosts, they're marked "done" for current cycle
- New members joining mid-cycle get added to current rotation
- Visual indication of who's done vs who still needs to host

### Activity Tracking
- **Per activity:** Activity name (free-form text), date, host
- **History:** Past activities viewable
- **Simple entry:** Just activity and date, nothing complex

### Visual Calendar
- Calendar view showing upcoming Team Friendship Hours
- Bi-weekly schedule visible
- Past activities on calendar as history

## Technical Stack

### Backend: http-nu
- **Repo:** https://github.com/cablehead/http-nu
- Nushell-based HTTP server
- Simple, scriptable backend

### Frontend: Datastar
- **Repo:** https://github.com/starfederation/datastar
- Reactive frontend framework
- HTML-first, minimal JavaScript

### Data Storage
- Simple file-based (JSON or SQLite)
- No complex database needed

### Deployment
- Rootless Podman container on `loving-kypris`
- Red Hat best practices:
  - UID 1001+ (OpenShift compatible)
  - GID 0 with group rwx
  - Numeric UIDs/GIDs in Dockerfile
  - Group-writable directories

## Data Model

### TeamMember
```
{
  "id": "uuid",
  "name": "string",
  "active": "boolean",
  "added_date": "date"
}
```

### Activity
```
{
  "id": "uuid",
  "host_id": "TeamMember.id",
  "activity_name": "string",
  "date": "date",
  "cycle_number": "integer"
}
```

### Cycle
```
{
  "cycle_number": "integer",
  "started_date": "date",
  "completed_members": ["TeamMember.id", ...]
}
```

## User Interface

### Main View
- Current cycle status (who's hosted, who's left)
- Next host suggestion (random from remaining, or let user pick)
- Quick-add form for recording an activity
- Calendar showing upcoming bi-weekly slots

### Team Management
- List of current team members
- Add new member (joins current rotation)
- Remove member (removes from rotation)
- Show inactive members for history

### History View
- Past activities with host, date, activity name
- Searchable/filterable
- Grouped by cycle

## Development Approach

### Design Recipes (HtDF/HtDD)
All functions and data follow CPSC110 design recipes:
1. Signature, purpose, stub
2. Examples/tests first
3. Template
4. Implementation
5. Test and debug

### Testing
- Unit tests for all logic
- Integration tests for API endpoints
- Local CI via `forgejo-runner exec`

### CI/CD

**Local CI (.forgejo/workflows/ci.yaml):**
```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: -self-hosted
    steps:
      - name: Test
        run: |
          cd "${PROJECT_DIR:-.}"
          # Run tests
```

**Remote CI (same file, different runner):**
```yaml
  test-remote:
    runs-on:
      - "ubuntu-latest:docker://node:20-bookworm"
      - "ubuntu-22.04:docker://node:20-bookworm"
      - "podman:docker://quay.io/podman/stable"
    steps:
      - uses: actions/checkout@v4
      - name: Test
        run: |
          # Same test commands
```

## File Structure
```
team-friendship-hour/
├── .forgejo/
│   └── workflows/
│       └── ci.yaml
├── src/
│   ├── server.nu          # http-nu server
│   ├── routes/
│   │   ├── api.nu         # API endpoints
│   │   └── pages.nu       # HTML pages
│   ├── data/
│   │   ├── store.nu       # Data persistence
│   │   └── models.nu      # Data definitions
│   └── static/
│       └── datastar/      # Frontend assets
├── tests/
│   ├── test_models.nu
│   ├── test_rotation.nu
│   └── test_api.nu
├── Containerfile
├── compose.yaml
└── README.md
```

## Deployment

### Container
```dockerfile
FROM docker.io/nushell/nu:latest

USER 1001:0
WORKDIR /app
COPY --chown=1001:0 . .
RUN chmod -R g+rwX /app

EXPOSE 8080
CMD ["nu", "src/server.nu"]
```

### Compose
```yaml
services:
  tfh:
    build: .
    ports:
      - "8080:8080"
    volumes:
      - ./data:/app/data
```

## Success Criteria

1. ✅ Can add/remove team members
2. ✅ Tracks who has hosted in current cycle
3. ✅ Automatically resets cycle when everyone has hosted
4. ✅ Records activities with date and description
5. ✅ Visual calendar shows schedule
6. ✅ Survives container restarts (data persisted)
7. ✅ All tests pass (local + remote CI)
8. ✅ Runs in rootless Podman with Red Hat best practices

## Git Forge

- **Repository:** `kypris/team-friendship-hour` on Forgejo
- **URL:** `https://paphos.hound-celsius.ts.net/kypris/team-friendship-hour`
