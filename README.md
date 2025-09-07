# 模块化 macOS 开发环境安装脚本

一个模块化、可定制的 macOS 开发环境自动安装系统。每个组件都是独立的安装脚本，可以单独运行或组合安装。

## 🚀 新的模块化架构

## 📋 可用组件

| 组件         | 脚本                     | 描述                             |
| ------------ | ------------------------ | -------------------------------- |
| **homebrew** | `installers/homebrew.sh` | Homebrew 包管理器 + 中国镜像     |
| **git**      | `installers/git.sh`      | 最新版 Git + 性能优化配置        |
| **iterm2**   | `installers/iterm2.sh`   | iTerm2 + Oh My Zsh + bureau 主题 |
| **go**       | `installers/go.sh`       | Go 编程语言 + 中国代理           |
| **python**   | `installers/python.sh`   | Python 3 + pip 中国镜像          |
| **java**     | `installers/java.sh`     | OpenJDK + 环境配置               |
| **rust**     | `installers/rust.sh`     | Rust + Cargo 中国镜像            |
| **nodejs**   | `installers/nodejs.sh`   | Node.js + npm 中国镜像           |
| **vscode**   | `installers/vscode.sh`   | Visual Studio Code               |
| **singbox**  | `installers/singbox.sh`  | sing-box 代理工具                |

## 🛠 使用方式

### 1. 完整安装（推荐）

```bash
# 安装所有组件
git clone https://github.com/sixban6/init_mac.git
cd init_mac
chmod +x setup_mac.sh
./setup_mac.sh --all
```

### 2. 交互式选择安装

```bash
# 进入选择模式，可以勾选想要的组件
./setup_mac.sh --selective
```

### 3. 指定组件安装

```bash
# 只安装基础开发环境
./setup_mac.sh homebrew git iterm2

# 只安装编程语言
./setup_mac.sh go python nodejs rust
```

### 4. 单独安装组件

```bash
# 单独运行某个安装脚本
./installers/homebrew.sh
./installers/git.sh
./installers/python.sh
```

## 📖 命令参数

```bash
Usage: ./setup_mac.sh [OPTIONS] [COMPONENTS]

OPTIONS:
    -h, --help      显示帮助信息
    -l, --list      列出所有可用组件
    -a, --all       安装所有组件（默认）
    -s, --selective 交互式选择安装

COMPONENTS:
    指定要安装的组件名称
```

## ✅ 特性优势

### 🧩 模块化设计

- 每个工具都是独立的安装脚本
- 可以单独运行任何组件
- 便于定制和维护
- 方便调试和故障排除

### 🇨🇳 中国网络优化

- 所有工具都配置了中国镜像源
- Homebrew、pip、npm、Go、Rust 等都使用国内镜像
- 提供最佳的下载速度

### 👨‍💻 专业配置

- iTerm2 + Oh My Zsh + **bureau 主题**（程序员友好）
- Git 性能优化设置
- 环境变量自动配置
- 开发工具别名和快捷键
- **无字体依赖问题** - bureau 主题完美显示

## 安装内容

### iTerm2

- 从官方源下载
- 配置开发友好的设置
- 设置为默认终端应用

### Homebrew

- 使用中国镜像源安装，下载更快
- 配置清华大学镜像源
- 在 shell 配置文件中设置环境变量

### Git

- 通过 Homebrew 安装最新版本
- 强制升级，即使系统已有 Git
- 配置 PATH 优先使用 Homebrew 版本
- 自动优化中国网络环境下的性能设置

### Go 编程语言

- 通过 Homebrew 安装最新稳定版
- 在 `$HOME/go` 配置 GOPATH
- 创建工作空间目录（`src`, `bin`, `pkg`）
- 添加环境变量到 shell 配置文件
- 自动配置中国模块代理（goproxy.cn）

### Python

- 通过 Homebrew 安装最新 Python 3
- 升级并配置 pip
- 安装基础包：`setuptools`, `wheel`
- 配置 Python 别名（python→python3, pip→pip3）
- 自动配置清华大学 pip 镜像源

### Java (Zulu JDK)

- 通过 Homebrew 安装 Azul Zulu JDK
- 自动配置 JAVA_HOME 环境变量
- 添加 Java 工具到 PATH

### Rust

- 通过 Homebrew 安装最新 Rust 工具链
- 配置 CARGO_HOME 环境变量
- 设置 Cargo 工具 PATH
- 自动配置清华大学 Cargo 镜像源

### Node.js

- 通过 Homebrew 安装最新 LTS 版本
- 配置 npm 全局包目录避免权限问题
- 设置 npm 全局包 PATH
- 自动配置 npmmirror 镜像源

### sing-box

- 安装最新版代理工具
- 创建基础配置文件
- 设置配置目录结构

### Visual Studio Code

- 通过 Homebrew Cask 安装
- 配置命令行工具（`code`）
- 更新 PATH 以支持 CLI 访问

## 系统要求

- macOS (Darwin)
- 网络连接
- 部分安装需要管理员权限

## 安全特性

- **幂等性**: 可安全多次运行
- **版本检查**: 仅在有新版本时更新
- **备份友好**: 不会覆盖现有配置
- **错误处理**: 全面的错误检查和日志记录
- **非破坏性测试**: 测试脚本仅使用临时文件

## 日志文件

所有操作都会记录到：

- `setup.log` - 安装日志
- `test_results.log` - 测试结果日志

## 架构设计

- `install_iterm2()` - iTerm2 安装和配置
- `install_homebrew()` - Homebrew 中国镜像源配置
- `install_git()` - Git 最新版本安装
- `install_go()` - Go 语言环境设置
- `install_python()` - Python 环境配置
- `install_java()` - Java JDK 安装和配置
- `install_rust()` - Rust 工具链安装
- `install_nodejs()` - Node.js 和 npm 配置
- `install_singbox()` - sing-box 代理工具安装
- `install_vscode()` - VS Code 安装

## 中国镜像源配置

脚本自动配置多个工具使用中国镜像源以提高下载速度：

### Homebrew

- **Brew**: `https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git`
- **Core**: `https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git`
- **Bottles**: `https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles`

### Git

- 配置性能优化设置，提升在中国网络环境下的性能
- 增加缓冲区大小和预载索引

### Go 语言

- **模块代理**: `https://goproxy.cn,direct`
- **校验数据库**: `sum.golang.google.cn`

### Python pip

- **镜像源**: `https://pypi.tuna.tsinghua.edu.cn/simple`
- 自动配置 `~/.pip/pip.conf`

### Rust Cargo

- **镜像源**: `https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git`
- 自动配置 `~/.cargo/config`

### Node.js npm

- **镜像源**: `https://registry.npmmirror.com`
- 配置常用二进制文件镜像（sass, electron, puppeteer 等）

## Vscode 配置

⏺ 我为 VSCode 配置了世界级公司的最佳实践，具体包括：
🔧 核心编辑器配置

- 字体: SF Mono 系列（macOS 系统字体）
- 缩进: 自动检测项目偏好，默认 2 空格
- 代码格式化: 保存时自动格式化，粘贴时格式化
- 代码行长度: 80/100/120 字符提示线（Google 标准）
- 自动保存: 切换文件时自动保存
- 去除尾随空格: 自动清理多余空格

📦 核心扩展（5 个）

1. Go 扩展 (golang.go) - Google 官方推荐
2. Python 扩展 (ms-python.python) - 微软官方
3. Java 扩展 (redhat.java) - Red Hat 官方
4. Prettier (esbenp.prettier-vscode) - 代码格式化
5. GitLens (eamodio.gitlens) - Git 增强工具

🌍 各语言最佳实践配置

Go 语言（Google 标准）

- 使用 goimports 格式化工具
- Tab 缩进（Go 官方要求）
- 保存时自动导入整理
- 启用语言服务器

Python 语言（PEP 8 + Black）

- Black 格式化器（Instagram、Pinterest 使用的标准）
- 4 空格缩进（PEP 8 标准）
- Flake8 代码检查，88 字符行长度
- 自动导入整理

Java 语言（Google Java 样式）

- 2 空格缩进（Google Java 样式指南）
- 自动构建和导入管理
- Maven/Gradle 项目支持

JavaScript/TypeScript（Google/Airbnb 标准）

- 2 空格缩进
- 双引号（Google 标准）
- 分号强制使用
- 80 字符行长度

📁 项目模板

创建了即用型项目模板：

- Go 项目: ~/Developer/.vscode-templates/go-project/
- Python 项目: ~/Developer/.vscode-templates/python-project/
- Java 项目: ~/Developer/.vscode-templates/java-project/

所有模板都经过编译测试，可以直接运行。

🎨 界面优化

- 深色主题（Default Dark+）
- 禁用预览模式（文件总是在新标签页打开）
- 显示面包屑导航
- 优化文件树缩进
- 终端字体配置

🔒 隐私和性能

- 关闭遥测 - 不向微软发送使用数据
- 性能优化 - 排除 build、node_modules 等目录
- 安全配置 - 禁用工作区信任模式
- 自动更新扩展 - 保持工具最新

✅ 验证测试

- VS Code 安装检查 ✓
- 命令行工具可用 ✓
- 设置文件语法正确 ✓
- 所有 5 个扩展安装成功 ✓
- 项目模板编译通过 ✓
- 语言服务器配置正确 ✓

这套配置让用户打开 VS
Code 就能立即开始编写 Go、Python、Java 程序，所有格式化、语法检查、智能提示都按照业界最高标准自动工作。

## 安装后操作

成功安装后：

1. 重启终端或运行：
   ```bash
   source ~/.zshrc  # 或您的 shell 配置文件
   ```

## 故障排除

### 常见问题

1. **Xcode 命令行工具**: 如有提示请安装
2. **权限错误**: 确保具有管理员权限
3. **网络问题**: 检查下载时的网络连接
4. **Shell 配置**: 安装后重启终端

## 许可证

MIT 许可证 - 自由使用和修改。
