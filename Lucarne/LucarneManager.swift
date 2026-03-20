import Cocoa
import Combine

enum LucarneState {
    case idle
    case selectionMode
    case active
}

class LucarneManager: ObservableObject {
    @Published var state: LucarneState = .idle

    private weak var appDelegate: AppDelegate?
    private var selectionOverlay: SelectionOverlay?
    private var captureLoop: CaptureLoopManager?
    private var lucarnePanel: LucarnePanel?

    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
    }

    // MARK: - Actions

    func toggleCapture() {
        switch state {
        case .idle:
            startSelection()
        case .selectionMode:
            cancelSelection()
        case .active:
            closeActiveLucarne()
        }
    }

    func startSelection() {
        guard PermissionManager.hasScreenCapturePermission() else {
            appDelegate?.showOnboarding()
            return
        }

        state = .selectionMode
        selectionOverlay = SelectionOverlay { [weak self] rect in
            guard let self = self else { return }
            self.selectionOverlay = nil

            if let rect = rect {
                self.createLucarne(for: rect)
            } else {
                self.state = .idle
            }
        }
        selectionOverlay?.show()
    }

    func cancelSelection() {
        selectionOverlay?.close()
        selectionOverlay = nil
        state = .idle
    }

    func createLucarne(for rect: CGRect) {
        let captureLoop: CaptureLoopManager

        // Chercher la fenêtre sous la sélection pour s'y accrocher
        if let (windowID, windowBounds) = CaptureLoopManager.findWindow(at: rect) {
            // Calculer la zone relative à la fenêtre
            let relativeRect = CGRect(
                x: rect.origin.x - windowBounds.origin.x,
                y: rect.origin.y - windowBounds.origin.y,
                width: rect.width,
                height: rect.height
            )
            captureLoop = CaptureLoopManager(
                screenRect: rect,
                windowID: windowID,
                relativeRect: relativeRect
            )
        } else {
            // Fallback : capture de zone écran fixe
            captureLoop = CaptureLoopManager(rect: rect)
        }
        self.captureLoop = captureLoop

        let panel = LucarnePanel(
            captureRect: rect,
            captureLoop: captureLoop
        ) { [weak self] in
            self?.closeActiveLucarne()
        }
        self.lucarnePanel = panel

        captureLoop.start()
        panel.show()

        state = .active
        appDelegate?.updateMenu()
    }

    func closeActiveLucarne() {
        captureLoop?.stop()
        captureLoop = nil
        lucarnePanel?.close()
        lucarnePanel = nil
        state = .idle
        appDelegate?.updateMenu()
    }
}
