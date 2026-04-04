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
            button.imagePosition = .imageOnly
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
            button.title = ""
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

    /// Loads the bundled coffee icon as a template image for the menu bar.
    private static func makeCoffeeIcon() -> NSImage {
        if let url = Bundle.main.url(forResource: "coffee_icon", withExtension: "png"),
           let srcImage = NSImage(contentsOf: url) {
            // Menu bar expects 22pt tall images. Draw the 18pt icon centered
            // within a 22pt canvas so it sits vertically centered.
            let iconSize: CGFloat = 18
            let canvasHeight: CGFloat = 22
            let canvas = NSImage(size: NSSize(width: iconSize, height: canvasHeight), flipped: false) { rect in
                let yOffset = (canvasHeight - iconSize) / 2 - 1
                srcImage.draw(in: NSRect(x: 0, y: yOffset, width: iconSize, height: iconSize))
                return true
            }
            canvas.isTemplate = true
            return canvas
        }
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let fallback = NSImage(systemSymbolName: "timer", accessibilityDescription: "Pomodoro")!
        let configured = fallback.withSymbolConfiguration(config) ?? fallback
        configured.isTemplate = true
        return configured
    }

    /// Loads the bundled moon icon as a template image for break sessions.
    private static func makeMoonIcon() -> NSImage {
        if let url = Bundle.main.url(forResource: "moon_icon", withExtension: "png"),
           let srcImage = NSImage(contentsOf: url) {
            let iconSize: CGFloat = 15
            let canvasWidth: CGFloat = 18
            let canvasHeight: CGFloat = 22
            let canvas = NSImage(size: NSSize(width: canvasWidth, height: canvasHeight), flipped: false) { rect in
                let xOffset = (canvasWidth - iconSize) / 2
                let yOffset = (canvasHeight - iconSize) / 2 - 0.5
                srcImage.draw(in: NSRect(x: xOffset, y: yOffset, width: iconSize, height: iconSize))
                return true
            }
            canvas.isTemplate = true
            return canvas
        }
        // Fallback to SF Symbol
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let fallback = NSImage(systemSymbolName: "moon.fill", accessibilityDescription: "Break")!
        let configured = fallback.withSymbolConfiguration(config) ?? fallback
        configured.isTemplate = true
        return configured
    }

    /// Update the status item text and icon based on timer state.
    private func updateMenuBar(text: String) {
        guard let button = statusItem.button else { return }

        if text.contains("Ready") || text.contains("Paused") {
            button.image = Self.makeCoffeeIcon()
            button.imagePosition = .imageOnly
            button.title = ""
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
