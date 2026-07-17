# 可选工作 Git 身份实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法进行跟踪。

**目标：** 让 Chezmoi 首次初始化可选配置工作 Git 身份，并只在启用时生成 `~/Work/` 的条件 Git 配置。

**架构：** `.chezmoi.toml.tmpl` 负责交互并把 `workGitEnabled`、`workGitName`、`workGitEmail` 持久化到本机 Chezmoi 数据。Git 主配置模板根据 `workGitEnabled` 输出 `includeIf`，工作配置模板从本机数据渲染；未启用时两个模板均不产生工作配置内容。

**技术栈：** Chezmoi Go templates、POSIX/TOML 配置、Bash 测试、Git 配置解析。

---

## 文件结构

- 修改：`.chezmoi.toml.tmpl` — 增加工作身份的交互和本机数据字段。
- 修改：`dot_config/git/config.tmpl` — 条件输出 `includeIf`。
- 修改：`dot_config/git/config-work.tmpl` — 改为基于本机数据的条件模板。
- 创建：`tests/work-git-config.sh` — 在启用和禁用两种数据下渲染并验证 Git 身份。
- 不修改：现有 `tests/git-public-identity.sh`、`tests/git-work-identity.sh` 的测试目标；必要时只扩展其 Chezmoi 数据输入以保持测试环境明确。

### 任务 1：固定启用和禁用行为的失败测试

**文件：**
- 创建：`tests/work-git-config.sh`

- [x] **步骤 1：编写失败测试**

测试创建两个隔离 source/home：

```bash
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
[data]
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
        [[ "$(git -C "$home/Work/project" config user.name)" == work-user ]]
        [[ "$(git -C "$home/Work/project" config user.email)" == work-user@company.invalid ]]
    else
        [[ ! -f "$home/.config/git/config-work" ]]
        ! rg -F '[includeIf "gitdir:~/Work/"]' "$home/.config/git/config"
    fi
    printf '%s case passed\n' "$case_name"
}

render_case true enabled
render_case false disabled
```

- [x] **步骤 2：运行测试验证失败**

运行：`bash tests/work-git-config.sh`

预期：FAIL，原因是当前 `config-work.tmpl` 写死工作身份，主配置无条件输出 `includeIf`，且 `.chezmoi.toml.tmpl` 尚未提供工作身份数据。

### 任务 2：实现 Git 模板条件渲染

**文件：**
- 修改：`dot_config/git/config.tmpl`
- 修改：`dot_config/git/config-work.tmpl`

- [x] **步骤 1：修改主配置模板**

在公共配置的用户段之后加入以下模板块：

```gotemplate
{{- if and (hasKey . "workGitEnabled") .workGitEnabled }}
[includeIf "gitdir:~/Work/"]
	path = ~/.config/git/config-work
{{- end }}
```

当 `workGitEnabled` 缺失时按禁用处理，以兼容只渲染 Git 模板的现有测试。

- [x] **步骤 2：替换工作配置模板**

将 `dot_config/git/config-work.tmpl` 替换为：

```gotemplate
{{- if and (hasKey . "workGitEnabled") .workGitEnabled }}
[user]
	name = {{ .workGitName }}
	email = {{ .workGitEmail }}
{{- end }}
```

- [x] **步骤 3：运行最小测试验证通过**

运行：`bash tests/work-git-config.sh`

预期：输出 `enabled case passed` 和 `disabled case passed`。

### 任务 3：实现 Chezmoi 初始化数据交互

**文件：**
- 修改：`.chezmoi.toml.tmpl`

- [x] **步骤 1：加入 `workGitEnabled` 解析**

在模板的 `[data]` 输出前增加以下逻辑：

```gotemplate
{{- $workGitEnabled := false -}}
{{- if hasKey . "workGitEnabled" -}}
{{-   $workGitEnabled = .workGitEnabled -}}
{{- else if stdinIsATTY -}}
{{-   $workGitEnabled = promptBoolOnce . "workGitEnabled" "Configure work Git identity" -}}
{{- else -}}
{{-   fail "workGitEnabled is unset and there is no TTY to prompt. Run init interactively or pre-populate Chezmoi data." -}}
{{- end -}}
```

- [x] **步骤 2：仅在启用时询问姓名和邮箱**

紧接着加入：

```gotemplate
{{- $workGitName := "" -}}
{{- $workGitEmail := "" -}}
{{- if $workGitEnabled -}}
{{-   if hasKey . "workGitName" -}}
{{-     $workGitName = .workGitName -}}
{{-   else if stdinIsATTY -}}
{{-     $workGitName = promptStringOnce . "workGitName" "Work Git name" -}}
{{-   else -}}
{{-     fail "workGitName is unset and there is no TTY to prompt. Run init interactively or pre-populate Chezmoi data." -}}
{{-   end -}}
{{-   if hasKey . "workGitEmail" -}}
{{-     $workGitEmail = .workGitEmail -}}
{{-   else if stdinIsATTY -}}
{{-     $workGitEmail = promptStringOnce . "workGitEmail" "Work Git email" -}}
{{-   else -}}
{{-     fail "workGitEmail is unset and there is no TTY to prompt. Run init interactively or pre-populate Chezmoi data." -}}
{{-   end -}}
{{- end -}}
```

- [x] **步骤 3：把三个值写入 `[data]`**

在 `[data]` 区域增加：

```toml
workGitEnabled = {{ $workGitEnabled }}
workGitName = {{ $workGitName | quote }}
workGitEmail = {{ $workGitEmail | quote }}
```

- [x] **步骤 4：用隔离 source 验证配置模板失败路径**

运行：`chezmoi execute-template --source="$(pwd)" < .chezmoi.toml.tmpl >/tmp/work-git-chezmoi.toml`

预期：在没有 TTY 且没有预置数据时明确失败，并包含 `workGitEnabled is unset`；不应出现 Go template 解析错误。

### 任务 4：补充边界测试并回归

**文件：**
- 修改：`tests/work-git-config.sh`
- 视需要修改：`tests/git-public-identity.sh`、`tests/git-work-identity.sh`

- [x] **步骤 1：增加源码泄露检查**

在工作配置测试末尾加入：

```bash
! rg -n 'zhangkunming|zhangkunming@qdlimap\.com' \
    "$repo_root/dot_config" "$repo_root/.chezmoi.toml.tmpl"
```

- [x] **步骤 2：验证已有测试**

运行：

```bash
for test_file in tests/*.sh; do bash "$test_file"; done
```

预期：所有测试通过，包括公共身份、工作身份、初始化仓库归属和新增的启用/禁用测试。

- [x] **步骤 3：静态检查和差异检查**

运行：

```bash
sh -n init.sh
bash -n tests/*.sh
git diff --check
```

预期：全部退出码为 0，无语法错误和空白错误。

- [x] **步骤 4：检查未授权范围**

运行：`git diff --stat` 和 `git status --short`

确认只包含本计划涉及的模板、测试和文档变更，不修改 `references/` 子模块或初始化脚本行为。
