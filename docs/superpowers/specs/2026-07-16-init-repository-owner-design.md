# 初始化脚本仓库归属替换设计

## 目标

将 `init.sh` 中属于上游项目的默认仓库归属从 `signalridge` 改为当前仓库所有者 `okylean`，使脚本的默认行为、帮助示例和下载示例都指向 `okylean/dotfiles`。

## 范围

- 将 `init.sh` 帮助文本中的默认所有者、仓库示例和 Raw GitHub 下载地址改为 `okylean`。
- 将 `DOTFILES_REPO` 未设置时的默认值从 `signalridge` 改为 `okylean`。
- 保留用户通过 `--repo` 或 `DOTFILES_REPO` 指定其他仓库的能力。
- 不修改 `references/signalridge-dotfiles` 子模块、`.gitmodules` 或 README 的参考项目列表。
- 不调整 Chezmoi 安装目录、本地源码检测、克隆深度及其他初始化行为。

## 行为与验证

执行 `init.sh --help` 时，不应再出现指向 signalridge 仓库的默认值或示例。未提供 `--repo` 与 `DOTFILES_REPO` 时，远程初始化目标应归一化为 `https://github.com/okylean/dotfiles.git`。验证包括搜索脚本中的残留归属，以及运行相关初始化脚本测试。
