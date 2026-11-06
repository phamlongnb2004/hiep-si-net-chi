# Tình trạng chuyển sang ứng dụng gốc

Cập nhật: 06/11/2026 · Ứng dụng 2.0.0 · Dữ liệu 1

## Đã xong (đã dựng và chạy thử thật)
**Máy chủ (giao thức v2, chạy song song v1)**
- Máy chủ quyết định: quái theo bản đồ dùng chung cho mọi người chơi, đánh thường + 24 kỹ năng (4 phái × 6), choáng/chậm/độc, rồng khạc theo luồng, chết mất 10% vàng và hồi sinh, kinh nghiệm/lên cấp, vàng, rơi đồ (có chủ 20 giây), túi đồ, bình máu, mua sách, học kỹ năng, lò rèn.
- Kiểm tra vị trí (tốc độ, vách, độ cao), thời gian hồi, cổng; bỏ qua bản lưu do ứng dụng gửi.
- Người chơi bản cũ và bản mới thấy nhau trên cùng bản đồ.
- Sao lưu bảng nhân vật một lần, nhập bản lưu cũ nguyên trạng, ghi lại bất thường (không cắt dữ liệu).
- Phiên đăng nhập hết hạn sau 30 ngày không dùng; chặn ứng dụng quá cũ (`MIN_APP`); công tắc tắt giao thức cũ (`V1=off`).
- Kiểm thử bằng tay chơi giả lập: 16/16 bước đạt; nhập bản lưu cũ có lỗi: giữ nguyên, ghi bất thường.

**Ứng dụng Godot 4.5.1 (Windows + Android, không WebView)**
- Đăng nhập/đăng ký, chọn máy chủ, tạo nhân vật (4 phái, xem trước nhân vật).
- Bản đồ cuộn ngang vẽ lại từ ảnh gốc: trời, núi xa/lớp giữa cuộn chậm, dải đất theo bậc, mép vách, cây, nhà, biển khu, NPC, cổng.
- Nhân vật nhiều lớp (thân theo bộ áo, mũ, áo choàng), quái theo khung hình gốc, rồng khạc có hạt.
- Điều khiển: bàn phím (A/D, W/Space, J, 1-6, Q, E, B), chuột/chạm để chọn quái hoặc đi tới NPC; cần điều khiển + nút cảm ứng trên Android.
- Giao diện: máu/kinh nghiệm, vàng/đá, bản đồ nhỏ, 6 kỹ năng có thời gian hồi và khóa, bình máu, nhật ký, trò chuyện, túi đồ (so sánh, mặc, bán, sắp xếp, bán đồ thường), nhân vật, cửa hàng (sách, bình), học kỹ năng, lò rèn.
- Mất mạng: dừng điều khiển, tự kết nối lại (chờ tăng dần), nhận lại toàn bộ trạng thái từ máy chủ; không có chơi offline.
- Cập nhật có chữ ký: kiểm chữ ký, SHA-256, kích thước, tải tiếp khi đứt, quay lại gói trước khi hỏng (đã thử cả 5 trường hợp).
- Bản dựng: trình cài Windows (NSIS, 52 MB), APK ký bằng khóa cũ (78 MB), Linux .tar.gz (54 MB), gói dữ liệu (29 MB); đã phát hành, tải ở /tai-game.

## Còn thiếu / cần làm tiếp
- **iOS**: cần máy Mac (Xcode) + tài khoản Apple Developer (99 USD/năm) để ký và phát hành qua TestFlight/App Store; mã Godot dùng chung được, chỉ thiếu bước dựng/ký. Trang tải đã có ô iPhone/iPad ("Sắp có"), tự hiện nút khi manifest có app.ios.
- **Ký APK bằng khóa cũ và đưa bản dựng lên GitHub Releases**: cần máy VM (giữ keystore, khóa cập nhật, token GitHub) — kết nối máy lại rồi chạy `tools/publish.sh`.
- **Thử trên máy thật**: chưa chạy trên điện thoại Android và máy Windows thật (mới thử trên Linux cùng bộ mã).
- Âm thanh, nhiệm vụ, bang hội, bạn bè, giao dịch: để sau (giao thức đã chừa chỗ).
- Hiệu ứng chiêu: dùng ảnh chiêu gốc nhưng đơn giản hơn bản web ở vài chiêu (vùng lửa/băng, mưa tên).
- Biểu tượng bên trong file `.exe` còn là biểu tượng Godot (cần `rcedit`); file chưa ký số nên Windows SmartScreen sẽ hỏi.
- Bản web cho admin chưa chuyển sang v2: sẽ tắt cùng bản cũ khi cutover; admin thử bằng ứng dụng Windows.
- Đo tải máy chủ với nhiều người chơi (mục tiêu của đề xuất 2) — làm khi đã phát hành.
