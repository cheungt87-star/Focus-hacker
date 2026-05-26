import AppKit
import Combine
import SwiftUI

/// Off-screen SwiftUI content rasterized for the menu bar. `MenuBarExtra` labels ignore
/// most SwiftUI background fills; `ImageRenderer` preserves solid pill colors.
private enum MenuBarPillMetrics {
    /// Squared chip corners (not fully round capsule).
    static let cornerRadius: CGFloat = 4
    /// Standard menu bar status item height.
    static let statusItemHeight: CGFloat = 22
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

private extension NSImage {
    var hasValidMenuBarRasterSize: Bool {
        size.width > 0.5 && size.height > 0.5
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
                pillContent
            } else {
                Text(viewModel.menuBarText)
            }
        }
        .accessibilityLabel(viewModel.menuBarAccessibilityLabel)
        .onAppear { refreshPillRaster() }
        .onChange(of: viewModel.menuBarText) { _ in refreshPillRaster() }
        .onChange(of: viewModel.menuBarPillText) { _ in refreshPillRaster() }
        .onChange(of: viewModel.menuBarGetReadySecondsRemaining) { _ in refreshPillRaster() }
        .onChange(of: viewModel.menuBarShowsPill) { _ in refreshPillRaster() }
        .onChange(of: viewModel.menuBarLabelRevision) { _ in refreshPillRaster() }
        .onChange(of: viewModel.state.remainingSeconds) { _ in refreshPillRaster() }
        .onChange(of: viewModel.state.sessionState) { _ in refreshPillRaster() }
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

    @ViewBuilder
    private var pillContent: some View {
        if let pillRaster, pillRaster.hasValidMenuBarRasterSize {
            Image(nsImage: pillRaster)
                .resizable()
                .scaledToFit()
                .frame(height: MenuBarPillMetrics.statusItemHeight)
                .fixedSize()
        } else {
            Text(viewModel.menuBarPillText)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .monospacedDigit()
        }
    }

    @MainActor
    private func refreshPillRaster() {
        guard viewModel.menuBarShowsPill else {
            pillRaster = nil
            return
        }

        let pillText = viewModel.menuBarPillText
        let content = MenuBarPillRasterContent(
            text: pillText,
            background: viewModel.menuBarPillBackground,
            opacity: pillOpacity
        )
        let renderer = ImageRenderer(content: content)
        renderer.isOpaque = false
        renderer.scale = 2
        pillRaster = renderer.nsImage
    }
}
