#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
tmp_source="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-source-test.XXXXXX")"
tmp_home="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-home-test.XXXXXX")"
global_config="$tmp_home/.config/git/config"
repo="$tmp_home/project"

mkdir -p "$tmp_source/dot_config/git" "$repo"
cp "$repo_root/dot_config/git/config.tmpl" "$tmp_source/dot_config/git/config.tmpl"

chezmoi \
    --source "$tmp_source" \
    --destination "$tmp_home" \
    --config /dev/null \
    --config-format toml \
    --persistent-state "$tmp_home/chezmoistate.boltdb" \
    --cache "$tmp_home/cache" \
    apply

git -C "$repo" init -q

actual_name="$(env -u GIT_CONFIG_GLOBAL -u XDG_CONFIG_HOME HOME="$tmp_home" GIT_CONFIG_NOSYSTEM=1 git -C "$repo" config user.name)"
actual_email="$(env -u GIT_CONFIG_GLOBAL -u XDG_CONFIG_HOME HOME="$tmp_home" GIT_CONFIG_NOSYSTEM=1 git -C "$repo" config user.email)"

[[ "$actual_name" == "okylean" ]] || {
    printf 'unexpected user.name: %s\n' "$actual_name" >&2
    exit 1
}
[[ "$actual_email" == "okylean@gmail.com" ]] || {
    printf 'unexpected user.email: %s\n' "$actual_email" >&2
    exit 1
}

printf 'public Git identity: %s <%s>\n' "$actual_name" "$actual_email"
printf 'rendered Git config: %s\n' "$global_config"
