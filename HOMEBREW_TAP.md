# Homebrew Tap Setup Guide

This guide explains how to set up your own Homebrew tap for AeroSwitch distribution with automated formula updates.

## 🚀 Automated Setup (Recommended)

The GitHub Actions workflow will automatically update your Homebrew formula when you create releases!

## Step 1: Create a Homebrew Tap Repository

1. Create a new GitHub repository named `homebrew-aeroswitch`
   - Repository name MUST start with `homebrew-`
   - Make it public
   - Initialize with README

2. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/homebrew-aeroswitch.git
   cd homebrew-aeroswitch
   ```

## Step 2: Set Up Automated Formula Updates

1. Create the Formula directory:
   ```bash
   mkdir -p Formula
   ```

2. Copy the formula file:
   ```bash
   cp /path/to/aeroswitch/Formula/aeroswitch.rb Formula/
   ```

3. Copy the automation workflow:
   ```bash
   mkdir -p .github/workflows
   cp /path/to/aeroswitch/.github/workflows/update-homebrew-formula.yml .github/workflows/update-formula.yml
   ```

4. Update the formula:
   - Replace `yourusername` with your actual GitHub username in `Formula/aeroswitch.rb`

## Step 3: Configure GitHub Secrets

In your main AeroSwitch repository, add these secrets:

1. Go to Settings → Secrets and variables → Actions
2. Add these repository secrets:
   - `RELEASE_PLEASE_TOKEN`: A GitHub Personal Access Token with repo permissions
   - `HOMEBREW_TAP_TOKEN`: A GitHub Personal Access Token with repo permissions for the tap repository

## Step 4: Test the Setup

The automation will work when you:
1. Merge PRs to main (release-please will create a release PR)
2. Merge the release PR (this triggers the release and formula update)

## Step 3: Create GitHub Release

1. Create a release tag in your main AeroSwitch repository:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. Create a GitHub release:
   - Go to your AeroSwitch repo → Releases → New release
   - Choose tag v1.0.0
   - Upload the `aeroswitch-1.0.0-macos.tar.gz` file
   - Note the SHA256 from the .sha256 file

3. Update the formula with the correct SHA256:
   ```ruby
   sha256 "actual_sha256_hash_here"
   ```

## Step 4: Test the Formula

1. Test locally:
   ```bash
   brew install --build-from-source ./Formula/aeroswitch.rb
   ```

2. Test the tap:
   ```bash
   brew tap yourusername/aeroswitch
   brew install aeroswitch
   ```

## Step 5: Usage

Once published, users can install with:

```bash
# Add your tap
brew tap yourusername/aeroswitch

# Install AeroSwitch
brew install aeroswitch

# Or in one command
brew install yourusername/aeroswitch/aeroswitch
```

## Step 6: Updates

To release a new version:

1. Update the version in `Sources/main.swift`
2. Update the Makefile version
3. Build and test
4. Create new GitHub release
5. Update the formula with new URL and SHA256
6. Commit and push the formula changes

## Formula Validation

Before publishing, validate your formula:

```bash
brew audit --strict Formula/aeroswitch.rb
brew style Formula/aeroswitch.rb
```

## Notes

- The repository name must be `homebrew-something`
- The formula file must be in `Formula/` directory
- Formula name should match the binary name
- Make sure all URLs and hashes are correct before publishing