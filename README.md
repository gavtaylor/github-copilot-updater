# github-copilot-updater

A small standalone script that checks for and installs the latest
[GitHub Copilot desktop app](https://github.com/github/app) release on Linux.

## Why this exists

GitHub/Microsoft do not currently ship an auto-update mechanism for the Linux
build of the Copilot app (rpm or deb). This script fills that gap: it checks
the latest GitHub release, compares it to what's installed, and installs the
update if one is available.

## Requirements

- `curl`
- One of:
  - `dnf` or `yum` + `rpm` (Fedora, RHEL, openSUSE, etc.)
  - `apt-get` + `dpkg` (Debian, Ubuntu, etc.)
- `jq` (optional, recommended, the script falls back to `grep`/`cut` if not installed)
- `sudo` access to install packages

## Installation

Clone this repo, or download the script directly:

```bash
curl -fsSL https://raw.githubusercontent.com/gavtaylor/github-copilot-updater/main/update-copilot.sh -o ~/.local/bin/update-copilot
chmod +x ~/.local/bin/update-copilot
```

Make sure `~/.local/bin` is on your `PATH`. Then run it whenever you want to check for updates:

```bash
update-copilot
```

### Using it as a shell function instead

If you'd rather source it as a bash function (e.g. from your `.bashrc` or a
`bashrc.d/` snippet), download the script somewhere permanent and source it:

```bash
curl -fsSL https://raw.githubusercontent.com/gavtaylor/github-copilot-updater/main/update-copilot.sh -o ~/.bashrc.d/update-copilot.sh
```

```bash
# in .bashrc
for f in ~/.bashrc.d/*.sh; do source "$f"; done
```

The script detects whether it's being run directly or sourced, and only
auto-executes when run directly, so sourcing it just makes the
`update-copilot` function available in your shell without running it.

## What it does

1. Reads the currently installed version (`rpm -q` or `dpkg-query`).
2. Fetches the latest release tag from the GitHub API.
3. If already up to date, exits with no changes.
4. If an update is available, prompts for `sudo` up front (before the ~300-400MB
   download, not after), downloads the correct package for your package
   manager, and installs it.
5. Verifies the installed version actually matches the expected version after
   install, this catches package managers reporting a false "success" on a
   no-op transaction.
6. Warns (without blocking) if the GitHub Copilot process is still running,
   since closing the window only minimises it to the tray on most desktop
   environments. It needs to be fully quit and relaunched to pick up the new
   version.

## Known limitations

- **No checksum/signature verification.** GitHub does not currently publish a
  `SHA256SUMS` file or a signature for the `.rpm`/`.deb` release assets (only
  the macOS `.tar.gz` and Linux `.AppImage` builds have Tauri updater
  signatures). The script downloads over HTTPS from `github.com` directly but
  cannot cryptographically verify the package contents beyond that. If GitHub
  starts publishing checksums for these assets, this script should be updated
  to verify against them.
- Only supports `x64` builds. Open an issue/PR if you need `arm64` support.

## Contributing

This is intentionally kept small and dependency-light. PRs welcome for genuine
bug fixes or missing distro support, please avoid scope creep into a general
Copilot CLI/config manager, that's a different project.

## License

MIT, see [LICENSE](LICENSE).
