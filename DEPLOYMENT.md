# Deployment Guide

This project includes a complete CI/CD pipeline using GitHub Actions for automated testing, building, and deployment of your Hummingbird Swift server application.

## Overview

The CI/CD pipeline provides:

- **Automated Testing**: Runs on every push and pull request
- **One-Click Releases**: Choose release type (patch/minor/major) from GitHub Actions
- **Automatic Version Bumping**: Semantic versioning based on release type
- **Docker Image Building**: Multi-architecture (amd64/arm64) images pushed to GitHub Container Registry
- **Automated Deployment**: Deploy to your chosen platform
- **Security Scanning**: Vulnerability scanning with Trivy
- **Swift Script Actions**: Simple, type-safe GitHub Actions written as Swift scripts

## Swift Script Actions

This project uses **Swift scripts** for GitHub Actions instead of bash:

✅ **Simple**: One `.swift` file per action, no compilation needed
✅ **Type-Safe**: Swift type system instead of string manipulation
✅ **Fast**: Runs directly, no build time
✅ **Maintainable**: Clear, readable Swift code
✅ **Testable**: Test locally with `./script.swift args`

See [.github/actions/README.md](.github/actions/README.md) for how to use and create them.

## Quick Start

### 1. Initial Setup

1. **Enable GitHub Container Registry**
   - Go to your repository Settings > Actions > General
   - Under "Workflow permissions", select "Read and write permissions"
   - Save

2. **Configure Secrets** (if deploying)
   - Go to Settings > Secrets and variables > Actions
   - Add deployment-specific secrets (see deployment guides below)

### 2. Running Your First Release

1. Go to the **Actions** tab in your GitHub repository
2. Select the **Release and Deploy** workflow
3. Click **Run workflow**
4. Choose your release type:
   - **patch**: Bug fixes (1.0.0 → 1.0.1)
   - **minor**: New features, backwards compatible (1.0.0 → 1.1.0)
   - **major**: Breaking changes (1.0.0 → 2.0.0)
5. Click **Run workflow**

The workflow will:
- Calculate the new version number
- Run all tests
- Build multi-architecture Docker images
- Push images to GitHub Container Registry
- Create a Git tag and GitHub release
- Deploy (if configured)

## Workflows

### 1. Release and Deploy ([.github/workflows/release.yml](.github/workflows/release.yml))

**Trigger**: Manual (workflow_dispatch)

**What it does**:
- Calculates next version based on selected release type
- Runs tests with PostgreSQL
- Builds and pushes Docker images (amd64 + arm64)
- Creates Git tag and GitHub release
- Deploys application (if enabled)

**Jobs**:
1. **version**: Calculate semantic version
2. **test**: Run Swift tests with PostgreSQL
3. **build-and-push**: Build multi-arch Docker images
4. **create-release**: Create GitHub release with changelog
5. **deploy**: Deploy to your platform (disabled by default)
6. **notify**: Send deployment notifications

### 2. CI ([.github/workflows/ci.yml](.github/workflows/ci.yml))

**Trigger**: Push to main/develop, Pull Requests

**What it does**:
- Runs SwiftLint for code quality
- Tests on Ubuntu and macOS
- Builds Docker image
- Security scanning with Trivy

### 3. Docker Cleanup ([.github/workflows/docker-cleanup.yml](.github/workflows/docker-cleanup.yml))

**Trigger**: Weekly (Sundays at 2 AM UTC) or manual

**What it does**:
- Removes old Docker images from GitHub Container Registry
- Keeps at least 5 most recent images
- Deletes images older than 1 week

## Version Management

### How Versioning Works

The pipeline uses **semantic versioning** (semver):

```
MAJOR.MINOR.PATCH
```

- **MAJOR**: Incompatible API changes (breaking changes)
- **MINOR**: New functionality, backwards-compatible
- **PATCH**: Bug fixes, backwards-compatible

### Version Bumping

Starting from the latest Git tag (or v0.0.0 if no tags exist):

| Release Type | Example          | Use Case                |
|--------------|------------------|-------------------------|
| patch        | 1.2.3 → 1.2.4    | Bug fixes               |
| minor        | 1.2.3 → 1.3.0    | New features            |
| major        | 1.2.3 → 2.0.0    | Breaking changes        |

### Version Tags

Each release creates:
- A Git tag (e.g., `v1.2.3`)
- A GitHub release with changelog
- Docker images tagged with:
  - Full version: `v1.2.3`
  - Minor version: `1.2`
  - Major version: `1`
  - Latest: `latest`

## Docker Images

### Registry

Images are pushed to GitHub Container Registry:
```
ghcr.io/<your-username>/<your-repo>:latest
ghcr.io/<your-username>/<your-repo>:v1.2.3
```

### Multi-Architecture Support

Images are built for:
- `linux/amd64` (x86_64)
- `linux/arm64` (ARM, Apple Silicon)

### Using the Images

Pull and run locally:
```bash
docker pull ghcr.io/<your-username>/<your-repo>:latest
docker run -p 8080:8080 ghcr.io/<your-username>/<your-repo>:latest
```

Or use with docker-compose:
```bash
export GITHUB_REPOSITORY=<your-username>/<your-repo>
export DB_PASSWORD=your-secure-password
docker-compose up -d
```

## Deployment Options

The pipeline supports multiple deployment targets. Choose one that fits your needs:

### Option 1: VPS/Virtual Machine

Deploy to any server with Docker installed.

**Best for**: Small to medium applications, cost-effective hosting

**Setup**: See [.github/deployment-examples/vps-deployment.md](.github/deployment-examples/vps-deployment.md)

**Requirements**:
- VPS with Docker and Docker Compose
- SSH access
- Reverse proxy (Nginx/Caddy) for HTTPS

### Option 2: Kubernetes

Deploy to any Kubernetes cluster (GKE, EKS, AKS, self-hosted).

**Best for**: Large-scale applications, microservices, high availability

**Setup**: See [.github/deployment-examples/kubernetes-deployment.yaml](.github/deployment-examples/kubernetes-deployment.yaml)

**Features**:
- Auto-scaling based on CPU/memory
- Rolling updates
- Health checks
- Load balancing

### Option 3: AWS ECS

Deploy to AWS Elastic Container Service with Fargate.

**Best for**: AWS-native deployments, serverless containers

**Setup**: See [.github/deployment-examples/aws-ecs-deployment.md](.github/deployment-examples/aws-ecs-deployment.md)

**Features**:
- Managed container orchestration
- Auto-scaling
- Integration with AWS services (RDS, CloudWatch, etc.)
- Cost-effective with Fargate Spot

### Other Options

The workflow can be adapted for:
- **Google Cloud Run**: Serverless container platform
- **Azure Container Apps**: Serverless containers on Azure
- **Railway/Render/Fly.io**: Platform-as-a-Service providers
- **DigitalOcean App Platform**: Managed container hosting

## Configuration

### Environment Variables

Your application may need these environment variables:

```bash
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=hummingbird
DATABASE_USER=hummingbird
DATABASE_PASSWORD=your-secure-password
LOG_LEVEL=info
```

### Health Checks

The workflow expects a `/health` endpoint. Add one to your application:

```swift
app.get("health") { req -> String in
    return "OK"
}
```

For a more comprehensive health check:

```swift
app.get("health") { req async throws -> HTTPResponse.Status in
    // Check database connection
    try await req.db.raw("SELECT 1").run()
    return .ok
}
```

## Monitoring and Observability

### Recommended Additions

1. **Logging**:
   - Use structured logging
   - Send logs to CloudWatch, Datadog, or Grafana Loki
   - Track request IDs for distributed tracing

2. **Metrics**:
   - Expose Prometheus metrics
   - Track request latency, error rates, throughput
   - Monitor database connection pools

3. **Tracing**:
   - Implement distributed tracing with OpenTelemetry
   - Track request flows through your application

4. **Alerts**:
   - Set up alerts for error rates
   - Monitor resource usage (CPU, memory)
   - Alert on deployment failures

### Example: Adding Prometheus Metrics

```swift
import Prometheus

// Add to your application setup
let prometheus = PrometheusMetrics()
app.middleware.use(prometheus)

// Custom metrics
let requestCounter = prometheus.counter(
    name: "http_requests_total",
    helpText: "Total HTTP requests"
)
```

## Security Best Practices

### 1. Secrets Management

✅ **DO**:
- Store secrets in GitHub Secrets
- Use environment variables
- Rotate secrets regularly
- Use AWS Secrets Manager / HashiCorp Vault in production

❌ **DON'T**:
- Commit secrets to Git
- Hardcode credentials
- Share secrets in plain text

### 2. Container Security

✅ **DO**:
- Run containers as non-root user (already configured)
- Scan images for vulnerabilities (Trivy in CI)
- Keep base images updated
- Use minimal base images

### 3. Network Security

✅ **DO**:
- Use HTTPS/TLS in production
- Implement rate limiting
- Use security headers
- Configure firewalls properly

## Troubleshooting

### Build Fails

**Check**:
- Swift version compatibility
- Package dependencies
- Build logs in Actions tab

### Tests Fail

**Check**:
- Database connection in tests
- Environment variables
- Test logs

### Deployment Fails

**Check**:
- GitHub Secrets configured correctly
- Deployment target accessible
- Docker image pulled successfully
- Application logs

### Docker Image Issues

**Pull latest image**:
```bash
docker pull ghcr.io/<your-username>/<your-repo>:latest
```

**Check image exists**:
```bash
docker images | grep <your-repo>
```

**View container logs**:
```bash
docker logs <container-id>
```

## Advanced Topics

### Custom Deployment Logic

Edit the `deploy` job in [.github/workflows/release.yml](.github/workflows/release.yml):

```yaml
deploy:
  name: Deploy Application
  runs-on: ubuntu-latest
  needs: [version, build-and-push, create-release]
  if: true  # Enable deployment

  steps:
    - name: Your Custom Deployment
      run: |
        # Your deployment commands
```

### Database Migrations

Add a migration step before deployment:

```yaml
- name: Run Migrations
  run: |
    docker run --rm \
      -e DATABASE_URL=${{ secrets.DATABASE_URL }} \
      ghcr.io/${{ github.repository }}:${{ needs.version.outputs.new_version }} \
      ./migrate
```

### Blue-Green Deployment

Implement zero-downtime deployments:

1. Deploy new version to separate environment
2. Run health checks
3. Switch traffic to new version
4. Keep old version for rollback

### Rollback

To rollback to a previous version:

1. Go to Actions > Release and Deploy
2. Select a previous successful run
3. Re-run the workflow
4. Or manually deploy a previous tag:
   ```bash
   docker pull ghcr.io/<your-username>/<your-repo>:v1.2.2
   ```

## Cost Considerations

### GitHub Actions

- 2000 free minutes/month for private repos
- Unlimited for public repos
- Additional minutes: $0.008/minute

### Storage (Container Registry)

- 500 MB free for private repos
- Unlimited for public repos
- Additional: $0.25/GB/month

### Optimization Tips

1. Use caching for Swift packages
2. Clean up old Docker images
3. Use Fargate Spot for non-production
4. Right-size your containers

## Support

### Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Hummingbird Documentation](https://docs.hummingbird.codes/)
- [Docker Documentation](https://docs.docker.com/)

### Getting Help

1. Check workflow logs in Actions tab
2. Review deployment guide for your platform
3. Open an issue in your repository
4. Check Hummingbird community forums

## Next Steps

1. **Run your first release**: Test the workflow
2. **Configure deployment**: Choose and set up a deployment target
3. **Add monitoring**: Implement logging and metrics
4. **Set up alerts**: Get notified of issues
5. **Document your API**: Add OpenAPI/Swagger documentation
6. **Add more tests**: Increase code coverage
7. **Implement CI/CD best practices**: Review and improve your pipeline

---

## Example: Complete Deployment Flow

```bash
# 1. Developer makes changes
git checkout -b feature/new-endpoint
# ... make changes ...
git commit -m "Add new API endpoint"
git push origin feature/new-endpoint

# 2. Create PR - CI runs automatically
# - SwiftLint checks code
# - Tests run on Ubuntu and macOS
# - Docker build test
# - Security scan

# 3. Merge PR to main
git checkout main
git merge feature/new-endpoint
git push origin main

# 4. Create release (via GitHub Actions UI)
# - Select "Release and Deploy" workflow
# - Choose release type: "minor"
# - Click "Run workflow"

# 5. Workflow runs
# - Version: 1.2.0 → 1.3.0
# - Tests pass
# - Docker image built and pushed
# - GitHub release created
# - Application deployed

# 6. Verify deployment
curl https://your-domain.com/health
# Response: OK
```

That's it! You now have a production-ready CI/CD pipeline for your Hummingbird application.
