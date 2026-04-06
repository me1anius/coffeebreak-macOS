import AppKit
import SwiftUI

/// Manages the NSStatusItem (menu bar icon/text) and the NSPopover that
/// appears when the user clicks it.
@MainActor
final class MenuBarController {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var eventMonitor: Any?

    init(viewModel: TimerViewModel) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Configure the popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: AppSizing.popoverWidth, height: AppSizing.popoverHeight)
        popover.behavior = .transient
        popover.animates = true

        // Set SwiftUI content as the popover's view controller
        let hostingController = NSHostingController(rootView: TimerView(viewModel: viewModel))
        hostingController.view.frame = NSRect(
            x: 0, y: 0,
            width: AppSizing.popoverWidth,
            height: AppSizing.popoverHeight
        )
        popover.contentViewController = hostingController

        // Configure the status bar button
        if let button = statusItem.button {
            button.image = Self.makeCoffeeIcon()
            button.imagePosition = .imageLeading
            button.imageScaling = .scaleProportionallyDown
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
            button.title = "\u{200B}"
            button.action = #selector(handleClick(_:))
            button.target = self
            // Enable right-click detection
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Wire up menu bar text updates from the view model
        viewModel.onMenuBarTextChange = { [weak self] text in
            self?.updateMenuBar(text: text)
        }

        setupEventMonitor()
    }

    // MARK: - Coffee Cup Icon

    /// Renders an SF Symbol into a fixed-size canvas to prevent clipping across displays.
    private static func renderSymbol(_ name: String, pointSize: CGFloat, canvasSize: CGFloat) -> NSImage {
        let symbol = NSImage(systemSymbolName: name, accessibilityDescription: "Coffee Break")!
        let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .medium)
        let configured = symbol.withSymbolConfiguration(config) ?? symbol

        let size = NSSize(width: canvasSize, height: canvasSize)
        let canvas = NSImage(size: size, flipped: false) { rect in
            let symbolSize = configured.size
            let x = (rect.width - symbolSize.width) / 2
            let y = (rect.height - symbolSize.height) / 2
            configured.draw(in: NSRect(x: x, y: y, width: symbolSize.width, height: symbolSize.height))
            return true
        }
        canvas.isTemplate = true
        return canvas
    }

    /// Creates the coffee cup icon for the menu bar using SF Symbol `cup.and.saucer.fill`.
    private static func makeCoffeeIcon() -> NSImage {
        renderSymbol("cup.and.saucer.fill", pointSize: 14, canvasSize: 18)
    }

    /// Creates the moon icon for break sessions using SF Symbol `moon.fill`.
    private static func makeMoonIcon() -> NSImage {
        renderSymbol("moon.fill", pointSize: 13, canvasSize: 18)
    }

    /// Update the status item text and icon based on timer state.
    private func updateMenuBar(text: String) {
        guard let button = statusItem.button else { return }

        if text.contains("Ready") || text.contains("Paused") {
            button.image = Self.makeCoffeeIcon()
            button.imagePosition = .imageLeading
            button.title = "\u{200B}"
        } else if text.contains("☕") || text.contains("Break") {
            button.image = Self.makeMoonIcon()
            button.imagePosition = .imageLeading
            let time = text.replacingOccurrences(of: "☕ ", with: "")
                          .replacingOccurrences(of: "⏸", with: "").trimmingCharacters(in: .whitespaces)
            button.title = time
        } else {
            button.image = Self.makeCoffeeIcon()
            button.imagePosition = .imageLeading
            let time = text.replacingOccurrences(of: "🍅 ", with: "")
                          .replacingOccurrences(of: "⏸", with: "").trimmingCharacters(in: .whitespaces)
            button.title = time
        }
    }

    // MARK: - Click Handling

    @objc private func handleClick(_ sender: Any?) {
        guard let event = NSApp.currentEvent else {
            togglePopover(sender)
            return
        }

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover(sender)
        }
    }

    private func showContextMenu() {
        guard let button = statusItem.button else { return }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit Coffee Break", action: #selector(quitApp), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }

        // Position the menu below the status item
        statusItem.menu = menu
        button.performClick(nil)
        // Clear the menu so left-click goes back to the popover
        statusItem.menu = nil
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Popover Toggle

    @objc private func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover()
        } else {
            openPopover()
        }
    }

    private func openPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        startEventMonitor()
    }

    private func closePopover() {
        popover.performClose(nil)
        stopEventMonitor()
    }

    // MARK: - Event Monitor

    private func setupEventMonitor() {}

    private func startEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }

    private func stopEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
