#!/usr/bin/env bash
# Make GitHub Container Registry package public
set -euo pipefail

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed"
    echo "Install with: brew install gh"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub"
    echo "Run: gh auth login"
    exit 1
fi

PACKAGE_NAME="${1:-python-tool}"
OWNER="${GITHUB_USER:-mi-skam}"

echo "🔓 Making package ghcr.io/$OWNER/$PACKAGE_NAME public..."

# Using GitHub API to change package visibility
# Note: This requires the user to have admin permissions on the package
gh api \
  --method PATCH \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "/user/packages/container/$PACKAGE_NAME/visibility" \
  -f visibility='public' && echo "✅ Package is now public!" || {
    echo "⚠️  Could not update package visibility automatically"
    echo ""
    echo "Please make the package public manually:"
    echo "1. Go to: https://github.com/$OWNER/$PACKAGE_NAME/pkgs/container/$PACKAGE_NAME"
    echo "2. Click on 'Package settings' (⚙️ icon)"
    echo "3. Scroll to 'Danger Zone'"
    echo "4. Click 'Change visibility'"
    echo "5. Select 'Public' and confirm"
}

echo ""
echo "📦 Test pulling without authentication:"
echo "docker pull ghcr.io/$OWNER/$PACKAGE_NAME:latest"