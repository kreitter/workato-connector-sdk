#!/bin/bash
# Syncs Claude Code updates from dev container back to host
# Run this manually or set up as a periodic task

set -e

echo "🔄 Syncing dev container changes back to host..."

# Paths
CONTAINER_CLAUDE_DIR="/home/vscode/.claude"
HOST_CLAUDE_MOUNT="/Users/dave/.claude"

# Path transformations (reverse of sync-claude-context.sh)
CONTAINER_PROJECT_PATH="/workspaces/workato-connector-sdk"
HOST_PROJECT_PATH="/Users/dave/Documents/GitHub/workato-connector-sdk"

CONTAINER_PROJECT_SLUG="-workspaces-workato-connector-sdk"
HOST_PROJECT_SLUG="-Users-dave-Documents-GitHub-workato-connector-sdk"

# Check if we're in the container
if [ ! -d "$CONTAINER_CLAUDE_DIR" ]; then
  echo "❌ Not in dev container - this script should run inside the container"
  exit 1
fi

# Check if host mount is writable (needs to be mounted as writable)
if [ ! -w "$HOST_CLAUDE_MOUNT" ]; then
  echo "❌ Host .claude directory not writable"
  echo "💡 Update devcontainer.json mount to be writable:"
  echo '   "source=/Users/dave/.claude,target=/Users/dave/.claude,type=bind"'
  exit 1
fi

echo "📁 Syncing session updates back to host..."

# Sync project sessions back (with path transformation)
CONTAINER_PROJECT_DIR="$CONTAINER_CLAUDE_DIR/projects/$CONTAINER_PROJECT_SLUG"
HOST_PROJECT_DIR="$HOST_CLAUDE_MOUNT/projects/$HOST_PROJECT_SLUG"

if [ ! -d "$CONTAINER_PROJECT_DIR" ]; then
  echo "ℹ️  No container sessions to sync back"
  exit 0
fi

# Ensure host project directory exists
mkdir -p "$HOST_PROJECT_DIR"

SESSION_COUNT=0
for session_file in "$CONTAINER_PROJECT_DIR"/*.jsonl; do
  if [ -f "$session_file" ]; then
    SESSION_COUNT=$((SESSION_COUNT + 1))
    filename=$(basename "$session_file")
    target_file="$HOST_PROJECT_DIR/$filename"

    # Transform paths back to host format
    # Replace container paths with host paths
    sed -e "s|$CONTAINER_PROJECT_PATH|$HOST_PROJECT_PATH|g" \
        "$session_file" > "$target_file"

    echo "  ✓ Synced back: $filename"
  fi
done

# Also sync global files that might have changed
echo ""
echo "📋 Syncing global configuration..."

for file in settings.json history.jsonl; do
  if [ -f "$CONTAINER_CLAUDE_DIR/$file" ]; then
    cp "$CONTAINER_CLAUDE_DIR/$file" "$HOST_CLAUDE_MOUNT/$file"
    echo "  ✓ $file"
  fi
done

# Sync todos (if they changed)
if [ -d "$CONTAINER_CLAUDE_DIR/todos" ]; then
  rsync -a --delete "$CONTAINER_CLAUDE_DIR/todos/" "$HOST_CLAUDE_MOUNT/todos/" 2>/dev/null || \
    cp -r "$CONTAINER_CLAUDE_DIR/todos/"* "$HOST_CLAUDE_MOUNT/todos/" 2>/dev/null || true
  echo "  ✓ todos/"
fi

echo ""
echo "✅ Synced $SESSION_COUNT session file(s) back to host"
echo "📁 Host location: $HOST_CLAUDE_MOUNT"
echo ""
echo "💡 Your session updates are now available on the host machine!"
echo ""
