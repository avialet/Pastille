import Cocoa

struct PermissionManager {

    /// Vérifie si la permission d'enregistrement d'écran est accordée
    static func hasScreenCapturePermission() -> Bool {
        return CGPreflightScreenCaptureAccess()
    }

    /// Demande la permission d'enregistrement d'écran (ouvre le dialogue système)
    static func requestScreenCapturePermission() {
        CGRequestScreenCaptureAccess()
    }

    /// Ouvre les Réglages Système à la section Enregistrement d'écran
    static func openSystemPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}
