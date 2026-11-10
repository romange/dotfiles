#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 0 ]]; then
	echo "Usage: bash install_packages.sh" >&2
	exit 1
fi

if [[ ! -r /etc/os-release ]]; then
	echo "Package installation requires Debian or Ubuntu." >&2
	exit 1
fi
source /etc/os-release
case " $ID ${ID_LIKE-} " in
	*" ubuntu "*) perf_package=linux-tools-common ;;
	*" debian "*) perf_package=linux-perf ;;
	*)
		echo "Package installation supports Debian and Ubuntu; use setup.sh --skip-packages elsewhere." >&2
		exit 1
		;;
esac

case "$(dpkg --print-architecture)" in
	amd64) vscode_arch=x64 ;;
	arm64) vscode_arch=arm64 ;;
	armhf) vscode_arch=armhf ;;
	*)
		echo "VS Code's Debian package requires amd64, arm64, or armhf." >&2
		exit 1
		;;
esac

sudo_cmd=()
if [[ $EUID -ne 0 ]]; then
	sudo_cmd=(sudo)
fi

packages=(
	automake bash-completion bison build-essential ca-certificates
	cmake curl flex git graphviz guake htop less libbz2-dev libcurl4-gnutls-dev
	libevent-dev libssl-dev libtool libxml2-dev llvm meld nano ninja-build
	openssh-client pkg-config rsync sysstat tmux tree vim vim-gui-common
	wget xz-utils "$perf_package"
)

"${sudo_cmd[@]}" apt-get update
"${sudo_cmd[@]}" apt-get install --yes "${packages[@]}"

vscode_dir="$(mktemp -d)"
trap 'rm -rf -- "$vscode_dir"' EXIT
curl --fail --location --silent --show-error \
	--output "$vscode_dir/code.deb" \
	"https://update.code.visualstudio.com/latest/linux-deb-$vscode_arch/stable"
# apt's unprivileged downloader needs access to the temporary package.
chmod 755 "$vscode_dir"
chmod 644 "$vscode_dir/code.deb"
printf '%s\n' 'code code/add-microsoft-repo boolean true' \
	| "${sudo_cmd[@]}" debconf-set-selections
"${sudo_cmd[@]}" apt-get install --yes "$vscode_dir/code.deb"

# GitHub CLI from the official apt repository.
"${sudo_cmd[@]}" mkdir -p -m 755 /etc/apt/keyrings
curl --fail --location --silent --show-error \
	https://cli.github.com/packages/githubcli-archive-keyring.gpg \
	| "${sudo_cmd[@]}" tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
"${sudo_cmd[@]}" chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
	| "${sudo_cmd[@]}" tee /etc/apt/sources.list.d/github-cli.list >/dev/null
"${sudo_cmd[@]}" apt-get update
"${sudo_cmd[@]}" apt-get install --yes gh

# Copilot CLI
curl -fsSL https://gh.io/copilot-install | bash

# Slack publishes its latest Debian package for amd64 only.
if [[ "$(dpkg --print-architecture)" == amd64 ]]; then
	curl --fail --location --silent --show-error \
		--output "$vscode_dir/slack.deb" \
		"https://slack.com/api/desktop.latestRelease?arch=x64&variant=deb&redirect=true"
	chmod 644 "$vscode_dir/slack.deb"
	"${sudo_cmd[@]}" apt-get install --yes "$vscode_dir/slack.deb"
else
	echo "Skipping Slack: no Debian package for this architecture." >&2
fi
