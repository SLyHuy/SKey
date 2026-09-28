import SKeyEngine
import SwiftUI

@main
struct SKeyApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    private let controller = AppController.shared

    var body: some Scene {
        MenuBarExtra {
            MenuContent(controller: controller)
        } label: {
            Image(nsImage: controller.state.showsVietnamese ? StatusIcon.vietnamese : StatusIcon.english)
        }
        .menuBarExtraStyle(.menu)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppController.shared.start()
    }
}

private struct MenuContent: View {
    let controller: AppController

    var body: some View {
        @Bindable var state = controller.state

        // Like macOS' Input menu: one row per language, the active one checked.
        Toggle(isOn: Binding(get: { state.isVietnamese }, set: { if $0 { state.isVietnamese = true } })) {
            Label { Text("Tiếng Việt") } icon: { Image(nsImage: StatusIcon.vietnamese) }
        }
        Toggle(isOn: Binding(get: { !state.isVietnamese }, set: { if $0 { state.isVietnamese = false } })) {
            Label { Text("English") } icon: { Image(nsImage: StatusIcon.english) }
        }
        Text("Chuyển nhanh: \(state.hotkey.symbol)")

        if let method = state.activeInputMethod {
            if state.activeInputMethodIsVietnamese {
                Text("⚠︎ Đang bật \(method) của macOS. Hãy chuyển về ABC.")
            } else {
                Text("SKey tạm nghỉ khi dùng \(method)")
            }
        }
        if !state.permissionGranted {
            Button("⚠︎ Cấp quyền Accessibility…") { controller.showOnboarding() }
        }

        Divider()

        if let app = state.frontApp {
            Toggle("Luôn tiếng Anh trong \(app.name)", isOn: Binding(
                get: { state.englishApps.contains(app.bundleID) },
                set: { state.setEnglishOnly(app.bundleID, $0) }
            ))
        }
        Menu("App luôn dùng tiếng Anh") {
            let apps = controller.installedEnglishApps()
            ForEach(apps, id: \.bundleID) { app in
                Button("Bỏ \(app.name)") { state.setEnglishOnly(app.bundleID, false) }
            }
            if apps.isEmpty {
                Text("Chưa có app nào")
            }
            Divider()
            Button("Khôi phục mặc định (các terminal)") { state.englishApps = AppState.defaultEnglishApps }
        }

        Menu("Tuỳ chọn") {
            Picker("Phím tắt chuyển Vi/En", selection: $state.hotkey) {
                ForEach(ToggleHotkey.allCases) { Text($0.title).tag($0) }
            }
            Picker("Kiểu đặt dấu", selection: $state.toneStyle) {
                Text("Kiểu cũ: hòa, thúy").tag(ToneStyle.old)
                Text("Kiểu mới: hoà, thuý").tag(ToneStyle.new)
            }
            Divider()
            Toggle("Âm báo khi chuyển Vi/En", isOn: $state.beepOnToggle)
            Toggle("Chống mất chữ do gợi ý/tự hoàn thành", isOn: $state.fixSuggestions)
            Toggle("Sửa dấu từ đã gõ khi quay lại bằng chuột/mũi tên", isOn: $state.editPreviousWords)
            Toggle("Khởi động cùng macOS", isOn: Binding(
                get: { controller.launchAtLogin },
                set: { controller.setLaunchAtLogin($0) }
            ))
        }

        Divider()

        Button("Hướng dẫn cài đặt…") { controller.showOnboarding() }
        Button("Giới thiệu SKey") { controller.showAbout() }
        Button("Thoát SKey") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}
