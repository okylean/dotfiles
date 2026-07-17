# 可选工作 Git 身份设计

## 目标

在不把工作姓名和邮箱提交到公开 dotfiles 仓库的前提下，为 `~/Work/` 下的 Git 仓库配置独立身份。首次初始化时由用户选择是否启用工作身份；启用后，姓名和邮箱只保存在本机 Chezmoi 配置数据中。

## 范围

- 在 Chezmoi 首次初始化时询问是否配置工作 Git 身份。
- 启用后继续询问工作姓名和邮箱，并持久化到本机 `~/.config/chezmoi/chezmoi.toml`。
- 仅在启用工作身份时，为全局 Git 配置生成 `includeIf "gitdir:~/Work/"`。
- 仅在启用工作身份时生成 `~/.config/git/config-work`。
- 保持 `~/Work/` 之外的个人 Git 身份与现有通用 Git 行为不变。
- 不引入 age、keymanager、gopass 或独立密钥备份仓库。

## 数据模型

`.chezmoi.toml.tmpl` 生成以下本机数据：

```toml
[data]
workGitEnabled = true
workGitName = "work-user"
workGitEmail = "work-user@company.invalid"
```

- `workGitEnabled` 表示当前机器是否启用工作身份。
- `workGitName` 和 `workGitEmail` 仅在启用时询问和写入。
- 这些值存在目标机器的 Chezmoi 配置中，不以明文出现在 source state 或 Git 历史中。

## 初始化行为

配置模板按以下顺序解析：

1. 如果 Chezmoi 数据中已有 `workGitEnabled`，复用已有值。
2. 如果缺少该值且标准输入是 TTY，询问是否配置工作 Git 身份。
3. 如果缺少该值且没有 TTY，明确失败并提示用户交互执行初始化或预先提供数据。
4. 启用工作身份后，对 `workGitName` 和 `workGitEmail` 采用相同的“已有值、交互询问、非交互失败”策略。
5. 未启用时，不询问姓名和邮箱，并将其保持为空字符串。

该设计避免非交互初始化把提示文本、空身份或错误默认值写入配置。

## Git 配置渲染

`dot_config/git/config.tmpl` 保留现有个人身份和通用设置。只有 `workGitEnabled` 为 `true` 时才追加：

```ini
[includeIf "gitdir:~/Work/"]
    path = ~/.config/git/config-work
```

`dot_config/git/config-work.tmpl` 不包含固定身份，只在启用时渲染：

```ini
[user]
    name = {{ .workGitName }}
    email = {{ .workGitEmail }}
```

未启用时模板输出为空。Chezmoi 将不创建该目标文件；如果用户从启用切换为禁用，则应用空模板时移除之前由 Chezmoi 管理的 `config-work`。

为兼容使用 `/dev/null` 配置运行的现有公共身份测试，Git 主模板在 `workGitEnabled` 缺失时按未启用处理。首次真实初始化的严格交互校验仍由 `.chezmoi.toml.tmpl` 负责。

## 安全边界

- 工作姓名和邮箱不会保存在公开仓库的受版本控制文件中。
- 它们会以明文存在于本机 `~/.config/chezmoi/chezmoi.toml` 和渲染后的 `~/.config/git/config-work` 中。
- 本设计防止仓库公开泄露，不提供本机静态加密。
- `includeIf` 路径和是否支持工作身份不视为敏感信息，但禁用时仍不输出无效引用。

## 测试与验收

自动化测试覆盖以下行为：

1. 启用工作身份时，渲染后的主配置包含 `includeIf`，并生成工作配置。
2. `~/Work/` 仓库解析为工作姓名和邮箱。
3. `~/Work/` 之外的仓库继续解析为个人姓名和邮箱。
4. 禁用或缺少工作身份数据时，主配置不包含 `includeIf`，工作配置不存在。
5. 源文件中不出现当前工作姓名和邮箱明文。
6. 所有现有初始化和公共 Git 身份测试继续通过。

## 非目标

- 不管理 SSH、GPG 或 age 私钥。
- 不实现 Signal 项目的 keys-manage 备份与恢复链路。
- 不为多个工作目录或多个公司身份提供动态映射。
- 不改变当前个人 Git 身份、默认分支、拉取、推送或差异配置。
