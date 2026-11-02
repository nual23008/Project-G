# Lộ trình

Trạng thái 2026-11-02: **Phase 1 và Phase 2 hoàn tất trong phạm vi tương ứng**. Phase 3 là bước tiếp theo. The First Echo hiện hoàn thành chặng thám hiểm và báo tin Rowan; đoạn Lyra/ký ức chưa triển khai.

| Phase | Nội dung | Dependency | Nghiệm thu |
|---|---|---|---|
| 1 | Village, movement, collision, camera, Rowan, UI | Godot 4.x + asset gốc | menu → đi lại → thoại → menu, headless và render sạch |
| 2 | Inventory ô lưới, pickup, forest, enemy AI, melee, HP/death, quest, save | Nền tảng P1 ổn định | nhận quest → chiến đấu → nhặt tinh thể → hoàn thành → reload giữ tiến trình |
| 3 | Lyra, Kael, Mira, nhiệm vụ phụ có hậu quả, ruins nhỏ, ký ức | Combat/quest/save của P2 | phần mở đầu trọn vẹn; đo thời lượng thực tế, mục tiêu 20–40 phút |
| 4 | Các vùng liên thông, equipment, crafting, boss, factions, lịch NPC, ngày đêm | Slice có QA và profiling | khu vực có nội dung, trạng thái bền vững, stream khi thực sự cần |
| 5 | 5 chương, 3 kết thúc, balance, polish, Windows/Linux release | Chơi xuyên suốt mọi nhánh | regression, save migration, export và kiểm tra từng nền tảng |

Thứ tự P2: Health + combat components → enemy phản ứng patrol/detect/chase/attack/return → item/inventory → quest events và forest → save/load atomic → thử một vòng chơi hoàn chỉnh. Chỉ mở Continue khi đã có save hợp lệ. Chưa xuất binary trước khi có export templates và kiểm tra nền tảng.
