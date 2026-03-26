# AI Development Environment Setup

Quickly configure AI development tools on any computer with a single command.

## Quick Start

```bash
curl -sL https://raw.githubusercontent.com/YOUR_USERNAME/ai-dev-env-deploy/main/src/setup.sh | bash
```

## Features

- **One-command setup**: `curl | bash` installation
- **Interactive configuration**: Default values for common options
- **Secure credential storage**: API keys stored locally, never transmitted
- **Multi-platform**: Supports Linux (all distros) and macOS
- **Self-updating**: Check and apply updates with one command

## Installation

### 1. Download and Run

```bash
curl -sL https://raw.githubusercontent.com/YOUR_USERNAME/ai-dev-env-deploy/main/src/setup.sh | bash
```

### 2. Configure

```bash
./setup.sh install   # Check prerequisites
./setup.sh configure # Set up credentials
```

### 3. Update

```bash
./setup.sh update    # Check for and apply updates
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

- Source validation: Only runs if downloaded from `raw.githubusercontent.com`
- Local storage: Credentials stored in `~/.config/ai-dev-env/config.json`
- No telemetry: Nothing is sent to external servers

## Troubleshooting

### Permission denied

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

### Update fails

```bash
# Force update
curl -sL https://raw.githubusercontent.com/YOUR_USERNAME/ai-dev-env-deploy/main/src/setup.sh -o setup.sh
```

## For Version Pinning

```bash
# Use specific version tag
git clone https://github.com/YOUR_USERNAME/ai-dev-env-deploy.git
cd ai-dev-env-deploy
git checkout v1.0.0
./src/setup.sh install
```

## Testing

Run Docker sandbox tests to verify the script works on multiple distributions:

```bash
make docker-build  # Build test images
make docker-test   # Run tests
make docker-all    # Build and test
```

## License

MIT
