#!/usr/bin/env bash
#
# Cài config WezTerm này trên macOS hoặc Linux.
#
#   ./install.sh          chỉ liên kết thư mục config
#   ./install.sh --font   liên kết + cài JetBrainsMono Nerd Font
#
set -eu

NF_VERSION="${NF_VERSION:-v3.5.1}"
WANT_FONT=0

for arg in "$@"; do
	case "$arg" in
		--font) WANT_FONT=1 ;;
		-h|--help)
			sed -n '3,8p' "$0" | sed 's/^# \{0,1\}//'
			exit 0
			;;
		*)
			echo "Tham số không hiểu: $arg" >&2
			exit 1
			;;
	esac
done

repo="$(cd "$(dirname "$0")" && pwd)"
target="${XDG_CONFIG_HOME:-$HOME/.config}/wezterm"

echo "repo   : $repo"
echo "target : $target"

# ── Liên kết thư mục config ────────────────────────────────────────────────
if [ -L "$target" ] && [ "$(readlink "$target")" = "$repo" ]; then
	echo "Đã trỏ đúng vào repo rồi, không cần làm gì."
else
	if [ -e "$target" ] || [ -L "$target" ]; then
		backup="$target.backup.$(date +%Y%m%d%H%M%S)"
		mv "$target" "$backup"
		echo "Đã chuyển config cũ sang $backup"
	fi
	mkdir -p "$(dirname "$target")"
	ln -s "$repo" "$target"
	echo "Đã liên kết: $target -> $repo"
fi

# ── Font ───────────────────────────────────────────────────────────────────
if [ "$WANT_FONT" -eq 1 ]; then
	echo
	echo "Đang tải JetBrainsMono Nerd Font $NF_VERSION ..."

	command -v curl >/dev/null 2>&1 || { echo "Cần curl." >&2; exit 1; }
	command -v unzip >/dev/null 2>&1 || { echo "Cần unzip." >&2; exit 1; }

	case "$(uname -s)" in
		Darwin) font_dir="$HOME/Library/Fonts" ;;
		*)      font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts" ;;
	esac
	mkdir -p "$font_dir"

	tmp="$(mktemp -d)"
	trap 'rm -rf "$tmp"' EXIT

	url="https://github.com/ryanoasis/nerd-fonts/releases/download/$NF_VERSION/JetBrainsMono.zip"
	curl -fsSL "$url" -o "$tmp/JetBrainsMono.zip"
	unzip -qo "$tmp/JetBrainsMono.zip" -d "$tmp/x"

	n=0
	for face in Regular Bold Italic BoldItalic Medium MediumItalic; do
		src="$tmp/x/JetBrainsMonoNerdFont-$face.ttf"
		if [ -f "$src" ]; then
			cp -f "$src" "$font_dir/"
			n=$((n + 1))
		fi
	done
	echo "Đã cài $n file font vào $font_dir"

	if command -v fc-cache >/dev/null 2>&1; then
		fc-cache -f "$font_dir" >/dev/null
		echo "Đã nạp lại cache font."
	fi
fi

echo
echo "Xong. Mở WezTerm lên là chạy."
echo "Muốn chỉnh riêng cho máy này: cp local.lua.example local.lua"
