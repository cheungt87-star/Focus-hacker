import AppKit
import Foundation

struct BlockedAppDisplayInfo {
    let bundleIdentifier: String
    let displayName: String
    let icon: NSImage
}

enum BlockedAppDisplayInfoResolver {
    static func resolve(bundleIdentifier: String) -> BlockedAppDisplayInfo {
        if let applicationURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            let icon = NSWorkspace.shared.icon(forFile: applicationURL.path)
            let displayName = displayName(from: applicationURL) ?? fallbackDisplayName(bundleIdentifier: bundleIdentifier)
            return BlockedAppDisplayInfo(
                bundleIdentifier: bundleIdentifier,
                displayName: displayName,
                icon: icon
            )
        }

        return BlockedAppDisplayInfo(
            bundleIdentifier: bundleIdentifier,
            displayName: fallbackDisplayName(bundleIdentifier: bundleIdentifier),
            icon: NSImage(named: NSImage.applicationIconName) ?? NSImage()
        )
    }

    private static func displayName(from applicationURL: URL) -> String? {
        guard let bundle = Bundle(url: applicationURL) else {
            return nil
        }
        if let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
           !displayName.isEmpty {
            return displayName
        }
        if let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String,
           !name.isEmpty {
            return name
        }
        return applicationURL.deletingPathExtension().lastPathComponent
    }

    private static func fallbackDisplayName(bundleIdentifier: String) -> String {
        let lastComponent = bundleIdentifier.split(separator: ".").last.map(String.init) ?? bundleIdentifier
        guard !lastComponent.isEmpty else {
            return bundleIdentifier
        }
        return lastComponent.prefix(1).uppercased() + lastComponent.dropFirst()
    }
}
