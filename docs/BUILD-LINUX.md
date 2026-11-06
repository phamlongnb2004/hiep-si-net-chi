# Dựng bản Linux

Cùng mã Godot với bản Windows/Android, xuất bằng preset **"Linux"** (x86_64, dữ liệu gộp trong file chạy).

- Cần export template `linux_release.x86_64` (4.5.1) trong `~/.local/share/godot/export_templates/4.5.1.stable/`.
- `tools/build-native.sh` tự xuất `build/linux/HiepSiNetChi.x86_64` và đóng gói `build/HiepSiNetChi-Linux.tar.gz` gồm: file game, `icon.png`, `install.sh`, `uninstall.sh`, `DOC-TRUOC.txt` (thư mục `installer/linux/`).
- `install.sh` cài vào `~/.local/share/HiepSiNetChi` và tạo lối tắt trong menu ứng dụng, không cần sudo.
- Yêu cầu máy: Linux 64-bit có X11/Wayland, OpenGL 3.3, có mạng.
- Đã chạy thử chính file xuất ra (xvfb + Mesa): đăng ký, tạo nhân vật, qua cổng, đánh quái, mở túi đồ.
- Link tải cố định: `/tai/linux` (đọc `app.linux.url` trong `update/latest.json`).
