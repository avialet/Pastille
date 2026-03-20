import Cocoa
import SwiftUI
import Combine

// MARK: - NSPanel custom (ne vole jamais le focus)

class PastilleNSPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

// MARK: - Notifications

extension Notification.Name {
    static let pastilleHoverChanged = Notification.Name("pastilleHoverChanged")
    static let pastilleResized = Notification.Name("pastilleResized")
}

// MARK: - Gestionnaire du panel flottant

class PastillePanel {
    private var panel: PastilleNSPanel?
    private var mouseGlobalMonitor: Any?
    private var mouseLocalMonitor: Any?
    private var mouseDragMonitor: Any?
    private let captureRect: CGRect
    private let captureLoop: CaptureLoopManager
    private let onClose: () -> Void
    private var isHovering = false

    /// Aspect ratio de la pastille (largeur / hauteur)
    private var aspectRatio: CGFloat = 1.0
    /// Drag resize state
    private var isResizing = false
    private var resizeStartMouseLocation: NSPoint = .zero
    private var resizeStartFrame: NSRect = .zero

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
        self.aspectRatio = panelWidth / panelHeight

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
            onClose: { [weak self] in self?.onClose() },
            onResizeDrag: { [weak self] phase, location in
                self?.handleResizeDrag(phase: phase, location: location)
            }
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

    // MARK: - Resize homothétique

    private func handleResizeDrag(phase: ResizeDragPhase, location: NSPoint) {
        guard let panel = self.panel else { return }

        switch phase {
        case .began:
            isResizing = true
            resizeStartMouseLocation = NSEvent.mouseLocation
            resizeStartFrame = panel.frame
            // Désactiver le déplacement pendant le resize
            panel.isMovableByWindowBackground = false

        case .changed:
            let currentMouse = NSEvent.mouseLocation
            // Le delta horizontal détermine le scale (drag vers la droite = agrandir)
            let deltaX = currentMouse.x - resizeStartMouseLocation.x
            // Aussi prendre en compte le delta vertical (vers le bas en écran = négatif en AppKit)
            let deltaY = -(currentMouse.y - resizeStartMouseLocation.y)
            // Prendre le delta le plus grand en valeur absolue
            let delta = abs(deltaX) > abs(deltaY) ? deltaX : deltaY

            let newWidth = max(80, resizeStartFrame.width + delta)
            let newHeight = newWidth / aspectRatio

            // Garder le coin supérieur gauche fixe (en coordonnées AppKit = coin inférieur gauche)
            let originY = resizeStartFrame.origin.y + resizeStartFrame.height - newHeight
            let newFrame = NSRect(
                x: resizeStartFrame.origin.x,
                y: originY,
                width: newWidth,
                height: newHeight
            )
            panel.setFrame(newFrame, display: true)
            panel.contentView?.frame = NSRect(x: 0, y: 0, width: newWidth, height: newHeight)

        case .ended:
            isResizing = false
            panel.isMovableByWindowBackground = true
        }
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
        guard let panel = self.panel, !isResizing else { return }
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

// MARK: - Phase de drag resize

enum ResizeDragPhase {
    case began, changed, ended
}
