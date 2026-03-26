# AI Development Environment Setup - Infrastructure

## Overview

This project uses a **jsDelivr CDN + GitHub public distribution repository** architecture to achieve zero-maintenance-cost script distribution. Users can configure their AI development environment with a single curl command.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          Architecture Diagram                            │
└─────────────────────────────────────────────────────────────────────────┘

    ┌─────────────────────┐         ┌─────────────────────────────┐
    │   Private Repo      │         │   Public Distribution Repo   │
    │   ai-dev-env        │  push   │   ai-dev-env-deploy         │
    │   (source code)     │ ──────► │   (release files only)      │
    │                     │         │                              │
    │   - src/            │  GitHub │   - src/setup.sh            │
    │   - lib/            │ Actions │   - src/lib/*               │
    │   - .github/        │         │   - README.md                │
    │   - tests/          │         │                              │
    └─────────────────────┘         └─────────────────────────────┘
                                                        │
                                                        │ push
                                                        ▼
                                            ┌─────────────────────┐
                                            │   jsDelivr CDN      │
                                            │   cdn.jsdelivr.net  │
                                            │   (global CDN)      │
                                            └─────────────────────┘
                                                        │
                                                        │ curl
                                                        ▼
                                            ┌─────────────────────┐
                                            │   User's Computer   │
                                            │   (any OS)          │
                                            └─────────────────────┘
```

## Components

### 1. Private Repository (`ai-dev-env`)

- **Purpose**: Source code repository
- **Visibility**: Private (as required by project spec)
- **Management**: GitHub CLI (`gh`)

Contains:
- Full source code in `src/`
- Library modules in `src/lib/`
- GitHub Actions workflows in `.github/workflows/`
- Test suite in `tests/`

### 2. Public Distribution Repository (`ai-dev-env-deploy`)

- **Purpose**: Public release distribution
- **Visibility**: Public (required for jsDelivr access)
- **Sync Method**: Automated via GitHub Actions

Contains:
- Only release files: `src/setup.sh`, `src/lib/*`
- No sensitive data or secrets
- Auto-synced from private repo

### 3. jsDelivr CDN

- **Purpose**: Global CDN for script delivery
- **Cost**: Free
- **Maintenance**: Zero (no server management)
- **Features**:
  - Global CDN with edge servers
  - Version pinning via git tags
  - Branch references (e.g., `@main`)
  - No rate limits for public repos

## Distribution URLs

### Latest Version (main branch)

```bash
curl -sL https://cdn.jsdelivr.net/gh/{owner}/ai-dev-env-deploy@main/src/setup.sh | bash
```

### Versioned Release

```bash
curl -sL https://cdn.jsdelivr.net/gh/{owner}/ai-dev-env-deploy@v1.0.0/src/setup.sh | bash
```

### Specific Commit

```bash
curl -sL https://cdn.jsdelivr.net/gh/{owner}/ai-dev-env-deploy@abc123/src/setup.sh | bash
```

## Workflow

### Development Workflow

```
1. Developer clones private repo
   gh repo clone {owner}/ai-dev-env

2. Make changes to source code
   edit src/setup.sh, src/lib/*.sh

3. Test locally
   bash src/setup.sh install
   bash src/setup.sh configure

4. Commit and push
   git add .
   git commit -m "feat: ..."
   git push

5. CI/CD syncs to distribution repo
   (automatic via GitHub Actions)
```

### Release Workflow

```
1. Update version in src/setup.sh
   readonly VERSION="2.0.0"

2. Create git tag
   git tag v2.0.0
   git push origin v2.0.0

3. GitHub Actions syncs to distribution repo
   (automatic)

4. Users receive update notification
   setup.sh update
```

### Update Flow (End User)

```
1. User runs update command
   setup.sh update

2. Script checks VERSION_URL for new version

3. If update available:
   - Shows changelog (if provided)
   - Prompts for confirmation
   - Downloads new version
   - Verifies checksum
   - Applies update
   - Re-executes with new version
```

## Security

### Source Validation

The script validates its source URL against an allowed list:

- `cdn.jsdelivr.net` (primary)
- `raw.githubusercontent.com` (fallback)

If downloaded from an untrusted source, the script will refuse to execute.

### Checksum Verification

Each release includes SHA256 checksums:

```
SHA256SUMS:
  setup.sh: a1b2c3d4e5f6...
  lib/core.sh: f6e5d4c3b2a1...
```

The script verifies checksums before applying updates.

### Credential Storage

- Credentials are stored locally in `~/.config/ai-dev-env/config.json`
- Credentials are NEVER uploaded or transmitted
- Each machine has its own local configuration

## Maintenance

### Required Maintenance (Minimal)

1. **GitHub Token Rotation**
   - If using a deploy key for CI/CD sync
   - Rotate every 90 days recommended

2. **Dependency Updates**
   - Occasionally update `jq` dependency check
   - Update package manager detection if needed

### No Maintenance Required

- jsDelivr CDN (operated by Cloudflare)
- GitHub Actions (operated by GitHub)
- Distribution repository (auto-synced)

## Troubleshooting

### Common Issues

#### 1. curl command fails

```bash
# Check network connectivity
curl -v https://cdn.jsdelivr.net

# Verify URL is correct
curl -sL https://cdn.jsdelivr.net/gh/{owner}/ai-dev-env-deploy@main/src/setup.sh
```

#### 2. Permission denied

```bash
# Check config directory permissions
ls -la ~/.config/ai-dev-env/

# Fix permissions if needed
chmod 700 ~/.config/ai-dev-env
```

#### 3. Checksum mismatch

```bash
# Re-download
curl -sL https://cdn.jsdelivr.net/gh/{owner}/ai-dev-env-deploy@main/src/setup.sh -o /tmp/setup.sh

# Verify manually
sha256sum /tmp/setup.sh
```

#### 4. jq not found

```bash
# Install jq
# Debian/Ubuntu:
sudo apt-get install jq

# macOS:
brew install jq
```

### Debug Mode

Enable debug output:

```bash
DEBUG=1 bash setup.sh install
```

## Appendix: GitHub CLI Usage

### Initial Setup

```bash
# Install GitHub CLI (if not installed)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# Authenticate
gh auth login
```

### Repository Management

```bash
# Clone private repo
gh repo clone {owner}/ai-dev-env

# Create distribution repo (one-time setup)
gh repo create ai-dev-env-deploy --public

# View repo info
gh repo view {owner}/ai-dev-env --web
```

### Release Management

```bash
# Create release
cd ai-dev-env
git tag v1.0.0
git push origin v1.0.0

# View releases
gh release list

# Create release with notes
gh release create v1.0.0 \
  --title "v1.0.0" \
  --notes "Initial release with AI development environment setup"
```

## Versioning Policy

- **Major Version**: Breaking changes (e.g., config format changes)
- **Minor Version**: New features (e.g., new config options)
- **Patch Version**: Bug fixes (e.g., error handling improvements)

Users can pin to a specific version or use `@main` for latest.

## Contact & Support

For issues or questions:
- Open an issue in the private repository
- Check troubleshooting section above
