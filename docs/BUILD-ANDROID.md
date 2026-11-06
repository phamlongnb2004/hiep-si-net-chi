# Dựng bản Android

APK gốc Godot, cùng tên gói **`vn.hiepsinetchi.game`** và ký bằng **khóa cũ** (`~/pwab/signing.keystore` trên máy VM) để cài đè lên ứng dụng vỏ cũ mà không phải gỡ. `versionCode` bắt đầu từ **20000** (lớn hơn bản cũ).

## Cần có
- Godot 4.5.1 + export templates (`android_release.apk`, `android_debug.apk`, `android_source.zip`, `version.txt`).
- Java 17 trở lên.
- Một trong hai cách:
  1. **Android SDK thật** (cần mở `dl.google.com`, `maven.google.com`, `repo1.maven.org` trong claude.ai → Settings → Capabilities nếu dựng ở đây), đặt `export/android/android_sdk_path` trong Editor Settings.
  2. **Không có SDK** (cách đang dùng): tạo thư mục SDK giả chỉ để Godot qua bước kiểm tra, xuất APK *chưa ký*, rồi ký bằng `uber-apk-signer` (tải từ GitHub, có sẵn zipalign + apksigner):
     ```bash
     mkdir -p ~/fake-android-sdk/platform-tools ~/fake-android-sdk/build-tools/35.0.0
     printf '#!/bin/sh\nexit 0\n' > ~/fake-android-sdk/platform-tools/adb
     printf '#!/bin/sh\nexit 0\n' > ~/fake-android-sdk/build-tools/35.0.0/apksigner
     chmod +x ~/fake-android-sdk/*/adb ~/fake-android-sdk/build-tools/35.0.0/apksigner
     # Editor Settings (~/.config/godot/editor_settings-4.5.tres):
     # export/android/android_sdk_path = "/home/<bạn>/fake-android-sdk"
     ```
     Preset Android trong `client/export_presets.cfg` đặt `package/signed=false`.

## Dựng và ký
```bash
tools/build-native.sh 2.0.0 1 20000          # tạo build/android/HiepSiNetChi-unsigned.apk
java -jar ~/tools/uber-apk-signer.jar -a build/android/HiepSiNetChi-unsigned.apk \
  --ks ~/pwab/signing.keystore --ksAlias <alias> --ksPass <mật khẩu> --ksKeyPass <mật khẩu khóa> -o build/android/signed
```
`tools/publish.sh` làm bước ký này tự động (đọc `KS_ALIAS`, `KS_PASS`, `KS_KEY_PASS` từ biến môi trường). Không bao giờ đưa keystore hay mật khẩu vào kho mã.

## Cấu hình chính (preset "Android")
- Hai kiến trúc `arm64-v8a`, `armeabi-v7a`; màn hình ngang (xoay theo cảm biến), toàn màn hình.
- Quyền: `INTERNET`, `ACCESS_NETWORK_STATE`, `VIBRATE`.
- Nút Quay lại mở bảng tùy chọn thay vì thoát ngay.

## Cập nhật trên Android
Ứng dụng không tự thay APK. Khi máy chủ báo có bản mới (hoặc bản cũ không còn được hỗ trợ), game hiện thông báo và người chơi tải lại tại `/tai-game`, cài đè (giữ nguyên tài khoản vì dữ liệu nằm trên máy chủ). Dữ liệu ảnh mới (gói `.pck`) thì game tự tải khi mở.
