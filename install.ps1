<#
.SYNOPSIS
    Cài config WezTerm này trên Windows.

.DESCRIPTION
    Trỏ %USERPROFILE%\.config\wezterm vào thư mục repo bằng symlink
    (rơi về junction nếu máy chưa bật Developer Mode — junction không cần
    quyền quản trị). Config cũ được đổi tên thành .backup.<thời gian>.

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
$existing = Get-Item $target -Force -ErrorAction SilentlyContinue

if ($existing -and $existing.Target -and ($existing.Target -eq $repo)) {
    Write-Host "Da tro dung vao repo roi, khong can lam gi." -ForegroundColor Green
}
else {
    if ($existing) {
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
    }
    catch {
        cmd /c mklink /J "`"$target`"" "`"$repo`"" | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Tao symlink lan junction deu that bai." -ForegroundColor Red
            exit 1
        }
        $mode = 'junction'
    }
    Write-Host "Da lien ket ($mode): $target -> $repo" -ForegroundColor Green
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
