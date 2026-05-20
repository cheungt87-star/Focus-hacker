import AppKit
import CoreGraphics
import Foundation

struct AppWindowPreview {
    let displayName: String
    let icon: NSImage
    let screenshot: NSImage?
    let isRunning: Bool
}

enum AppWindowPreviewCapture {
    struct WindowCandidate: Equatable {
        let windowID: CGWindowID
        let bounds: CGRect
    }

    @MainActor
    static func preview(forApplicationURL applicationURL: URL) -> AppWindowPreview {
        let icon = NSWorkspace.shared.icon(forFile: applicationURL.path)
        let displayName = applicationURL.deletingPathExtension().lastPathComponent

        guard let bundle = Bundle(url: applicationURL),
              let bundleIdentifier = bundle.bundleIdentifier else {
            return AppWindowPreview(
                displayName: displayName,
                icon: icon,
                screenshot: nil,
                isRunning: false
            )
        }

        guard let runningApp = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == bundleIdentifier && !$0.isTerminated
        }) else {
            return AppWindowPreview(
                displayName: resolvedDisplayName(from: bundle, fallback: displayName),
                icon: icon,
                screenshot: nil,
                isRunning: false
            )
        }

        let resolvedName = resolvedDisplayName(from: bundle, fallback: displayName)
        guard screenCaptureAccessGranted(),
              let candidate = frontmostWindow(forOwnerPID: runningApp.processIdentifier),
              let screenshot = captureWindowImage(windowID: candidate.windowID, bounds: candidate.bounds) else {
            return AppWindowPreview(
                displayName: resolvedName,
                icon: icon,
                screenshot: nil,
                isRunning: true
            )
        }

        return AppWindowPreview(
            displayName: resolvedName,
            icon: icon,
            screenshot: scaledThumbnail(from: screenshot, maxSize: NSSize(width: 320, height: 180)),
            isRunning: true
        )
    }

    static func frontmostWindow(
        from windowInfos: [[String: Any]],
        ownerPID: pid_t
    ) -> WindowCandidate? {
        for info in windowInfos {
            guard let windowPID = info[kCGWindowOwnerPID as String] as? pid_t,
                  windowPID == ownerPID else {
                continue
            }
            guard let layer = info[kCGWindowLayer as String] as? Int, layer == 0 else {
                continue
            }
            guard let bounds = boundsFromWindowInfo(info) else {
                continue
            }
            guard bounds.width > 1, bounds.height > 1 else {
                continue
            }
            guard let windowNumber = info[kCGWindowNumber as String] as? CGWindowID else {
                continue
            }
            if let alpha = info[kCGWindowAlpha as String] as? Double, alpha < 0.01 {
                continue
            }
            return WindowCandidate(windowID: windowNumber, bounds: bounds)
        }
        return nil
    }

    static func isApplicationBundleURL(_ url: URL) -> Bool {
        url.pathExtension.caseInsensitiveCompare("app") == .orderedSame
    }

    static func boundsFromWindowInfo(_ info: [String: Any]) -> CGRect? {
        guard let boundsDict = info[kCGWindowBounds as String] as? [String: Any] else {
            return nil
        }
        let x = (boundsDict["X"] as? NSNumber)?.doubleValue ?? 0
        let y = (boundsDict["Y"] as? NSNumber)?.doubleValue ?? 0
        let width = (boundsDict["Width"] as? NSNumber)?.doubleValue ?? 0
        let height = (boundsDict["Height"] as? NSNumber)?.doubleValue ?? 0
        return CGRect(x: x, y: y, width: width, height: height)
    }

    private static func frontmostWindow(forOwnerPID ownerPID: pid_t) -> WindowCandidate? {
        guard let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return nil
        }
        return frontmostWindow(from: windowList, ownerPID: ownerPID)
    }

    private static func screenCaptureAccessGranted() -> Bool {
        if CGPreflightScreenCaptureAccess() {
            return true
        }
        _ = CGRequestScreenCaptureAccess()
        return CGPreflightScreenCaptureAccess()
    }

    private static func captureWindowImage(windowID: CGWindowID, bounds: CGRect) -> NSImage? {
        guard let cgImage = CGWindowListCreateImage(
            bounds,
            .optionIncludingWindow,
            windowID,
            [.bestResolution, .boundsIgnoreFraming]
        ) else {
            return nil
        }
        let size = NSSize(width: cgImage.width, height: cgImage.height)
        return NSImage(cgImage: cgImage, size: size)
    }

    private static func scaledThumbnail(from image: NSImage, maxSize: NSSize) -> NSImage {
        let sourceSize = image.size
        guard sourceSize.width > 0, sourceSize.height > 0 else {
            return image
        }
        let scale = min(maxSize.width / sourceSize.width, maxSize.height / sourceSize.height, 1)
        let targetSize = NSSize(
            width: floor(sourceSize.width * scale),
            height: floor(sourceSize.height * scale)
        )
        let thumbnail = NSImage(size: targetSize)
        thumbnail.lockFocus()
        image.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: sourceSize),
            operation: .copy,
            fraction: 1
        )
        thumbnail.unlockFocus()
        return thumbnail
    }

    private static func resolvedDisplayName(from bundle: Bundle, fallback: String) -> String {
        if let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
           !displayName.isEmpty {
            return displayName
        }
        if let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String,
           !name.isEmpty {
            return name
        }
        return fallback
    }
}
