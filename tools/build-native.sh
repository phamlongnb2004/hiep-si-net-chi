#!/usr/bin/env bash
# Dựng ứng dụng gốc (Godot 4.5.1): Windows (trình cài NSIS), Android (APK chưa ký), gói dữ liệu cập nhật (.pck).
# Chạy trên Linux có: Godot 4.5.1 + export templates, makensis, Java 17+ (xem docs/BUILD-WINDOWS.md, docs/BUILD-ANDROID.md).
# Dùng: tools/build-native.sh <phiên-bản-app> <số-bản-dữ-liệu> <versionCode-android>
#   vd: tools/build-native.sh 2.0.0 1 20000
set -euo pipefail
VER=${1:?phiên bản app, vd 2.0.0}; AV=${2:?số bản dữ liệu, vd 1}; CODE=${3:?versionCode Android, vd 20000}
GODOT=${GODOT:-godot}
ROOT=$(cd "$(dirname "$0")/.." && pwd); C="$ROOT/client"; B="$ROOT/build"
mkdir -p "$B/windows" "$B/android"
# phiên bản ghi vào project + preset
sed -i "s/^config\/version=.*/config\/version=\"$VER\"/" "$C/project.godot"
sed -i "s/^version\/name=.*/version\/name=\"$VER\"/; s/^version\/code=.*/version\/code=$CODE/; s/^application\/file_version=.*/application\/file_version=\"$VER.0\"/; s/^application\/product_version=.*/application\/product_version=\"$VER.0\"/" "$C/export_presets.cfg"
cp "$ROOT/shared/data.json" "$C/data/data.json"
"$GODOT" --headless --path "$C" --import >/dev/null 2>&1 || true
"$GODOT" --headless --path "$C" --export-release "Windows" "$B/windows/HiepSiNetChi.exe"
"$GODOT" --headless --path "$C" --export-release "Android" "$B/android/HiepSiNetChi-unsigned.apk"
"$GODOT" --headless --path "$C" --script res://tools/make_pack.gd -- out="$B/assets-$AV.pck"
( cd "$ROOT/installer" && makensis -V2 -DVERSION="$VER" -DSRC="$B/windows/HiepSiNetChi.exe" -DOUT="$B/HiepSiNetChi-Setup.exe" hsnc.nsi )
ls -la "$B" "$B/android"
echo "Xong. Tiếp theo (trên máy giữ khóa): tools/publish.sh $VER $AV"
