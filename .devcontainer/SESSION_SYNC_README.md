# Claude Code Session Sync for Dev Containers

## Problem Solved

When working in a dev container, Claude Code sessions are isolated from your host machine. Additionally, workspace paths change:
- **Host**: `/Users/dave/Documents/GitHub/workato-connector-sdk`
- **Container**: `/workspaces/workato-connector-sdk`

This script syncs your Claude Code session history into the dev container and transforms all path references so you can resume conversations seamlessly.

## How It Works

### 1. Mount (Read-Only)
The devcontainer.json mounts your local `.claude` directory:
```json
"mounts": [
  "source=/Users/dave/.claude,target=/Users/dave/.claude,type=bind,readonly"
]
```

### 2. Sync Script (`sync-claude-context.sh`)
Runs automatically when you attach to the container (`postAttachCommand`):

**What it does:**
1. Copies your entire `.claude` directory from host to `/home/vscode/.claude`
2. Transforms session files (`.jsonl`) to replace all path references:
   - `"/Users/dave/Documents/GitHub/workato-connector-sdk"` → `"/workspaces/workato-connector-sdk"`
3. Renames project folder:
   - `-Users-dave-Documents-GitHub-workato-connector-sdk` → `-workspaces-workato-connector-sdk`
4. Shows you the most recent session ID to resume

### 3. Resume Your Session
After the sync completes, you'll see:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Most recent session: e0800e13-4c17-4da9-ace0-538567f8ac0d
   Size: 10M

💡 To resume your previous conversation:
   /resume e0800e13-4c17-4da9-ace0-538567f8ac0d
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## What Gets Synced

### Global Files
- `CLAUDE.md` - Your global user instructions
- `settings.json` - Claude Code settings
- `history.jsonl` - Command history
- `statusline.sh` - Status line configuration

### Directories
- `commands/` - Custom slash commands
- `file-history/` - File edit history
- `ide/` - IDE integrations
- `plugins/` - Installed plugins
- `shell-snapshots/` - Terminal snapshots
- `statsig/` - Analytics data
- `todos/` - Todo tracking data

### Project Sessions (Transformed)
- All `.jsonl` session files with paths rewritten for container

## Path Transformations Applied

The script uses `sed` to transform all instances of:

```bash
# From (host path):
"/Users/dave/Documents/GitHub/workato-connector-sdk"

# To (container path):
"/workspaces/workato-connector-sdk"
```

This affects:
- `"cwd"` fields in session messages
- `"file_path"` fields in tool calls
- Any other absolute path references

## Bi-Directional Sync

### Host → Container (Automatic on Attach)
The `sync-claude-context.sh` script runs when you attach and:
1. Copies your host `.claude` to container
2. Transforms paths for container environment
3. Shows you the session ID to resume

### Container → Host (Automatic Background Sync)
A background daemon runs every 5 minutes to:
1. Copy updated sessions from container back to host
2. Transform paths back to host format
3. Update your host `.claude` directory

**This means:**
- ✅ Continue a session in the dev container
- ✅ Exit the container
- ✅ Resume the same session on your host machine
- ✅ All messages synchronized automatically!

### Manual Sync Back to Host
If you want to force an immediate sync from container to host:
```bash
.devcontainer/sync-back-to-host.sh
```

## Why Writable Mount?

The mount is writable (not read-only) because:
1. We need to sync updates back to the host
2. The background daemon writes to it every 5 minutes
3. This enables true bi-directional session continuity
4. Your session history stays synchronized everywhere

## Rebuilding the Container

Every time you rebuild or reattach to the container:
1. The mount makes your latest `.claude` data available (including updates from other sessions)
2. The sync script copies and transforms it fresh
3. The background daemon starts to sync changes back
4. You get full bi-directional synchronization

## Troubleshooting

### Session not found
If `/resume <session-id>` doesn't work:
1. Check if the sync script ran: look for output when attaching
2. Verify the transformed session exists:
   ```bash
   ls -la /home/vscode/.claude/projects/-workspaces-workato-connector-sdk/
   ```
3. Check if paths were transformed correctly:
   ```bash
   grep "cwd" /home/vscode/.claude/projects/-workspaces-workato-connector-sdk/e0800e13-4c17-4da9-ace0-538567f8ac0d.jsonl | head -1
   ```
   Should show: `"cwd":"/workspaces/workato-connector-sdk"`

### Script errors
View script output when attaching to the container. If it fails:
1. Check if `/Users/dave/.claude` is mounted correctly
2. Verify permissions on the host directory
3. Check if the project slug matches in the script

## Making This Work for Other Projects

To use this pattern in other dev containers:

1. Copy `.devcontainer/sync-claude-context.sh` to your project
2. Update the paths in the script:
   ```bash
   HOST_PROJECT_PATH="/Users/dave/Documents/GitHub/YOUR-PROJECT"
   CONTAINER_PROJECT_PATH="/workspaces/YOUR-PROJECT"
   ```
3. Update project slugs to match your directory names
4. Add the same mount and postAttachCommand to your devcontainer.json

## Benefits

✅ **Bi-directional sync** - Changes flow both ways automatically
✅ **Full session continuity** - Resume anywhere (host or container)
✅ **All context preserved** - File history, todos, commands, settings
✅ **Automatic path transformation** - No manual editing needed
✅ **Background daemon** - Syncs every 5 minutes automatically
✅ **No manual file copying** - Everything handled automatically
✅ **Works across container rebuilds** - Always up-to-date

## Current Session

**Session ID**: `e0800e13-4c17-4da9-ace0-538567f8ac0d`
**Status**: Implementing Workato Validate Command (77/77 tests passing!)
**Next**: Resume in dev container to investigate Thor CLI issue with Claude Code's help
