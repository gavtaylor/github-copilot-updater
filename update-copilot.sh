#!/usr/bin/env bash

update-copilot() {
    set -o pipefail
    local current latest release_url rpm_file tmpfile
    rpm_file=$(mktemp --suffix=.rpm)

    current=$(rpm -q --qf '%{VERSION}\n' github 2>/dev/null || true)
    latest=$(
        curl -fsSL "https://api.github.com/repos/github/app/releases/latest" |
        (command -v jq >/dev/null 2>&1 && jq -r .tag_name || grep '"tag_name"' | cut -d '"' -f 4) |
        sed 's/^v//'
    )

    if [[ -z "$latest" || "$latest" == "null" ]]; then
        echo "✗ Unable to determine latest GitHub Copilot version."
        rm -f "$rpm_file"
        return 1
    fi

    release_url="https://github.com/github/app/releases/tag/v${latest}"

    if [[ "$current" == "$latest" ]]; then
        echo "✓ GitHub Copilot is already up to date (${current})"
        echo "Release notes: ${release_url}"
        rm -f "$rpm_file"
        return 0
    fi

    echo "Updating GitHub Copilot: ${current:-not installed} → ${latest}"

    if ! curl -fsSL \
        "https://github.com/github/app/releases/latest/download/GitHub-Copilot-linux-x64.rpm" \
        -o "$rpm_file"; then
        echo "✗ Download failed."
        rm -f "$rpm_file"
        return 1
    fi

    if ! sudo dnf install -y "$rpm_file"; then
        echo "✗ Installation failed."
        rm -f "$rpm_file"
        return 1
    fi

    rm -f "$rpm_file"
    echo "✓ Updated to ${latest}"
    echo "Release notes: ${release_url}"
}
