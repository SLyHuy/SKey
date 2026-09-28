import SwiftUI

/// Setup guide: the Accessibility permission, then macOS settings that interfere with
/// typing. Every item shows its live status.
struct OnboardingView: View {
    let state: AppState
    let openAccessibility: () -> Void
    let refreshPermission: () -> Void
    let openKeyboardSettings: () -> Void
    let close: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(nsImage: StatusIcon.vietnamese)
                    .resizable()
                    .frame(width: 48, height: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cài đặt SKey").font(.title2.bold())
                    Text("Không kết nối mạng, không ghi lại phím gõ.")
                        .foregroundStyle(.secondary)
                }
            }

            permissionSection
            Divider()
            tipsSection

            HStack {
                Spacer()
                Button("Xong", action: close)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 540)
    }

    // MARK: - 1. Permission

    @ViewBuilder
    private var permissionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                StatusMark(ok: state.permissionGranted)
                Text("1. Quyền Accessibility").font(.headline)
            }
            if state.permissionGranted {
                Text("\(appName) đã có quyền và đang hoạt động.")
                    .foregroundStyle(.secondary)
            } else {
                Text("SKey cần quyền này để đọc phím bạn gõ và chuyển thành chữ tiếng Việt.")
                Text("Bấm **Mở cài đặt Accessibility**, bật **\(appName)**, rồi quay lại đây.")
                Text("Đã bật mà vẫn chưa có quyền? Việc này thường gặp sau khi cập nhật SKey: bấm **Làm mới quyền** rồi bật lại.")
                    .foregroundStyle(.secondary)
                HStack {
                    Button("Làm mới quyền", action: refreshPermission)
                    Button("Mở cài đặt Accessibility", action: openAccessibility)
                        .buttonStyle(.borderedProminent)
                    ProgressView().controlSize(.small).padding(.leading, 4)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - 2. macOS settings

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("2. Nên chỉnh trong macOS").font(.headline)
            Text("System Settings → Keyboard → Text Input → **Edit…**")
                .foregroundStyle(.secondary)
            ForEach(state.systemTips) { tip in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    StatusMark(ok: tip.ok)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tip.title)
                        Text(tip.detail)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            Button("Mở cài đặt Bàn phím", action: openKeyboardSettings)
        }
    }

    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "SKey"
    }
}

private struct StatusMark: View {
    let ok: Bool

    var body: some View {
        Image(systemName: ok ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
            .foregroundStyle(ok ? .green : .orange)
    }
}
