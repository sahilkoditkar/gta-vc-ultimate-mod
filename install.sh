#!/usr/bin/env bash
# Linux (Bottles / Wine / Proton): runs the same installer with PowerShell 7.
cd "$(dirname "$0")"
if ! command -v pwsh >/dev/null 2>&1; then
  echo "PowerShell 7 is needed. Install it with one of:"
  echo "  sudo snap install powershell --classic"
  echo "  or: https://learn.microsoft.com/powershell/scripting/install/install-ubuntu"
  echo "For .rar car archives also:  sudo apt install p7zip-full p7zip-rar"
  exit 1
fi
exec pwsh -NoProfile -File ./install.ps1 "$@"
