# justfile for gcp-python-uv project

# ==================== Configuration ====================
# Load environment variables from .env file if it exists
set dotenv-load := true

# Core configuration (from .env or environment with sensible defaults)
project_id := env_var_or_default("GCP_PROJECT_ID", `gcloud config get-value project`)
region := env_var_or_default("GCP_REGION", "europe-west3")
GCP_SERVICE_NAME := env_var_or_default("GCP_SERVICE_NAME", "gcp-python-uv")

# Python configuration (single source of truth: .python-version)
python_version := `cat .python-version | tr -d '\n'`
python_image := env_var_or_default("PYTHON_IMAGE", "python:" + python_version + "-slim")

# Port configuration
port := env_var_or_default("PORT", "8080")
dev_local_port := env_var_or_default("DEV_LOCAL_PORT", "8082")

# Artifact Registry configuration
GCP_ARTIFACT_REGISTRY_REPO := env_var_or_default("GCP_ARTIFACT_REGISTRY_REPO", "cloud-run-apps")
git_hash := `git rev-parse --short HEAD`
image_tag := region + "-docker.pkg.dev/" + project_id + "/" + GCP_ARTIFACT_REGISTRY_REPO + "/" + GCP_SERVICE_NAME + ":" + git_hash

# ==================== Default Target ====================
# Show available commands
default:
    @just --list --unsorted

# ==================== Development Commands ====================
# Start development server with Docker Compose watch mode
dev port=dev_local_port:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🚀 Starting development server on http://localhost:{{port}}"
    echo "💡 Code changes will sync automatically with watch mode"
    echo "🛑 Press Ctrl+C to stop"
    DEV_LOCAL_PORT={{port}} docker compose up --watch


# Test production build locally
test-prod local_port=dev_local_port:
    #!/usr/bin/env bash
    set -euo pipefail
    trap 'docker stop $(docker ps -q --filter ancestor={{GCP_SERVICE_NAME}}) 2>/dev/null' EXIT
    echo "🚀 Starting production container on http://localhost:{{local_port}}"
    echo "⚠️  Note: Code changes require rebuilding the container"
    docker run -p {{local_port}}:{{port}} -e PORT={{port}} --rm {{GCP_SERVICE_NAME}}

# ==================== Build Commands ====================
# Build Docker image (defaults to host platform for speed)
build platform="":
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -z "{{platform}}" ]; then
        echo "🔨 Building Docker image for host platform..."
        docker build --build-arg PYTHON_IMAGE={{python_image}} -t {{GCP_SERVICE_NAME}} -t {{image_tag}} .
    else
        echo "🔨 Building Docker image for platform {{platform}}..."
        docker build --platform {{platform}} --build-arg PYTHON_IMAGE={{python_image}} -t {{GCP_SERVICE_NAME}} -t {{image_tag}} .
    fi

# Update dependencies
update:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "📦 Updating dependencies with dockerized uv..."
    docker run --rm -v $(pwd):/app -w /app {{python_image}} sh -c "pip install uv && uv lock --upgrade"
    echo "✅ Dependencies updated in uv.lock"

# Clean up local Docker images
clean:
    #!/usr/bin/env bash
    set -euo pipefail
    docker image rm {{GCP_SERVICE_NAME}} {{image_tag}} 2>/dev/null || true
    docker image prune -f
    echo "🧹 Local Docker images cleaned"

# Clean up old images from Artifact Registry
clean-registry keep="5":
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🧹 Cleaning old images from Artifact Registry (keeping {{keep}} most recent)..."
    
    images_to_delete=$(gcloud artifacts docker images list \
        {{region}}-docker.pkg.dev/{{project_id}}/{{GCP_ARTIFACT_REGISTRY_REPO}}/{{GCP_SERVICE_NAME}} \
        --sort-by=~create_time \
        --format="value(package)" | \
        tail -n +$(({{keep}} + 1)))
    
    if [ -z "$images_to_delete" ]; then
        echo "ℹ️  No old images to delete (found less than {{keep}} images)"
    else
        echo "$images_to_delete" | xargs -I {} gcloud artifacts docker images delete {} --quiet
        echo "✅ Registry cleaned"
    fi

# ==================== Deployment Commands ====================
# Deploy to Google Cloud Run
deploy: _validate-deployment _build-and-push
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🚀 Deploying to Cloud Run..."
    gcloud run deploy {{GCP_SERVICE_NAME}} \
        --image {{image_tag}} \
        --platform managed \
        --region {{region}} \
        --allow-unauthenticated \
        --project {{project_id}}
    echo "🌐 Service URL: $(gcloud run services describe {{GCP_SERVICE_NAME}} --region={{region}} --project={{project_id}} --format='value(status.url)')"

# Delete Cloud Run service
destroy:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🗑️  Deleting Cloud Run service..."
    if gcloud run services describe {{GCP_SERVICE_NAME}} --region={{region}} --project={{project_id}} &>/dev/null; then
        gcloud run services delete {{GCP_SERVICE_NAME}} --region {{region}} --project {{project_id}} --quiet
        echo "✅ Service deleted"
    else
        echo "ℹ️  Service not found"
    fi

# ==================== Monitoring Commands ====================
# Check service status
status:
    #!/usr/bin/env bash
    set -euo pipefail
    if gcloud run services describe {{GCP_SERVICE_NAME}} --region={{region}} --project={{project_id}} &>/dev/null; then
        echo "✅ Service is deployed"
        echo "🌐 URL: $(gcloud run services describe {{GCP_SERVICE_NAME}} --region={{region}} --project={{project_id}} --format='value(status.url)')"
        echo "📊 Ready: $(gcloud run services describe {{GCP_SERVICE_NAME}} --region={{region}} --project={{project_id}} --format='value(status.conditions[0].status)')"
    else
        echo "❌ Service not deployed"
        exit 1
    fi

# View service logs
logs limit="50":
    gcloud logging read \
        "resource.type=cloud_run_revision AND resource.labels.GCP_SERVICE_NAME={{GCP_SERVICE_NAME}}" \
        --limit={{limit}} \
        --project={{project_id}} \
        --format=json \
        | jq -r 'reverse | .[] | "[\(.timestamp | sub("\\.[0-9]+Z$"; "Z") | strptime("%Y-%m-%dT%H:%M:%SZ") | strftime("%Y-%m-%d %H:%M"))] \(.textPayload // .jsonPayload.message // "No message")"'

# ==================== Private Recipes (Template Method Pattern) ====================
# Validate deployment prerequisites
_validate-deployment:
    #!/usr/bin/env bash
    set -euo pipefail
    
    # Check project
    if [[ -z "{{project_id}}" || "{{project_id}}" == "(unset)" ]]; then
        echo "❌ No GCP project set. Run: gcloud config set project YOUR_PROJECT_ID"
        exit 1
    fi
    
    # Check tools
    for tool in gcloud docker; do
        if ! command -v $tool &> /dev/null; then
            echo "❌ $tool not found. Please install it."
            exit 1
        fi
    done
    
    # Check authentication
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        echo "❌ Not authenticated. Run: gcloud auth login"
        exit 1
    fi
    
    echo "✅ Deployment prerequisites validated"

# Build and push image (Factory pattern for Cloud Run images)
_build-and-push: _setup-registry
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🔨 Building Docker image for Cloud Run (linux/amd64)..."
    docker build --platform linux/amd64 --build-arg PYTHON_IMAGE={{python_image}} -t {{image_tag}} .
    echo "📤 Pushing to Artifact Registry..."
    docker push {{image_tag}}

# Setup Artifact Registry (Singleton pattern - ensures single repository)
_setup-registry:
    #!/usr/bin/env bash
    set -euo pipefail
    
    # Create repository if it doesn't exist
    if ! gcloud artifacts repositories describe {{GCP_ARTIFACT_REGISTRY_REPO}} \
        --location={{region}} \
        --project={{project_id}} &>/dev/null; then
        echo "📦 Creating Artifact Registry repository..."
        gcloud artifacts repositories create {{GCP_ARTIFACT_REGISTRY_REPO}} \
            --repository-format=docker \
            --location={{region}} \
            --project={{project_id}} \
            --description="Docker images for Cloud Run applications"
    fi
    
    # Configure Docker authentication
    gcloud auth configure-docker {{region}}-docker.pkg.dev --quiet