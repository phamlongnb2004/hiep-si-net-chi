# Hiệp Sĩ Nét Chì Online

Game nhập vai chibi chơi online cùng nhau, có bản Android (APK), Windows (.exe) và bản chơi ngay trên trình duyệt.

- **Tài khoản:** đăng ký bằng tên và mật khẩu, nhân vật lưu trên máy chủ, đổi máy vẫn còn.
- **Chơi cùng nhau:** thấy người chơi khác trên cùng bản đồ, có tên, cấp và thanh máu.
- **Chat:** bấm Enter (trên điện thoại bấm nút Chat). Gõ `/tg nội dung` để nhắn cho cả máy chủ, không có thì chỉ người cùng bản đồ thấy.
- **Chơi offline:** vẫn chơi một mình được khi không có mạng, tiến trình lưu trên máy.

Quái vật, đồ rơi và trận đánh chạy riêng trên máy từng người. Mọi người thấy nhau, chat với nhau nhưng mỗi người tự đánh quái của mình.

## Cấu trúc thư mục

| Thư mục | Nội dung |
|---|---|
| `server/` | Máy chủ Node.js: tài khoản, lưu nhân vật, đồng bộ người chơi, chat. Phục vụ luôn bản chơi trên trình duyệt. |
| `public/` | Bản game đã ghép (tự tạo khi build). |
| `tools/` | Bản game gốc, lớp online, font, script ghép game. |
| `desktop/` | Bản Windows (Electron). |
| `mobile/` | Bản Android (Capacitor). |
| `.github/workflows/build.yml` | Tự build APK và .exe trên GitHub. |
| `render.yaml` | Cấu hình đưa máy chủ lên Render. |

## Bước 1. Tạo cơ sở dữ liệu miễn phí (Neon)

Máy chủ miễn phí trên Render xóa file mỗi lần khởi động lại, nên nhân vật phải lưu vào Postgres.

1. Vào https://neon.com, đăng ký (không cần thẻ).
2. Tạo project mới, chọn vùng gần Việt Nam nhất (Singapore).
3. Ở trang project, bấm **Connect**, chép chuỗi kết nối dạng `postgresql://...neon.tech/neondb?sslmode=require`.

Gói miễn phí của Neon không hết hạn. Gói Postgres miễn phí của Render bị xóa sau 30 ngày, nên không dùng.

## Bước 2. Đưa mã lên GitHub

1. Tạo kho mới trên https://github.com/new, ví dụ `hiep-si-net-chi` (để Private cũng được).
2. Giải nén file zip dự án, mở terminal trong thư mục `hsnc-online` rồi chạy:

```bash
git remote add origin https://github.com/TEN_BAN/hiep-si-net-chi.git
git push -u origin main
```

Dự án đã có sẵn commit đầu tiên, chỉ cần thêm địa chỉ kho và đẩy lên.

## Bước 3. Chạy máy chủ trên Render

1. Vào https://render.com, đăng nhập bằng GitHub.
2. Bấm **New → Blueprint**, chọn kho `hiep-si-net-chi`.
3. Khi được hỏi `DATABASE_URL`, dán chuỗi kết nối Neon ở bước 1. Bấm **Apply**.
4. Đợi build xong (vài phút). Render cho bạn địa chỉ dạng `https://hiep-si-net-chi.onrender.com`.
5. Mở địa chỉ đó trên trình duyệt: game hiện ra, đăng ký tài khoản và chơi thử. Mở thêm `/api/health` để xem máy chủ đang dùng `postgres`.

Máy chủ miễn phí ngủ sau 15 phút không có ai chơi. Người đầu tiên vào sẽ phải đợi khoảng 1 phút để máy chủ thức dậy.

## Bước 4. Build file APK và .exe

1. Trên GitHub, vào kho → **Settings → Secrets and variables → Actions → tab Variables → New repository variable**.
   - Name: `SERVER_URL`
   - Value: địa chỉ Render ở bước 3, ví dụ `https://hiep-si-net-chi.onrender.com` (không có dấu `/` ở cuối).
2. Vào tab **Actions → Build game → Run workflow**.
3. Khoảng 10 phút sau, bấm vào lượt chạy, kéo xuống phần **Artifacts**:
   - `HiepSiNetChi-android`: file `HiepSiNetChi.apk`.
   - `HiepSiNetChi-windows`: file `setup.exe` (cài đặt) và `portable.exe` (chạy luôn).

Muốn có trang tải chính thức cho bạn bè, tạo tag phiên bản rồi đẩy lên:

```bash
git tag v1.0.0
git push origin v1.0.0
```

GitHub sẽ build và tạo bản phát hành trong mục **Releases** kèm file APK và .exe.

## Cài đặt cho người chơi

**Android:** tải file APK, mở file, cho phép "Cài ứng dụng từ nguồn không xác định" khi điện thoại hỏi. Game chạy ngang màn hình, toàn màn hình.

**Windows:** chạy `setup.exe` để cài hoặc `portable.exe` để chơi ngay. Windows có thể hiện cảnh báo SmartScreen vì file chưa ký số: bấm **More info → Run anyway**. Bấm F11 để toàn màn hình.

Nếu build không đặt `SERVER_URL`, lần đầu mở game bấm mục **Máy chủ** trên màn đăng nhập và nhập địa chỉ Render. Game nhớ địa chỉ này cho lần sau.

## Chạy thử trên máy của bạn

```bash
npm install
node tools/build-client.js
npm start
```

Mở http://localhost:8080. Không có `DATABASE_URL` thì dữ liệu lưu ở `data/db.json`.

Bạn bè cùng mạng Wi-Fi có thể vào bằng địa chỉ IP máy bạn, ví dụ `http://192.168.1.10:8080`.

## Sửa game

- Sửa lớp online: `tools/net.js`. Sửa game gốc: `tools/game-base.html`.
- Sau khi sửa, đẩy lên GitHub: Render tự cập nhật máy chủ, chạy lại workflow để có APK và .exe mới.
- Đổi tên hoặc biểu tượng ứng dụng: `desktop/package.json`, `mobile/capacitor.config.json`, ảnh trong `mobile/assets/` và `desktop/icon.ico`.
