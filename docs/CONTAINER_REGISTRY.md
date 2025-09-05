# Container Registry Guide

## GitHub Container Registry (ghcr.io)

This project uses GitHub Container Registry to store Docker images. By default, packages are private and require authentication to pull.

## Making Packages Public

### Option 1: Using GitHub Web UI (Recommended)

1. Go to your package page: https://github.com/mi-skam/python-tool/pkgs/container/python-tool
2. Click on **Package settings** (⚙️ icon)
3. Scroll down to **Danger Zone**
4. Click **Change visibility**
5. Select **Public** and confirm

### Option 2: Using GitHub CLI

Run the provided script:

```bash
./scripts/make-package-public.sh
```

Or manually with GitHub CLI:

```bash
gh api \
  --method PATCH \
  -H "Accept: application/vnd.github+json" \
  "/user/packages/container/python-tool/visibility" \
  -f visibility='public'
```

### Option 3: Using GitHub API

```bash
curl -X PATCH \
  -H "Authorization: Bearer YOUR_GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/user/packages/container/python-tool/visibility \
  -d '{"visibility":"public"}'
```

## Automatic Publishing

The `.github/workflows/publish.yml` workflow automatically:
1. Builds multi-platform images (linux/amd64, linux/arm64)
2. Pushes to ghcr.io on every push to main
3. Tags with branch name and commit SHA

**Note**: After first publish, you must manually make the package public using one of the methods above.

## Testing Public Access

Once public, anyone can pull without authentication:

```bash
# No login required for public packages
docker pull ghcr.io/mi-skam/python-tool:latest
docker pull ghcr.io/mi-skam/python-tool:main
docker pull ghcr.io/mi-skam/python-tool:main-e849866
```

## Container Labels

The workflow adds standard OCI labels:
- `org.opencontainers.image.source` - Repository URL
- `org.opencontainers.image.description` - Package description
- `org.opencontainers.image.licenses` - License information
- `org.opencontainers.image.version` - Version/tag

## Deployment Usage

Once public, the Terraform deployment can pull images without authentication:

```yaml
# cloud-init.yml
- su - deploy -c "docker pull ghcr.io/mi-skam/python-tool:${git_hash}"
```

No Docker login required for public packages!