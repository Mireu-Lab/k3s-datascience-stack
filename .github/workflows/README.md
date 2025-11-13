# GitHub Actions CI/CD for Container Images

This directory contains GitHub Actions workflows for automated container image building and deployment.

## Workflows

### 🐳 Build JupyterHub Custom Image

**File:** `build-jupyterhub-image.yml`

**Purpose:** Automatically builds and publishes the custom JupyterHub container image with NVIDIA CUDA, JAX, Spark, and Hadoop support.

**Triggers:**
- Push to `main` branch (when Dockerfile changes)
- Pull request to `main` branch (build only, no push)
- Manual workflow dispatch (with optional custom tag)

**Image Registry:** GitHub Container Registry (ghcr.io)

**Image Name:** `ghcr.io/mireu-lab/jupyterhub-cuda-jax`

**Tags:**
- `latest` - Latest build from main branch
- `main-<commit-sha>` - Specific commit from main
- Custom tag via manual dispatch

## Setup Instructions

### 1. Enable GitHub Container Registry

The workflow uses GitHub's built-in Container Registry. No additional setup needed.

### 2. Configure Package Visibility

After first build, make the package public (optional):

1. Go to https://github.com/orgs/Mireu-Lab/packages
2. Find `jupyterhub-cuda-jax` package
3. Click "Package settings"
4. Change visibility to "Public" (optional)

### 3. Using the Image in K3s

#### Option A: Public Image (No Authentication)

If package is public, use directly in `values.yaml`:

```yaml
singleuser:
  image:
    name: ghcr.io/mireu-lab/jupyterhub-cuda-jax
    tag: latest
    pullPolicy: Always
```

#### Option B: Private Image (Requires Authentication)

1. Create GitHub Personal Access Token:
   - Go to: https://github.com/settings/tokens
   - Click "Generate new token (classic)"
   - Select scope: `read:packages`
   - Copy the token

2. Create Kubernetes secret:

```bash
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_GITHUB_USERNAME \
  --docker-password=YOUR_GITHUB_TOKEN \
  --docker-email=YOUR_EMAIL \
  -n jupyterhub
```

3. Update `values.yaml`:

```yaml
singleuser:
  image:
    name: ghcr.io/mireu-lab/jupyterhub-cuda-jax
    tag: latest
    pullPolicy: Always
  imagePullSecrets:
    - name: ghcr-secret
```

## Manual Workflow Trigger

### Via GitHub UI

1. Go to: https://github.com/Mireu-Lab/k3s-datascience-stack/actions
2. Select "Build and Push JupyterHub Custom Image"
3. Click "Run workflow"
4. Optionally specify a custom tag
5. Click "Run workflow"

### Via GitHub CLI

```bash
# Trigger with default tags
gh workflow run build-jupyterhub-image.yml

# Trigger with custom tag
gh workflow run build-jupyterhub-image.yml -f tag=v1.0.0
```

## Monitoring Builds

### Check Build Status

```bash
# List recent workflow runs
gh run list --workflow=build-jupyterhub-image.yml

# Watch specific run
gh run watch <run-id>

# View run logs
gh run view <run-id> --log
```

### View Published Images

```bash
# List package versions
gh api /orgs/Mireu-Lab/packages/container/jupyterhub-cuda-jax/versions

# Or visit
# https://github.com/orgs/Mireu-Lab/packages/container/package/jupyterhub-cuda-jax
```

## Workflow Features

### ✅ Build Caching

Uses GitHub Actions cache to speed up builds:
- Layer caching with `cache-from: type=gha`
- Significantly faster rebuild times

### ✅ Multi-tagging

Automatic tagging strategy:
- `latest` for main branch
- Branch-specific tags
- SHA-based tags for traceability
- Custom tags via manual dispatch

### ✅ Metadata

Includes OCI image metadata:
- Title, description, vendor
- Source repository link
- Build date and revision
- License information

### ✅ Build Summary

Generates GitHub Actions summary with:
- Image tags and digest
- Usage instructions
- Direct copy-paste values.yaml snippet

## Updating the Image

### Method 1: Automatic (Recommended)

1. Edit `jupyterhub/Dockerfile`
2. Commit and push to main:
   ```bash
   git add jupyterhub/Dockerfile
   git commit -m "Update JupyterHub image: add new packages"
   git push origin main
   ```
3. Workflow triggers automatically
4. Image available in ~10-15 minutes

### Method 2: Manual Trigger

1. Go to Actions tab on GitHub
2. Select workflow
3. Click "Run workflow"
4. Wait for completion

### Method 3: Pull Request

1. Create branch and edit Dockerfile
2. Open PR to main
3. Workflow builds but doesn't push (for testing)
4. Merge PR to trigger actual build and push

## Troubleshooting

### Build Fails

Check logs:
```bash
gh run view --log
```

Common issues:
- Dockerfile syntax errors
- Network timeouts during package downloads
- Insufficient runner resources

### Image Pull Fails in K3s

Check authentication:
```bash
kubectl get secret ghcr-secret -n jupyterhub
kubectl describe pod <pod-name> -n jupyterhub
```

Verify image exists:
```bash
docker pull ghcr.io/mireu-lab/jupyterhub-cuda-jax:latest
```

### Workflow Not Triggering

Check workflow file syntax:
```bash
gh workflow view build-jupyterhub-image.yml
```

Ensure changes are in monitored paths:
- `jupyterhub/Dockerfile`
- `.github/workflows/build-jupyterhub-image.yml`

## Local Development

For local testing before pushing:

```bash
cd jupyterhub
bash 01-build-image.sh
# Follow prompts for local build
```

Note: Local builds are for testing only. Production deployments should use GitHub Actions-built images.

## Security Considerations

1. **Token Management**: Never commit GitHub tokens to repository
2. **Image Scanning**: Consider adding vulnerability scanning to workflow
3. **Base Image Updates**: Regularly update NVIDIA CUDA base image
4. **Secrets**: Store sensitive build args in GitHub Secrets

## Resources

- GitHub Actions Docs: https://docs.github.com/en/actions
- GitHub Container Registry: https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry
- Docker Build Action: https://github.com/docker/build-push-action
- Kubernetes Image Pull Secrets: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/
