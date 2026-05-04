#!/bin/bash
# Syncs and transforms Claude Code context from host to dev container
# Handles path transformations for session continuity

set -e

echo "🔄 Syncing Claude Code context to dev container..."

# Paths
HOST_CLAUDE_DIR="/Users/dave/.claude"
CONTAINER_CLAUDE_DIR="/home/vscode/.claude"

# Path transformations needed
HOST_PROJECT_PATH="/Users/dave/Documents/GitHub/workato-connector-sdk"
CONTAINER_PROJECT_PATH="/workspaces/workato-connector-sdk"

HOST_PROJECT_SLUG="-Users-dave-Documents-GitHub-workato-connector-sdk"
CONTAINER_PROJECT_SLUG="-workspaces-workato-connector-sdk"

# Check if host .claude directory is accessible
if [ ! -d "$HOST_CLAUDE_DIR" ]; then
  echo "⚠️  Host .claude directory not accessible at: $HOST_CLAUDE_DIR"
  echo "   Starting fresh in dev container"
  exit 0
fi

# Create container .claude directory structure
mkdir -p "$CONTAINER_CLAUDE_DIR"
mkdir -p "$CONTAINER_CLAUDE_DIR/projects/$CONTAINER_PROJECT_SLUG"

echo "📁 Copying Claude Code configuration..."

# Copy global files
for file in CLAUDE.md settings.json history.jsonl statusline.sh; do
  if [ -f "$HOST_CLAUDE_DIR/$file" ]; then
    cp "$HOST_CLAUDE_DIR/$file" "$CONTAINER_CLAUDE_DIR/$file"
    echo "  ✓ $file"
  fi
done

# Copy directories (without transformation)
for dir in commands file-history ide plugins shell-snapshots statsig todos; do
  if [ -d "$HOST_CLAUDE_DIR/$dir" ]; then
    cp -r "$HOST_CLAUDE_DIR/$dir" "$CONTAINER_CLAUDE_DIR/"
    echo "  ✓ $dir/"
  fi
done

# Copy and transform project sessions
HOST_PROJECT_DIR="$HOST_CLAUDE_DIR/projects/$HOST_PROJECT_SLUG"
CONTAINER_PROJECT_DIR="$CONTAINER_CLAUDE_DIR/projects/$CONTAINER_PROJECT_SLUG"

if [ -d "$HOST_PROJECT_DIR" ]; then
  echo ""
  echo "📋 Transforming session files for dev container paths..."

  SESSION_COUNT=0
  for session_file in "$HOST_PROJECT_DIR"/*.jsonl; do
    if [ -f "$session_file" ]; then
      SESSION_COUNT=$((SESSION_COUNT + 1))
      filename=$(basename "$session_file")
      target_file="$CONTAINER_PROJECT_DIR/$filename"

      # Transform paths in the session file
      # Replace both cwd and file_path entries
      sed -e "s|$HOST_PROJECT_PATH|$CONTAINER_PROJECT_PATH|g" \
          "$session_file" > "$target_file"

      echo "  ✓ Transformed: $filename"
    fi
  done

  echo ""
  echo "✅ Transformed $SESSION_COUNT session file(s)"

  # Find and display the most recent session
  LATEST=$(find "$CONTAINER_PROJECT_DIR" -name "*.jsonl" -type f -print0 | xargs -0 ls -t | head -1)
  if [ -n "$LATEST" ]; then
    SESSION_ID=$(basename "$LATEST" .jsonl)
    FILE_SIZE=$(du -h "$LATEST" | cut -f1)

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 Most recent session: $SESSION_ID"
    echo "   Size: $FILE_SIZE"
    echo ""
    echo "💡 To resume your previous conversation:"
    echo "   /resume $SESSION_ID"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  fi
else
  echo "ℹ️  No existing sessions found"
  echo "   Starting fresh in dev container"
fi

# Set proper ownership
chown -R vscode:vscode "$CONTAINER_CLAUDE_DIR" 2>/dev/null || true

echo ""
echo "✅ Claude context sync complete!"
echo "📁 Location: $CONTAINER_CLAUDE_DIR"
echo ""
