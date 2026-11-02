# Prompt triển khai — XP, cấp 9999 và bảng chỉ số

## Mục tiêu và lựa chọn đã thống nhất

Mở rộng RPG Godot 4 hiện tại bằng vòng chơi thật: hạ quái → quái rơi orb kinh nghiệm có idle riêng → người chơi sống đi tới thu thập → thanh XP tăng → lên cấp → nhận 5 điểm mỗi cấp → mở bảng chỉ số và phân bổ → chỉ số có tác dụng → lưu/tải giữ nguyên. Người dùng đã chọn 7 chỉ số và đòn chém cường hóa; yêu cầu cả bộ chỉ số khởi đầu. Không dựng cây kỹ năng nhiều nhánh hoặc thay các nhân dạng đồ họa vừa được duyệt.

Đọc AGENTS.md, PROGRESS.md, ARCHITECTURE.md và các Godot skills liên quan trước sửa. Mọi asset mới có resource/manifest riêng, idle/ambient nhiều keyframe thật ngay lúc chờ; FX ngắn có play riêng. State mới giữ identity/palette/vật liệu/frame/pivot của bộ animation tương ứng; body/VFX/contact phải đồng tick damage.

## Khởi đầu và công thức

Level1, XP0/100, điểm chưa dùng0; cả7 allocated bằng0. Kiếm18damage, đi72/chạy112px/s giữ cân bằng cũ khi chưa phân bổ. Không tự tăng stat theo level: 5 điểm/cấp là quyền lựa chọn.

| Chỉ số | Khởi đầu | Tác dụng mỗi điểm phân bổ n |
|---|---|---|
| Máu | 100 | max_health =100+20n |
| Năng lượng | 50 | max_energy =50+10n; R tiêu20, damage×1.8 |
| Thể lực | 100 | max_stamina =100+10n; chạy tiêu18/s, hồi20/s sau.6s nghỉ |
| Tốc độ | đi72/chạy112 | walk=72+108n/(n+50), run=walk×112/72; softcap đi180/chạy280 |
| May mắn | 0 | crit_chance=.5n/(n+100); xp_bonus=.5n/(n+100), đều dưới50% |
| Sức mạnh | 10 | displayed=10+n; cộng2n vào sát thương vũ khí |
| Phòng thủ | 0 | displayed=n; reduction=.8n/(n+40), dưới80%; damage nhận ít nhất1 |

XP cần từ cấp L lên L+1: `100 +25*(L-1)+5*(L-1)^2`, số nguyên64bit. XP trong thanh là phần dư của cấp hiện tại; dư được chuyển qua nhiều cấp trong một lần nhận. Cấp tối đa9999: XP=0, UI ghi MAX, không tăng thêm điểm hay tràn số. Tổng điểm đã phân bổ+điểm còn lại phải đúng`5*(level-1)`; tối đa49990. Không cấp5điểm ở level1. Từ chối số âm, float không nguyên, NaN, vô hạn, stat lạ, số điểm vượt ngân sách.

Quái thường rơi60XP, guardian120XP; XP chỉ cộng khi orb được thu thập. Luck bonus áp dụng khi nhặt: round(amount*(1+xp_bonus)). Orb không chiếm túi, tự hút khi gần trong64px và thu trong12px; không nhặt khi chết/pause/menu, raycast tránh hút xuyên tường. Drop có ID duy nhất, không mất qua đổi vùng/save/load, không nhận hai lần. Rơi orb độc lập loot cũ; guardian/quest chỉ thưởng một lần.

Để có nguồn XP tiếp tục, scout thường hồi sinh sau khi rời rừng và vào lại; guardian không hồi sinh. Loot vật liệu chỉ rơi lần đầu, các lượt scout sau rơi XP để tránh nhân vật liệu và đầy đồ trên đất. Orb cũ chưa nhặt cùng nguồn được gộp lượng XP, giữ ID cũ và vị trí đã lưu; không ghi đè hoặc cộng XP sớm. Không làm mất chest/collected/quest flags hoặc HP địch còn sống khi lưu giữa trận. Đây là quái hồi sinh theo vòng đi vùng, không timer respawn giữa combat; loading không kích hoạt hồi sinh.

## Tài nguyên và hành động

Mana hồi3/s sau1.5s không dùng. Shift chỉ tiêu thể lực khi thực sự di chuyển/chạy; hết thể lực đi bộ, cần hồi20 mới chạy lại để tránh giật bật/tắt. Không tiêu khi UI khóa input/đứng yên/tấn công. R dùng đòn attack cùng body animation đã có, VFX riêng cùng style; chỉ trừ mana sau khi chắc chắn attack bắt đầu, không trừ khi cooldown/chết/khóa input/không vũ khí. Critical×1.5 tính một lần mỗi swing; base luck0 không gây random trong hồi quy cũ. Giảm sát thương không làm hit âm hoặc bất tử.

Hurt ngắt đòn chưa tới contact cho cả player và enemy: hủy hit đang chờ và ẩn VFX/báo đòn, không được gây damage trong body state HURT. Đòn đã bắt đầu hợp lệ vẫn giữ mana đã tiêu và cooldown; không refund để spam đòn. Nhịp walk/sprint đi theo chỉ số Tốc độ, idle có nhịp riêng; tốc độ di chuyển không làm nhanh attack/hurt/death/contact.

Tăng max vital giữ lượng đã mất: alive_current += max_delta, không hồi đầy bằng cách mở bảng hoặc lên cấp. Save/load phục hồi đúng current; đi vùng giữ current. Hồi sinh đầy max vital hiện tại, giữ XP/level/điểm và không tự ghi đè save. Các hồi phục dừng khi world pause.

## Hợp đồng code và quyền ghi

- Architecture: `scripts/progression/progression.gd`, `resources/progression/*.json`, `scripts/save/save_service.gd`, `tests/progression_model_test.gd`. Model RefCounted: MAX_LEVEL, STAT_KEYS; properties level, experience, unspent_points, allocated; methods reset(), xp_required(level_override=0), gain_experience(amount)->Dictionary, allocate(stat,amount=1)->bool, derived_stats()->Dictionary, snapshot()->Dictionary, restore(data)->bool, valid_data(data)->bool. Signals changed và level_gained(old_level,new_level,points). Snapshot `{level,experience,unspent_points,allocated}`. Derived keys max_health/max_energy/max_stamina/walk_speed/run_speed/luck/strength/defense/damage_bonus/damage_reduction/crit_chance/xp_bonus.
- Gameplay: player/health/melee scripts và tests riêng. `player.apply_stats(values,refill=false)`, `restore_vitals(energy,stamina)`, energy/max_energy/stamina/max_stamina, signal resources_changed(energy,max_energy,stamina,max_stamina), empowered_attack(mouse_aim=false). Main gán weapon_damage=base weapon+damage_bonus; không cộng bonus hai lần. Melee.begin thêm empowered=false tùy chọn. Health damage_reduction mặc định0.
- UI: chỉ `scripts/ui/**`, `scenes/ui/**`; `ui.update_progression(model)`, `ui.set_resources(energy,max_energy,stamina,max_stamina)`, signal allocate_stat_requested(stat,amount), character_requested; screen`character`, bảng7row và batch1/5/10/100. Giữ HP public fields để hồi quy. Dùng asset mới `ui_experience`, `ui_energy`, `ui_stamina`, `ui_stats_panel`.
- Root: Main/input/world/XP orb/respawn integration, assets mới, merge manifest, integration/render tests, runner/docs. Không nhóm nào sửa file nhóm khác; engine CLI chạy tuần tự bởi root sau bàn giao.

## Save version2 và migration

Payload mới thêm `progression` và `vitals:{energy,stamina}`; HP kiểm theo derived max. Snapshot vùng thêm `spawn_cycles` cho scout, drops chấp nhận kind`experience` với amount integer, không yêu cầu item/count. Version1 vẫn verifychecksum/validschema cũ trước migrate: thêm progressionlevel1zeroallocation, vitals50/100, spawncycles0; giữ tuyệt đối inventory/quest/object/HP/position hiện có. Không tự ghi file khi load/migrate; lần lưu chủ động tiếp theo mới ghi version2. Backup v1/v2 đọc được; bản hỏng không ghi đè backup tốt. Các test cũ gọi valid_snapshot với payload v1 không envelope được chuẩn hóa tương thích; Main snapshot thật luôn có progression/vitals.

## UI và nghiệm thu

HUD luôn có level/XP và ba vital, số lớn không tràn tại9999/49990/maxHP. C mở bảng chỉ số; có nút truy cập rõ ràng, tiêu điểm bàn phím, Esc/C đóng. UI pause world; phân bổ điểm cập nhật đúng max/current/thiệt hại/tốc độ ngay và không cho chi vượt ngân sách. MAX vẫn thu/xóa orb nhưng không thêm XP/điểm; thông báo rõ. Không hiển thị tính năng giả.

Kiểm: XP0/boundary/carry/multilevel/cap9999/int64, 5points mỗi cấp/không lặp, stat budgets/tamper, hiệu ứng7stats, mana/sprint/regen/pause, kill→drop→collect→level→allocate thật, respawn scout không lặp guardian/quest, lưu orb chưa nhặt và pickup một lần sau reload, migrationv1/roundtripv2/backupcorrupt. Chạy toàn bộ check.sh giữ hồi quy; render thật HUD/bảng/XPdrop/levelup, motion preview mới và xem ảnh. Ghi kết quả và giới hạn thực vào PROGRESS.
