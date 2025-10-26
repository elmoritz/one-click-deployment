#!/usr/bin/env swift

import Foundation

// MARK: - Git Commit

struct GitCommit {
    let hash: String
    let subject: String

    var category: CommitCategory {
        let lower = subject.lowercased()

        if lower.contains("breaking") || lower.hasPrefix("!:") {
            return .breaking
        } else if lower.hasPrefix("feat:") || lower.hasPrefix("feature:") {
            return .features
        } else if lower.hasPrefix("fix:") {
            return .bugFixes
        } else if lower.hasPrefix("docs:") {
            return .documentation
        } else if lower.hasPrefix("perf:") {
            return .performance
        } else if lower.hasPrefix("refactor:") {
            return .refactoring
        } else if lower.hasPrefix("test:") {
            return .tests
        } else if lower.hasPrefix("chore:") || lower.hasPrefix("build:") || lower.hasPrefix("ci:") {
            return .chores
        } else {
            return .other
        }
    }

    var cleanSubject: String {
        subject
            .replacingOccurrences(of: #"^(feat|fix|docs|perf|refactor|test|chore|build|ci):\s*"#,
                                  with: "",
                                  options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }
}

enum CommitCategory {
    case breaking, features, bugFixes, performance, refactoring, documentation, tests, chores, other

    var title: String {
        switch self {
        case .breaking: return "### ⚠️  Breaking Changes"
        case .features: return "### ✨ Features"
        case .bugFixes: return "### 🐛 Bug Fixes"
        case .performance: return "### ⚡ Performance"
        case .refactoring: return "### ♻️  Refactoring"
        case .documentation: return "### 📚 Documentation"
        case .tests: return "### ✅ Tests"
        case .chores: return "### 🔧 Chores"
        case .other: return "### 🔧 Other Changes"
        }
    }
}

// MARK: - Git Operations

func getCommits(from: String?, to: String) -> [GitCommit] {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/git")

    let range = from.map { "\($0)..HEAD" } ?? "HEAD"
    process.arguments = [
        "log",
        range,
        "--pretty=format:%H|||%s",
        "--no-merges"
    ]

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = Pipe()

    try? process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else { return [] }

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    guard let output = String(data: data, encoding: .utf8) else { return [] }

    return output
        .split(separator: "\n")
        .compactMap { line in
            let parts = line.split(separator: "|||", maxSplits: 1)
            guard parts.count == 2 else { return nil }
            return GitCommit(
                hash: String(parts[0]),
                subject: String(parts[1])
            )
        }
}

// MARK: - Changelog Generation

func generateChangelog(commits: [GitCommit], version: String) -> String {
    var categorized: [CommitCategory: [GitCommit]] = [:]

    for commit in commits {
        categorized[commit.category, default: []].append(commit)
    }

    var lines: [String] = []
    lines.append("## \(version)")
    lines.append("")

    let orderedCategories: [CommitCategory] = [
        .breaking, .features, .bugFixes, .performance,
        .refactoring, .documentation, .tests, .chores, .other
    ]

    for category in orderedCategories {
        guard let commits = categorized[category], !commits.isEmpty else { continue }

        lines.append(category.title)
        lines.append("")

        for commit in commits {
            let shortHash = String(commit.hash.prefix(7))
            lines.append("- \(commit.cleanSubject) (\(shortHash))")
        }

        lines.append("")
    }

    return lines.joined(separator: "\n")
}

// MARK: - GitHub Actions Output

func setOutput(_ key: String, value: String) {
    guard let outputPath = ProcessInfo.processInfo.environment["GITHUB_OUTPUT"] else {
        print(value)
        return
    }

    // Use heredoc for multiline
    let output = "\(key)<<CHANGELOG_EOF\n\(value)\nCHANGELOG_EOF\n"
    if let fileHandle = FileHandle(forWritingAtPath: outputPath) {
        fileHandle.seekToEndOfFile()
        fileHandle.write(output.data(using: .utf8)!)
        fileHandle.closeFile()
    }
}

// MARK: - Main

guard CommandLine.arguments.count >= 2 else {
    print("Usage: changelog-generator.swift <to-version> [from-version]")
    exit(1)
}

let toVersion = CommandLine.arguments[1]
let fromVersion = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : nil

let commits = getCommits(from: fromVersion, to: toVersion)
let changelog = generateChangelog(commits: commits, version: toVersion)

print("✅ Changelog generated successfully")
print("")
print(changelog)

setOutput("changelog", value: changelog)
