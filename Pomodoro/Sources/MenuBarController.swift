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

    /// Creates the coffee cup icon for the menu bar using SF Symbol `cup.and.saucer.fill`.
    private static func makeCoffeeIcon() -> NSImage {
        let symbol = NSImage(systemSymbolName: "cup.and.saucer.fill", accessibilityDescription: "Coffee Break")!
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let configured = symbol.withSymbolConfiguration(config) ?? symbol
        configured.isTemplate = true
        return configured
    }

    /// Creates the moon icon for break sessions using SF Symbol `moon.fill`.
    private static func makeMoonIcon() -> NSImage {
        let symbol = NSImage(systemSymbolName: "moon.fill", accessibilityDescription: "Break")!
        let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        let configured = symbol.withSymbolConfiguration(config) ?? symbol
        configured.isTemplate = true
        return configured
    }

    /// Update the status item text and icon based on timer state.
    private func updateMenuBar(text: String) {
        guard let button = statusItem.button else { return }

        if text == "Ready" || text == "Paused" || text == "Focus" || text == "Break" {
            // Icon only — no timer text
            button.image = text == "Break" ? Self.makeMoonIcon() : Self.makeCoffeeIcon()
            button.imagePosition = .imageOnly
            button.title = ""
            statusItem.length = NSStatusItem.squareLength
        } else if text.hasPrefix("Break") {
            statusItem.length = NSStatusItem.variableLength
            button.image = Self.makeMoonIcon()
            button.imagePosition = .imageLeading
            button.title = text.replacingOccurrences(of: "Break ", with: "")
        } else {
            // Focus or Paused with time
            statusItem.length = NSStatusItem.variableLength
            button.image = Self.makeCoffeeIcon()
            button.imagePosition = .imageLeading
            button.title = text.replacingOccurrences(of: "Focus ", with: "")
                               .replacingOccurrences(of: "Paused ", with: "")
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
