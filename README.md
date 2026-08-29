# wezterm

Config WezTerm dùng chung cho Windows, macOS và Linux. Leader key kiểu tmux,
chuyển project bằng fuzzy search, lưu và khôi phục nguyên bố cục pane theo tên.

- Leader `Ctrl+A`, thao tác hay dùng vẫn nằm trên `Ctrl+Shift`
- Status bar hiện workspace, nhánh git và thư mục hiện tại
- `Ctrl+A W` mở fuzzy switcher quét mọi git repo trong thư mục code của bạn
- `Ctrl+A Shift+S` / `Shift+R` lưu và dựng lại bố cục pane, đúng tỉ lệ, đúng thư mục
- Catppuccin Mocha / Latte, tự đổi theo theme hệ điều hành

## Cài đặt

```sh
git clone git@github.com:bdkha/wezterm.git ~/Code/wezterm
cd ~/Code/wezterm
```

**macOS / Linux**

```sh
./install.sh --font
```

**Windows** (PowerShell)

```powershell
.\install.ps1 -Font
```

Script sẽ trỏ `~/.config/wezterm` vào thư mục repo bằng symlink — trên Windows
rơi về junction nếu máy chưa bật Developer Mode, nên không cần quyền quản trị.
Config cũ được đổi tên thành `wezterm.backup.<thời gian>` chứ không bị xoá.

Bỏ `--font` / `-Font` nếu máy đã có **JetBrainsMono Nerd Font**. Thiếu font này
thì icon và mũi tên powerline sẽ hiện thành ô vuông.

> Trên Windows, đóng hết cửa sổ WezTerm trước khi chạy installer — WezTerm giữ
> thư mục config nên không đổi tên được khi đang mở.

## Chỉnh riêng cho từng máy

`local.lua` nằm trong `.gitignore`, dùng để ghi đè mà không đụng vào repo:

```sh
cp local.lua.example local.lua
```

```lua
return {
	font_size = 13.5,
	opacity = 0.92,                     -- nền trong + mờ hậu cảnh
	project_roots = { "D:/Code", "D:/Product" },
}
```

Khoá nào không khai báo thì giữ mặc định trong `wezterm.lua`. Thư mục nào trong
`project_roots` không tồn tại trên máy đó sẽ tự bị bỏ qua, nên cứ liệt kê thoải mái.

## Phím tắt

Bấm `Ctrl+A` rồi thả ra, sau đó bấm phím lệnh. Trong lúc chờ, status bar hiện
huy hiệu vàng `LEADER`; sau 1,5 giây không bấm gì thì tự huỷ.

| Phím | Việc |
| --- | --- |
| `Ctrl+Shift+T` / `W` | tab mới / đóng tab |
| `Alt+1..8`, `Alt+9` | nhảy tới tab thứ n / tab cuối |
| `Ctrl+Shift+D` / `E` | chia pane dọc / ngang |
| `Alt+←↑↓→` hoặc `Alt+hjkl` | chuyển pane |
| `Ctrl+Shift+Z` | phóng to pane |
| `Ctrl+C` | có bôi đen thì copy, không thì gửi SIGINT |
| `Ctrl+Shift+F` / `K` | tìm trong scrollback / xoá scrollback |
| `Ctrl+Shift+P` | launcher: shell, workspace, thư mục code |
| `Ctrl+Shift+R` | nạp lại config |
| **`Ctrl+A W`** | **mở project** — fuzzy search mọi git repo |
| `Ctrl+A Shift+W` | tạo workspace trống |
| `Ctrl+A [` `]` | workspace trước / kế tiếp |
| **`Ctrl+A Shift+S`** | **lưu session** với tên tự đặt |
| **`Ctrl+A Shift+R`** | **khôi phục session** |
| `Ctrl+A Shift+D` | xoá session đã lưu |
| `Ctrl+A R` | chế độ resize (`hjkl` / mũi tên, `Esc` thoát) |
| `Ctrl+A P` / `S` | chọn pane / hoán đổi pane |
| `Ctrl+A \|` `\` `-` | chia pane kiểu tmux |
| `Ctrl+A ,` | đổi tên tab |
| `Ctrl+A K` | command palette |
| `Ctrl+A A` | gửi `Ctrl+A` thật xuống shell |

Xem đầy đủ, gồm cả mặc định của WezTerm: `wezterm show-keys`.

## Session

Bố cục pane được lưu thành file JSON trong `sessions/` (gitignore, vì chứa
đường dẫn thật trên máy). Lúc lưu, config đọc toạ độ của mọi pane rồi suy ngược
ra cây chia đôi; lúc khôi phục thì split đệ quy lại đúng cây đó và mở mỗi pane
vào thư mục đã ghi. Bố cục lồng nhau nhiều tầng, kể cả lưới 2×2, đều ra đúng hình.

Không có tự động lưu — chỉ ghi khi bạn bấm `Ctrl+A Shift+S`.

Không lưu được: nội dung màn hình, tiến trình đang chạy, và trạng thái zoom.

## Thư mục hiện tại (OSC 7)

Status bar, tên tab, nhánh git và session đều cần shell báo thư mục hiện tại
qua OSC 7. zsh và fish làm sẵn; bash và PowerShell thì không.

**PowerShell** — thêm vào `$PROFILE`:

```powershell
function Prompt {
    $loc = $executionContext.SessionState.Path.CurrentLocation
    $osc7 = ''
    if ($loc.Provider.Name -eq 'FileSystem') {
        $p = $loc.ProviderPath -replace '\\', '/'
        $osc7 = "$([char]27)]7;file://$env:COMPUTERNAME/$p$([char]27)\"
    }
    "${osc7}PS $loc$('>' * ($nestedPromptLevel + 1)) "
}
```

**bash** — thêm vào `~/.bashrc`:

```sh
PROMPT_COMMAND='printf "\033]7;file://%s%s\033\\" "$HOSTNAME" "$PWD"'
```

## Cấu trúc

```
wezterm.lua            điểm vào, mặc định có thể ghi đè
config/
  platform.lua         nhận diện hệ điều hành
  theme.lua            bảng màu Catppuccin, tự đổi sáng/tối
  util.lua             đọc cwd, nhánh git, icon theo tiến trình
  appearance.lua       font, cửa sổ, render
  launch.lua           shell mặc định và launcher, theo từng OS
  status.lua           tab bar và status bar
  workspaces.lua       quét project, fuzzy switcher
  sessions.lua         lưu / khôi phục bố cục pane
  keys.lua             phím tắt và chuột
install.sh             cài trên macOS / Linux
install.ps1            cài trên Windows
local.lua.example      mẫu ghi đè cho từng máy
```

## Sự cố

| Triệu chứng | Cách xử lý |
| --- | --- |
| Tab và status bar hiện ô vuông | Chưa có Nerd Font. Chạy installer với `--font` / `-Font`, rồi mở lại WezTerm |
| Thư mục trên status bar đứng im | Shell chưa phát OSC 7, xem mục trên |
| Cửa sổ nhấp nháy, dựng hình sai | Đặt `front_end = "OpenGL"` trong `local.lua` |
| Sửa config mà không thấy đổi | Nhiều khả năng lỗi cú pháp. Chạy `wezterm ls-fonts` để đọc lỗi kèm số dòng |
| `Ctrl+A` không về đầu dòng nữa | Đúng thiết kế, nó là leader. Bấm `Ctrl+A` rồi `A` để gửi xuống shell |
