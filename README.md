# Hummingbird Deployment Demo

The completed example for the [Todos with Postgres tutorial](https://docs.hummingbird.codes/2.0/tutorials/todos) with a **complete CI/CD pipeline** for automated deployment.

## Features

- **Hummingbird 2.0** Swift server framework
- **PostgreSQL** database integration
- **Complete CI/CD Pipeline** with GitHub Actions
- **One-Click Releases** with semantic versioning
- **Multi-architecture Docker images** (amd64 + arm64)
- **Automated testing** on every push
- **Security scanning** with Trivy
- **Swift script actions** - no bash, no compilation
- **Deployment examples** for VPS, Kubernetes, and AWS ECS

## Quick Start

### Running Locally

1. Start PostgreSQL:
   ```bash
   docker run -d -p 5432:5432 \
     -e POSTGRES_USER=hummingbird \
     -e POSTGRES_PASSWORD=password \
     -e POSTGRES_DB=hummingbird \
     postgres:16
   ```

2. Build and run:
   ```bash
   swift run App
   ```

3. Test the API:
   ```bash
   curl http://localhost:8080/health
   ```

### Running with Docker

```bash
export GITHUB_REPOSITORY=your-username/your-repo
export DB_PASSWORD=your-secure-password
docker-compose up -d
```

## CI/CD Pipeline

This project includes a production-ready CI/CD pipeline for automated deployment.

### One-Click Release

1. Go to **Actions** tab in GitHub
2. Select **Release and Deploy** workflow
3. Click **Run workflow**
4. Choose release type: **patch**, **minor**, or **major**
5. Click **Run workflow**

The pipeline will:
- Calculate the new version
- Run all tests
- Build Docker images (amd64 + arm64)
- Push to GitHub Container Registry
- Create GitHub release
- Deploy (if configured)

### Workflows

- **[Release and Deploy](.github/workflows/release.yml)**: One-click releases with deployment
- **[CI](.github/workflows/ci.yml)**: Automated testing on PRs and pushes
- **[Docker Cleanup](.github/workflows/docker-cleanup.yml)**: Clean up old images weekly

## Documentation

- **[DEPLOYMENT.md](DEPLOYMENT.md)**: Complete deployment guide
- **[Release Checklist](.github/RELEASE_CHECKLIST.md)**: Pre/post-release checklist
- **[VPS Deployment](.github/deployment-examples/vps-deployment.md)**: Deploy to VPS with Docker
- **[Kubernetes](.github/deployment-examples/kubernetes-deployment.yaml)**: K8s deployment manifests
- **[AWS ECS](.github/deployment-examples/aws-ecs-deployment.md)**: Deploy to AWS ECS

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Actions                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Version Calculation (Semantic Versioning)               │
│     ├─ patch: 1.0.0 → 1.0.1                                │
│     ├─ minor: 1.0.0 → 1.1.0                                │
│     └─ major: 1.0.0 → 2.0.0                                │
│                                                             │
│  2. Automated Testing                                       │
│     ├─ Swift tests (Ubuntu + macOS)                        │
│     └─ PostgreSQL integration tests                         │
│                                                             │
│  3. Docker Build                                            │
│     ├─ Multi-arch: amd64 + arm64                           │
│     ├─ Optimized production image                          │
│     └─ Push to GitHub Container Registry                    │
│                                                             │
│  4. Release Creation                                        │
│     ├─ Git tag (e.g., v1.2.3)                              │
│     ├─ GitHub Release with changelog                        │
│     └─ Release notes                                        │
│                                                             │
│  5. Deployment (Optional)                                   │
│     ├─ VPS via SSH                                         │
│     ├─ Kubernetes cluster                                   │
│     ├─ AWS ECS/Fargate                                     │
│     └─ Other platforms                                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Deployment Options

Choose a deployment target that fits your needs:

1. **VPS/Virtual Machine**: Cost-effective, full control
2. **Kubernetes**: Scalable, enterprise-grade
3. **AWS ECS**: Managed containers, AWS integration
4. **Cloud Run / Azure Container Apps**: Serverless containers

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed guides.

## Project Structure

```
.
├── .github/
│   ├── workflows/           # GitHub Actions workflows
│   │   ├── release.yml      # Release and deployment
│   │   ├── ci.yml           # Continuous integration
│   │   └── docker-cleanup.yml
│   ├── deployment-examples/ # Deployment guides
│   │   ├── vps-deployment.md
│   │   ├── kubernetes-deployment.yaml
│   │   └── aws-ecs-deployment.md
│   └── RELEASE_CHECKLIST.md
├── Sources/
│   └── App/                 # Hummingbird application
├── Tests/                   # Test suite
├── Dockerfile               # Production Docker image
├── docker-compose.yml       # Local development setup
├── Package.swift            # Swift package definition
└── DEPLOYMENT.md            # Complete deployment guide
```

## Development

### Running Tests

```bash
# Start test database
docker run -d -p 5432:5432 \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=hummingbird_test \
  postgres:16

# Run tests
swift test
```

### Local Development

```bash
# Watch for changes and rebuild
swift build --watch

# Run with custom port
swift run App --port 3000
```

## Tutorial

Follow the [Todos with Postgres tutorial](https://docs.hummingbird.codes/2.0/tutorials/todos) to learn how to build this application from scratch.

## License

This is a demonstration project for educational purposes.