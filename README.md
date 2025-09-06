# macOS Development Environment Setup

一个全面的脚本，用于在 macOS 上自动设置完整的开发环境，支持中国镜像源。

## 功能特性

- **iTerm2**: 下载并配置 iTerm2 作为默认终端
- **Homebrew**: 安装 Homebrew 并配置中国镜像源（清华大学源）
- **Git**: 安装最新版本，强制升级到 Homebrew 版本
- **Go**: 安装最新版本并完成工作空间配置
- **Python**: 安装最新 Python 3 及基础包
- **Java**: 安装 Zulu JDK 最新版本并配置环境
- **Rust**: 安装最新版本并配置 Cargo 环境
- **Node.js**: 安装最新版本并配置 npm 环境
- **sing-box**: 安装代理工具并创建基础配置
- **VS Code**: 安装并配置命令行集成
- **智能更新**: 仅更新过期软件，已是最新版本则跳过
- **全面测试**: 验证所有安装和配置

## 使用方法

### 快速开始

```bash
# 方法1: 下载后运行（推荐）
curl -fsSL https://raw.githubusercontent.com/sixban6/init_mac/main/setup_mac.sh -o setup_mac.sh
chmod +x setup_mac.sh
./setup_mac.sh

# 方法2: 直接运行
curl -fsSL https://raw.githubusercontent.com/sixban6/init_mac/main/setup_mac.sh | bash
```

**重要提示**: 
- 请不要使用 `sudo` 运行此脚本
- Homebrew 需要在普通用户权限下安装和运行
- 脚本会在需要管理员权限时提示您输入密码

### 测试安装

```bash
# 运行全面测试（不影响本地环境）
./test_setup.sh
```

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

脚本遵循 OCP（开闭原则），采用模块化函数：

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

## 安装后操作

成功安装后：

1. 重启终端或运行：
   ```bash
   source ~/.zshrc  # 或您的 shell 配置文件
   ```

2. 验证安装：
   ```bash
   ./test_setup.sh
   ```

3. 开始使用新的开发环境！

## 故障排除

### 常见问题

1. **Xcode 命令行工具**: 如有提示请安装
2. **权限错误**: 确保具有管理员权限
3. **网络问题**: 检查下载时的网络连接
4. **Shell 配置**: 安装后重启终端

### 手动恢复

如果出现问题，可以手动：

1. 检查日志: `cat setup.log`
2. 验证安装: `./test_setup.sh`
3. 根据需要重新运行特定函数

## 测试

测试脚本（`test_setup.sh`）执行全面验证：

- ✅ Xcode 命令行工具
- ✅ iTerm2 安装和配置
- ✅ Homebrew 和中国镜像源
- ✅ Git 安装和版本验证
- ✅ Go 语言编译和执行测试
- ✅ Python 环境和包管理
- ✅ Java JDK 和编译测试
- ✅ Rust 工具链和编译测试  
- ✅ Node.js 和 npm 环境
- ✅ sing-box 配置和功能测试
- ✅ VS Code 和命令行工具
- ✅ Shell 配置文件验证
- ✅ 集成测试和性能基准

**注意**: 测试完全无侵入性，仅使用临时文件。

## 许可证

MIT 许可证 - 自由使用和修改。