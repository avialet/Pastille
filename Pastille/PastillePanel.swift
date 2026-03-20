import Cocoa
import SwiftUI
import Combine

// MARK: - NSPanel custom (ne vole jamais le focus)

class PastilleNSPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

// MARK: - Notification pour le hover

extension Notification.Name {
    static let pastilleHoverChanged = Notification.Name("pastilleHoverChanged")
}

// MARK: - Gestionnaire du panel flottant

class PastillePanel {
    private var panel: PastilleNSPanel?
    private var mouseGlobalMonitor: Any?
    private var mouseLocalMonitor: Any?
    private let captureRect: CGRect
    private let captureLoop: CaptureLoopManager
    private let onClose: () -> Void
    private var isHovering = false

    init(captureRect: CGRect, captureLoop: CaptureLoopManager, onClose: @escaping () -> Void) {
        self.captureRect = captureRect
        self.captureLoop = captureLoop
        self.onClose = onClose
    }

    func show() {
        // Taille de la vignette : 50% de la zone capturée
        let scale: CGFloat = 0.5
        let panelWidth = captureRect.width * scale
        let panelHeight = captureRect.height * scale

        // Positionner en bas à droite de l'écran
        guard let screen = NSScreen.main else { return }
        let panelX = screen.visibleFrame.maxX - panelWidth - 20
        let panelY = screen.visibleFrame.minY + 20

        let panel = PastilleNSPanel(
            contentRect: NSRect(x: panelX, y: panelY, width: panelWidth, height: panelHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary]

        let contentView = PastilleContentView(
            captureLoop: captureLoop,
            onClose: { [weak self] in self?.onClose() }
        )
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight)
        panel.contentView = hostingView

        // Animation d'apparition : fade-in
        panel.alphaValue = 0
        panel.orderFrontRegardless()

        // Transmettre le window number au moteur de capture pour s'exclure
        captureLoop.panelWindowNumber = panel.windowNumber

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1.0
        }

        self.panel = panel
        setupMouseMonitors()
    }

    // MARK: - Hover detection

    private func setupMouseMonitors() {
        // Monitor global : détecte la souris quand les événements vont aux autres apps
        mouseGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            self?.checkMousePosition()
        }

        // Monitor local : détecte la souris quand les événements arrivent au panel
        mouseLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.checkMousePosition()
            return event
        }
    }

    private func checkMousePosition() {
        guard let panel = self.panel else { return }
        let mouseLocation = NSEvent.mouseLocation
        let isInside = panel.frame.contains(mouseLocation)

        if isInside && !isHovering {
            isHovering = true
            panel.ignoresMouseEvents = false
            NotificationCenter.default.post(
                name: .pastilleHoverChanged,
                object: nil,
                userInfo: ["hovering": true]
            )
        } else if !isInside && isHovering {
            isHovering = false
            panel.ignoresMouseEvents = true
            NotificationCenter.default.post(
                name: .pastilleHoverChanged,
                object: nil,
                userInfo: ["hovering": false]
            )
        }
    }

    // MARK: - Fermeture

    func close() {
        if let monitor = mouseGlobalMonitor {
            NSEvent.removeMonitor(monitor)
            mouseGlobalMonitor = nil
        }
        if let monitor = mouseLocalMonitor {
            NSEvent.removeMonitor(monitor)
            mouseLocalMonitor = nil
        }
        panel?.orderOut(nil)
        panel = nil
    }
}
