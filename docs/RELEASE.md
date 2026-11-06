# Quy trình phát hành

## Hai loại cập nhật
| | Gói dữ liệu (`assets-N.pck`) | Ứng dụng (`.exe` / `.apk`) |
|---|---|---|
| Chứa | ảnh, số liệu luật chơi (`data.json`) | mã chương trình + dữ liệu đi kèm |
| Ai tải | **game tự tải** khi mở, áp dụng lần mở sau | người chơi tải ở `/tai-game`, cài đè |
| Khi nào | đổi hình, cân lại số liệu | đổi mã, giao diện, giao thức |

## An toàn
- `update/manifest.json` = `{payload, sig}`: `payload` là JSON (base64), `sig` là chữ ký **RSA-SHA256** bằng khóa riêng `~/hsnc-keys/update_priv.pem` (chỉ nằm trên máy VM, không bao giờ đưa vào kho mã). Ứng dụng có sẵn khóa công khai `client/data/update_pub.pem` và từ chối manifest sai chữ ký.
- Mỗi file trong manifest có `sha256` + `size`; gói tải xong phải khớp cả hai mới được dùng.
- `min_app`: gói dữ liệu chỉ áp dụng cho ứng dụng đủ mới. `app.min`: ứng dụng cũ hơn mức này bị báo phải cập nhật (máy chủ cũng chặn bằng biến `MIN_APP`).
- Tải đứt giữa chừng: lần sau tải tiếp phần còn thiếu (HTTP Range).
- Quay lại bản trước: ứng dụng giữ gói hiện tại và gói trước; khi khởi động, gói nào hỏng (sai SHA-256 hoặc không gắn được) thì tự dùng gói trước, cùng lắm là dữ liệu có sẵn trong ứng dụng.
- Android không bao giờ tự thay APK.

## Các bước
1. Dựng (máy Linux có Godot): `tools/build-native.sh <phiên bản> <số bản dữ liệu> <versionCode>`
   - vd lần đầu: `tools/build-native.sh 2.0.0 1 20000`; mỗi lần đổi app tăng phiên bản và versionCode; chỉ đổi dữ liệu thì tăng số bản dữ liệu.
2. Viết `changelog.txt` (mỗi dòng một ý, tiếng Việt).
3. Phát hành (trên máy VM giữ khóa):
   ```bash
   export KS_ALIAS=... KS_PASS=... KS_KEY_PASS=... GH_TOKEN=...
   tools/publish.sh 2.0.0 1 2.0.0 changelog.txt
   git push
   ```
   Script ký APK bằng khóa cũ, tạo GitHub Release `v<phiên bản>`, tải lên `HiepSiNetChi-Setup.exe`, `HiepSiNetChi.apk`, `assets-N.pck`, ký manifest, ghi `release-files/update/manifest.json` + `latest.json`, commit.
4. Cloudflare tự dựng lại sau khi push: `/update/manifest.json` mới, `/tai-game` hiện phiên bản, giờ cập nhật, kích thước, nhật ký thay đổi; `/tai/windows`, `/tai/android` chuyển tới file mới nhất.
5. Bắt buộc mọi người lên bản mới: đặt `MIN_APP` trên Cloudflare (và `app.min` khi phát hành).

## Vì sao file nằm ở GitHub Releases
Cloudflare Workers chỉ phục vụ file tĩnh tối đa 25 MB; trình cài Windows (~54 MB), APK (~80 MB) và gói dữ liệu (~29 MB) lớn hơn. Link trên trang tải vẫn cố định (`/tai/windows`, `/tai/android`) và luôn trỏ tới bản mới nhất.

## Chuyển hẳn sang ứng dụng gốc (cutover)
Sau khi bản 2.0.0 đã có trên `/tai-game` và chạy ổn:
1. `wrangler.jsonc` → `"vars": { "V1": "off" }`, push: bản web và ứng dụng vỏ cũ không vào được nữa, không còn ai gửi bản lưu kiểu cũ.
2. Admin thử game bằng ứng dụng Windows (bản web chưa chuyển sang giao thức v2 nên tắt cùng lúc).
