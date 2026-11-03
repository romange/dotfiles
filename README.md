# Dotfiles and machine setup

Bash, Git, Vim, tmux and WezTerm settings, plus Debian/Ubuntu-family dependencies.
Replaces the separate setup gist; overlapping settings are merged.

## New machine

Review the scripts first. Run as your normal user, **not** with `sudo`.

```bash
git clone https://github.com/romange/dotfiles.git
cd dotfiles
bash setup.sh
```

| Command | Purpose |
|---|---|
| `bash setup.sh` | Install packages via sudo/apt, then copy dotfiles after confirmation |
| `bash setup.sh --skip-packages` | Copy dotfiles only; also works outside Debian/Ubuntu |
| `bash install_packages.sh` | Install dependencies only |
| `bash bootstrap.sh` | Copy dotfiles only |

Add `--force` to `setup.sh` or `bootstrap.sh` to skip overwrite confirmation.
Existing managed dotfiles are overwritten; back them up first. Existing GTK CSS
and private overrides are preserved. Open a new terminal afterward, or run
`source ~/.bash_profile`.

To update later, run `git pull --ff-only`, then one of the commands above.

## Dependencies and defaults

`install_packages.sh` lists build tools, C/C++ libraries, shell utilities, GUI
tools. Ubuntu may need the universe repository enabled. Python packages are not
explicitly installed; other tools may pull Python in as a dependency.
The compiler uses the current distribution version, and `xz -T0` replaces parallel `pxz`.
Ubuntu's perf tool may also need `linux-tools-$(uname -r)`.

Shell startup adds installed `/usr/lib/go-*/bin` toolchains to PATH and loads
optional Cargo, envman, and Google Cloud SDK (`/opt/google/google-cloud-sdk`)
startup hooks. These tools are not installed by setup; their configuration and
credentials are not copied into this repository.

VS Code is installed from Microsoft's official `.deb` for your architecture,
with its apt repository enabled for future updates.

Setup does not purge applications, disable AppArmor/UFW, change sysctl settings,
generate SSH keys, or import identities/credentials. Only allowlisted dotfiles
are copied. Sanitizer suppressions live in `~/.config/dotfiles/lsan.supp`.

## Private configuration

Keep identity, signing keys and credential-helper settings in
`~/.gitconfig.local`, **outside the checkout**:

```bash
git config --file "$HOME/.gitconfig.local" user.name "Your Name"
git config --file "$HOME/.gitconfig.local" user.email "you@example.invalid"
```

Git signing is enabled by default: configure your key locally, or set
`commit.gpgsign false` in that file. HTTPS credentials are saved indefinitely in
plaintext by Git's `store` helper (normally `~/.git-credentials`); protect that
file and never commit it.
Keep SSH keys/config in `~/.ssh`; setup never touches them.

Use `~/.path` for PATH additions, `~/.bash_aliases_private` for private aliases,
`~/.extra` for final shell overrides, and `~/.pythonrc` for Python startup code.
These files are not overwritten and are gitignored, along with common credential
files and backups. Ignore rules are not a guarantee: review `git diff --cached`
before publishing, and never force-add private files.

Based on [Mathias Bynens's dotfiles](https://github.com/mathiasbynens/dotfiles).
See `LICENSE-MIT.txt`.
