#!/usr/bin/env bash

set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
tmp_source="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-work-source.XXXXXX")"
tmp_home="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-work-home.XXXXXX")"

mkdir -p "$tmp_source/dot_config/git" "$tmp_home/Work/project" "$tmp_home/Personal/project"
cp "$repo_root/dot_config/git/config.tmpl" "$tmp_source/dot_config/git/config.tmpl"
cp "$repo_root/dot_config/git/config-work.tmpl" "$tmp_source/dot_config/git/config-work.tmpl"
cat >"$tmp_source/.chezmoidata.toml" <<'EOF'
workGitEnabled = true
workGitName = "zhangkunming"
workGitEmail = "zhangkunming@qdlimap.com"
EOF

HOME="$tmp_home" chezmoi \
    --source "$tmp_source" \
    --destination "$tmp_home" \
    --config /dev/null \
    --config-format toml \
    --persistent-state "$tmp_home/chezmoistate.boltdb" \
    --cache "$tmp_home/cache" \
    apply

git -C "$tmp_home/Work/project" init -q
git -C "$tmp_home/Personal/project" init -q

work_name="$(env -u GIT_CONFIG_GLOBAL -u XDG_CONFIG_HOME HOME="$tmp_home" GIT_CONFIG_NOSYSTEM=1 git -C "$tmp_home/Work/project" config user.name)"
work_email="$(env -u GIT_CONFIG_GLOBAL -u XDG_CONFIG_HOME HOME="$tmp_home" GIT_CONFIG_NOSYSTEM=1 git -C "$tmp_home/Work/project" config user.email)"
personal_name="$(env -u GIT_CONFIG_GLOBAL -u XDG_CONFIG_HOME HOME="$tmp_home" GIT_CONFIG_NOSYSTEM=1 git -C "$tmp_home/Personal/project" config user.name)"
personal_email="$(env -u GIT_CONFIG_GLOBAL -u XDG_CONFIG_HOME HOME="$tmp_home" GIT_CONFIG_NOSYSTEM=1 git -C "$tmp_home/Personal/project" config user.email)"

[[ "$work_name" == "zhangkunming" ]] || { printf 'unexpected Work user.name: %s\n' "$work_name" >&2; exit 1; }
[[ "$work_email" == "zhangkunming@qdlimap.com" ]] || { printf 'unexpected Work user.email: %s\n' "$work_email" >&2; exit 1; }
[[ "$personal_name" == "okylean" ]] || { printf 'unexpected personal user.name: %s\n' "$personal_name" >&2; exit 1; }
[[ "$personal_email" == "okylean@gmail.com" ]] || { printf 'unexpected personal user.email: %s\n' "$personal_email" >&2; exit 1; }

printf 'Work Git identity tests passed\n'
