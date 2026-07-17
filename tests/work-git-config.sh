#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

render_case() {
    local enabled="$1" case_name="$2"
    local source home
    source="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-work-source.XXXXXX")"
    home="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-work-home.XXXXXX")"
    mkdir -p "$source/dot_config/git" "$home/Work/project" "$home/Personal/project"
    cp "$repo_root/dot_config/git/config.tmpl" "$source/dot_config/git/config.tmpl"
    cp "$repo_root/dot_config/git/config-work.tmpl" "$source/dot_config/git/config-work.tmpl"
    cat >"$source/.chezmoidata.toml" <<EOF
workGitEnabled = $enabled
workGitName = "work-user"
workGitEmail = "work-user@company.invalid"
EOF

    HOME="$home" chezmoi --source "$source" --destination "$home" \
        --config /dev/null --config-format toml \
        --persistent-state "$home/state.db" --cache "$home/cache" apply

    git -C "$home/Work/project" init -q
    git -C "$home/Personal/project" init -q
    if [[ "$enabled" == true ]]; then
        [[ -f "$home/.config/git/config-work" ]]
        rg -F '[includeIf "gitdir:~/Work/"]' "$home/.config/git/config"
        [[ "$(env -u GIT_CONFIG_GLOBAL -u XDG_CONFIG_HOME HOME="$home" GIT_CONFIG_NOSYSTEM=1 git -C "$home/Work/project" config user.name)" == work-user ]]
        [[ "$(env -u GIT_CONFIG_GLOBAL -u XDG_CONFIG_HOME HOME="$home" GIT_CONFIG_NOSYSTEM=1 git -C "$home/Work/project" config user.email)" == work-user@company.invalid ]]
    else
        [[ ! -f "$home/.config/git/config-work" ]]
        ! rg -F '[includeIf "gitdir:~/Work/"]' "$home/.config/git/config"
    fi
    printf '%s case passed\n' "$case_name"
}

render_case true enabled
render_case false disabled

invalid_source="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-work-invalid-source.XXXXXX")"
invalid_home="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-work-invalid-home.XXXXXX")"
mkdir -p "$invalid_source/dot_config/git"
cp "$repo_root/dot_config/git/config.tmpl" "$invalid_source/dot_config/git/config.tmpl"
cp "$repo_root/dot_config/git/config-work.tmpl" "$invalid_source/dot_config/git/config-work.tmpl"
cat >"$invalid_source/.chezmoidata.toml" <<'EOF'
workGitEnabled = true
workGitName = ""
workGitEmail = ""
EOF
if HOME="$invalid_home" chezmoi --source "$invalid_source" --destination "$invalid_home" \
    --config /dev/null --config-format toml \
    --persistent-state "$invalid_home/state.db" --cache "$invalid_home/cache" apply; then
    printf 'empty work identity was accepted\n' >&2
    exit 1
fi

! rg -n 'zhangkunming|zhangkunming@qdlimap\.com' \
    "$repo_root/dot_config" "$repo_root/.chezmoi.toml.tmpl"
