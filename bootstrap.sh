#!/usr/bin/env bash

function doIt() (
	set -euo pipefail
	cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

	# Only reviewed, shareable files may be copied out of this checkout.
	local files=(
		.aliases .bash_profile .bash_prompt .bashrc .curlrc .editorconfig
		.exports .functions .gdbinit .gitattributes .gitconfig .gitignore
		.inputrc .screenrc .tmux.conf .vimrc .wezterm.lua .wgetrc
	)
	local file config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
	for file in "${files[@]}"; do
		rsync -avh --no-perms -- "$file" "$HOME/"
	done
	mkdir -p "$HOME/.vim/backups" "$HOME/.vim/swaps" "$HOME/.vim/undo"
	mkdir -p "$config_dir/wezterm" "$HOME/.config/dotfiles" "$config_dir/gtk-3.0"
	rsync -avh --no-perms -- wezterm/utils.lua "$config_dir/wezterm/"
	rsync -avh --no-perms -- config/lsan.supp "$HOME/.config/dotfiles/"

	# An existing stylesheet may contain local customizations.
	if [[ ! -e "$config_dir/gtk-3.0/gtk.css" && ! -L "$config_dir/gtk-3.0/gtk.css" ]]; then
		rsync -avh --no-perms -- config/gtk.css "$config_dir/gtk-3.0/"
	fi
)

if [[ $# -gt 1 || ( $# -eq 1 && "$1" != --force && "$1" != -f ) ]]; then
	echo "Usage: bash bootstrap.sh [--force]" >&2
	if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
		unset -f doIt
		return 1
	fi
	exit 1
fi

install_requested=false
if [[ "${1-}" == --force || "${1-}" == -f ]]; then
	install_requested=true
	doIt
else
	read -r -p "This may overwrite existing dotfiles in your home directory. Continue? (y/n) " -n 1
	echo ""
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		install_requested=true
		doIt
	fi
fi
status=$?
unset -f doIt
if [[ $status -ne 0 ]]; then
	if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
		return "$status"
	fi
	exit "$status"
fi
if "$install_requested" && [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
	source "$HOME/.bash_profile"
fi
unset status install_requested
