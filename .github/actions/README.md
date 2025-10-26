# Swift GitHub Actions

Custom GitHub Actions written as **Swift scripts** - no compilation needed!

## Actions

### 1. Version Bumper ([version-bumper](./version-bumper))

Calculates semantic version bumps from git tags.

```yaml
- uses: ./.github/actions/version-bumper
  id: version
  with:
    release-type: 'minor'  # patch, minor, or major
```

**Outputs**: `new-version`, `old-version`

### 2. Changelog Generator ([changelog-generator](./changelog-generator))

Generates formatted changelogs from git commits using conventional commits.

```yaml
- uses: ./.github/actions/changelog-generator
  id: changelog
  with:
    from-version: 'v1.2.3'
    to-version: 'v1.3.0'
```

**Outputs**: `changelog`

### 3. Release Notifier ([release-notifier](./release-notifier))

Creates GitHub Actions summaries for releases.

```yaml
- uses: ./.github/actions/release-notifier
  with:
    version: 'v1.3.0'
    previous-version: 'v1.2.5'
    release-type: 'minor'
    image-tags: 'ghcr.io/user/repo:v1.3.0'
    deployment-status: 'success'
```

## Structure

Each action contains:
- `action.yml` - GitHub Action metadata
- `*.swift` - Swift script (executable)

```
version-bumper/
├── action.yml
└── version-bumper.swift
```

## Why Swift Scripts?

✅ **Simple**: Just one `.swift` file per action
✅ **No Compilation**: Runs directly with `swift` interpreter
✅ **Type-Safe**: Full Swift type system
✅ **Fast**: No build time in CI
✅ **Testable**: Can test locally with `swift <script>.swift`

## Testing Locally

```bash
# Version Bumper
cd .github/actions/version-bumper
chmod +x version-bumper.swift
./version-bumper.swift patch

# Changelog Generator
cd .github/actions/changelog-generator
chmod +x changelog-generator.swift
./changelog-generator.swift v1.3.0 v1.2.0

# Release Notifier
cd .github/actions/release-notifier
chmod +x release-notifier.swift
./release-notifier.swift v1.3.0 v1.2.5 minor
```

## Creating New Actions

1. Create directory: `.github/actions/my-action/`
2. Create `action.yml`:

```yaml
name: 'My Action'
description: 'Does something'
inputs:
  my-input:
    description: 'An input'
    required: true
outputs:
  my-output:
    description: 'An output'
    value: ${{ steps.run.outputs.my-output }}
runs:
  using: 'composite'
  steps:
    - id: run
      shell: bash
      run: |
        chmod +x ${{ github.action_path }}/my-action.swift
        ${{ github.action_path }}/my-action.swift "${{ inputs.my-input }}"
```

3. Create `my-action.swift`:

```swift
#!/usr/bin/env swift

import Foundation

// Get arguments
let myInput = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ""

// Your logic here
let result = "processed: \(myInput)"

// Output to GitHub Actions
if let outputPath = ProcessInfo.processInfo.environment["GITHUB_OUTPUT"] {
    let output = "my-output=\(result)\n"
    if let fileHandle = FileHandle(forWritingAtPath: outputPath) {
        fileHandle.seekToEndOfFile()
        fileHandle.write(output.data(using: .utf8)!)
        fileHandle.closeFile()
    }
}

print("✅ Done: \(result)")
```

4. Make executable:

```bash
chmod +x .github/actions/my-action/my-action.swift
```

Done! No Package.swift, no compilation, just simple Swift scripts.
