#!/usr/bin/env swift

// ⚠️ xcstrings → Swift enum code generator
// Usage: swift Scripts/GenerateStrings.swift
// Or:    make strings
//
// Array Group Convention:
//   Keys with a numeric prefix in their last segment (e.g. "reader.setting.transition.0_paging")
//   are automatically grouped into a [String] array property.
//   The property name is derived from the parent prefix's last segment + "Items".
//   Example: "reader.setting.transition.0_paging" → transitionItems[0]

import Foundation

// MARK: - Models

struct ModuleConfig {
  let xcstringsPath: String
  let outputPath: String
  let prefix: String
  let enumName: String
  let bundlePropertyName: String
  let bundleTokenClassName: String
}

struct StringEntry {
  let fullKey: String
  let baseKey: String
  let propertyName: String
  let formatSpecifier: String?
  let section: String
  let englishValue: String?
}

struct DetectedArrayGroup {
  let propertyName: String
  let keys: [String] // ordered by numeric prefix
}

// MARK: - Helpers

func toCamelCase(_ dotPath: String) -> String {
  let segments = dotPath.split(separator: ".").map(String.init)
  let words = segments.flatMap { $0.split(separator: "_").map(String.init) }
  guard let first = words.first else { return "" }
  let rest = words.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst() }
  return first.lowercased() + rest.joined()
}

func sectionTitle(_ segment: String) -> String {
  segment.split(separator: "_")
    .map { $0.prefix(1).uppercased() + $0.dropFirst() }
    .joined(separator: " ")
}

func englishValue(for key: String, in strings: [String: Any]) -> String? {
  guard let entry = strings[key] as? [String: Any],
        let localizations = entry["localizations"] as? [String: Any],
        let en = localizations["en"] as? [String: Any],
        let stringUnit = en["stringUnit"] as? [String: Any],
        let value = stringUnit["value"] as? String else { return nil }
  return value
}

func swiftType(for specifier: String) -> String {
  switch specifier {
  case "%@": return "String"
  case "%lld": return "Int"
  default: return "String"
  }
}

/// Check if a string's last dot-segment starts with a digit followed by underscore (e.g. "0_paging")
func isArrayGroupKey(_ key: String) -> Bool {
  guard let lastSegment = key.split(separator: ".").last else { return false }
  let s = String(lastSegment)
  guard let underscoreIdx = s.firstIndex(of: "_") else { return false }
  let numPart = s[s.startIndex..<underscoreIdx]
  return !numPart.isEmpty && numPart.allSatisfy(\.isNumber)
}

/// Extract the numeric order from a key's last segment (e.g. "reader.setting.transition.0_paging" → 0)
func arrayGroupOrder(_ key: String) -> Int {
  guard let lastSegment = key.split(separator: ".").last else { return 0 }
  let s = String(lastSegment)
  guard let underscoreIdx = s.firstIndex(of: "_") else { return 0 }
  return Int(s[s.startIndex..<underscoreIdx]) ?? 0
}

/// Extract parent prefix from a key (e.g. "reader.setting.transition.0_paging" → "reader.setting.transition")
func arrayGroupPrefix(_ key: String) -> String {
  let segments = key.split(separator: ".")
  return segments.dropLast().map(String.init).joined(separator: ".")
}

/// Generate property name from prefix (e.g. "reader.setting.transition" → "transitionItems")
func arrayGroupPropertyName(_ prefix: String) -> String {
  guard let lastSegment = prefix.split(separator: ".").last else { return "items" }
  let camel = toCamelCase(String(lastSegment))
  return camel + "Items"
}

// MARK: - Array Group Detection

func detectArrayGroups(keys: [String]) -> [DetectedArrayGroup] {
  // Find keys with numeric prefix pattern
  var groupMap: [String: [(order: Int, key: String)]] = [:]

  for key in keys {
    guard isArrayGroupKey(key) else { continue }
    let prefix = arrayGroupPrefix(key)
    let order = arrayGroupOrder(key)
    groupMap[prefix, default: []].append((order, key))
  }

  // Sort groups by prefix, items by order
  return groupMap.keys.sorted().map { prefix in
    let items = groupMap[prefix]!.sorted { $0.order < $1.order }
    return DetectedArrayGroup(
      propertyName: arrayGroupPropertyName(prefix),
      keys: items.map(\.key)
    )
  }
}

// MARK: - Project Root

let projectRoot: URL = {
  // When run by xcodebuild, SRCROOT points to the module project directory
  if let srcRoot = ProcessInfo.processInfo.environment["SRCROOT"] {
    // Walk up from SRCROOT until we find the Tuist directory (project root marker)
    var url = URL(fileURLWithPath: srcRoot)
    while url.path != "/" {
      if FileManager.default.fileExists(atPath: url.appendingPathComponent("Tuist").path) {
        return url
      }
      url = url.deletingLastPathComponent()
    }
  }
  // When run from CLI, use script location
  return URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
}()

// MARK: - Generation

func generate(config: ModuleConfig) throws {
  let xcstringsURL = projectRoot.appendingPathComponent(config.xcstringsPath)
  let outputURL = projectRoot.appendingPathComponent(config.outputPath)

  let data = try Data(contentsOf: xcstringsURL)
  guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
        let strings = json["strings"] as? [String: Any] else {
    print("Error: Failed to parse \(config.xcstringsPath)")
    return
  }

  let allKeys = Array(strings.keys)

  // Auto-detect array groups
  let arrayGroups = detectArrayGroups(keys: allKeys)
  let arrayGroupKeySet = Set(arrayGroups.flatMap { $0.keys })

  // Parse individual entries (excluding array group keys and non-prefixed keys)
  var entries: [StringEntry] = []

  for key in allKeys {
    // Skip array group keys
    if arrayGroupKeySet.contains(key) { continue }

    // Extract format specifier (separated by space in key)
    let parts = key.split(separator: " ", maxSplits: 1)
    let baseKey = String(parts[0])
    let formatSpecifier = parts.count > 1 ? String(parts[1]) : nil

    // Remove module prefix
    guard baseKey.hasPrefix(config.prefix) else { continue }
    let stripped = String(baseKey.dropFirst(config.prefix.count))

    // Get section (first segment after prefix)
    let sectionSegment = stripped.split(separator: ".").first.map(String.init) ?? stripped

    // Convert to camelCase
    let propertyName = toCamelCase(stripped)

    entries.append(StringEntry(
      fullKey: key,
      baseKey: baseKey,
      propertyName: propertyName,
      formatSpecifier: formatSpecifier,
      section: sectionSegment,
      englishValue: englishValue(for: key, in: strings)
    ))
  }

  // Sort entries by base key for deterministic output
  entries.sort { $0.baseKey < $1.baseKey }

  // Group by section, preserving order of first appearance (sorted)
  var sectionOrder: [String] = []
  var sectionMap: [String: [StringEntry]] = [:]

  for entry in entries {
    if sectionMap[entry.section] == nil {
      sectionOrder.append(entry.section)
    }
    sectionMap[entry.section, default: []].append(entry)
  }

  // Build output
  var lines: [String] = []

  lines.append("// ⚠️ This file is auto-generated by Scripts/GenerateStrings.swift")
  lines.append("// Do not edit manually. Run `make strings` to regenerate.")
  lines.append("")
  lines.append("import Foundation")
  lines.append("")
  lines.append("// MARK: - Bundle")
  lines.append("")
  lines.append("private final class \(config.bundleTokenClassName) {}")
  lines.append("")
  lines.append("extension Bundle {")
  lines.append("  static let \(config.bundlePropertyName) = Bundle(for: \(config.bundleTokenClassName).self)")
  lines.append("}")
  lines.append("")
  lines.append("// MARK: - \(config.enumName)")
  lines.append("")
  lines.append("enum \(config.enumName) {")

  for (sectionIndex, section) in sectionOrder.enumerated() {
    guard let sectionEntries = sectionMap[section] else { continue }

    if sectionIndex > 0 { lines.append("") }
    lines.append("  // MARK: - \(sectionTitle(section))")

    for entry in sectionEntries {
      lines.append("")
      if let enValue = entry.englishValue {
        lines.append("  /// \(enValue)")
      }
      if let specifier = entry.formatSpecifier {
        let type = swiftType(for: specifier)
        lines.append("  static func \(entry.propertyName)(_ arg0: \(type)) -> String {")
        lines.append("    String(localized: \"\(entry.baseKey) \\(arg0)\", bundle: .\(config.bundlePropertyName))")
        lines.append("  }")
      } else {
        lines.append("  static var \(entry.propertyName): String {")
        lines.append("    String(localized: \"\(entry.baseKey)\", bundle: .\(config.bundlePropertyName))")
        lines.append("  }")
      }
    }
  }

  // Generate auto-detected array groups
  if !arrayGroups.isEmpty {
    lines.append("")
    lines.append("  // MARK: - Segment Items")

    for group in arrayGroups {
      let enValues = group.keys.compactMap { englishValue(for: $0, in: strings) }
      lines.append("")
      if !enValues.isEmpty {
        lines.append("  /// \(enValues.joined(separator: ", "))")
      }
      lines.append("  static var \(group.propertyName): [String] {")
      lines.append("    [")
      for (i, key) in group.keys.enumerated() {
        let comma = i < group.keys.count - 1 ? "," : ""
        lines.append("      String(localized: \"\(key)\", bundle: .\(config.bundlePropertyName))\(comma)")
      }
      lines.append("    ]")
      lines.append("  }")
    }
  }

  lines.append("}")
  lines.append("")

  let output = lines.joined(separator: "\n")
  try output.write(to: outputURL, atomically: true, encoding: .utf8)
  print("✓ Generated: \(config.outputPath)")
}

// MARK: - Module Configs

let modules: [ModuleConfig] = [
  ModuleConfig(
    xcstringsPath: "Projects/Feature/FinderFeature/Sources/Resources/Localizable.xcstrings",
    outputPath: "Projects/Feature/FinderFeature/Sources/Localization/FinderStrings.swift",
    prefix: "finder.",
    enumName: "FinderStrings",
    bundlePropertyName: "finderFeature",
    bundleTokenClassName: "FinderBundleToken"
  ),
  ModuleConfig(
    xcstringsPath: "Projects/Feature/ReaderFeature/Sources/Resources/Localizable.xcstrings",
    outputPath: "Projects/Feature/ReaderFeature/Sources/Localization/ReaderStrings.swift",
    prefix: "reader.",
    enumName: "ReaderStrings",
    bundlePropertyName: "readerFeature",
    bundleTokenClassName: "ReaderBundleToken"
  ),
  ModuleConfig(
    xcstringsPath: "Projects/UserInterface/SharedUIComponents/Sources/Resources/Localizable.xcstrings",
    outputPath: "Projects/UserInterface/SharedUIComponents/Sources/Localization/SharedStrings.swift",
    prefix: "shared.",
    enumName: "SharedStrings",
    bundlePropertyName: "sharedUIComponents",
    bundleTokenClassName: "SharedUIBundleToken"
  )
]

// MARK: - Main

for module in modules {
  do {
    try generate(config: module)
  } catch {
    print("Error generating \(module.enumName): \(error)")
    exit(1)
  }
}

print("\nDone! All string files generated.")
