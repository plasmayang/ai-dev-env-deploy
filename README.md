# AI Development Environment Setup

Quickly configure AI development tools on any computer with a single command.

## Quick Start

```bash
# Download and run (single command)
curl -sL https://raw.githubusercontent.com/YOUR_USERNAME/ai-dev-env-deploy/main/src/setup-standalone.sh -o setup.sh && chmod +x setup.sh && ./setup.sh install
```

Or use GitHub CLI (recommended):
```bash
gh api repos/YOUR_USERNAME/ai-dev-env-deploy/contents/src/setup-standalone.sh --jq '.content' | base64 -d > setup.sh && chmod +x setup.sh && ./setup.sh install
```

## Features

- **One-command setup**: Download and run installation
- **Interactive configuration**: Default values for common options
- **Secure credential storage**: API keys stored locally, never transmitted
- **Multi-platform**: Supports Linux (all distros) and macOS
- **Self-updating**: Check and apply updates with one command

## Installation

### Step 1: Download the script

```bash
# Using curl (may have CDN caching delay)
curl -sL https://raw.githubusercontent.com/YOUR_USERNAME/ai-dev-env-deploy/main/src/setup-standalone.sh -o setup.sh

# Using GitHub CLI (recommended - always latest)
gh api repos/YOUR_USERNAME/ai-dev-env-deploy/contents/src/setup-standalone.sh --jq '.content' | base64 -d > setup.sh
```

### Step 2: Run installation

```bash
chmod +x setup.sh
./setup.sh install
```

### Step 3: Configure

```bash
./setup.sh configure
```

### Step 4: Update (optional)

```bash
./setup.sh update
```

## Configuration Options

| Option | Description | Required |
|--------|-------------|----------|
| OpenAI API Key | API key for GPT models (sk-...) | Yes |
| GitHub Token | Personal Access Token for GitHub CLI | Yes |
| Preferred IDE | VSCode / Cursor / CLion / Vim | Yes |
| Default Model | gpt-4o / gpt-4o-mini / claude-3-5-sonnet / o3-mini | Yes |
| Theme | dark / light / system | No |
| Shell | bash / zsh / fish | No |

## Usage

```bash
./setup.sh help      # Show help
./setup.sh version   # Show version
./setup.sh install   # Check system and prerequisites
./setup.sh configure # Configure credentials
./setup.sh update    # Update to latest version
```

## Security

- **Source validation**: Only runs if downloaded from `raw.githubusercontent.com`
- **Local storage**: Credentials stored in `~/.config/ai-dev-env/config.json`
- **No telemetry**: Nothing is sent to external servers

## Prerequisites

The script automatically checks for:
- `curl` - For downloading updates
- `git` - For version control
- `jq` - For JSON config (optional, recommended)

Install missing dependencies:
```bash
# Debian/Ubuntu
sudo apt-get update && sudo apt-get install -y curl git jq

# macOS
brew install curl git jq
```

## Troubleshooting

### Script not found

```bash
chmod +x setup.sh
```

### jq not found

```bash
# Debian/Ubuntu
sudo apt-get install jq

# macOS
brew install jq
```

### Force update

```bash
gh api repos/YOUR_USERNAME/ai-dev-env-deploy/contents/src/setup-standalone.sh --jq '.content' | base64 -d > setup.sh
```

## For Version Pinning

```bash
# Clone and checkout specific version
git clone https://github.com/YOUR_USERNAME/ai-dev-env-deploy.git
cd ai-dev-env-deploy
git checkout v1.0.0
./src/setup-standalone.sh install
```

## Testing

Run Docker sandbox tests to verify the script works on multiple distributions:

```bash
make docker-build  # Build test images
make docker-test   # Run tests
make docker-all   # Build and test
```

## License

MIT
