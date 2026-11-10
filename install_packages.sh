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

# Claude Desktop (beta) from Anthropic's apt repository; amd64 and arm64 only.
case "$(dpkg --print-architecture)" in
	amd64 | arm64)
		"${sudo_cmd[@]}" apt-get install --yes gnupg
		claude_key=/usr/share/keyrings/claude-desktop-archive-keyring.asc
		"${sudo_cmd[@]}" curl --fail --location --silent --show-error \
			--output "$claude_key" https://downloads.claude.ai/claude-desktop/key.asc
		claude_fpr="31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE"
		if [[ "$(gpg --show-keys --with-colons "$claude_key" | awk -F: '$1 == "fpr" {print $10}')" != "$claude_fpr" ]]; then
			echo "Unexpected Claude Desktop signing key fingerprint." >&2
			exit 1
		fi
		echo "deb [arch=amd64,arm64 signed-by=$claude_key] https://downloads.claude.ai/claude-desktop/apt/stable stable main" \
			| "${sudo_cmd[@]}" tee /etc/apt/sources.list.d/claude-desktop.list >/dev/null
		"${sudo_cmd[@]}" apt-get update
		"${sudo_cmd[@]}" apt-get install --yes claude-desktop
		;;
	*) echo "Skipping Claude Desktop: requires amd64 or arm64." >&2 ;;
esac

# Docker Engine, Buildx and the Compose plugin from Docker's apt repository.
case " $ID " in
	*" ubuntu "*) docker_distro=ubuntu ;;
	*) docker_distro=debian ;;
esac
docker_codename="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
if [[ "$docker_distro" == debian ]]; then
	docker_codename="${VERSION_CODENAME:-}"
fi
if [[ -z "$docker_codename" ]]; then
	echo "Cannot determine the distribution codename for Docker." >&2
	exit 1
fi
docker_key=/etc/apt/keyrings/docker.asc
"${sudo_cmd[@]}" curl --fail --location --silent --show-error \
	--output "$docker_key" "https://download.docker.com/linux/$docker_distro/gpg"
"${sudo_cmd[@]}" chmod a+r "$docker_key"
echo "deb [arch=$(dpkg --print-architecture) signed-by=$docker_key] https://download.docker.com/linux/$docker_distro $docker_codename stable" \
	| "${sudo_cmd[@]}" tee /etc/apt/sources.list.d/docker.list >/dev/null
"${sudo_cmd[@]}" apt-get update
"${sudo_cmd[@]}" apt-get install --yes docker-ce docker-ce-cli containerd.io \
	docker-buildx-plugin docker-compose-plugin
