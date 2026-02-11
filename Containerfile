# Team Friendship Hour Containerfile
# Following Red Hat best practices:
# - Non-root user (UID 1001)
# - Group 0 (root group) for OpenShift compatibility
# - Group-writable directories
# - Minimal layers
# - Clear labels

FROM docker.io/library/alpine:3.21

# Metadata labels
LABEL name="team-friendship-hour" \
      version="1.0.0" \
      description="Team Friendship Hour webapp for tracking bi-weekly team activities" \
      maintainer="DevRel Team"

# Install Nushell and dependencies
RUN apk add --no-cache \
    nushell \
    curl \
    ca-certificates \
    && rm -rf /var/cache/apk/*

# Create app user with UID 1001 and add to group 0 (root group)
# This follows OpenShift best practices for arbitrary user IDs
RUN adduser -D -u 1001 -G root appuser && \
    mkdir -p /app/data /app/src && \
    chown -R 1001:0 /app && \
    chmod -R g+rwX /app

# Set working directory
WORKDIR /app

# Copy application files
COPY --chown=1001:0 src/ /app/src/

# Ensure data directory is group-writable for persistence
RUN chmod -R g+rwX /app/data

# Switch to non-root user
USER 1001

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/ || exit 1

# Set environment variables
ENV PORT=8080

# Run the server
CMD ["nu", "/app/src/server.nu", "--port", "8080"]
