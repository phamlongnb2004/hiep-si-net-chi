#!/bin/sh
# Cài Hiệp Sĩ Nét Chì cho người dùng hiện tại (không cần sudo): chép game, tạo biểu tượng trong menu ứng dụng.
set -e
D="$(cd "$(dirname "$0")" && pwd)"
APP="$HOME/.local/share/HiepSiNetChi"
mkdir -p "$APP" "$HOME/.local/share/applications"
cp "$D/HiepSiNetChi.x86_64" "$D/icon.png" "$D/uninstall.sh" "$APP/"
chmod +x "$APP/HiepSiNetChi.x86_64" "$APP/uninstall.sh"
cat > "$HOME/.local/share/applications/hiepsinetchi.desktop" <<DESK
[Desktop Entry]
Type=Application
Name=Hiệp Sĩ Nét Chì
Comment=Game nhập vai cuộn ngang online
Exec="$APP/HiepSiNetChi.x86_64"
Icon=$APP/icon.png
Terminal=false
Categories=Game;RolePlaying;
DESK
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$HOME/.local/share/applications" || true
echo "Đã cài vào $APP. Mở game từ menu ứng dụng (Hiệp Sĩ Nét Chì) hoặc chạy: $APP/HiepSiNetChi.x86_64"
