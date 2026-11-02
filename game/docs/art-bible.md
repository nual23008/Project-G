# Mỹ thuật cho bản chơi mở đầu

Giữ viewport 640×360, tile 16×16, nearest và integer scaling. Góc nhìn top-down ba phần tư; ánh sáng từ trên trái. Nhân vật 24×32, guardian 32×32, chân và collision giữ kích thước bản đang chơi. Không đổi nội dung hoặc save.

Một palette chung nằm trong `tools/build_stage1_art.py` (`PALETTE`): bóng mận #332938/#493543; gỗ #614234/#80513e/#a57550/#c79b67; mái đỏ rượu #572f3b/#793d48/#a35d59; đá kem #726952/#938368/#ad9474/#d0bc91/#f6e3b0; foliage #153a3b/#214c43/#315b43/#47704a/#64814e/#87915c; nước #214c58/#346b70/#508b87/#80b4a4; cloth indigo #294453/#3e667f/#5b91a1. Ánh hổ phách #d49b58/#f0bc73/#ffe2a0. Các màu còn lại là skin, herb, crystal, UI, sparkle và shadow alpha96; danh sách hex chính xác được xuất thành `assets/art_stage1/palette.json`.

Tối đa 48 màu opaque cho toàn bộ bộ ảnh, không anti-aliasing. Font Noto Sans tiếng Việt hiện tại được giữ để bảo toàn khả năng đọc Unicode. Pixel đơn chỉ dành cho mắt, đinh, glint và đom đóm; vật liệu dùng cụm có cạnh rõ. Không co giãn nhà/đá. Cây chỉ dịch từng cụm tán tối đa 1 pixel, khói/cửa sổ có vòng riêng trong sheet nhà, nước chuyển vệt gợn. Đất/đường/bờ là vật liệu tĩnh, khai báo đúng 1 frame.

Nguồn là pixel art deterministic gốc trong `assets/sprites`, `assets/tilesets`; mỗi frame xuất lại qua character grid bằng `pixel_draw.py`. Không dùng nguồn ImageGen thử nghiệm trong `art_v3`. Grid nguồn, sheet Godot và preview đều có trong `assets/art_stage1`. Animation đánh dùng nhịp vật lý hiện tại: contact lúc .084 giây nằm trong frame index2 của slash 8 frame/.24 giây và attack body9frame/.27giây.
