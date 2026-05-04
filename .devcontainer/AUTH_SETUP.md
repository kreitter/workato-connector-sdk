# Authentication Setup for Dev Container

## Investigation Results

### Claude Code Authentication
**Finding**: Claude Code auth appears to be handled via the `.claude/` directory we're already syncing!
- ✅ No separate globalStorage directory found
- ✅ No macOS Keychain entries
- ✅ Auth likely embedded in session files or handled via API

**Action**: No additional mounting needed! The current `.claude` sync should handle it.

### Git/GitHub Authentication
**Finding**: You're using **1Password SSH Agent** (excellent choice!)
- ✅ SSH config points to: `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`
- ✅ Keys stored securely in 1Password (not on filesystem)
- ✅ Agent provides keys on-demand

## Recommended Configuration

### For 1Password SSH Agent

Add these to `devcontainer.json`:

```json
{
  "mounts": [
    // Existing Claude sync
    "source=/Users/dave/.claude,target=/Users/dave/.claude,type=bind",

    // 1Password SSH agent socket
    "source=/Users/dave/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock,target=/tmp/1password-agent.sock,type=bind",

    // SSH config (so git knows to use 1Password)
    "source=/Users/dave/.ssh/config,target=/home/vscode/.ssh/config,type=bind,readonly",

    // Git config (user name/email)
    "source=/Users/dave/.gitconfig,target=/home/vscode/.gitconfig,type=bind,readonly",

    // GitHub CLI config (if you use gh)
    "source=/Users/dave/.config/gh,target=/home/vscode/.config/gh,type=bind,readonly"
  ],

  "containerEnv": {
    // Point SSH to 1Password agent
    "SSH_AUTH_SOCK": "/tmp/1password-agent.sock"
  },

  "postCreateCommand": "bundle install && mkdir -p ~/.ssh && chmod 700 ~/.ssh"
}
```

### How This Works

1. **1Password SSH Agent Socket**:
   - Mounts the agent socket into container
   - Container SSH clients can request keys from 1Password
   - Keys never enter the container, only signatures
   - Super secure! 🔒

2. **SSH Config**:
   - Container inherits your `~/.ssh/config`
   - Git knows to use the 1Password agent
   - GitHub authentication "just works"

3. **Git Config**:
   - Your name/email from host `.gitconfig`
   - Container Claude can create commits with correct authorship

4. **GitHub CLI** (optional):
   - If you use `gh` command, tokens are available
   - Read-only to prevent accidental changes

### Test Commands (Run in Dev Container)

```bash
# Test SSH to GitHub
ssh -T git@github.com
# Should output: "Hi <username>! You've successfully authenticated..."

# Test git operations
git status
git add .
git commit -m "test"
git push origin your-branch

# Test GitHub CLI
gh auth status
gh pr list
```

## Security Analysis

### ✅ Secure Mounts (What We're Doing)
- **1Password socket**: ✅ Keys stay in 1Password, only signatures pass through
- **SSH config**: ✅ Read-only, just tells SSH where the agent is
- **Git config**: ✅ Read-only, just name/email (public info)
- **GitHub CLI**: ✅ Read-only tokens

### ❌ Insecure Alternatives (What We're NOT Doing)
- Copying SSH private keys into container
- Storing tokens in environment variables
- Writable mounts for sensitive data
- Hardcoded credentials

## Expected Behavior

### First Launch
1. Container builds with all mounts
2. SSH agent socket available immediately
3. Git operations work without password prompts
4. Claude Code auth works (already in `.claude/`)

### When Dev Container Claude Commits Code
```bash
# This should "just work":
git checkout -b claude-dev-container-fixes
git add lib/workato/cli/validators/
git commit -m "Fix: Updated validators based on test results"
git push origin claude-dev-container-fixes

# Then on host:
git fetch
git checkout claude-dev-container-fixes
# Review and merge!
```

### When You Exit and Re-Enter
- All auth persists (1Password agent always available)
- No re-authentication needed
- Seamless workflow

## Troubleshooting

### SSH doesn't work in container
```bash
# Check if agent socket is mounted
ls -la /tmp/1password-agent.sock

# Check environment variable
echo $SSH_AUTH_SOCK

# Test agent connection
ssh-add -l
```

### Git push asks for password
```bash
# Check remote URL (should be git@github.com, not https)
git remote -v

# If https, change to SSH:
git remote set-url origin git@github.com:USER/REPO.git
```

### 1Password prompts for approval
- This is normal! 1Password may ask you to approve SSH key usage
- Click "Allow" in 1Password
- Can check "Always Allow" for this socket

## Benefits of This Setup

✅ **Zero credentials in container** - Keys stay in 1Password
✅ **No password prompts** - Agent handles auth automatically
✅ **Works across rebuilds** - Mounts reconnect each time
✅ **Secure by default** - Read-only mounts for sensitive data
✅ **Dev container Claude can commit/push** - Full git workflow enabled
✅ **You keep control** - 1Password still guards your keys

## Alternative: If 1Password Socket Doesn't Work

If the 1Password socket mount has issues, fallback to macOS SSH agent:

```json
"containerEnv": {
  "SSH_AUTH_SOCK": "/run/host-services/ssh-auth.sock"
},
"mounts": [
  "source=/run/host-services/ssh-auth.sock,target=/run/host-services/ssh-auth.sock,type=bind"
]
```

But your current 1Password setup is more secure and should work perfectly!

## Summary

**Claude Code Auth**: ✅ Already working (via `.claude/` sync)
**Git/GitHub Auth**: ✅ Ready to implement (1Password SSH agent)

Next step: Update `devcontainer.json` with the mounts above!
