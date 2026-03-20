import Cocoa
import Combine

class CaptureLoopManager: ObservableObject {
    @Published var currentImage: NSImage?

    private let screenRect: CGRect          // Zone originale en coordonnées écran (fallback)
    private let targetWindowID: CGWindowID  // Fenêtre cible (0 = capture écran brute)
    private let relativeRect: CGRect        // Zone relative à la fenêtre cible
    private let logicalSize: NSSize         // Taille logique pour l'affichage
    private var timer: DispatchSourceTimer?

    /// Window number du panel Lucarne, pour l'exclure des captures
    var panelWindowNumber: Int = 0

    /// Initialisation avec capture liée à une fenêtre spécifique
    init(screenRect: CGRect, windowID: CGWindowID, relativeRect: CGRect) {
        self.screenRect = screenRect
        self.targetWindowID = windowID
        self.relativeRect = relativeRect
        self.logicalSize = NSSize(width: screenRect.width, height: screenRect.height)
    }

    /// Fallback : capture d'une zone écran fixe (pas de fenêtre cible)
    init(rect: CGRect) {
        self.screenRect = rect
        self.targetWindowID = kCGNullWindowID
        self.relativeRect = .zero
        self.logicalSize = NSSize(width: rect.width, height: rect.height)
    }

    func start() {
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: 1.0 / 15.0)
        timer.setEventHandler { [weak self] in
            self?.captureFrame()
        }
        timer.resume()
        self.timer = timer
    }

    func stop() {
        timer?.cancel()
        timer = nil
        currentImage = nil
    }

    private func captureFrame() {
        if targetWindowID != kCGNullWindowID {
            captureTargetWindow()
        } else {
            captureScreenRect()
        }
    }

    // MARK: - Capture liée à une fenêtre

    private func captureTargetWindow() {
        // Capturer la fenêtre entière (suit la fenêtre même si elle bouge)
        guard let fullImage = CGWindowListCreateImage(
            .null,
            .optionIncludingWindow,
            targetWindowID,
            [.bestResolution, .boundsIgnoreFraming]
        ) else { return }

        // Calculer le crop en pixels (image Retina = 2x la taille logique)
        let scaleX = CGFloat(fullImage.width) / max(getWindowWidth(), 1)
        let scaleY = CGFloat(fullImage.height) / max(getWindowHeight(), 1)

        let cropPixelRect = CGRect(
            x: relativeRect.origin.x * scaleX,
            y: relativeRect.origin.y * scaleY,
            width: relativeRect.width * scaleX,
            height: relativeRect.height * scaleY
        )

        guard let croppedImage = fullImage.cropping(to: cropPixelRect) else { return }

        let nsImage = NSImage(cgImage: croppedImage, size: logicalSize)
        self.currentImage = nsImage
    }

    // MARK: - Capture d'écran brute (fallback)

    private func captureScreenRect() {
        let windowID: CGWindowID
        let listOption: CGWindowListOption

        if panelWindowNumber > 0 {
            windowID = CGWindowID(panelWindowNumber)
            listOption = .optionOnScreenBelowWindow
        } else {
            windowID = kCGNullWindowID
            listOption = .optionOnScreenOnly
        }

        guard let cgImage = CGWindowListCreateImage(
            screenRect,
            listOption,
            windowID,
            [.bestResolution]
        ) else { return }

        let nsImage = NSImage(cgImage: cgImage, size: logicalSize)
        self.currentImage = nsImage
    }

    // MARK: - Utilitaires

    /// Récupère les dimensions actuelles de la fenêtre cible
    private func getWindowWidth() -> CGFloat {
        return getWindowBounds()?.width ?? relativeRect.width
    }

    private func getWindowHeight() -> CGFloat {
        return getWindowBounds()?.height ?? relativeRect.height
    }

    private func getWindowBounds() -> CGRect? {
        guard let windowInfoList = CGWindowListCopyWindowInfo(
            .optionIncludingWindow, targetWindowID
        ) as? [[String: Any]],
              let info = windowInfoList.first,
              let boundsDict = info[kCGWindowBounds as String] as? NSDictionary else {
            return nil
        }

        var bounds = CGRect.zero
        guard CGRectMakeWithDictionaryRepresentation(boundsDict, &bounds) else {
            return nil
        }
        return bounds
    }

    // MARK: - Recherche de fenêtre sous la sélection

    /// Trouve la fenêtre au premier plan sous le centre de la zone sélectionnée
    static func findWindow(at screenRect: CGRect) -> (windowID: CGWindowID, windowBounds: CGRect)? {
        let center = CGPoint(x: screenRect.midX, y: screenRect.midY)
        let myPID = ProcessInfo.processInfo.processIdentifier

        guard let windowInfoList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else { return nil }

        // La liste est ordonnée front-to-back : la première qui contient le centre est la bonne
        for info in windowInfoList {
            guard let windowNumber = info[kCGWindowNumber as String] as? Int,
                  let ownerPID = info[kCGWindowOwnerPID as String] as? Int,
                  let boundsDict = info[kCGWindowBounds as String] as? NSDictionary else { continue }

            // Ignorer nos propres fenêtres
            if ownerPID == Int(myPID) { continue }

            // Ignorer les fenêtres de layer != 0 (éléments système comme la barre de menu)
            if let layer = info[kCGWindowLayer as String] as? Int, layer != 0 { continue }

            var bounds = CGRect.zero
            guard CGRectMakeWithDictionaryRepresentation(boundsDict, &bounds) else { continue }

            if bounds.contains(center) {
                return (CGWindowID(windowNumber), bounds)
            }
        }

        return nil
    }
}
