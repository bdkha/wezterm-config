<#
.SYNOPSIS
    Cài config WezTerm này trên Windows.

.DESCRIPTION
    Trỏ %USERPROFILE%\.config\wezterm vào thư mục repo bằng symlink.
    Máy chưa bật Developer Mode thì không tạo được symlink; khi đó script
    đặt biến môi trường user WEZTERM_CONFIG_FILE trỏ thẳng vào wezterm.lua
    trong repo. Không dùng junction: bản WezTerm mới bật mitigation
    ProcessRedirectionTrustPolicy của Windows nên từ chối đi qua junction do
    user thường tạo, báo lỗi 448 ERROR_UNTRUSTED_MOUNT_POINT.
    Config cũ được đổi tên thành .backup.<thời gian>.

.PARAMETER Font
    Tải và cài JetBrainsMono Nerd Font cho user hiện tại. Không cần admin.

.EXAMPLE
    .\install.ps1
    .\install.ps1 -Font
#>
[CmdletBinding()]
param(
    [switch]$Font,
    [string]$FontVersion = 'v3.5.1'
)

$ErrorActionPreference = 'Stop'

$repo   = $PSScriptRoot
$target = Join-Path $HOME '.config\wezterm'

Write-Host "repo   : $repo"
Write-Host "target : $target"

# ── Liên kết thư mục config ────────────────────────────────────────────────
$entry   = Join-Path $repo 'wezterm.lua'
$envName = 'WEZTERM_CONFIG_FILE'
$envVal  = [Environment]::GetEnvironmentVariable($envName, 'User')

$existing = Get-Item $target -Force -ErrorAction SilentlyContinue
$isLink   = $existing -and ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint)
$linkTo   = if ($isLink) { [string](@($existing.Target)[0]) } else { $null }

if ($isLink -and $existing.LinkType -eq 'SymbolicLink' -and $linkTo -eq $repo) {
    Write-Host "Da tro dung vao repo bang symlink roi, khong can lam gi." -ForegroundColor Green
    $mode = 'symlink'
}
else {
    if ($isLink) {
        # Ke ca junction dang tro dung repo cung phai bo: WezTerm moi khong
        # di qua junction do user thuong tao (loi 448).
        try {
            $existing.Delete()
            Write-Host "Da go lien ket cu ($($existing.LinkType)) tai $target" -ForegroundColor Yellow
        }
        catch {
            Write-Host ""
            Write-Host "Khong go duoc lien ket cu tai $target" -ForegroundColor Red
            Write-Host "Dong het cua so WezTerm roi chay lai script nay."
            exit 1
        }
    }
    elseif ($existing) {
        $backupName = "wezterm.backup." + (Get-Date -Format 'yyyyMMddHHmmss')
        try {
            Rename-Item -Path $target -NewName $backupName -ErrorAction Stop
            Write-Host "Da chuyen config cu sang $backupName" -ForegroundColor Yellow
        }
        catch {
            Write-Host ""
            Write-Host "Khong doi ten duoc thu muc config cu." -ForegroundColor Red
            Write-Host "Thuong la do WezTerm dang chay va giu thu muc do."
            Write-Host "Dong het cua so WezTerm roi chay lai script nay."
            exit 1
        }
    }

    New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null

    $mode = $null
    try {
        New-Item -ItemType SymbolicLink -Path $target -Target $repo -ErrorAction Stop | Out-Null
        $mode = 'symlink'
        Write-Host "Da lien ket (symlink): $target -> $repo" -ForegroundColor Green
    }
    catch {
        $mode = 'envvar'
    }
}

if ($mode -eq 'symlink') {
    # Bien moi truong khong con can nua, de lai chi gay kho hieu.
    if ($envVal -eq $entry) {
        [Environment]::SetEnvironmentVariable($envName, $null, 'User')
        Write-Host "Da xoa bien $envName (da co symlink, khong can nua)." -ForegroundColor Yellow
    }
}
else {
    # Khong tao duoc symlink (chua bat Developer Mode, khong co quyen).
    # Khong rot ve junction: WezTerm moi tra loi 448 khi di qua junction
    # do user thuong tao. Tro thang bang bien moi truong thay vi vay.
    [Environment]::SetEnvironmentVariable($envName, $entry, 'User')
    $env:WEZTERM_CONFIG_FILE = $entry

    Write-Host ""
    Write-Host "Khong tao duoc symlink (may chua bat Developer Mode)." -ForegroundColor Yellow
    Write-Host "Da dat bien moi truong user thay the:" -ForegroundColor Green
    Write-Host "  $envName = $entry"
    Write-Host ""
    Write-Host "Dang xuat roi dang nhap lai (hoac khoi dong lai Explorer) de" -ForegroundColor Yellow
    Write-Host "WezTerm thay bien nay. Muon thu ngay ma khong dang xuat:"
    Write-Host "  `$env:$envName = '$entry'"
    Write-Host "  & 'C:\Program Files\WezTerm\wezterm-gui.exe'"
    Write-Host ""
    Write-Host "Muon dung symlink cho gon: bat Developer Mode trong"
    Write-Host "Settings > System > For developers, roi chay lai script nay."
}

# ── Font ───────────────────────────────────────────────────────────────────
if ($Font) {
    Write-Host ""
    Write-Host "Dang tai JetBrainsMono Nerd Font $FontVersion ..."

    $tmp = Join-Path $env:TEMP ("jbmono-nf-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    $zip = Join-Path $tmp 'JetBrainsMono.zip'

    $url = "https://github.com/ryanoasis/nerd-fonts/releases/download/$FontVersion/JetBrainsMono.zip"
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
    Expand-Archive -Path $zip -DestinationPath (Join-Path $tmp 'x') -Force

    $want = @(
        'JetBrainsMonoNerdFont-Regular.ttf'
        'JetBrainsMonoNerdFont-Bold.ttf'
        'JetBrainsMonoNerdFont-Italic.ttf'
        'JetBrainsMonoNerdFont-BoldItalic.ttf'
        'JetBrainsMonoNerdFont-Medium.ttf'
        'JetBrainsMonoNerdFont-MediumItalic.ttf'
    )
    $dest = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    $reg = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'

    $n = 0
    Get-ChildItem (Join-Path $tmp 'x') -Filter *.ttf -Recurse |
        Where-Object { $want -contains $_.Name } |
        ForEach-Object {
            $file = Join-Path $dest $_.Name
            Copy-Item $_.FullName $file -Force
            New-ItemProperty -Path $reg -Name "$($_.BaseName) (TrueType)" -Value $file -PropertyType String -Force | Out-Null
            $n++
        }

    Write-Host "Da cai $n file font vao thu muc font cua user (khong can admin)." -ForegroundColor Green
    Write-Host "Ung dung dang mo can khoi dong lai moi thay font moi."
    Write-Host "Don dep thu cong neu muon: $tmp"
}

Write-Host ""
Write-Host "Xong. Mo WezTerm len la chay." -ForegroundColor Green
Write-Host "Muon chinh rieng cho may nay: copy local.lua.example thanh local.lua"
