# AWS Account Switcher

A Go-based CLI tool to quickly switch between different AWS organization profiles by commenting/uncommenting sections in your `~/.aws/config` file.

## Overview

When working with multiple AWS organizations (e.g., Company A, Company B, and personal accounts), you often need to switch between them. This tool automates that process by managing profile sections in your AWS config file.

**The tool automatically detects organizations from your config file** - no code changes needed! Simply organize your config with `## BEGIN` and `## END` markers.

## Features

- 🔄 **Quick Switching**: Switch between organizations with a simple menu
- 🔍 **Auto-Detection**: Automatically discovers organizations from your config file
- 💾 **Automatic Backup**: Creates a backup before making changes
- ✨ **Smart Detection**: Shows which organization is currently active
- 🎯 **Safe Operations**: Validates input and prevents accidental changes
- 📝 **Clean Interface**: User-friendly CLI with colors and emojis
- 🎨 **Dynamic Formatting**: Converts `ORGANIZATION_NAME` to readable "Organization Name"

## Prerequisites

- Go 1.21 or higher
- AWS CLI configured with `~/.aws/config` file

## Installation

### Option 1: Build from source

```bash
cd ~/Documents/github/super-scripts/aws/aws-switcher
go build -o aws-switcher
```

### Option 2: Install globally

```bash
cd ~/Documents/github/super-scripts/aws/aws-switcher
go install
```

Then add to your `~/.zshrc` or `~/.bashrc`:

```bash
export PATH="$PATH:$(go env GOPATH)/bin"
```

Or create a symlink:

```bash
ln -s ~/Documents/github/super-scripts/aws/aws-switcher/aws-switcher /usr/local/bin/aws-switcher
```

## Configuration

Your `~/.aws/config` file must be organized with special section markers. The tool will automatically detect all organizations from these markers:

```ini
## BEGIN COMPANY_A
[profile qa]
sso_start_url = https://company-a.awsapps.com/start#/
...
## END COMPANY_A

## BEGIN COMPANY_B
#[profile qa]
#sso_start_url = https://company-b.awsapps.com/start/#/
...
## END COMPANY_B

## BEGIN PERSONAL
#[profile personal]
...
## END PERSONAL
```

**Note**:
- Only one organization should be active (uncommented) at a time
- Organization names can be any format (e.g., `LULO_X`, `COMPANY_A`, `PERSONAL`)
- The tool automatically formats names for display (e.g., `LULO_X` → "Lulo X")

## Usage

Simply run the tool:

```bash
./aws-switcher
```

Or if installed globally:

```bash
aws-switcher
```

You'll see a menu like this:

```
╔═══════════════════════════════════════════════════════╗
║          AWS Account Organization Switcher           ║
╚═══════════════════════════════════════════════════════╝

📍 Current active organization: Company A

Select the organization you want to activate:

✓ 1. Company A
  2. Company B
  3. Personal

Enter your choice (1-3) or 'q' to quit:
```

## How It Works

1. **Reads** your `~/.aws/config` file
2. **Identifies** organization sections using `BEGIN`/`END` markers
3. **Detects** which organization is currently active
4. **Prompts** you to select an organization
5. **Comments** all inactive organizations (adds `#` prefix)
6. **Uncomments** the selected organization (removes `#` prefix)
7. **Saves** changes and creates a backup

## How Organizations are Detected

The tool automatically scans your `~/.aws/config` file for section markers:

- Looks for `## BEGIN ORGANIZATION_NAME` markers
- Extracts the organization name after `BEGIN`
- No hardcoded organization list - fully dynamic!
- Add or remove organizations by editing your config file

**Example**: If your config has `## BEGIN PRODUCTION` and `## BEGIN DEVELOPMENT`, the tool will automatically show both options in the menu.

## Backup

Every time you switch, a backup is created at:

```
~/.aws/config.backup
```

To restore from backup:

```bash
cp ~/.aws/config.backup ~/.aws/config
```

## Example Workflow

```bash
# Currently working with Company A
$ aws sso login --profile qa
# Logged into Company A QA

# Need to switch to Company B
$ aws-switcher
# Select: 2

# Now working with Company B
$ aws sso login --profile qa
# Logged into Company B QA
```

## Troubleshooting

### Config file not found
Make sure your AWS config exists at `~/.aws/config`

### Section markers missing
Ensure your config file has the required `## BEGIN ORG_NAME` and `## END ORG_NAME` markers

### Permissions error
Make sure you have write permissions to `~/.aws/config`

## Development

To run in development mode:

```bash
go run main.go
```

To run tests:

```bash
go test ./...
```

## License

MIT

## Author

Created for managing multiple AWS organizations with Terraform and AWS CLI.
