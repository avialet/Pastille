import Cocoa

// MARK: - Fenêtre de sélection (peut devenir key pour recevoir Escape)

class SelectionWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - Overlay de sélection plein écran

class SelectionOverlay {
    private var window: SelectionWindow?
    private let completion: (CGRect?) -> Void

    init(completion: @escaping (CGRect?) -> Void) {
        self.completion = completion
    }

    func show() {
        guard let screen = NSScreen.main else {
            completion(nil)
            return
        }

        let window = SelectionWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.level = .init(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        window.hasShadow = false

        let selectionView = SelectionView { [weak self] rect in
            self?.window?.orderOut(nil)
            self?.window = nil

            if let rect = rect, rect.width > 10, rect.height > 10 {
                // Convertir les coordonnées NSView → coordonnées CGDisplay
                let screenHeight = screen.frame.height
                let cgRect = CGRect(
                    x: rect.origin.x + screen.frame.origin.x,
                    y: screenHeight - rect.origin.y - rect.height,
                    width: rect.width,
                    height: rect.height
                )
                self?.completion(cgRect)
            } else {
                self?.completion(nil)
            }
        }

        window.contentView = selectionView
        window.makeKeyAndOrderFront(nil)

        self.window = window
    }

    func close() {
        window?.orderOut(nil)
        window = nil
    }
}

// MARK: - Vue de sélection (dessin du rectangle)

class SelectionView: NSView {
    private var startPoint: NSPoint?
    private var currentPoint: NSPoint?
    private let completion: (NSRect?) -> Void

    private let vermillon = NSColor(red: 0.906, green: 0.298, blue: 0.235, alpha: 1.0)

    init(completion: @escaping (NSRect?) -> Void) {
        self.completion = completion
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) non implémenté")
    }

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func draw(_ dirtyRect: NSRect) {
        // Fond assombri translucide
        NSColor.black.withAlphaComponent(0.3).setFill()
        bounds.fill()

        // Rectangle de sélection
        guard let start = startPoint, let current = currentPoint else { return }

        let rect = selectionRect(from: start, to: current)
        guard rect.width > 1, rect.height > 1 else { return }

        // Zone claire (découpe dans le dimming)
        NSColor.clear.setFill()
        rect.fill(using: .copy)

        // Bordure rouge
        let borderPath = NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2)
        vermillon.setStroke()
        borderPath.lineWidth = 2.0
        borderPath.stroke()

        // Dimensions en texte
        let dimensions = "\(Int(rect.width)) × \(Int(rect.height))"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white,
            .backgroundColor: NSColor.black.withAlphaComponent(0.6)
        ]
        let textSize = dimensions.size(withAttributes: attrs)
        let textPoint = NSPoint(
            x: rect.midX - textSize.width / 2,
            y: rect.minY - textSize.height - 6
        )
        dimensions.draw(at: textPoint, withAttributes: attrs)
    }

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        currentPoint = startPoint
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)

        if let start = startPoint, let end = currentPoint {
            let rect = selectionRect(from: start, to: end)
            completion(rect)
        } else {
            completion(nil)
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            completion(nil)
        }
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    private func selectionRect(from a: NSPoint, to b: NSPoint) -> NSRect {
        return NSRect(
            x: min(a.x, b.x),
            y: min(a.y, b.y),
            width: abs(b.x - a.x),
            height: abs(b.y - a.y)
        )
    }
}
