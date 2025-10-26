#!/usr/bin/env swift

import Foundation

// MARK: - Arguments

guard CommandLine.arguments.count >= 4 else {
    print("Usage: release-notifier.swift <version> <previous-version> <release-type> [image-tags] [deployment-status]")
    exit(1)
}

let version = CommandLine.arguments[1]
let previousVersion = CommandLine.arguments[2]
let releaseType = CommandLine.arguments[3]
let imageTags = CommandLine.arguments.count > 4 ? CommandLine.arguments[4] : nil
let deploymentStatus = CommandLine.arguments.count > 5 ? CommandLine.arguments[5] : nil
let repository = ProcessInfo.processInfo.environment["GITHUB_REPOSITORY"] ?? "unknown/repo"

// MARK: - Summary Generation

func generateSummary() -> String {
    var lines: [String] = []

    lines.append("# 🚀 Release Summary")
    lines.append("")
    lines.append("## Version Information")
    lines.append("")
    lines.append("| Item | Value |")
    lines.append("|------|-------|")
    lines.append("| **New Version** | `\(version)` |")
    lines.append("| **Previous Version** | `\(previousVersion)` |")
    lines.append("| **Release Type** | `\(releaseType)` |")
    lines.append("")

    if let tags = imageTags, !tags.isEmpty {
        lines.append("## 🐳 Docker Images")
        lines.append("")
        lines.append("```")
        for tag in tags.split(separator: ",") {
            lines.append(tag.trimmingCharacters(in: .whitespaces))
        }
        lines.append("```")
        lines.append("")

        lines.append("Pull the image:")
        lines.append("```bash")
        lines.append("docker pull ghcr.io/\(repository):\(version)")
        lines.append("```")
        lines.append("")
    }

    if let status = deploymentStatus {
        lines.append("## 📦 Deployment")
        lines.append("")
        let emoji = status == "success" ? "✅" : (status == "skipped" ? "⏭️ " : "❌")
        lines.append("\(emoji) Status: **\(status)**")
        lines.append("")
    }

    lines.append("## 📋 Next Steps")
    lines.append("")
    lines.append("- [ ] Verify deployment health")
    lines.append("- [ ] Monitor application logs")
    lines.append("- [ ] Check error rates and metrics")
    lines.append("- [ ] Update documentation if needed")
    lines.append("")

    return lines.joined(separator: "\n")
}

// MARK: - GitHub Actions Output

func writeSummary(_ content: String) {
    guard let summaryPath = ProcessInfo.processInfo.environment["GITHUB_STEP_SUMMARY"] else {
        print(content)
        return
    }

    if let fileHandle = FileHandle(forWritingAtPath: summaryPath) {
        fileHandle.seekToEndOfFile()
        fileHandle.write(content.data(using: .utf8)!)
        fileHandle.closeFile()
    }
}

// MARK: - Main

let summary = generateSummary()
writeSummary(summary)

print("✅ Release summary generated")
print("")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🚀 Release Complete!")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("")
print("Version:      \(previousVersion) → \(version)")
print("Release Type: \(releaseType)")
if let status = deploymentStatus {
    print("Deployment:   \(status)")
}
print("")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
