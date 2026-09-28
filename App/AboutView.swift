import SwiftUI

struct AboutView: View {
    let hotkey: ToggleHotkey

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 96, height: 96)
                Text("SKey").font(.largeTitle.bold())
                Text("Phiên bản \(version)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text("Bộ gõ Telex tối giản, tối ưu cho lập trình viên")
                    .font(.title3)
                    .padding(.top, 4)
            }

            VStack(alignment: .leading, spacing: 14) {
                Feature(icon: "chevron.left.forwardslash.chevron.right",
                        title: "Gõ song ngữ, không cần chuyển",
                        detail: "class, function, useState… không bao giờ bị thêm dấu; comment tiếng Việt gõ bình thường. Không tự sửa chữ sau lưng bạn.")
                Feature(icon: "character.cursor.ibeam",
                        title: "Bỏ dấu ngay như Unikey",
                        detail: "Gõ lặp phím dấu để giữ tiếng Anh: consst → const, usser → user, tesst → test.")
                Feature(icon: "terminal",
                        title: "Tự dùng tiếng Anh trong Terminal",
                        detail: "Terminal, iTerm2, Warp, Ghostty… và bất kỳ app nào bạn chọn.")
                Feature(icon: "bolt",
                        title: "Nhanh, nhẹ, làm đúng một việc",
                        detail: "Chỉ Telex, xuất Unicode dựng sẵn. Không gõ tắt, không bảng mã thừa.")
                Feature(icon: "lock.shield",
                        title: "Riêng tư",
                        detail: "Không kết nối mạng, không ghi lại phím gõ.")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 4) {
                Text("Chuyển Vi/En: \(hotkey.title)")
                Text("© 2026 Huy Ly")
            }
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 32)
        .padding(.top, 8)
        .padding(.bottom, 28)
        .frame(width: 460)
    }

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }
}

private struct Feature: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
