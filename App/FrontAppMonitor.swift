import AppKit

/// Tracks the app the user is typing in, via notifications, so the key path never has
/// to query NSWorkspace.
@MainActor
final class FrontAppMonitor {
    private var observer: NSObjectProtocol?
    private let onChange: (AppInfo) -> Void

    init(onChange: @escaping (AppInfo) -> Void) {
        self.onChange = onChange
        if let app = NSWorkspace.shared.frontmostApplication { report(app) }
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] note in
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            MainActor.assumeIsolated {
                if let app { self?.report(app) }
            }
        }
    }

    private func report(_ app: NSRunningApplication) {
        guard let id = app.bundleIdentifier, id != Bundle.main.bundleIdentifier else { return }
        onChange(AppInfo(bundleID: id, name: app.localizedName ?? id))
    }
}
