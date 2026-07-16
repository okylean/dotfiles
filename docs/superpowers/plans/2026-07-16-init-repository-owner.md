# 初始化脚本仓库归属替换实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 将 `init.sh` 的默认仓库归属、帮助示例和下载示例从 `signalridge` 替换为 `okylean`。

**架构：** 保留现有参数解析、仓库地址归一化和 Chezmoi 执行流程，只修改脚本中的上游所有者常量。新增独立 Shell 测试，通过帮助输出和伪造的 `chezmoi` 命令验证默认仓库，避免真实网络访问。

**技术栈：** POSIX shell、Bash 测试脚本、ripgrep、Chezmoi 命令行约定

---

## 文件结构

- 创建：`tests/init-repository-owner.sh`，只验证初始化脚本的默认仓库所有者和帮助文本。
- 修改：`init.sh`，替换属于上游项目的 `signalridge` 仓库归属字符串。

### 任务 1：用测试固定默认仓库归属

**文件：**
- 创建：`tests/init-repository-owner.sh`
- 测试：`tests/init-repository-owner.sh`

- [ ] **步骤 1：编写失败的测试**

```bash
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
```

- [ ] **步骤 2：运行测试验证失败**

运行：`tests/init-repository-owner.sh`

预期：FAIL，因为帮助输出当前包含 `default: signalridge`，找不到 `default: okylean`。

- [ ] **步骤 3：提交测试红灯状态之外的最少实现**

此步骤不修改生产脚本；确认失败原因准确后直接进入任务 2。

### 任务 2：替换默认仓库所有者

**文件：**
- 修改：`init.sh:16-17`
- 修改：`init.sh:36`
- 修改：`init.sh:45`
- 测试：`tests/init-repository-owner.sh`

- [ ] **步骤 1：编写最少实现代码**

将以下帮助文本：

```text
default: signalridge
signalridge, signalridge/dotfiles, https://github.com/signalridge/dotfiles.git
https://raw.githubusercontent.com/signalridge/dotfiles/<tag-or-branch>/init.sh
```

替换为：

```text
default: okylean
okylean, okylean/dotfiles, https://github.com/okylean/dotfiles.git
https://raw.githubusercontent.com/okylean/dotfiles/<tag-or-branch>/init.sh
```

并将默认变量改为：

```sh
repo="${DOTFILES_REPO:-okylean}"
```

- [ ] **步骤 2：运行测试验证通过**

运行：`tests/init-repository-owner.sh`

预期：PASS，并输出 `init repository owner tests passed`。

- [ ] **步骤 3：执行静态验证**

运行：`sh -n init.sh && bash -n tests/init-repository-owner.sh`

预期：退出码为 0，无输出。

运行：`if rg -n 'signalridge' init.sh; then exit 1; fi`

预期：退出码为 0，无输出。

- [ ] **步骤 4：检查差异**

运行：`git diff --check -- init.sh tests/init-repository-owner.sh`

预期：退出码为 0，无空白错误。

- [ ] **步骤 5：Commit**

```bash
git add init.sh tests/init-repository-owner.sh docs/superpowers/plans/2026-07-16-init-repository-owner.md
git commit -m "fix: 更新初始化脚本默认仓库"
```
