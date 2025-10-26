#!/usr/bin/env swift

import Foundation

// MARK: - Semantic Version

struct SemanticVersion {
    let major: Int
    let minor: Int
    let patch: Int

    init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    init(string: String) throws {
        let clean = string.hasPrefix("v") ? String(string.dropFirst()) : string
        let parts = clean.split(separator: ".").compactMap { Int($0) }

        guard parts.count == 3 else {
            throw VersionError.invalidFormat(string)
        }

        self.major = parts[0]
        self.minor = parts[1]
        self.patch = parts[2]
    }

    func bump(_ type: String) -> SemanticVersion {
        switch type {
        case "major":
            return SemanticVersion(major: major + 1, minor: 0, patch: 0)
        case "minor":
            return SemanticVersion(major: major, minor: minor + 1, patch: 0)
        case "patch":
            return SemanticVersion(major: major, minor: minor, patch: patch + 1)
        default:
            return self
        }
    }

    var description: String {
        "v\(major).\(minor).\(patch)"
    }
}

enum VersionError: Error {
    case invalidFormat(String)
}

// MARK: - Git Operations

func getLatestGitTag() -> String? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
    process.arguments = ["describe", "--tags", "--abbrev=0"]

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = Pipe()

    try? process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else { return nil }

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
}

// MARK: - GitHub Actions Output

func setOutput(_ key: String, value: String) {
    guard let outputPath = ProcessInfo.processInfo.environment["GITHUB_OUTPUT"] else {
        print("\(key)=\(value)")
        return
    }

    let output = "\(key)=\(value)\n"
    if let fileHandle = FileHandle(forWritingAtPath: outputPath) {
        fileHandle.seekToEndOfFile()
        fileHandle.write(output.data(using: .utf8)!)
        fileHandle.closeFile()
    }
}

// MARK: - Main

guard CommandLine.arguments.count > 1 else {
    print("Usage: version-bumper.swift <release-type>")
    exit(1)
}

let releaseType = CommandLine.arguments[1]

do {
    // Get current version from git tags
    let currentTag = getLatestGitTag() ?? "v0.0.0"
    let currentVersion = try SemanticVersion(string: currentTag)

    // Bump version
    let newVersion = currentVersion.bump(releaseType)

    // Output
    print("✅ Version bump: \(currentVersion.description) → \(newVersion.description)")
    setOutput("old-version", value: currentVersion.description)
    setOutput("new-version", value: newVersion.description)

} catch {
    print("❌ Error: \(error)")
    exit(1)
}
