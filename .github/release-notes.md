## Cài đặt
1. Tải **SKey-{{VERSION}}.dmg** bên dưới (hoặc bản `.zip`), mở ra và kéo **SKey.app** vào **Applications**.
2. Mở SKey. macOS sẽ báo **"SKey" Not Opened: Apple could not verify "SKey" is free of malware…**
   Đây là thông báo **bình thường cho mọi app chưa được Apple notarize**, không có nghĩa Apple tìm thấy mã độc (SKey phát hành miễn phí nên không notarize). Muốn chắc chắn, hãy [kiểm tra file tải về](#kiểm-tra-file-tải-về) trước.
   - Bấm **Done** (đừng bấm *Move to Trash*).
   - Vào **System Settings → Privacy & Security**, kéo xuống phần **Security**, bấm **Open Anyway** cạnh dòng *"SKey" was blocked…*, xác nhận bằng mật khẩu hoặc Touch ID.
   - Hoặc chạy lệnh: `xattr -dr com.apple.quarantine /Applications/SKey.app`
3. Làm theo màn hình **Cài đặt SKey**: cấp quyền **Accessibility**, chỉ giữ input source **ABC** (xoá Simple Telex), tắt tự sửa chính tả và gợi ý chữ của macOS.

**Nếu đang dùng bản cũ:** thoát SKey, thay bằng bản mới trong Applications, mở lại. macOS coi mỗi bản là một app khác nên quyền Accessibility cũ không còn hiệu lực: trong màn hình cài đặt, bấm **Làm mới quyền** rồi bật lại SKey.

## Kiểm tra file tải về
Các file này do GitHub Actions build trực tiếp từ mã nguồn trong repo và có chứng thực nguồn gốc. Kiểm tra bằng [GitHub CLI](https://cli.github.com):
```
gh attestation verify SKey-{{VERSION}}.dmg -R SLyHuy/SKey
```
Hoặc so checksum:
```
shasum -a 256 SKey-{{VERSION}}.dmg
```
với dòng tương ứng trong file `SKey-{{VERSION}}.sha256`.

---
**SKey**: bộ gõ Telex tối giản cho macOS, tối ưu cho lập trình viên. Không kết nối mạng, không ghi lại phím gõ.
Giấy phép GPL-3.0 © 2026 Huy Ly · Mã nguồn: https://github.com/SLyHuy/SKey · Báo lỗ hổng: [SECURITY.md](https://github.com/SLyHuy/SKey/blob/master/SECURITY.md)
