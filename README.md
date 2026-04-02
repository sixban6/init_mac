# 模块化 macOS 开发环境安装脚本

一个模块化、可定制的 macOS 开发环境自动安装系统。每个组件都是独立安装脚本，可单独运行或组合安装。

## 可用组件

| 组件 | 脚本 | 描述 |
| --- | --- | --- |
| `homebrew` | `installers/homebrew.sh` | 安装 Homebrew，并自动测速选择可用镜像源 |
| `git` | `installers/git.sh` | 安装/升级 Git 并做基础性能优化 |
| `wezterm` | `installers/wezterm.sh` | 安装 WezTerm 并写入开发者友好配置 |
| `pearcleaner` | `installers/pearcleaner.sh` | 安装 Pearcleaner（支持卸载） |
| `sec` | `installers/sec.sh` | 安装安全工具：Lulu + BlockBlock |
| `brave-browser` | `installers/brave-browser.sh` | 安装 Brave 浏览器 |
| `obsidian` | `installers/obsidian.sh` | 安装 Obsidian 笔记软件 |
| `tailscale` | `installers/tailscale.sh` | 安装 Tailscale |
| `telegram` | `installers/telegram.sh` | 安装 Telegram |
| `iina` | `installers/iina.sh` | 安装 IINA 播放器 |
| `go` | `installers/go.sh` | 安装 Go 并配置开发环境 |
| `python` | `installers/python.sh` | 安装 Python 并配置 pip 镜像 |
| `java` | `installers/java.sh` | 安装 OpenJDK 并配置环境变量 |
| `rust` | `installers/rust.sh` | 安装 Rust 并配置 Cargo 镜像 |
| `nodejs` | `installers/nodejs.sh` | 安装 Node.js 并配置 npm 镜像 |
| `vscode` | `installers/vscode.sh` | 安装 VS Code 与常用开发配置 |
| `singbox` | `installers/singbox.sh` | 安装 sing-box |

## 使用方式

### 1. 完整安装（默认）

```bash
git clone https://github.com/sixban6/init_mac.git
cd init_mac
chmod +x setup_mac.sh
./setup_mac.sh --all
```

### 2. 交互式选择安装

```bash
./setup_mac.sh --selective
```

### 3. 指定组件安装

```bash
# 基础开发环境
./setup_mac.sh homebrew git wezterm

# 常用应用
./setup_mac.sh brave-browser obsidian tailscale telegram iina

# 工程语言环境
./setup_mac.sh go python java rust nodejs

# 安全与清理工具
./setup_mac.sh sec pearcleaner
```

### 4. 单独运行组件脚本

```bash
./installers/homebrew.sh
./installers/wezterm.sh
./installers/sec.sh
./installers/pearcleaner.sh
```

## pearcleaner 卸载用法

`pearcleaner` 模块支持安装和卸载：

```bash
# 安装
./installers/pearcleaner.sh --install

# 卸载
./installers/pearcleaner.sh --uninstall
```

## 关键模块说明

### Homebrew 模块

- 自动安装 Homebrew（若未安装）
- 自动安装并执行 `switch_brew.sh`
- 将 `switch_brew.sh` 写入 `/usr/local/bin/switch_brew.sh`
- 根据测速结果设置 Homebrew 相关环境变量

### WezTerm 模块

- 使用 `brew install --cask wezterm` 安装
- 自动创建配置目录：`~/.config/wezterm`
- 自动写入配置文件：`~/.config/wezterm/wezterm.lua`
- WezTerm 配置文件保存后会自动热重载，无需重启

### sec 模块

- 使用 Homebrew Cask 安装：
  - `lulu`
  - `blockblock`

## 命令参数

```bash
Usage: ./setup_mac.sh [OPTIONS] [COMPONENTS]

OPTIONS:
  -h, --help      显示帮助
  -l, --list      列出可用组件
  -a, --all       安装所有组件（默认）
  -s, --selective 交互式选择安装
```

## 系统要求

- macOS（Darwin）
- 网络连接
- 部分安装步骤可能需要管理员权限

## 相关脚本

- 主安装入口：`setup_mac.sh`
- 卸载脚本：`uninstall_mac.sh`
- 安装器目录：`installers/`
