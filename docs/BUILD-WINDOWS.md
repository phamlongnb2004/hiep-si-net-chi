# Dựng bản Windows

Ứng dụng gốc viết bằng **Godot 4.5.1** (thư mục `client/`), xuất ra một file `.exe` (đã gộp sẵn dữ liệu) rồi đóng thành trình cài đặt bằng **NSIS**.

## Cần có (máy Linux)
- Godot 4.5.1: `Godot_v4.5.1-stable_linux.x86_64` (github.com/godotengine/godot/releases) — đặt biến `GODOT` trỏ tới file này.
- Export templates 4.5.1: giải nén `windows_release_x86_64.exe` (và `version.txt`) vào `~/.local/share/godot/export_templates/4.5.1.stable/`.
- `makensis` (gói `nsis`).

## Dựng
```bash
GODOT=~/godot/Godot_v4.5.1-stable_linux.x86_64 tools/build-native.sh 2.0.0 1 20000
```
Kết quả:
- `build/windows/HiepSiNetChi.exe` — game (khoảng 125 MB, đã gộp dữ liệu).
- `build/HiepSiNetChi-Setup.exe` — trình cài đặt (khoảng 54 MB).

## Trình cài đặt (`installer/hsnc.nsi`)
- Không cần quyền quản trị: cài vào `%LOCALAPPDATA%\HiepSiNetChi`, tạo biểu tượng trên Desktop và menu Start, mục gỡ cài đặt trong Cài đặt Windows.
- Cài đè lên bản cũ được (tự đóng game đang mở).
- Dữ liệu người chơi (phiên đăng nhập, gói dữ liệu đã tải) nằm ở `%APPDATA%\Godot\app_userdata\Hiệp Sĩ Nét Chì` và được giữ lại khi gỡ.

## Chạy thử không cần Windows
```bash
cd client
HSNC_SERVER=http://localhost:8799 xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 -- autotest=/tmp/shots
```
Bản tự chạy: đăng ký tài khoản mới, vào máy chủ, tạo nhân vật, qua cổng, đánh quái, mở túi đồ, chụp màn hình từng bước. Thêm `HSNC_TOUCH=1` để xem giao diện cảm ứng.

## Ghi chú
- File `.exe` chưa ký số (code signing), Windows SmartScreen sẽ hỏi "Vẫn chạy". Muốn hết cảnh báo cần mua chứng chỉ ký mã.
- Biểu tượng trong file `.exe` dùng biểu tượng mặc định của Godot (đổi cần `rcedit`); trình cài đặt và lối tắt dùng biểu tượng game.
