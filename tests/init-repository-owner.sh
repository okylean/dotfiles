#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
fake_bin="$tmp_dir/bin"
log_file="$tmp_dir/commands.log"
downloaded_init="$tmp_dir/init.sh"
mkdir -p "$fake_bin"

help_output="$("$repo_root/init.sh" --help 2>&1)"
rg -F 'default: okylean' <<<"$help_output" >/dev/null
if rg -F 'signalridge' <<<"$help_output" >/dev/null; then
    printf 'help still references signalridge\n' >&2
    exit 1
fi

cat >"$fake_bin/chezmoi" <<'EOF'
#!/bin/sh
printf 'chezmoi %s\n' "$*" >>"$INIT_TEST_LOG"
EOF
chmod +x "$fake_bin/chezmoi"
cp "$repo_root/init.sh" "$downloaded_init"
chmod +x "$downloaded_init"
: >"$log_file"

HOME="$tmp_dir/home" PATH="$fake_bin:/usr/bin:/bin" INIT_TEST_LOG="$log_file" \
    "$downloaded_init"

rg -F 'chezmoi init --apply https://github.com/okylean/dotfiles.git' "$log_file" >/dev/null
printf 'init repository owner tests passed\n'
