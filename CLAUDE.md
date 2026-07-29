# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a collection of Bash utility scripts for AWS automation, DevOps tasks, and general infrastructure management. Scripts are organized by category and typically designed to be run standalone with AWS CLI and standard Unix tools.

## Repository Structure

- `aws/` - AWS automation scripts for Lambda, VPC, and resource discovery
- `devops/` - CI/CD and GitHub automation utilities
- `utils/` - General-purpose tools
- `networking/` - Network-related scripts (currently empty)
- `infra/` - Infrastructure provisioning helpers (currently empty)
- `scripts/` - Miscellaneous scripts (currently empty)

Each script directory contains:
- A main `.sh` script file
- A `README.md` with usage documentation

## Key Scripts

### AWS Resources Explorer (`aws/Resources explorer/resources-explorer.sh`)
- Inventories AWS resources across all enabled regions and global services
- Outputs JSONL format (one JSON object per line)
- Covers 20+ AWS services including EC2, Lambda, RDS, S3, IAM, etc.
- Usage: `./resources-explorer.sh [-p PROFILE] [-o output.jsonl]`
- Requires: AWS CLI v2, jq

### Lambda Layer Updater (`aws/Lambda Layer Updater/lambda-layer-updater.sh`)
- Batch updates Lambda layer versions across functions
- Interactive confirmation for each function update
- Configured via hardcoded variables: `OLD_LAYER`, `NEW_LAYER`, `SCRIPT_PROFILE`, `SCRIPT_REGION`
- Usage: Edit variables in script, then run `./lambda-layer-updater.sh`

### Lambda VPC Validator (`aws/Lambda VPC Validator/lambda-vpc-validator.sh`)
- Scans all regions for Lambda functions with a specific runtime not in VPC
- Displays environment variables for matching functions
- Configured via: `SCRIPT_PROFILE`, `TARGET_RUNTIME`
- Note: Contains Spanish comments and output messages

### Journal Post Gate (`utils/Journal Post Gate/journal-post-gate.sh`)
- Deterministic leak check for text about to be published on a public site
- Built-in rules are generic (AWS accounts, ARNs, IPs, secret prefixes, local paths, creds in URLs)
- Employer-specific rules live OUTSIDE the repo in `~/.config/journal-post-gate/{patterns,denylist}.txt`
- Usage: `./journal-post-gate.sh <file>` or stdin; `--patterns` lists the ruleset
- Exit 0 clean / 1 blocked / 2 usage. Blocks itself when scanned (its own ruleset matches) — expected

### Daily Journal Post (`utils/Journal Post Gate/daily-journal-post.sh`)
- Turns a private journal entry into a draft post for the personal site, via opencode
- Opens a pull request and stops — never pushes to master, because that publishes immediately
- Skips silently if there is no journal entry for the date, or a post already exists for it
- Usage: `./daily-journal-post.sh [YYYY-MM-DD] [--dry-run]`; model via `JOURNAL_POST_MODEL`
- Intended to run daily from launchd/cron

### Claude Agents Status (`utils/Claude Agents Status/claude-agents.sh`)
- Reports the status of Claude Code background agent sessions from `~/.claude/jobs/*/state.json`
- Shows state (`working`/`blocked`/`done`), age, tokens consumed, scratch size and ticket name
- Flags stalled sessions (blocked >7d with <5k tokens) and finished sessions holding >10 MB of scratch
- Usage: `./claude-agents.sh [-a|-d|-f|-j] [session-id]`
- Requires: `jq`, macOS (`stat -f %m`). Override the jobs path with `CLAUDE_JOBS_DIR`
- Note: Contains Spanish comments and output messages

### GitHub Org Repo Cloner (`devops/GitHub Org Repo Cloner/github-org-repo-cloner.sh`)
- Clones all repositories from a GitHub organization
- Supports pagination and private repos via GitHub token
- Uses custom SSH alias (`github-alias-account`) for multi-account support
- Configured via: `ORG`, `GITHUB_TOKEN`, `DEST_DIR`

## Common Development Patterns

### Script Configuration
Scripts use hardcoded configuration variables at the top of the file that must be edited before use:
- AWS profile names (`SCRIPT_PROFILE`)
- AWS regions (`SCRIPT_REGION`)
- ARNs, runtime versions, organization names, etc.

### AWS CLI Usage
- All scripts use AWS CLI v2
- Profile support via `--profile` flag or environment variables
- Safe API calls that swallow errors: `aws ... 2>/dev/null || true`
- Multi-region iteration pattern using `aws ec2 describe-regions`

### Output Formats
- AWS Resources Explorer: JSONL (machine-readable, one JSON per line)
- Other scripts: Human-readable with emoji indicators (🔄, ✅, ❌, 👉, etc.)

### Error Handling
- Scripts use `set -euo pipefail` for strict error handling (Resources Explorer)
- Permission errors are gracefully handled by suppressing stderr
- Interactive scripts prompt for confirmation before destructive operations

## Testing Scripts

No automated tests are present. Scripts should be tested manually:
1. Review and edit configuration variables
2. Test with `--help` or `-h` flags where available
3. Start with read-only operations or dry-run modes
4. Use non-production AWS profiles for testing

## Dependencies

Common dependencies across scripts:
- AWS CLI v2 (required for all AWS scripts)
- jq (required for JSON parsing)
- curl (required for GitHub API scripts)
- git (required for GitHub cloning)
- bash 4+ (for modern syntax features)

Check dependencies before running:
```bash
command -v aws >/dev/null 2>&1 || { echo "AWS CLI required"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq required"; exit 1; }
```