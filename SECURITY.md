# Bảo mật

SKey là bộ gõ: nó nhìn thấy mọi phím bạn gõ. Vì vậy mọi lỗ hổng có thể làm lộ, lưu lại hay gửi đi chữ bạn gõ đều được coi là nghiêm trọng.

## Phiên bản được hỗ trợ

Chỉ **bản mới nhất** trên [trang Releases](https://github.com/SLyHuy/SKey/releases/latest) được sửa lỗi bảo mật. Hãy luôn cập nhật lên bản mới nhất.

## Báo cáo lỗ hổng

**Đừng mở Issue công khai** cho lỗ hổng bảo mật.

Hãy báo riêng qua GitHub: vào tab **Security** của repo → **Report a vulnerability**, hoặc mở thẳng
[github.com/SLyHuy/SKey/security/advisories/new](https://github.com/SLyHuy/SKey/security/advisories/new).
Chỉ bạn và người duy trì dự án thấy được báo cáo này.

Nên có trong báo cáo:
- Phiên bản SKey và macOS.
- Các bước tái hiện, và ảnh hưởng (ví dụ: chữ gõ bị ghi ra đâu, gửi đi đâu, ai đọc được).
- Bản vá hoặc cách khắc phục, nếu bạn có.

Người duy trì sẽ cố gắng phản hồi trong vài ngày, cùng bạn xác nhận lỗi, và công bố bản sửa kèm ghi nhận đóng góp của bạn (nếu bạn muốn).

## Những gì được coi là lỗ hổng

- Chữ gõ hoặc nội dung đọc qua Accessibility bị ghi ra đĩa, log, clipboard, hoặc gửi ra ngoài máy.
- SKey đọc hay giữ nhiều hơn giới hạn đã công bố (tối đa 14 ký tự trước con trỏ, bộ nhớ tạm 21 ký tự, chỉ trong RAM).
- SKey xử lý phím trong ô mật khẩu (Secure Input).
- Bản phát hành không khớp mã nguồn, hoặc quy trình build/phát hành có thể bị chèn mã.

## Kiểm chứng bản phát hành

Mọi bản phát hành đều được GitHub Actions build từ mã nguồn trong repo và có chứng thực nguồn gốc (build attestation). Kiểm tra file bạn tải về bằng [GitHub CLI](https://cli.github.com):

```bash
gh attestation verify SKey-x.y.z.dmg -R SLyHuy/SKey
```

Thiết kế về quyền riêng tư được mô tả trong mục "Quyền riêng tư & bảo mật" của [README](README.md#quyền-riêng-tư--bảo-mật).
