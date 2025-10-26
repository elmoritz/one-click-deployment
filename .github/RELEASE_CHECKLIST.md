# Release Checklist

Use this checklist when creating a new release.

## Pre-Release

- [ ] All tests passing locally
- [ ] Code reviewed and merged to main
- [ ] Database migrations tested (if any)
- [ ] Breaking changes documented (for major releases)
- [ ] CHANGELOG updated (optional - auto-generated)
- [ ] Dependencies updated and tested

## Creating Release

1. Go to **Actions** tab
2. Select **Release and Deploy** workflow
3. Click **Run workflow**
4. Select release type:
   - [ ] **patch** - Bug fixes only (x.y.Z)
   - [ ] **minor** - New features, backwards compatible (x.Y.0)
   - [ ] **major** - Breaking changes (X.0.0)
5. Click **Run workflow** button

## Post-Release Verification

- [ ] Workflow completed successfully
- [ ] Git tag created (check Tags)
- [ ] GitHub Release created with changelog
- [ ] Docker images pushed to GHCR
- [ ] Deployment successful (if enabled)
- [ ] Application health check passing
- [ ] Monitor logs for errors (first 15 minutes)
- [ ] Verify new features/fixes in production

## Rollback (if needed)

If the release has issues:

1. Go to previous successful workflow run
2. Click **Re-run all jobs**
3. Or manually revert:
   ```bash
   # Tag the current bad release as bad
   git tag -d v1.2.3
   git push --delete origin v1.2.3

   # Deploy previous version
   docker pull ghcr.io/username/repo:v1.2.2
   ```

## Communication

- [ ] Notify team of release
- [ ] Update documentation (if needed)
- [ ] Announce breaking changes (for major releases)
- [ ] Update API documentation (if endpoints changed)

## Monitoring

After release, monitor:

- [ ] Error rates
- [ ] Response times
- [ ] Resource usage (CPU, memory)
- [ ] Database connections
- [ ] User reports/feedback

---

## Release Type Guide

### Patch (x.y.Z)

**Use for**:
- Bug fixes
- Security patches
- Documentation fixes
- Performance improvements (non-breaking)

**Example**: 1.2.3 → 1.2.4

### Minor (x.Y.0)

**Use for**:
- New features (backwards compatible)
- New API endpoints
- Deprecations (with backwards compatibility)
- Significant improvements

**Example**: 1.2.3 → 1.3.0

### Major (X.0.0)

**Use for**:
- Breaking API changes
- Removed features
- Major architectural changes
- Database schema changes (breaking)

**Example**: 1.2.3 → 2.0.0

---

## Common Issues

### Workflow fails on tests
- Check database connection
- Review test logs
- Verify environment variables

### Docker build fails
- Check Dockerfile syntax
- Verify dependencies resolve
- Check disk space in Actions runner

### Deployment fails
- Verify secrets configured
- Check deployment target health
- Review deployment logs

### Image not found
- Wait for build to complete
- Check GHCR permissions
- Verify repository name
