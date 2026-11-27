#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
dependencies="$repo_root/Dependencies"
downloads="$(mktemp -d)"
trap 'rm -rf "$downloads"' EXIT

python_archive="$downloads/Python-3.14-iOS-support.b14.tar.gz"
ytdlp_wheel="$downloads/yt_dlp.whl"

curl --fail --location --silent --show-error --retry 2 \
    https://github.com/beeware/Python-Apple-support/releases/download/3.14-b14/Python-3.14-iOS-support.b14.tar.gz \
    --output "$python_archive"
curl --fail --location --silent --show-error --retry 2 \
    https://files.pythonhosted.org/packages/30/1e/f4bf64ca733135e609696c6df77a6c22c6d4909b6e293e4563ae51ea335c/yt_dlp-2026.11.23-py3-none-any.whl \
    --output "$ytdlp_wheel"

printf '%s  %s\n' 703ff822529f46edcbcd8b88096b2544f6990f3109ad38b4b4b61bb489a7c1ee "$python_archive" | shasum -a 256 --check
printf '%s  %s\n' e9188e0c559905f7ee05acc1ba0b6fb3f310e7565bf6dea5f62b5300e0775e35 "$ytdlp_wheel" | shasum -a 256 --check

mkdir -p "$dependencies"
tar -xzf "$python_archive" -C "$dependencies"
cp "$ytdlp_wheel" "$dependencies/yt_dlp.whl"
