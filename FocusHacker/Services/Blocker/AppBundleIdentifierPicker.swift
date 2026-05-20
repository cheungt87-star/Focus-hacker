import AppKit
import Foundation
import UniformTypeIdentifiers

struct PickedApplication: Equatable {
    let bundleIdentifier: String
    let displayName: String
    let applicationURL: URL
}

enum AppBundleIdentifierPicker {
    enum PickError: Error, Equatable {
        case cancelled
        case unreadableBundle
        case missingBundleIdentifier
        case invalidApplication
    }

    @MainActor
    static func pickApplication() -> Result<PickedApplication, PickError> {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.treatsFilePackagesAsDirectories = false
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications", isDirectory: true)
        panel.title = "Choose an app to block"
        panel.message = "This app will lose internet access during focus — it can still open."
        panel.prompt = "Choose"
        panel.showsHiddenFiles = false
        panel.identifier = NSUserInterfaceItemIdentifier("com.focushacker.app-blocklist-picker")

        let delegate = AppPickerPanelDelegate()
        delegate.attach(to: panel)
        panel.delegate = delegate
        panel.accessoryView = delegate.previewView
        panel.isAccessoryViewDisclosed = false

        guard panel.runModal() == .OK, let url = panel.url else {
            return .failure(.cancelled)
        }
        guard AppWindowPreviewCapture.isApplicationBundleURL(url) else {
            return .failure(.invalidApplication)
        }
        guard let bundle = Bundle(url: url) else {
            return .failure(.unreadableBundle)
        }
        guard let bundleIdentifier = bundle.bundleIdentifier else {
            return .failure(.missingBundleIdentifier)
        }

        let displayName = displayName(from: bundle, applicationURL: url)
        return .success(
            PickedApplication(
                bundleIdentifier: bundleIdentifier,
                displayName: displayName,
                applicationURL: url
            )
        )
    }

    private static func displayName(from bundle: Bundle, applicationURL: URL) -> String {
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
}

@MainActor
private final class AppPickerPanelDelegate: NSObject, NSOpenSavePanelDelegate {
    private let titleLabel = NSTextField(labelWithString: "Select an app to preview")
    private let statusLabel = NSTextField(labelWithString: "")
    private let imageView = NSImageView()
    private let placeholderIcon = NSImage(named: NSImage.applicationIconName) ?? NSImage()
    private var disclosureObservation: NSKeyValueObservation?

    func attach(to panel: NSOpenPanel) {
        disclosureObservation = panel.observe(\.isAccessoryViewDisclosed, options: [.new]) { [weak self] panel, _ in
            Task { @MainActor in
                self?.panelSelectionDidChange(panel)
            }
        }
    }

    lazy var previewView: NSView = {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 360, height: 220))

        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.font = NSFont.systemFont(ofSize: 11)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.imageAlignment = .alignCenter
        imageView.wantsLayer = true
        imageView.layer?.backgroundColor = NSColor.quaternaryLabelColor.withAlphaComponent(0.2).cgColor
        imageView.layer?.cornerRadius = 8
        imageView.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(titleLabel)
        container.addSubview(statusLabel)
        container.addSubview(imageView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),

            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            statusLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            imageView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
            imageView.heightAnchor.constraint(equalToConstant: 180),
        ])

        imageView.image = placeholderIcon
        return container
    }()

    func panelSelectionDidChange(_ sender: Any?) {
        guard let panel = sender as? NSOpenPanel else {
            resetPreview()
            return
        }

        guard panel.isAccessoryViewDisclosed else {
            return
        }

        guard let url = panel.url,
              AppWindowPreviewCapture.isApplicationBundleURL(url) else {
            resetPreview()
            return
        }

        let preview = AppWindowPreviewCapture.preview(forApplicationURL: url)
        titleLabel.stringValue = preview.displayName
        if preview.isRunning {
            if preview.screenshot != nil {
                statusLabel.stringValue = "Preview of this app's open window"
            } else {
                statusLabel.stringValue = "App is open — showing icon (screen recording may be required for preview)"
            }
        } else {
            statusLabel.stringValue = "App is not running — showing icon"
        }
        imageView.image = preview.screenshot ?? preview.icon
    }

    private func resetPreview() {
        titleLabel.stringValue = "Select an app to preview"
        statusLabel.stringValue = ""
        imageView.image = placeholderIcon
    }
}
