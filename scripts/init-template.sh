#!/usr/bin/env bash
# Initialize template with your project-specific values
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Python CLI Template Initialization${NC}"
echo "This script will replace template placeholders with your project values."
echo ""

# Get project name
echo -e "${YELLOW}Project Configuration:${NC}"
read -p "Project name (lowercase, hyphens only): " PROJECT_NAME
if [[ ! $PROJECT_NAME =~ ^[a-z0-9-]+$ ]]; then
    echo -e "${RED}❌ Project name must contain only lowercase letters, numbers, and hyphens.${NC}"
    exit 1
fi

# Get GitHub username
read -p "GitHub username: " GITHUB_USERNAME
if [[ -z "$GITHUB_USERNAME" ]]; then
    echo -e "${RED}❌ GitHub username is required.${NC}"
    exit 1
fi

# Get domain (optional for deployment)
echo ""
echo -e "${YELLOW}Deployment Configuration (optional):${NC}"
read -p "Your domain name (e.g., example.com) [skip if not deploying]: " DOMAIN
read -p "Cloudflare zone ID [skip if not using Cloudflare]: " CLOUDFLARE_ZONE_ID

echo ""
echo -e "${BLUE}🔄 Updating template files...${NC}"

# Update .env.example
if [ -f .env.example ]; then
    sed -i.bak "s/YOUR_PROJECT_NAME/$PROJECT_NAME/g" .env.example
    sed -i.bak "s/YOUR_GITHUB_USERNAME/$GITHUB_USERNAME/g" .env.example
    rm .env.example.bak
    echo "✅ Updated .env.example"
fi

# Update terraform.tfvars.example
if [ -f infrastructure/terraform.tfvars.example ]; then
    sed -i.bak "s/YOUR_GITHUB_USERNAME/$GITHUB_USERNAME/g" infrastructure/terraform.tfvars.example
    if [ -n "$DOMAIN" ]; then
        sed -i.bak "s/your-domain.com/$DOMAIN/g" infrastructure/terraform.tfvars.example
    fi
    if [ -n "$CLOUDFLARE_ZONE_ID" ]; then
        sed -i.bak "s/your_cloudflare_zone_id_here/$CLOUDFLARE_ZONE_ID/g" infrastructure/terraform.tfvars.example
    fi
    rm infrastructure/terraform.tfvars.example.bak
    echo "✅ Updated infrastructure/terraform.tfvars.example"
fi

# Update CLAUDE.md
if [ -f CLAUDE.md ]; then
    sed -i.bak "s/YOUR_PROJECT_NAME/$PROJECT_NAME/g" CLAUDE.md
    sed -i.bak "s/YOUR_GITHUB_USERNAME/$GITHUB_USERNAME/g" CLAUDE.md
    rm CLAUDE.md.bak
    echo "✅ Updated CLAUDE.md"
fi

# Update pyproject.toml if it exists
if [ -f pyproject.toml ]; then
    # Update project name and package name
    sed -i.bak "s/name = \"python-tool\"/name = \"$PROJECT_NAME\"/g" pyproject.toml
    sed -i.bak "s/python-tool/$(echo $PROJECT_NAME | tr '-' '_')/g" pyproject.toml
    rm pyproject.toml.bak
    echo "✅ Updated pyproject.toml"
fi

# Rename source directory
if [ -d "src/python_tool" ]; then
    PACKAGE_NAME=$(echo $PROJECT_NAME | tr '-' '_')
    mv "src/python_tool" "src/$PACKAGE_NAME"
    echo "✅ Renamed source directory to src/$PACKAGE_NAME"
fi

# Update imports in source files
PACKAGE_NAME=$(echo $PROJECT_NAME | tr '-' '_')
if [ -d "src/$PACKAGE_NAME" ]; then
    find "src/$PACKAGE_NAME" -name "*.py" -exec sed -i.bak "s/python_tool/$PACKAGE_NAME/g" {} \;
    find "src/$PACKAGE_NAME" -name "*.py.bak" -delete
    echo "✅ Updated Python imports"
fi

# Update test files
if [ -d "tests" ]; then
    find tests -name "*.py" -exec sed -i.bak "s/python_tool/$PACKAGE_NAME/g" {} \;
    find tests -name "*.py.bak" -delete
    echo "✅ Updated test imports"
fi

# Create .env from template
if [ -f .env.example ] && [ ! -f .env ]; then
    cp .env.example .env
    echo "✅ Created .env from template"
fi

# Create terraform.tfvars from template (if deployment configured)
if [ -n "$DOMAIN" ] && [ -f infrastructure/terraform.tfvars.example ] && [ ! -f infrastructure/terraform.tfvars ]; then
    cp infrastructure/terraform.tfvars.example infrastructure/terraform.tfvars
    echo "✅ Created infrastructure/terraform.tfvars from template"
fi

echo ""
echo -e "${GREEN}✅ Template initialization complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review and update .env with your specific values"
echo "2. Run: ${BLUE}just install${NC} to set up the development environment"
echo "3. Run: ${BLUE}just test${NC} to verify everything works"

if [ -n "$DOMAIN" ]; then
    echo "4. Configure infrastructure/terraform.tfvars with your API tokens"
    echo "5. Run: ${BLUE}just deploy${NC} to deploy to the cloud"
fi

echo ""
echo -e "${BLUE}🎉 Happy coding!${NC}"