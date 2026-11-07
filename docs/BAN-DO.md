# Bản đồ, quái và trùm (đợt 1, bản 2.6.0)

## Lộ trình
| # | Bản đồ | Cấp | Nối với | Khu trùm (cổng ở giữa) |
|---|---|---|---|---|
| 0 | Làng Hiệp Sĩ | an toàn | trái: Bãi Biển · phải: Đồng Bằng | — |
| 1 | Đồng Bằng Khởi Nguyên | 1–11 | Làng · Rừng Tuyết | Hang Vua Heo — Vua Heo Rừng 12 (vào từ cấp 6) |
| 2 | Rừng Tuyết Phong | 10–19 | Đồng Bằng · Núi Lửa | Hang Sói — Sói Tuyết Đầu Đàn 20 (cấp 14) |
| 3 | Núi Lửa Hắc Ám | 19–30 | Rừng Tuyết · Đầm Lầy | Miệng Núi Lửa — Rồng Độc 22, Rồng Băng 26, Rồng Lửa 30 (cấp 20) |
| 4 | Đầm Lầy Sương Độc | 30–40 | Núi Lửa | Hang Rắn — Rắn Chúa Ba Đầu 42 (cấp 36) |
| 5 | Bãi Biển Vỏ Sò | 5–15 | Làng · Rạn San Hô | Hang Cua — Vua Cua Khổng Lồ 16 (cấp 10) |
| 6 | Rạn San Hô (dưới nước, đi bình thường) | 15–25 | Bãi Biển | Ổ Rùa — Rùa Đá Ngàn Năm 26 (cấp 20) |
| 7–12 | các khu trùm | | lối ra bên trái về cổng | |

Số thứ tự bản đồ cũ (0–3) giữ nguyên. Ba con rồng không còn đứng ngoài Núi Lửa; chỗ cũ thay bằng bãi Sói Lửa, Gấu Than, Heo Lửa.

## Quái mới (sức mạnh theo cấp như mọi quái thường)
| Quái | Bản đồ | Cách đánh |
|---|---|---|
| Cua Đỏ | Bãi Biển | cận chiến, vết kẹp |
| Hải Âu | Bãi Biển | bay thấp, mổ |
| Ốc Gai | Bãi Biển | thủ cao; định kỳ rút vào vỏ (thủ ×3) |
| Cá Nóc | Rạn San Hô | định kỳ phồng gai: đánh vào bị dội 30% sát thương |
| Sứa Điện | Rạn San Hô | đòn đánh làm chậm 55% trong 1,6 giây |
| Cá Kiếm | Rạn San Hô | lao tới từ xa (có vùng báo), đẩy lùi |
| Ếch Độc | Đầm Lầy | giữ khoảng cách phun cục độc (nhảy để tránh), trúng bị nhiễm độc |
| Nấm Ma | Đầm Lầy | chết thì nổ bào tử sau 0,7 giây (có vùng báo) |
| Cá Sấu Bùn | Đầm Lầy | máu trâu, chậm; mỗi đòn thứ 3 quật đuôi quanh mình (nhảy để tránh) |

## Trùm (mỗi chiêu có vùng đỏ báo trước dưới đất)
| Trùm | Chiêu |
|---|---|
| Vua Cua Khổng Lồ | Đập Càng (sóng xung kích, đẩy lùi) · Càng Xoay (lao xoay, sát thương liên tục) · Mưa Bọt (6 vùng bọt rơi, làm chậm) |
| Rùa Đá Ngàn Năm | Xoáy Nước (kéo người chơi vào giữa) · Dậm Đất (gai đá phía trước, choáng 1,2 giây) · Vòi Nước (tia nước thẳng, đẩy lùi) |
| Rắn Chúa Ba Đầu | Tam Độc (phun độc, để lại mây độc 4 giây) · Quật Đuôi (quét quanh mình, nhảy để tránh) · Gọi Rắn Con (3 con) |
| Vua Heo Rừng | Húc Lao · Dậm Đất · Gọi Đàn (mượn hình Heo Lửa phóng to, màu vàng) |
| Sói Tuyết Đầu Đàn | Vồ Liên Hoàn · Tru Băng · Gọi Bầy (mượn hình Sói Tuyết phóng to) |
| Ba rồng | khạc lửa/độc/băng như cũ + Đập Cánh |

Quái do trùm gọi ra không cho thưởng và biến mất khi khu trùm hết trùm.

## Hiệu ứng xấu lên người chơi
Độc (mất máu mỗi 0,5 giây), chậm, choáng (không đi, không đánh được). Hiện trên đầu nhân vật: ★ choáng, vòng xanh chậm, bọt xanh độc.

## Ảnh
- Quái/trùm mới: `client/assets/mon2/<loài>/<động tác><khung>.webp`, mỗi động tác 8 khung (đi, đánh; trùm thêm đứng và 3 chiêu).
- Hiệu ứng chiêu: `client/assets/vfx/<tên>/0..7.webp` (16 hiệu ứng).
- Bộ bản đồ tách mảnh: `side/{far,mid,ground,capL,capR}_<beach|reef|swamp|cave>`, cảnh vật `ai/<chủ đề>_<tên>`.
