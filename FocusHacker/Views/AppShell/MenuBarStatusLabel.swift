import AppKit
import Combine
import SwiftUI

/// Off-screen SwiftUI content rasterized for the menu bar. `MenuBarExtra` labels ignore
/// most SwiftUI background fills; `ImageRenderer` preserves solid pill colors.
private enum MenuBarPillMetrics {
    /// Squared chip corners (not fully round capsule).
    static let cornerRadius: CGFloat = 4
}

private struct MenuBarPillRasterContent: View {
    let text: String
    let background: Color
    let opacity: Double

    private var pillShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: MenuBarPillMetrics.cornerRadius, style: .continuous)
    }

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .monospacedDigit()
            .foregroundStyle(Color.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(background, in: pillShape)
            .opacity(opacity)
    }
}

struct MenuBarStatusLabel: View {
    @ObservedObject var viewModel: AppShellViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var flashDimmed = false
    @State private var pillRaster: NSImage?

    private var shouldAnimateFlash: Bool {
        viewModel.menuBarShouldFlash && !reduceMotion
    }

    private var pillOpacity: Double {
        shouldAnimateFlash && flashDimmed ? 0.35 : 1
    }

    var body: some View {
        Group {
            if viewModel.menuBarShowsPill {
                if let pillRaster {
                    Image(nsImage: pillRaster)
                } else {
                    Text(viewModel.menuBarPillText)
                }
            } else {
                Text(viewModel.menuBarText)
            }
        }
        .accessibilityLabel(viewModel.menuBarAccessibilityLabel)
        .onAppear { refreshPillRaster() }
        .onChange(of: viewModel.menuBarText) { _ in refreshPillRaster() }
        .onChange(of: viewModel.menuBarPillText) { _ in refreshPillRaster() }
        .onChange(of: viewModel.menuBarShowsPill) { _ in refreshPillRaster() }
        .onChange(of: viewModel.menuBarShouldFlash) { flashing in
            if !flashing {
                flashDimmed = false
            }
            refreshPillRaster()
        }
        .onChange(of: flashDimmed) { _ in refreshPillRaster() }
        .onReceive(
            Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
        ) { _ in
            guard shouldAnimateFlash else { return }
            flashDimmed.toggle()
        }
    }

    @MainActor
    private func refreshPillRaster() {
        guard viewModel.menuBarShowsPill else {
            pillRaster = nil
            return
        }

        let content = MenuBarPillRasterContent(
            text: viewModel.menuBarPillText,
            background: viewModel.menuBarPillBackground,
            opacity: pillOpacity
        )
        let renderer = ImageRenderer(content: content)
        renderer.isOpaque = false
        renderer.scale = 2
        pillRaster = renderer.nsImage
    }
}
