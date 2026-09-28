# SKey

Bộ gõ **Telex** tối giản cho macOS. Làm đúng một việc: gõ tiếng Việt kiểu Telex, xuất **Unicode dựng sẵn**, gõ song ngữ Việt/Anh khi viết code, không bao giờ tự sửa chữ sau lưng bạn.

- Không gõ tắt, không bảng mã khác, không tự cập nhật.
- **Không có code kết nối mạng, không ghi lại phím gõ.**
- Icon **Vi/En** trên menu bar, phím tắt chuyển mặc định **⌥ Space**.

## Cài đặt (người dùng)

SKey được phát hành **không kèm chứng chỉ Apple** (chữ ký ad-hoc), nên lần đầu cần vài bước:

1. Tải `SKey-x.y.z.zip`, kiểm tra checksum nếu muốn: `shasum -a 256 SKey-x.y.z.zip` (so với file `.sha256`).
2. Giải nén, kéo **SKey.app** vào **Applications**.
3. Mở SKey. macOS sẽ chặn vì "không xác minh được nhà phát triển":
   vào **System Settings → Privacy & Security**, kéo xuống, bấm **Open Anyway**.
   Hoặc chạy lệnh sau trong Terminal:
   ```bash
   xattr -dr com.apple.quarantine /Applications/SKey.app
   ```
4. SKey hiện màn hình **Cài đặt SKey**: bấm **Mở cài đặt Accessibility**, bật **SKey**. SKey tự hoạt động, không cần mở lại.
5. Cũng trong màn hình đó, làm theo các mục còn dấu ⚠︎. Mỗi mục tự chuyển sang ✓ khi bạn chỉnh xong. Tất cả nằm trong **System Settings → Keyboard → Text Input → Edit…**:
   - Tắt **Correct spelling automatically**, **Capitalize words automatically**, **Show inline predictive text**.
   - Chỉ giữ **ABC**, xoá Simple Telex (bộ gõ tiếng Việt của macOS).
   - Nếu phím chuyển Vi/En của SKey trùng phím tắt đổi input source của macOS, tắt phím tắt đó trong **Keyboard Shortcuts… → Input Sources**.

   Mở lại màn hình này bất cứ lúc nào bằng menu SKey → **Hướng dẫn cài đặt…**

### Khi cập nhật phiên bản mới
Với bản ký ad-hoc, macOS coi mỗi bản build là một app khác nên **quyền Accessibility cũ không còn hiệu lực**, dù trong danh sách vẫn thấy SKey đang bật. Khi SKey hiện lại cửa sổ xin quyền, bấm **Làm mới quyền** rồi bật lại SKey. Làm tay cũng được: chọn SKey trong danh sách, bấm **−**, rồi thêm lại.

## Cách dùng

| Việc | Cách làm |
|---|---|
| Chuyển Vi/En | Phím tắt (mặc định ⌥ Space), hoặc menu **Gõ tiếng Việt** |
| Đổi phím tắt | Menu → **Phím tắt chuyển Vi/En**: ⌥ Space, ⌃ Space, ⌃ ⇧, ⌥ ⇧ |
| Luôn tiếng Anh trong một app | Mở app đó, rồi menu → **Luôn tiếng Anh trong <App>**. Mặc định đã có các terminal |
| Kiểu đặt dấu | Menu → **Kiểu đặt dấu**: kiểu cũ (hòa, thúy) hoặc kiểu mới (hoà, thuý) |

### Quy tắc Telex
`s f r x j` là sắc, huyền, hỏi, ngã, nặng; `z` xoá dấu. `aa ee oo` ra â ê ô; `aw ow uw` ra ă ơ ư; `uow` ra ươ; `w` đứng riêng (không có nguyên âm trước) **giữ nguyên là w**, khác Unikey, để gõ code nhanh hơn; `dd` ra đ.
Dấu gõ muộn cũng được, kể cả sau phụ âm cuối: `tieengs`, `tieesng`, `hienej` (hiện), `tiengse` (tiếng), `nguoiwf` (người), `dodongj` (động).

### Sửa dấu cho từ đã gõ
- **Bằng ⌫**: gõ `taan`, bấm cách, ⌫ để lùi về "tân", gõ `j` ra "tận". Thêm hoặc đổi dấu, đổi `d` thành `đ` (`dang ⌫ d` → đang) đều được. Chạy ở mọi app.
- **Bằng chuột hoặc phím mũi tên**: đặt con trỏ ngay **cuối** từ cần sửa rồi gõ phím dấu. SKey đọc từ trước con trỏ qua Accessibility. Tính năng này chỉ chạy ở những app cho phép đọc chữ (hầu hết app macOS, trình duyệt); con trỏ nằm giữa từ thì SKey không động vào. Tắt được trong menu → Tuỳ chọn.

### Gõ song ngữ (viết code, comment)
- **SKey không bao giờ tự sửa chữ đã gõ.** Chữ hiện ra thế nào thì giữ thế ấy, kể cả khi kết thúc từ. Gõ nhầm (ví dụ `taank` ra "tânk") thì bấm ⌫ sửa lại: "tân", rồi gõ `j` ra "tận".
- Từ không thể là tiếng Việt thì không bao giờ bị thêm dấu: `class`, `function`, `return`, `window`, `string`, `useState`.
- Từ tiếng Anh mà phím gõ tạo thành dấu tiếng Việt thì **gõ lặp phím dấu** để bỏ dấu, như Unikey: `consst` → const, `usser` → user, `serrver` → server, `dataa` → data, `iff` → if, `tesst` → test, `passs` → pass, `errror` → error. Gõ lặp có hiệu lực ngay: `nex` ra nẽ, gõ thêm `x` ra nex.

## Phát triển

Yêu cầu: macOS 14 trở lên, Xcode 16 trở lên, [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```bash
xcodegen generate            # tạo SKey.xcodeproj từ project.yml
open SKey.xcodeproj          # chạy scheme SKey → app "SKey Dev"
cd Packages/SKeyEngine && swift test   # test engine Telex
```

**Ký bản dev bằng chứng chỉ miễn phí**, để giữ quyền Accessibility qua các lần build:
1. Xcode → Settings → Accounts → thêm Apple ID (Personal Team).
2. Tạo file cấu hình local từ file mẫu:
   ```bash
   cp Config/Local.xcconfig.example Config/Local.xcconfig
   ```
   rồi điền Team ID vào `Config/Local.xcconfig`.

Bản dev dùng bundle id `com.huyly.skey.dev` (tên **SKey Dev**), tách biệt với bản release `com.huyly.skey`, nên quyền của hai bản không đè lên nhau. Không có `Local.xcconfig` thì bản dev ký ad-hoc và phải cấp lại quyền sau mỗi lần build.

**Phát hành:**
```bash
./scripts/release.sh
```
Script chạy test, build universal (arm64 + x86_64), ký ad-hoc, rồi tạo `dist/SKey-<version>.zip` và file `.sha256`. Phiên bản đặt ở `MARKETING_VERSION` trong `project.yml`.

## Cấu trúc

```
Packages/SKeyEngine/   Engine Telex thuần Swift (không dùng AppKit) + test (Swift Testing)
  TelexEngine.swift    Nhận phím, tính lại cả từ, trả về phần cần sửa (xoá n ký tự + chèn chuỗi)
  Syllable.swift       Cấu trúc âm tiết, kiểm tra hợp lệ, vị trí dấu
App/
  KeyboardTap.swift    CGEventTap, tự bật lại khi macOS tắt tap, gửi phím
  KeyRouter.swift      Phân loại phím: chữ, ngắt từ, backspace, di chuyển con trỏ, phím tắt
  AppController.swift  Quyền truy cập, theo dõi app và input source, cửa sổ
```
