# Quản trị game

Hai nơi quản trị, dùng chung quyền và chung nhật ký:

- **Trang web `/admin`**: tổng quan, người chơi, người đang online, vận hành, cân bằng, nhật ký, quản trị viên. Dùng được trên máy tính và điện thoại.
- **Bảng GM trong game**: nút **GM** ở góc phải trên, chỉ hiện với tài khoản quản trị.

## Bảo mật

| Lớp | Cách làm |
|---|---|
| Quyền | Bảng `admins` trên máy chủ: Chủ, GM hỗ trợ, Chỉ xem. Ứng dụng và trang web không chứa mật khẩu, khóa hay danh sách admin nào. Mọi lệnh đều được kiểm tra lại quyền trên máy chủ. |
| Đăng nhập | Mật khẩu tài khoản game + **mã 2 lớp TOTP** (Google/Microsoft Authenticator). Một mã đã dùng thì không dùng lại được. |
| Bật mã 2 lớp lần đầu | Cần **mã kích hoạt dùng một lần**. Chủ dùng mã gốc (trong mã nguồn chỉ có bản băm SHA-256). GM dùng mã mời do Chủ tạo, hết hạn sau 48 giờ. Người lấy được mật khẩu admin vẫn không tự bật mã 2 lớp được. |
| Dò mật khẩu | Một IP + tài khoản sai 5 lần → khóa 15 phút. Một IP sai 10 lần → khóa IP. Một tài khoản sai 25 lần → khóa tài khoản. Sai mã 2 lớp 5 lần → khóa 15 phút. Mọi lần sai đều ghi vào nhật ký. |
| Phiên | Cookie `HttpOnly; Secure; SameSite=Strict`, chỉ dùng cho `/api/admin`. Hết hạn sau 30 phút không dùng, tối đa 12 giờ. Gắn với trình duyệt: cookie mang sang trình duyệt khác thì mất hiệu lực. Máy chủ chỉ lưu bản băm của mã phiên. |
| Chống giả mạo | Mỗi yêu cầu phải có tiêu đề `X-HSNC-Admin`, kiểu JSON, và đến từ cùng nguồn (`Origin`). Trang `/admin` có CSP chặt (chỉ chạy mã của chính trang), cấm nhúng iframe, không lưu cache, không cho máy tìm kiếm lập chỉ mục. |
| GM trong game | Mỗi lần vào game phải nhập mã 2 lớp để mở bảng GM, hiệu lực 2 giờ. Quái do GM gọi ra không cho kinh nghiệm, vàng hay đồ. |
| Hạn chế lạm quyền | Chỉ Chủ được sửa vàng/đồ/cấp, tặng đồ, khôi phục nhân vật, đặt lại mật khẩu, bật bảo trì, bật sự kiện, chỉnh cân bằng, sửa máy chủ và phân quyền. GM không khóa được tài khoản quản trị khác. Phải luôn còn ít nhất một Chủ. |
| Hoàn tác | Mỗi lần sửa nhân vật, máy chủ lưu lại bản trước đó (`char_snap`). Khôi phục được về bất kỳ bản nào, kể cả bản trước khi lên 2.0. |

## Vai trò

| Việc | Chủ | GM | Chỉ xem |
|---|:-:|:-:|:-:|
| Xem tổng quan, người chơi, nhật ký | ✓ | ✓ | ✓ |
| Khóa / mở khóa, cấm chat, đá khỏi game, gửi thông báo | ✓ | ✓ | |
| Bảng GM trong game: dịch chuyển, tàng hình, kéo người chơi, gọi/dọn quái, hồi máu | ✓ | ✓ | |
| Sửa nhân vật, tặng đồ/vàng, khôi phục, đặt lại mật khẩu | ✓ | | |
| Bảo trì, sự kiện x2, cân bằng, máy chủ, phiên bản tối thiểu, tắt bản cũ | ✓ | | |
| Thêm, xóa, đổi quyền quản trị viên; đặt lại mã 2 lớp | ✓ | | |

## Lần đầu (Chủ)

1. Mở `https://hiep-si-net-chi.phamthanhlong-contact.workers.dev/admin`.
2. Đăng nhập bằng tài khoản game `phamlongnb2004`.
3. Nhập mã kích hoạt gốc (được gửi riêng, chỉ dùng được một lần).
4. Quét mã QR bằng Google Authenticator, rồi nhập mã 6 số để xác nhận.
5. Từ lần sau chỉ cần mật khẩu + mã 6 số.

Thêm GM: vào **Quản trị viên → Thêm quản trị**, nhập tên tài khoản game, rồi gửi riêng mã mời cho người đó.

**Mất điện thoại có mã 2 lớp:**
- Chủ khác vào **Quản trị viên → Đặt lại 2 lớp**.
- Nếu chỉ có một Chủ: đổi `BOOT_HASH` trong `cloudflare/admin.js` sang mã băm của một mã gốc mới, đẩy mã lên, rồi xóa hàng `admins` của mình. Việc xóa hàng này phải làm qua Cloudflare, cần hỗ trợ kỹ thuật.

## Dữ liệu (bảng mới trong Durable Object)

| Bảng | Chứa gì |
|---|---|
| `admins` | Quyền, khóa TOTP |
| `admin_sess` | Phiên (bản băm) |
| `admin_pre` | Bước giữa mật khẩu và mã 2 lớp |
| `admin_fail` | Đếm lần sai |
| `admin_log` | Mọi thao tác quản trị, cả web lẫn trong game |
| `game_log` | Rơi đồ Sử Thi/Huyền Thoại, rèn từ +8, nghi gian lận, khóa tài khoản. Giữ 90 ngày. |
| `chat_log` | Giữ 30 ngày |
| `char_snap` | Bản lưu trước mỗi lần sửa nhân vật |
| `online_stat` | Số người online mỗi 5 phút. Giữ 30 ngày. |
| `config` | Bảo trì, thông báo, sự kiện, cân bằng, danh sách máy chủ, phiên bản tối thiểu, công tắc bản cũ |

Bảng `users` có thêm các cột: `banned_until`, `ban_reason`, `muted_until`, `last_login`, `last_ip`.

## Kho vật phẩm

Tab **Kho vật phẩm** trên trang `/admin` liệt kê mọi món đang có trong game, kèm ảnh:
- 64 trang bị (4 phái × 4 ô × 4 độ hiếm), lọc theo phái, ô, độ hiếm, chọn cấp đồ;
- bình máu, đá cường hóa, vàng, kinh nghiệm;
- 6 sách kỹ năng của mỗi phái (có thể cho học luôn nếu đủ cấp).

Bấm món đồ để bỏ vào **giỏ quà**, rồi chỉnh từng món: rèn +, số lượng, chỉ số (mặc định / tối đa như đồ rơi tốt nhất / tự nhập, không vượt mức tối đa của game), khóa giao dịch. Người nhận là một nhân vật (tìm theo tên, hoặc bấm **Tặng vật phẩm…** ở trang người chơi) hoặc **mọi người đang online** trên một máy chủ.

Chỉ Chủ được tặng; GM và Chỉ xem chỉ xem danh mục. Máy chủ kiểm tra lại mọi thứ, lưu bản trước khi tặng (khôi phục được), ghi nhật ký, và báo người nhận trong game "🎁 Quản trị tặng bạn: …".

## Khu (từ 2.4.0)

Mỗi bản đồ chia nhiều khu giống Ngọc Rồng Online. Mỗi khu tối đa **15 người** và có quái, đồ rơi, trò chuyện bản đồ riêng.
- Vào bản đồ: giữ số khu đang ở nếu còn chỗ, không thì vào khu nhỏ nhất còn chỗ. Tối đa 40 khu mỗi bản đồ.
- Người chơi bấm nút **Khu N ▾** dưới tên bản đồ để xem số người từng khu và đổi khu (chờ 5 giây giữa hai lần đổi).
- Giao dịch chỉ với người cùng khu. GM dịch chuyển/kéo người chơi thì vào đúng khu của người đó, kể cả khi khu đầy.
- Đổi số người tối đa: **Vận hành → Khu trong bản đồ** (chỉ Chủ).

## Sức mạnh quái

Quái thường mạnh theo **cấp**, không theo loài: cùng cấp thì máu, công, thủ, kinh nghiệm như nhau, và cấp cao hơn luôn mạnh hơn. Bảng mốc `MON_LV` trong `shared/rules.js` (cấp 1, 5, 9, 12, 15, 19, 24, 30, 60, 100); cấp ở giữa nội suy. Rồng (trùm) giữ chỉ số riêng. Hệ số từng loại quái trong Admin → Cân bằng vẫn nhân thêm lên trên.

## Cân bằng

Các tham số trong `shared/rules.js` → `TUNE`:
- hệ số kinh nghiệm, vàng, rơi đồ;
- giá bình máu, hệ số giá cửa hàng;
- cộng tỉ lệ rèn, tỉ lệ quái tinh anh;
- hệ số máu, công, thủ, kinh nghiệm, vàng, rơi đồ cho từng loại quái.

- hệ số KI kỹ năng tốn (0 = tắt KI), hệ số sức mạnh mỗi điểm tiềm năng.

Chỉnh xong áp dụng ngay, không cần ra bản ứng dụng mới. Ứng dụng nhận giá mới qua tin `cfg` để hiện đúng giá.
