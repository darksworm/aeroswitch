# AeroSwitch Release Workflow

This document explains the automated release pipeline for AeroSwitch.

## 🔄 Automated Release Process

### 1. Development Workflow

```bash
# Make changes
git checkout -b feature/new-feature
# ... make your changes ...
git commit -m "feat: add new feature"
git push origin feature/new-feature
```

Create a PR → Merge to main → Release-please automatically creates a release PR

### 2. Release Workflow

When you merge the release PR created by release-please:

1. **Release Creation**: A new GitHub release is created
2. **Build**: Swift project is built in release mode
3. **Archive**: Release archive is created with checksums
4. **Upload**: Archive and checksums are uploaded to the release
5. **Homebrew Update**: Formula in tap repository is automatically updated

## 🛠️ Workflows

### `build.yml` - Build and Test
- **Triggers**: Pull requests and pushes to main
- **Matrix**: Tests both debug and release builds
- **Features**:
  - Caches Swift dependencies
  - Tests CLI commands (`--version`, `--help`)
  - Verifies binary size
  - Runs on macOS with latest Xcode

### `release-please.yml` - Release Management
- **Triggers**: Pushes to main
- **Features**:
  - Creates release PRs automatically
  - Builds and uploads release artifacts
  - Updates Homebrew formula automatically
  - Uses semantic versioning

## 📋 Prerequisites

### GitHub Secrets Required

In your main repository settings:

1. **`RELEASE_PLEASE_TOKEN`**
   - Personal Access Token with `repo` permissions
   - Used by release-please to create PRs and releases

2. **`HOMEBREW_TAP_TOKEN`**
   - Personal Access Token with `repo` permissions  
   - Used to update the Homebrew tap repository
   - Must have access to `yourusername/homebrew-aeroswitch`

### Homebrew Tap Repository

1. Create `yourusername/homebrew-aeroswitch` repository
2. Add the formula file to `Formula/aeroswitch.rb`
3. Add the update workflow to `.github/workflows/update-formula.yml`

## 🚀 Making a Release

### Option 1: Automatic (Recommended)
1. Merge PRs to main with conventional commit messages:
   - `feat:` for new features
   - `fix:` for bug fixes
   - `docs:` for documentation
   - `chore:` for maintenance

2. Release-please will create a release PR
3. Review and merge the release PR
4. Everything else is automated!

### Option 2: Manual
1. Update version in `Sources/main.swift`
2. Update version in `Makefile`
3. Create a git tag: `git tag v1.0.1`
4. Push the tag: `git push origin v1.0.1`
5. The release workflow will trigger

## 📊 Release Artifacts

Each release includes:
- `aeroswitch-X.Y.Z-macos.tar.gz` - Binary archive
- `aeroswitch-X.Y.Z-macos.tar.gz.sha256` - Checksum file

## 🍺 Homebrew Integration

After release, users can install with:
```bash
brew tap yourusername/aeroswitch
brew install aeroswitch
```

The formula is automatically updated with:
- New version number
- New download URL
- New SHA256 checksum

## 🔍 Troubleshooting

### Build Failures
- Check that the code compiles locally with `swift build -c release`
- Verify all tests pass with `swift test`

### Release-Please Issues
- Ensure conventional commit format
- Check that `RELEASE_PLEASE_TOKEN` has proper permissions

### Homebrew Update Failures
- Verify `HOMEBREW_TAP_TOKEN` has access to tap repository
- Check that the tap repository exists and has the workflow

### Manual Testing
```bash
# Test build locally
make release

# Test archive creation
make archive

# Test the binary
.build/release/aeroswitch --version
```

## 📝 Version Management

Versions are managed automatically by release-please based on commit messages:

- `feat:` → Minor version bump (1.0.0 → 1.1.0)
- `fix:` → Patch version bump (1.0.0 → 1.0.1)  
- `feat!:` or `BREAKING CHANGE:` → Major version bump (1.0.0 → 2.0.0)

## 🎯 Best Practices

1. **Use conventional commits** for automatic version management
2. **Test locally** before pushing
3. **Review release PRs** carefully before merging
4. **Monitor workflows** in the Actions tab
5. **Keep documentation updated** with new features