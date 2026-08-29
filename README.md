# wezterm

Config WezTerm dùng chung cho Windows, macOS và Linux. Leader key kiểu tmux,
chuyển project bằng fuzzy search, lưu và khôi phục nguyên bố cục pane theo tên.

- Leader `Ctrl+A`, thao tác hay dùng vẫn nằm trên `Ctrl+Shift`
- Status bar hiện workspace, nhánh git và thư mục hiện tại
- `Ctrl+A W` mở fuzzy switcher quét mọi git repo trong thư mục code của bạn
- `Ctrl+A Shift+S` / `Shift+R` lưu và dựng lại bố cục pane, đúng tỉ lệ, đúng thư mục
- `Ctrl+A T` chọn theme có xem trước — màu đổi ngay theo scheme đang trỏ tới

## Cài đặt

```sh
git clone git@github.com:bdkha/wezterm-config.git ~/Code/wezterm-config
cd ~/Code/wezterm-config
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
	theme = "Tokyo Night",              -- tên scheme bất kỳ, hoặc "auto"
	opacity = 0.92,                     -- nền trong + mờ hậu cảnh
	project_roots = { "D:/Code", "D:/Product" },
}
```

Khoá nào không khai báo thì giữ mặc định trong `wezterm.lua`. Thư mục nào trong
`project_roots` không tồn tại trên máy đó sẽ tự bị bỏ qua, nên cứ liệt kê thoải mái.

## Cách dùng

### Mở project

`Ctrl+A` `W`.

Picker quét thư mục `.git` ở độ sâu 1 và 2 dưới mỗi đường dẫn trong
`project_roots`. Repo con nằm trong repo cha bị bỏ qua — một repo có
`android/`, `ios/`, `server/` bên trong vẫn chỉ hiện một dòng.

Workspace đang mở xếp trên đầu, phía dưới là project chưa mở. Gõ vài chữ để
lọc, `Enter` để mở. Project chưa mở sẽ thành một workspace mới đặt tên theo
thư mục, shell mở sẵn ngay tại đó. Tên workspace hiện ở ô ngoài cùng bên phải
thanh trạng thái.

### Lưu và dựng lại bố cục pane

Chia pane và `cd` cho vừa ý — ví dụ pane trái chạy git, hai pane phải chạy
Metro và API server — rồi `Ctrl+A` `Shift+S`, gõ tên, `Enter`.

Lần sau `Ctrl+A` `Shift+R` rồi chọn tên đó: dựng lại đúng số pane, đúng tỉ lệ,
mỗi pane mở đúng thư mục cũ.

Session dựng vào workspace trùng tên với nó. Workspace đó đang mở sẵn thì chỉ
chuyển sang chứ không dựng lại, tránh nhân đôi tab. `Ctrl+A` `Shift+D` để xoá
một bản đã lưu.

### Đổi theme

`Ctrl+A` `T` mở chế độ duyệt. Bấm `↓` `↑` hoặc `j` `k` để đi qua từng scheme —
**cửa sổ đổi màu ngay theo cái đang trỏ tới**, cả nền lẫn tab bar lẫn status bar.
Tên scheme và vị trí hiện ở góc trái thanh tab.

| Phím | Việc |
| --- | --- |
| `↓` `↑` hoặc `j` `k` | scheme kế tiếp / trước đó |
| `PgDn` `PgUp` | nhảy 20 cái |
| `/` | fuzzy search — chọn xong nhảy con trỏ tới đó và xem trước tiếp |
| `Enter` | giữ scheme đang xem, áp cho mọi cửa sổ |
| `Esc` hoặc `q` | huỷ, trả lại màu như trước khi vào |
| `0` | về theme mặc định |

Xem trước chỉ tác động lên cửa sổ đang duyệt, các cửa sổ khác giữ nguyên. Chốt
bằng `Enter` thì mới ghi `theme.txt` và áp cho tất cả.

### Chỉnh kích thước pane

`Ctrl+A` `R` để vào chế độ resize — huy hiệu đỏ `RESIZE` hiện trên thanh tab.
Bấm `h` `j` `k` `l` hoặc mũi tên bao nhiêu lần tuỳ ý; `Esc`, `Enter` hoặc `q` để thoát.

## Phím tắt

Leader là `Ctrl+A`: bấm rồi thả ra, sau đó mới bấm phím lệnh. Trong lúc chờ,
thanh tab hiện huy hiệu vàng `LEADER`; sau 1,5 giây không bấm gì thì tự huỷ.

### Tab

| Phím | Việc |
| --- | --- |
| `Ctrl+Shift+T` | tab mới, kế thừa thư mục hiện tại |
| `Ctrl+Shift+W` | đóng tab, có hỏi lại nếu còn tiến trình chạy |
| `Alt+1` … `Alt+8` | nhảy tới tab thứ 1–8 |
| `Alt+9` | nhảy tới tab cuối cùng, dù đang có bao nhiêu tab |
| `Ctrl+Tab` | tab kế tiếp |
| `Ctrl+Shift+Tab` | tab trước |
| `Ctrl+Shift+PgUp` / `PgDn` | kéo tab hiện tại sang trái / phải |

### Pane

| Phím | Việc |
| --- | --- |
| `Ctrl+Shift+D` | chia dọc — pane mới nằm bên phải |
| `Ctrl+Shift+E` | chia ngang — pane mới nằm bên dưới |
| `Alt+←` `↑` `↓` `→` | chuyển pane theo hướng |
| `Alt+h` `j` `k` `l` | chuyển pane, kiểu vim |
| `Ctrl+Shift+Z` | phóng to pane ra cả tab, bấm lại để thu về |
| `Ctrl+Shift+Q` | đóng pane, có hỏi lại |

### Copy, dán, tìm

| Phím | Việc |
| --- | --- |
| `Ctrl+C` | đang bôi đen thì copy; không thì gửi SIGINT như bình thường |
| `Ctrl+Shift+C` | copy |
| `Ctrl+V` / `Ctrl+Shift+V` | dán |
| chuột phải | dán |
| `Ctrl+Shift+F` | tìm trong scrollback (lưu 25 000 dòng) |
| `Ctrl+Shift+X` | copy mode — chọn văn bản bằng bàn phím |
| `Ctrl+Shift+Space` | quick select — gắn nhãn mọi URL và đường dẫn, bấm 1–2 chữ để copy |
| `Ctrl+Shift+K` | xoá sạch scrollback |
| `Ctrl` + click | mở link dưới con trỏ |
| `Shift+PgUp` / `PgDn` | cuộn lên / xuống một trang |

### Cửa sổ và config

| Phím | Việc |
| --- | --- |
| `Ctrl+Shift+P` | launcher — shell, workspace, thư mục code |
| `Ctrl+Shift+N` | cửa sổ mới |
| `Ctrl+Shift+R` | nạp lại config sau khi sửa file |
| `Alt+Enter` | toàn màn hình |
| `Ctrl+=` / `Ctrl+-` / `Ctrl+0` | cỡ chữ to hơn / nhỏ hơn / về mặc định |

### Leader — project và workspace

| Phím | Việc |
| --- | --- |
| `Ctrl+A` `W` | **mở project** — fuzzy search mọi git repo |
| `Ctrl+A` `Shift+W` | tạo workspace trống, tên tự đặt |
| `Ctrl+A` `[` / `]` | workspace trước / kế tiếp |

### Leader — session

| Phím | Việc |
| --- | --- |
| `Ctrl+A` `Shift+S` | **lưu** bố cục hiện tại thành session có tên |
| `Ctrl+A` `Shift+R` | **khôi phục** session |
| `Ctrl+A` `Shift+D` | xoá một session đã lưu |

### Leader — pane

| Phím | Việc |
| --- | --- |
| `Ctrl+A` `\|` hoặc `\` | chia dọc — dùng `\` thì khỏi giữ `Shift` |
| `Ctrl+A` `-` | chia ngang |
| `Ctrl+A` `R` | chế độ resize — `hjkl` hoặc mũi tên; `Esc` / `Enter` / `q` để thoát |
| `Ctrl+A` `P` | gắn nhãn `a s d f…` lên từng pane, bấm chữ để nhảy tới |
| `Ctrl+A` `S` | cũng gắn nhãn, nhưng để hoán đổi vị trí với pane đang đứng |
| `Ctrl+A` `O` | xoay vòng vị trí các pane |
| `Ctrl+A` `Z` | phóng to pane |
| `Ctrl+A` `X` | đóng pane |

### Leader — tab và tiện ích

| Phím | Việc |
| --- | --- |
| `Ctrl+A` `C` | tab mới |
| `Ctrl+A` `,` | đổi tên tab — tên này được lưu vào session |
| `Ctrl+A` `T` | **chọn theme** — vào chế độ duyệt có xem trước |
| `Ctrl+A` `K` | command palette — tra mọi lệnh WezTerm khi quên phím |
| `Ctrl+A` `L` | launcher |
| `Ctrl+A` `F` | tìm trong scrollback |
| `Ctrl+A` `U` | bảng chọn ký tự và emoji, chọn xong tự copy |
| `Ctrl+A` `A` | gửi `Ctrl+A` thật xuống shell (PSReadLine: về đầu dòng) |

Các phím mặc định của WezTerm vẫn còn nguyên, gồm cả nhóm `Cmd` trên macOS.
Xem đầy đủ bằng `wezterm show-keys`, thêm `--lua` để lấy dạng dán được vào config.

## Theme

Mặc định là **Catppuccin Mocha**, không dò theo hệ điều hành.

`Ctrl+A T` mở chế độ duyệt qua hơn 1000 color scheme có sẵn của WezTerm, 15 cái
hay dùng được đẩy lên đầu. Màu đổi ngay theo scheme đang trỏ tới, `Enter` để giữ,
`Esc` để trả lại như cũ. Lựa chọn được ghi vào `theme.txt` (gitignore) nên còn
nguyên sau khi khởi động lại.

`InputSelector` của WezTerm chỉ báo lúc bấm `Enter`, không báo khi con trỏ di
chuyển, nên không xem trước bên trong nó được. Vì vậy việc duyệt dùng key table
riêng, còn fuzzy search vẫn là `InputSelector`, mở bằng phím `/`.

Mocha và Latte có bảng màu chỉnh tay. Các scheme còn lại được suy ra từ chính
nó — nền, chữ và 8 màu ANSI — nên powerline trên status bar luôn hợp tông với
scheme đang dùng, kể cả theme sáng.

Thứ tự ưu tiên: `theme.txt` → `theme` trong `local.lua` → mặc định. Chọn
"Về mặc định" trong picker là xoá `theme.txt`.

Đặt `theme = "auto"` nếu muốn theo hệ điều hành. Trên Windows, theme được đọc
thẳng từ registry vì `wezterm.gui.get_appearance()` trả sai khi chưa có cửa sổ nào.

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
  theme.lua            bảng màu, suy màu status bar từ scheme đang dùng
  theme_picker.lua     picker chọn theme (Ctrl+A T)
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
| Màu không như mong đợi | `Ctrl+A T` chọn lại, hoặc xoá `theme.txt` để về mặc định |
| Sửa config mà không thấy đổi | Nhiều khả năng lỗi cú pháp. Chạy `wezterm ls-fonts` để đọc lỗi kèm số dòng |
| `Ctrl+A` không về đầu dòng nữa | Đúng thiết kế, nó là leader. Bấm `Ctrl+A` rồi `A` để gửi xuống shell |
