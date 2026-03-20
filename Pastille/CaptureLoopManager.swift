import Cocoa
import Combine

class CaptureLoopManager: ObservableObject {
    @Published var currentImage: NSImage?

    private let screenRect: CGRect
    private let targetWindowID: CGWindowID
    private let relativeRect: CGRect
    private let logicalSize: NSSize
    private var timer: DispatchSourceTimer?

    /// Fréquence de rafraîchissement
    static let availableFrameRates: [Int] = [5, 8, 10]
    static let defaultFrameRate: Int = 10

    static var currentFrameRate: Int {
        get {
            let stored = UserDefaults.standard.integer(forKey: "pastilleFrameRate")
            return stored > 0 ? stored : defaultFrameRate
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "pastilleFrameRate")
        }
    }

    var panelWindowNumber: Int = 0

    /// Cache des dimensions de la fenêtre cible (évite CGWindowListCopyWindowInfo à chaque frame)
    private var cachedWindowSize: CGSize = .zero
    private var cacheMissCount: Int = 0
    private let cacheRefreshInterval: Int = 10  // Rafraîchir le cache toutes les N frames

    /// Queue dédiée pour la capture (ne bloque pas le main thread)
    private let captureQueue = DispatchQueue(label: "com.pastille.capture", qos: .userInitiated)

    /// Initialisation avec capture liée à une fenêtre spécifique
    init(screenRect: CGRect, windowID: CGWindowID, relativeRect: CGRect) {
        self.screenRect = screenRect
        self.targetWindowID = windowID
        self.relativeRect = relativeRect
        self.logicalSize = NSSize(width: screenRect.width, height: screenRect.height)
    }

    /// Fallback : capture d'une zone écran fixe
    init(rect: CGRect) {
        self.screenRect = rect
        self.targetWindowID = kCGNullWindowID
        self.relativeRect = .zero
        self.logicalSize = NSSize(width: rect.width, height: rect.height)
    }

    func start() {
        // Pré-remplir le cache au démarrage
        if targetWindowID != kCGNullWindowID, let bounds = queryWindowBounds() {
            cachedWindowSize = bounds.size
        }

        let fps = CaptureLoopManager.currentFrameRate
        let timer = DispatchSource.makeTimerSource(queue: captureQueue)
        timer.schedule(deadline: .now(), repeating: 1.0 / Double(fps))
        timer.setEventHandler { [weak self] in
            self?.captureFrame()
        }
        timer.resume()
        self.timer = timer
    }

    func stop() {
        timer?.cancel()
        timer = nil
        DispatchQueue.main.async { [weak self] in
            self?.currentImage = nil
        }
    }

    func restartWithCurrentFrameRate() {
        timer?.cancel()
        timer = nil
        start()
    }

    private func captureFrame() {
        let image: NSImage?
        if targetWindowID != kCGNullWindowID {
            image = captureTargetWindow()
        } else {
            image = captureScreenRect()
        }

        if let image = image {
            DispatchQueue.main.async { [weak self] in
                self?.currentImage = image
            }
        }
    }

    // MARK: - Capture liée à une fenêtre

    private func captureTargetWindow() -> NSImage? {
        guard let fullImage = CGWindowListCreateImage(
            .null,
            .optionIncludingWindow,
            targetWindowID,
            [.boundsIgnoreFraming]
        ) else { return nil }

        // Rafraîchir le cache périodiquement
        cacheMissCount += 1
        if cacheMissCount >= cacheRefreshInterval || cachedWindowSize == .zero {
            cacheMissCount = 0
            if let bounds = queryWindowBounds() {
                cachedWindowSize = bounds.size
            }
        }

        let winW = cachedWindowSize.width > 0 ? cachedWindowSize.width : relativeRect.width
        let winH = cachedWindowSize.height > 0 ? cachedWindowSize.height : relativeRect.height

        let scaleX = CGFloat(fullImage.width) / winW
        let scaleY = CGFloat(fullImage.height) / winH

        let cropPixelRect = CGRect(
            x: relativeRect.origin.x * scaleX,
            y: relativeRect.origin.y * scaleY,
            width: relativeRect.width * scaleX,
            height: relativeRect.height * scaleY
        )

        guard let croppedImage = fullImage.cropping(to: cropPixelRect) else { return nil }
        return NSImage(cgImage: croppedImage, size: logicalSize)
    }

    // MARK: - Capture d'écran brute (fallback)

    private func captureScreenRect() -> NSImage? {
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
            []
        ) else { return nil }

        return NSImage(cgImage: cgImage, size: logicalSize)
    }

    // MARK: - Utilitaires

    private func queryWindowBounds() -> CGRect? {
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

    static func findWindow(at screenRect: CGRect) -> (windowID: CGWindowID, windowBounds: CGRect)? {
        let center = CGPoint(x: screenRect.midX, y: screenRect.midY)
        let myPID = ProcessInfo.processInfo.processIdentifier

        guard let windowInfoList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else { return nil }

        for info in windowInfoList {
            guard let windowNumber = info[kCGWindowNumber as String] as? Int,
                  let ownerPID = info[kCGWindowOwnerPID as String] as? Int,
                  let boundsDict = info[kCGWindowBounds as String] as? NSDictionary else { continue }

            if ownerPID == Int(myPID) { continue }
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
