# Chỉ số và điểm tiềm năng (từ 2.3.0)

Giống Ngọc Rồng Online: người chơi tự cộng điểm vào chỉ số. Khác NRO: điểm có được khi **lên cấp** (5 điểm mỗi cấp), không lấy từ đánh quái.

| Chỉ số | Mỗi điểm | Tối đa |
|---|---|---|
| Máu | +5 máu | không giới hạn |
| KI | +5 KI | không giới hạn |
| Sức đánh | +0,7 | không giới hạn |
| Giáp | +0,3 | không giới hạn |
| Chí mạng | +0,2% (đòn chí mạng x1,6) | 150 điểm (+30%) |
| Tốc chạy | +1 | 60 điểm |
| Né tránh | +0,2% né hoàn toàn đòn quái | 125 điểm (25%) |
| Hút máu | +0,1% sát thương thành máu (không tính độc) | 150 điểm (15%) |
| Xuyên giáp | +0,5% bỏ qua giáp quái | 100 điểm (50%) |

**KI:** mỗi kỹ năng tốn KI (đánh thường không tốn). KI tối đa = 60 + 6 × (cấp − 1) + điểm KI. KI tự hồi 4% tối đa + 1 mỗi giây, gấp đôi trong vùng an toàn. Chi phí kỹ năng 1–6: 8, 14, 20, 26, 32, 40, tăng 2,5% mỗi cấp.

**Tẩy điểm:** lần đầu miễn phí, sau đó 200 × cấp vàng.

**Nhân vật cũ:** nhận đủ (cấp − 1) × 5 điểm để cộng.

**Chỉnh:** Admin → Cân bằng: hệ số KI (0 = tắt KI) và hệ số sức mạnh mỗi điểm.

Mã: `shared/rules.js` (PTS, stats, kiCost), `cloudflare/sim.js`, `cloudflare/ops.js` (stat, stat_reset), ứng dụng `client/scripts/bag.gd` (thẻ Chỉ số), `hud.gd` (thanh KI).
