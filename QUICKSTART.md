# Quick Start Guide

## Option 1: Using Docker Compose (Easiest)

```bash
# Start the application
docker compose up -d

# View logs
docker compose logs -f

# Stop the application
docker compose down
```

Visit http://localhost:8080

## Option 2: Local Development

### Prerequisites
1. Install Nushell: https://www.nushell.sh/
2. Install http-nu: `cargo install http-nu`

### Run
```bash
# Using the start script
./start.sh

# Or manually
cd src
nu server.nu --port 8080
```

Visit http://localhost:8080

## Option 3: Using Podman

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

Visit http://localhost:8080

## Running Tests

```bash
cd tests
nu run_all_tests.nu
```

## First Steps

1. Add team members using the "Add Team Member" form
2. Record your first activity using the "Record Activity" form
3. Watch the cycle progress as members host activities
4. View the activity history in the calendar section

## Features to Try

- Add 3-4 team members
- Record activities for each member
- Notice how the cycle automatically resets when everyone has hosted
- Add a new member mid-cycle and see them added to the rotation
- Remove a member and see the cycle adjust
- View the activity history sorted by date

## Troubleshooting

**Port already in use:**
```bash
# Change the port in compose.yaml or use --port flag
nu server.nu --port 8081
```

**Data not persisting:**
- Ensure the data directory has proper permissions
- Check that the volume mount is configured correctly in compose.yaml

**Container won't start:**
- Check logs: `docker compose logs`
- Verify port 8080 is available
- Ensure data directory exists and is writable
