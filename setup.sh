#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
skip_packages=false
bootstrap_args=()

for arg in "$@"; do
	case "$arg" in
		--skip-packages) skip_packages=true ;;
		-f|--force) bootstrap_args=(--force) ;;
		-h|--help)
			echo "Usage: bash setup.sh [--skip-packages] [--force]"
			echo "Install Debian/Ubuntu dependencies and copy the dotfiles to HOME."
			exit 0
			;;
		*) printf 'Unknown option: %s\n' "$arg" >&2; exit 1 ;;
	esac
done

if ! "$skip_packages"; then
	bash "$repo_dir/install_packages.sh"
fi
bash "$repo_dir/bootstrap.sh" "${bootstrap_args[@]}"
