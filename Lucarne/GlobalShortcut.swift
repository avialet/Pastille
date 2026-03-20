import Cocoa
import Carbon

class GlobalShortcut {
    static let shared = GlobalShortcut()
    private var hotKeyRef: EventHotKeyRef?
    private static var onTrigger: (() -> Void)?

    private init() {}

    func register(callback: @escaping () -> Void) {
        GlobalShortcut.onTrigger = callback

        let hotKeyID = EventHotKeyID(
            signature: OSType(0x4C554341), // "LUCA"
            id: 1
        )

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        // Installer le handler d'événements Carbon
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_: EventHandlerCallRef?, _: EventRef?, _: UnsafeMutableRawPointer?) -> OSStatus in
                GlobalShortcut.onTrigger?()
                return noErr
            },
            1,
            &eventType,
            nil,
            nil
        )

        // Cmd + Option + L (kVK_ANSI_L = 0x25)
        RegisterEventHotKey(
            UInt32(kVK_ANSI_L),
            UInt32(cmdKey | optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        GlobalShortcut.onTrigger = nil
    }
}
