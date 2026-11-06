# Cấu hình máy chủ

Máy chủ vẫn là **Cloudflare Worker + Durable Object "World" (SQLite)** như trước, chạy song song hai giao thức:

| | Giao thức cũ (v1) | Giao thức mới (v2) |
|---|---|---|
| Ai dùng | bản web (chỉ admin), ứng dụng vỏ cũ | ứng dụng gốc Windows/Android |
| Kết nối | `/ws?token&srv&app` | `/ws?token&srv&app&proto=2&v=<phiên bản app>` |
| Ai quyết định | ứng dụng tự tính, gửi cả bản lưu | **máy chủ** tính sát thương, quái, rơi đồ, vàng, kinh nghiệm, túi đồ, lò rèn |
| Lưu dữ liệu | ứng dụng gửi `save` | máy chủ tự ghi 15 giây/lần và khi thoát |

## File
- `cloudflare/worker.js` — đăng nhập, phiên, WebSocket, chuyển đổi hai giao thức, `/tai/windows`, `/tai/android`.
- `cloudflare/sim.js` — mô phỏng một bản đồ: quái (tuần tra, đuổi, vồ, rồng khạc), đạn, kỹ năng, trạng thái (choáng, chậm, độc), chết/hồi sinh, rơi đồ có chủ 20 giây, tự nhặt.
- `cloudflare/ops.js` — mặc/tháo/bán/sắp xếp đồ, bình máu, mua sách (phải đứng gần Thương Nhân), học kỹ năng, rèn (phải đứng gần Thợ Rèn).
- `shared/rules.js` + `shared/data.json` — luật chơi và số liệu dùng chung, xuất từ game gốc bằng `node tools/export-shared-data.js public/<bản dựng>.html`.

## Biến môi trường (Cloudflare → Worker → Settings → Variables)
| Biến | Ý nghĩa |
|---|---|
| `ADMINS` | thêm tài khoản admin được chơi trên trình duyệt (cách nhau bằng dấu phẩy) |
| `V1` | `off` = tắt giao thức cũ (chuyển hẳn sang ứng dụng gốc). Đặt trong `wrangler.jsonc` → `vars` |
| `MIN_APP` | phiên bản ứng dụng thấp nhất được vào (vd `2.0.0`); bản cũ hơn bị báo "cần cập nhật" (mã đóng 4007) |
| `ASSETLINKS` | nội dung `assetlinks.json` cho ứng dụng vỏ cũ (không cần cho APK gốc) |

`wrangler.jsonc` có `"keep_vars": true` để lần đẩy mã sau không xóa các biến đặt trên trang Cloudflare.

## Cơ sở dữ liệu
- Bảng cũ giữ nguyên: `users`, `sessions`, `chars`.
- Mới: `chars_v1_backup` (bản sao bảng `chars` tạo **một lần** khi máy chủ v2 khởi động lần đầu), `anomalies` (bản lưu bất thường: cấp > 60, túi > 30 món, bình > 20, đồ rèn quá +15, chỉ số vượt mức có thể có, món hỏng). Chỉ ghi lại, **không cắt dữ liệu** của ai; món hỏng được cất vào trường `bad` trong bản lưu.
- `sessions.last`: phiên hết hạn sau 30 ngày không dùng (phiên cũ tính từ lúc nâng cấp, không ai bị đẩy ra ngay).

## Chống gian lận
- Vị trí: kiểm tra tốc độ theo thời gian, không đi xuyên vách đất, không bay cao quá độ cao nhảy; sai thì máy chủ kéo về (`pos`).
- Đánh/kỹ năng: kiểm tra thời gian hồi, kỹ năng đã học, mục tiêu trong tầm theo vị trí quái trên máy chủ.
- Không nhận bản lưu từ ứng dụng v2; tin nhắn quá 80/giây bị bỏ.
- Cổng dịch chuyển: phải đứng tại cổng.

## Chạy thử tại máy
```bash
npx wrangler dev --port 8799 --local      # dùng bản sao wrangler.jsonc không có "build"
node <thư mục thử>/t2.js                   # 16 bước: đăng ký, tạo nhân vật, chống dịch chuyển, qua cổng, đánh quái, lưu, v1↔v2 thấy nhau
```

## Giao thức v2 (tóm tắt)
Ứng dụng → máy chủ: `in {x,y,f,mv,air}` (10 lần/giây), `atk {tg}`, `sk {i,tg}`, `pot`, `warp {p}`, `create {name,cls}`, `equip {id}`, `unequip {slot}`, `sell {id}`, `selljunk`, `sort`, `buypot {n}`, `book {i}`, `learn {i}`, `forge {id,slot?}`, `chat {text,all}`, `ping`.

Máy chủ → ứng dụng: `welcome {proto,id,me}`, `map {m,x,y,mons,drops}`, `snap {tk,p,m,e}` (10 lần/giây), `me {full,me}`, `pos`, `gain`, `log`, `res {op,ok,msg}`, `chat`, `err`.
Sự kiện trong `snap.e`: `h` quái trúng đòn, `p` người chơi mất máu, `ph` hồi máu, `a` đánh thường, `s` dùng kỹ năng, `k` quái chết, `r` quái hồi sinh, `ma` quái vồ, `b` rồng khạc, `d` đồ rơi, `g` nhặt, `x` đồ biến mất, `lv` lên cấp.

Còn chỗ cho tính năng sau (nhiệm vụ, bang hội, bạn bè, giao dịch): thêm loại tin mới, tin lạ bị bỏ qua ở cả hai phía.
