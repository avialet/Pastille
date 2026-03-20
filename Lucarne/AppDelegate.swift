import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private(set) var manager: LucarneManager!
    private var onboardingWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        manager = LucarneManager(appDelegate: self)
        setupStatusBar()

        GlobalShortcut.shared.register { [weak self] in
            DispatchQueue.main.async {
                self?.manager.toggleCapture()
            }
        }

        // Vérifier la permission d'enregistrement d'écran au lancement
        if !PermissionManager.hasScreenCapturePermission() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showOnboarding()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        GlobalShortcut.shared.unregister()
        manager.closeActiveLucarne()
    }

    // MARK: - Status Bar

    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "rectangle.dashed",
                accessibilityDescription: "Lucarne"
            )
        }
        updateMenu()
    }

    func updateMenu() {
        let menu = NSMenu()

        let captureItem = NSMenuItem(
            title: "Capturer une Lucarne",
            action: #selector(toggleCapture),
            keyEquivalent: "l"
        )
        captureItem.keyEquivalentModifierMask = [.command, .option]
        captureItem.target = self
        menu.addItem(captureItem)

        if manager.state == .active {
            let closeItem = NSMenuItem(
                title: "Fermer la Lucarne active",
                action: #selector(closeLucarne),
                keyEquivalent: ""
            )
            closeItem.target = self
            menu.addItem(closeItem)
        }

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "Quitter Lucarne",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - Actions

    @objc private func toggleCapture() {
        manager.toggleCapture()
    }

    @objc private func closeLucarne() {
        manager.closeActiveLucarne()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Onboarding

    func showOnboarding() {
        if onboardingWindow != nil { return }

        let view = OnboardingView {
            self.onboardingWindow?.close()
            self.onboardingWindow = nil
        }
        let hostingView = NSHostingView(rootView: view)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 320),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.title = "Lucarne"
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        onboardingWindow = window
    }
}
