#!/usr/bin/env bash
#
# update-copilot.sh
#
# Checks for and installs the latest GitHub Copilot desktop app release on
# Linux (rpm or deb), since GitHub/Microsoft do not currently ship an
# auto-update mechanism for the Linux build.
#
# Usage:
#   ./update-copilot.sh
#
# Requirements: curl, and either dnf/yum (rpm) or apt/dpkg (deb).
# jq is optional but recommended (falls back to grep/cut if absent).

set -o pipefail

REPO="github/app"
ASSET_BASENAME="GitHub-Copilot-linux"

update-copilot() {
    local current latest pkg_file gh_pid installed pkg_mgr pkg_name pkg_version_query asset_ext download_url

    if command -v rpm >/dev/null 2>&1 && (command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1); then
        pkg_mgr="rpm"
        asset_ext="rpm"
        pkg_name="github"
    elif command -v dpkg >/dev/null 2>&1 && command -v apt-get >/dev/null 2>&1; then
        pkg_mgr="deb"
        asset_ext="deb"
        pkg_name="github"
    else
        echo "✗ Unsupported system: no dnf/yum (rpm) or apt/dpkg (deb) found."
        return 1
    fi

    pkg_file=$(mktemp --suffix=".${asset_ext}")
    trap 'rm -f "$pkg_file"' RETURN

    if [[ "$pkg_mgr" == "rpm" ]]; then
        current=$(rpm -q --qf '%{VERSION}\n' "$pkg_name" 2>/dev/null || true)
    else
        current=$(dpkg-query -W -f='${Version}\n' "$pkg_name" 2>/dev/null | sed 's/-.*//' || true)
    fi

    latest=$(
        curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" |
        (command -v jq >/dev/null 2>&1 && jq -r .tag_name || grep '"tag_name"' | cut -d '"' -f 4) |
        sed 's/^v//'
    )

    if [[ -z "$latest" || "$latest" == "null" ]]; then
        echo "✗ Unable to determine latest GitHub Copilot version (GitHub API unreachable or rate-limited)."
        return 1
    fi

    if [[ "$current" == "$latest" ]]; then
        echo "✓ GitHub Copilot is already up to date (${current})"
        echo "Release notes: https://github.com/${REPO}/releases"
        return 0
    fi

    echo "Updating GitHub Copilot: ${current:-not installed} → ${latest}"

    # Prompt for sudo up front, before the (~300-400MB) download, not after.
    if ! sudo -v; then
        echo "✗ sudo authentication failed."
        return 1
    fi

    download_url="https://github.com/${REPO}/releases/download/v${latest}/${ASSET_BASENAME}-x64.${asset_ext}"

    if ! curl -fsSL "$download_url" -o "$pkg_file"; then
        echo "✗ Download failed: ${download_url}"
        return 1
    fi

    if [[ "$pkg_mgr" == "rpm" ]]; then
        if ! sudo dnf install -y "$pkg_file"; then
            echo "✗ Installation failed."
            return 1
        fi
        installed=$(rpm -q --qf '%{VERSION}\n' "$pkg_name" 2>/dev/null || true)
    else
        if ! sudo apt-get install -y "$pkg_file"; then
            echo "✗ Installation failed."
            return 1
        fi
        installed=$(dpkg-query -W -f='${Version}\n' "$pkg_name" 2>/dev/null | sed 's/-.*//' || true)
    fi

    if [[ "$installed" != "$latest" ]]; then
        echo "✗ Package manager reported success but installed version is ${installed:-none}, expected ${latest}."
        return 1
    fi

    echo "✓ Updated to ${latest}"
    echo "Release notes: https://github.com/${REPO}/releases"

    gh_pid=$(pgrep -x github 2>/dev/null || true)
    if [[ -n "$gh_pid" ]]; then
        echo "⚠ GitHub Copilot is still running (pid ${gh_pid})."
        echo "  Closing the window only minimises it to the tray, it will keep running ${current}."
        echo "  Fully quit it (tray icon → Quit) and relaunch to pick up ${latest}."
    fi
}

# Allow the script to be sourced (to reuse the function directly) or run
# standalone (to execute immediately).
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    update-copilot "$@"
fi
