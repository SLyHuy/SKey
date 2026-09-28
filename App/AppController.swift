import AppKit
import Observation
import ServiceManagement
import SwiftUI

/// Wires the pieces together: permission, event tap, key router, app and input source
/// tracking, windows.
@MainActor
@Observable
final class AppController {
    static let shared = AppController()

    let state = AppState()
    private(set) var launchAtLogin = SMAppService.mainApp.status == .enabled

    @ObservationIgnored private let tap = KeyboardTap()
    @ObservationIgnored private let router: KeyRouter
    @ObservationIgnored private var frontAppMonitor: FrontAppMonitor?
    @ObservationIgnored private var inputSourceObserver: AnyObject?
    @ObservationIgnored private var permissionTimer: Timer?
    @ObservationIgnored private var onboardingWindow: NSWindow?
    @ObservationIgnored private var aboutWindow: NSWindow?

    private init() {
        router = KeyRouter(state: state)
        router.onToggle = { [weak self] in self?.toggleLanguage() }
        tap.delegate = router
    }

    /// Called once the app has finished launching (never while SwiftUI builds views).
    func start() {
        frontAppMonitor = FrontAppMonitor { [weak self] app in
            self?.state.frontApp = app
            self?.router.reset()
        }
        updateInputSource()
        inputSourceObserver = InputSourceCheck.observe { [weak self] in self?.updateInputSource() }

        checkPermission()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.checkPermission()
                self.updateInputSource()  // safety net if a change notification is missed
                if self.onboardingWindow?.isVisible == true { self.refreshTips() }
            }
        }

        // Show the guide when SKey cannot work yet, or once if macOS settings need attention.
        refreshTips()
        let tipsNeedAttention = state.systemTips.contains { !$0.ok }
        if !state.permissionGranted || (tipsNeedAttention && !UserDefaults.standard.bool(forKey: Self.guideSeenKey)) {
            showOnboarding()
        }
    }

    private static let guideSeenKey = "setupGuideSeen"

    private func refreshTips() {
        let tips = SystemTips.current(hotkey: state.hotkey)
        if tips != state.systemTips { state.systemTips = tips }
    }

    func toggleLanguage() {
        state.isVietnamese.toggle()
        router.reset()
        if state.beepOnToggle { NSSound.beep() }
    }

    // MARK: - Permission

    private func checkPermission() {
        let trusted = Permissions.isTrusted
        if trusted, !tap.isRunning {
            _ = tap.start()
        } else if !trusted, tap.isRunning {
            tap.stop()
            router.reset()
        }
        let granted = trusted && tap.isRunning
        guard granted != state.permissionGranted else { return }
        state.permissionGranted = granted
        // Close the guide by itself only if nothing else in it needs attention.
        if granted, onboardingWindow?.isVisible == true, state.systemTips.allSatisfy(\.ok) {
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(1))
                self?.onboardingWindow?.close()
            }
        }
    }

    func showOnboarding() {
        refreshTips()
        UserDefaults.standard.set(true, forKey: Self.guideSeenKey)
        if onboardingWindow == nil {
            let view = OnboardingView(
                state: state,
                openAccessibility: {
                    Permissions.prompt()
                    Permissions.openSettings()
                },
                refreshPermission: {
                    Permissions.resetOwnEntry()
                    Permissions.prompt()
                    Permissions.openSettings()
                },
                openKeyboardSettings: {
                    if let url = SystemTips.openKeyboardSettings() { NSWorkspace.shared.open(url) }
                },
                close: { [weak self] in self?.onboardingWindow?.close() }
            )
            let window = NSWindow(contentViewController: NSHostingController(rootView: view))
            window.title = "Cài đặt SKey"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            onboardingWindow = window
        }
        NSApp.activate()
        onboardingWindow?.makeKeyAndOrderFront(nil)
    }

    // MARK: - Input source

    private func updateInputSource() {
        let status = InputSourceCheck.current()
        guard status.inputMethod != state.activeInputMethod else { return }
        state.activeInputMethod = status.inputMethod
        state.activeInputMethodIsVietnamese = status.isAppleVietnamese
        router.reset()
    }

    // MARK: - Menu actions

    func setLaunchAtLogin(_ on: Bool) {
        do {
            if on {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSSound.beep()
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    func showAbout() {
        let window = aboutWindow ?? {
            let w = NSWindow(contentViewController: NSHostingController(rootView: AboutView(hotkey: state.hotkey)))
            w.styleMask = [.titled, .closable, .fullSizeContentView]
            w.titlebarAppearsTransparent = true
            w.titleVisibility = .hidden
            w.isMovableByWindowBackground = true
            w.isReleasedWhenClosed = false
            w.center()
            aboutWindow = w
            return w
        }()
        (window.contentViewController as? NSHostingController<AboutView>)?.rootView = AboutView(hotkey: state.hotkey)
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    /// Installed apps from the English-only list, with their names.
    func installedEnglishApps() -> [AppInfo] {
        state.englishApps.compactMap { id in
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) else { return nil }
            let name = FileManager.default.displayName(atPath: url.path)
            return AppInfo(bundleID: id, name: name.hasSuffix(".app") ? String(name.dropLast(4)) : name)
        }
    }
}
