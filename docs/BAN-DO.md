# Bản đồ, quái và trùm (đợt 1 bản 2.6.0; bản đồ nhiều tầng từ 2.7.0)

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

## Bản đồ nhiều tầng (từ 2.7.0)
Mỗi bản đồ một kiểu riêng, đi lên xuống được:

| Bản đồ | Kiểu | Cổng khu trùm |
|---|---|---|
| Làng | chòi gác có thang, ban công nổi trên đài phun nước, chòi phải có dây | — |
| Đồng Bằng | đồi thoải lên xuống, bậc cỏ nổi, dây leo | trên đỉnh đồi giữa |
| Rừng Tuyết | leo núi từng bậc, vực sâu giữa đỉnh có cầu treo và thang xuống đáy vực (gấu ở đáy) | bên kia cầu |
| Núi Lửa | hố dung nham (đứng trong là bỏng 7% máu mỗi 0,5 giây) bước qua bằng đá nổi, núi lửa giữa, dây xích | trên miệng núi lửa |
| Đầm Lầy | vũng bùn (đi chậm), tán cây đứng được, dây leo, gò đất cao | trên gò đất |
| Bãi Biển | nước nông, dốc cát, vách nhiều tầng có thang, cầu treo lên mỏm trên cùng | trên mỏm cao nhất |
| Rạn San Hô | rãnh sâu giữa rạn, bậc san hô nổi nhiều tầng, rong biển để leo | dưới đáy rãnh |
| Khu trùm | Hang Vua Heo: 2 bậc nổi · Hang Sói: gò giữa · Miệng Núi Lửa: 2 hố dung nham giữa 3 rồng · Hang Cua: vũng nước · Ổ Rùa: bậc nổi bậc thang · Hang Rắn: vũng bùn | |

Điều khiển: nhảy (Space/W, nút nhảy, đẩy cần lên) ở chân dây/thang để bám leo; W/S hoặc cần lên/xuống để leo; đứng trên đỉnh thang giữ xuống để leo xuống; giữ xuống + nhảy để rơi xuyên bậc nổi; đẩy ngang hoặc nhảy để buông dây.

Dữ liệu (shared/data.json, mỗi bản đồ): `terr` mặt đất (có dốc), `plats` bậc nổi `[x0, y0, x1, y1, "bridge"?]`, `ropes` `[x, yTrên, yDưới, "rope"|"ladder"]`, `water` / `lava` `[x0, x1, yMặt]`. Bãi quái có `p` = số thứ tự bậc nổi thì quái chỉ đi trên bậc đó. Máy chủ kiểm tra người chơi đứng trên đất, bậc nổi hoặc đang bám dây (rules.js: floorY, onRope).

## Cổng khu trùm, thang/dây, dáng leo (2.7.1)
- Mỗi khu trùm có cổng riêng (`ai/gate_boar|wolf|volcano|crab|turtle|snake`, chọn theo bản đồ đích trong `world.gd` → `ARENA_GATE`).
- Thang và dây là **một khúc ảnh lặp theo chiều dọc** (`ai/ladder_wood`, `ai/ladder_bamboo`, `ai/rope`, `ai/vine`); `w`/`h` trong assets.json là kích thước hiển thị của một khúc. Thang tre dùng ở đầm lầy, bãi biển, rạn san hô; dây leo xanh ở đầm lầy và rạn san hô.
- Nhân vật leo: nhìn từ sau lưng, 4 khung (`anim/climb_<lớp>_<b|0..3>`, trường `hx/hy/hw/sy` = tâm đầu, đỉnh đầu, bề rộng đầu, vai), mũ và áo choàng mặt sau (`layer/<lớp>/hatb`, `capeb`), cánh xoè đủ hai bên sau lưng.
- Gửi trạng thái leo cho người khác: tin `in` có `air: 2` khi đang bám dây/thang; máy chủ chuyển nguyên giá trị vào ảnh chụp (`air` = 0 đứng, 1 nhảy, 2 leo).

## Tốc độ lên cấp (11/2026)
- Kinh nghiệm cần để lên cấp tính theo số quái **cùng cấp** phải hạ: `6 + 2,2 × cấp` con (cấp 1 ~8, cấp 10 ~28, cấp 20 ~50, cấp 30 ~72, cấp 40 ~94), không thấp hơn công thức cũ (cấp 75+ vẫn giữ độ khó cũ). Quái tinh anh x3, trùm nhiều hơn.
- Ước tính: cấp 1→10 khoảng 150 quái, 1→20 khoảng 530, 1→30 khoảng 1.130, 1→40 khoảng 1.950 (trước đây 1→30 chỉ ~80 quái).
- Admin chỉnh nhanh ở **Cân bằng → Toàn game → "x Kinh nghiệm cần để lên cấp"** (`lvMul`, 0,2–10; 2 = chậm gấp đôi), hoặc "x Kinh nghiệm" để đổi kinh nghiệm mỗi quái.

## Giá đồ, cường hóa, màn hình tải (2.7.5)
- Giá đồ cửa hàng: `(25 + 9×cấp) × (1 + cấp/3) × 3,5 × hệ số độ hiếm [1; 3,5; 10; 32]` — đồ trắng cùng cấp ≈ 45–85 lần hạ quái, đồ huyền thoại ≈ 1.500–2.700.
- Cường hóa: tỉ lệ +1→+15 = 95, 85, 75, 65, 55, 45, 36, 28, 21, 15, 10, 7, 5, 3, 2 %; đá = cấp đích + 1; vàng = `(40 + 6×cấp) × (1 + cấp/3) × L^1,6 × 1,5`; thất bại lên +5..+9 tụt 1 cấp, +10 trở lên tụt 2 cấp. Đá rơi từ quái thường: 20% (+0,3%/cấp, tối đa +8%).
- Admin vẫn chỉnh nhanh được: "x Giá đồ cửa hàng", "Cộng tỉ lệ rèn (%)", "x Vàng".
- Màn hình tải (`client/scripts/loading.gd`): hiện khi bước vào cổng, vào khu trùm, đổi khu và lúc vào game; nạp trước ảnh của bản đồ mới (cảnh nền, cảnh vật, cổng, thang, cầu, quái) vài ảnh mỗi khung hình; tối thiểu 0,9 giây; chặn điều khiển tới khi xong.

## Dáng nhảy (2.7.6)
- Mỗi lớp × 5 bộ áo có 4 khung nhảy riêng `anim/jump_<lớp>_<b|0..3>`: lấy đà, bật lên, đỉnh (co gối), rơi (duỗi chân).
- Khung chọn theo vận tốc dọc ước lượng từ vị trí (áp dụng cả cho người chơi khác): mới rời đất 0,07 s → lấy đà; vy < -260 → bật lên; vy < 200 → đỉnh; còn lại → rơi; chạm đất sau khi bay > 0,12 s thì khụy gối 0,12 s.
- Neo ngang đặt sao cho đầu trùng chỗ đầu khi đứng (mũ đi theo `hc`/`tp` như các khung khác); cỡ lấy theo khung rơi ≈ 1,03 × chiều cao thân đứng.
- Xem thử: `HSNC_PREVIEW=jump` (thêm `HSNC_SET=1` để xem bộ áo khác).

## Dáng bị hạ gục (2.7.7)
- `anim/die_<lớp>_<b|0..3>`: trúng đòn → ngã ngửa → chạm đất → nằm gục (giữ tới khi hồi sinh). Phát khi `dead` chuyển sang true (cả người chơi khác, theo cờ chết máy chủ gửi).
- Khi ngã: cánh chỉ còn ở khung đầu, áo choàng ẩn khi đã ngã, mũ nghiêng theo đầu rồi rơi nằm cạnh đầu.
- Xem thử: `HSNC_PREVIEW=die` (`HSNC_SET=1` bộ áo khác).

## Đồ theo bậc cấp + trang sức mới (2.8.0)
- 10 bậc: cấp 1–10, 11–20 … 91–100 (`band(lvl)`); món mới có trường `b`. Tên = tên món + tên bộ của phái theo bậc (`BAND_SET`) + hậu tố độ hiếm (Tinh Xảo / Cổ Đại / Thần Thánh). Trang sức dùng chất liệu chung theo bậc (`BAND_ACC`).
- Ô đồ mới, mọi phái dùng được: nhẫn (sức đánh + tốc chạy), khuyên tai (máu + sức đánh), đai lưng (máu + giáp), bùa hộ mệnh (giáp + máu + sức đánh). Rơi từ quái (trọng số 0,5) và bán ở Thương Nhân Giáp (nhóm "Trang sức").
- Cần cấp nhân vật ≥ cấp đồ mới mặc được (máy chủ chặn ở `equip`). Đồ đang mặc / đồ cũ không có `b` giữ nguyên tên và ảnh cũ.
- Icon: `gear2/<phái>/<bậc>/<ô>.webp` (6 ô theo phái), `acc2/<ô>/<bậc>.webp` (5 trang sức). Xem thử: `HSNC_PREVIEW=items HSNC_CLS=<phái>`.
- APP_MIN 2.8.0 (bản cũ không hiện được ô đồ mới).

## Boss Hoang Dã, trứng và pet (2.9.0)
- **Ma Long Hắc Vực** (`mons.malong`, `world: true`): mỗi máy chủ có người online, khoảng 30 phút (27–33, lần đầu 8–14 phút sau khi máy chủ chạy) xuất hiện 1 con ở bản đồ săn ngẫu nhiên (1–6), khu ngẫu nhiên trong 5 khu đầu (không báo khu). Báo trước 1 phút (tên bản đồ), báo khi xuất hiện, báo người kết liễu; 15–20 phút không ai hạ thì bay đi. Lập lịch ở `worker.js wbTick/wbSpawn`; khu có boss được giữ (`inst.keep`). GM: nút "Gọi Ma Long" (lệnh `worldboss`).
- Cấp boss = cấp quái cao nhất bản đồ + 10; máu ×400, công ×3, giáp ×2,5 so với quái cùng cấp; không bị đẩy/choáng như trùm; hồi 2%/giây khi 20 giây không ai đánh; về chỗ cũ không hồi máu.
- 3 giai đoạn theo máu (>60%, 60–30%, <30%): chiêu có `ph` chỉ dùng từ giai đoạn đó; dưới 60% nổi giận (công ×1,25, chiêu nhanh hơn 25%, ửng đỏ). Triệu Hồi rồng con: còn rồng con thì boss có khiên (nhận 15% sát thương).
- Đòn cuối (đã góp ≥1% máu) nhận 1 **Trứng** ngẫu nhiên trong 4 loài vào thẳng túi (được vượt giới hạn túi). Người góp ≥1% chia kinh nghiệm/vàng như trùm. Trứng (`slot: 'egg'`) giao dịch được, không bán cửa hàng, không mặc, không rèn.
- **Bà Ấp Trứng** (NPC `egg`, Làng x=1070, tổ ở bên phải): ấp 1 quả một lúc, 24 giờ; trả 2.000.000 vàng rút ngắn còn một nửa thời gian còn lại (1 lần/quả); nở khi hết giờ (chuồng tối đa 3). Dữ liệu: `ch.hatch {sp,start,end,cut}`, `ch.pets[]`, `ch.petOn`.
- **Pet**: 4 loài (Rồng Lửa thiên sức đánh, Cáo Băng chí mạng, Sói Sấm tốc đánh, Rùa Ngọc máu). Sao 1–5 (35/30/20/10/5%) nhân điểm ×0,8…×1,3. Mỗi cấp +3 điểm ngẫu nhiên (50% vào chỉ số thiên hướng). Cấp tối đa 100, không vượt cấp chủ + 5; nhận kinh nghiệm như chủ, chủ thêm 10% kinh nghiệm của pet. Kỹ năng tự dùng ở cấp 10/40/80 (hồi 8/15/40 giây). Giai đoạn: Non 1–39, Trưởng thành 40–79, Thần thú 80–100. Ngất khi hết máu (bị quái đang đánh chủ đánh trúng), tự hồi sinh sau 60 giây. Đổi tên miễn phí 1 lần (2–12 ký tự); thả pet = xóa vĩnh viễn, phải nhập đúng tên, nút chờ 3 giây.
- Thao tác: `hatch_start/hatch_cut/hatch_open` (phải đứng gần NPC), `pet_on/pet_name/pet_free` (ở đâu cũng được). Ảnh chụp có `q`: `[chủ, loài, giai đoạn, x, y, hướng, động tác(0/1 đánh/2 chiêu/3 ngất), máu%, tên, cấp, bay]`; sự kiện `pa` (pet đánh), `ps` (pet chiêu), `plv`, `pf`.
- Ảnh: `mon2/malong`, `mon2/dragonling`, `vfx/ml_*`, `vfx/pf_*`, `vfx/hit_*`, `pet/<loài>/<giai đoạn>/`, `egg/<loài>/`, `npc/egg`, `npc/nest`. Thân và chiêu vẽ tách riêng. Xem thử: `HSNC_PREVIEW=pets`.
- Chưa có: đồ pet (vòng cổ, giáp lưng, móng vuốt, bùa linh) — để đợt sau.
- APP_MIN 2.9.0.
