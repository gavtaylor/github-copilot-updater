#!/usr/bin/env bash

function update-copilot {
  wget https://github.com/github/app/releases/latest/download/GitHub-Copilot-linux-x64.rpm -O /tmp/GitHub-Copilot-linux-x64.rpm
  sudo dnf install /tmp/GitHub-Copilot-linux-x64.rpm
}
