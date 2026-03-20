import Cocoa
import Combine

enum PastilleState {
    case idle
    case selectionMode
    case active
}

class PastilleManager: ObservableObject {
    @Published var state: PastilleState = .idle

    private weak var appDelegate: AppDelegate?
    private var selectionOverlay: SelectionOverlay?
    private var captureLoop: CaptureLoopManager?
    private var pastillePanel: PastillePanel?

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
            closeActivePastille()
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
                self.createPastille(for: rect)
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

    func createPastille(for rect: CGRect) {
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

        let panel = PastillePanel(
            captureRect: rect,
            captureLoop: captureLoop
        ) { [weak self] in
            self?.closeActivePastille()
        }
        self.pastillePanel = panel

        captureLoop.start()
        panel.show()

        state = .active
        appDelegate?.updateMenu()
    }

    func closeActivePastille() {
        captureLoop?.stop()
        captureLoop = nil
        pastillePanel?.close()
        pastillePanel = nil
        state = .idle
        appDelegate?.updateMenu()
    }
}
