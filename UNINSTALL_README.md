# macOS 开发环境卸载脚本

这个脚本用于选择性地卸载通过 `setup_mac.sh` 安装的开发工具。

## 卸载内容

### ❌ 将被卸载的软件：
- **Python 配置** - 移除 pip 配置和环境变量（保留 Homebrew Python 作为依赖）
- **Java (OpenJDK)** - 完全卸载包括环境变量和系统链接
- **Rust** - 完全卸载包括 Cargo 配置和环境变量
- **Node.js** - 完全卸载包括 npm 配置和缓存
- **sing-box** - 完全卸载包括配置文件
- **VS Code** - 卸载应用程序和命令行工具（可选择保留用户数据）

### ✅ 将被保留的软件：
- **Homebrew** - 保留（仅清理未使用的依赖）
- **iTerm2** - 保留
- **Git** - 保留
- **Go** - 保留

## 使用方法

### 快速使用

```bash
# 下载卸载脚本
curl -fsSL https://raw.githubusercontent.com/sixban6/init_mac/main/uninstall_mac.sh -o uninstall_mac.sh
chmod +x uninstall_mac.sh

# 运行卸载脚本
./uninstall_mac.sh
```

### 本地使用

如果你已经有了脚本文件：

```bash
# 确保脚本有执行权限
chmod +x uninstall_mac.sh

# 运行卸载脚本
./uninstall_mac.sh
```

## 安全特性

### 🔒 安全保护措施：
- **交互式确认** - 执行前需要用户确认
- **配置文件备份** - 自动备份 shell 配置文件
- **用户数据保护** - VS Code 用户数据可选择保留
- **依赖检查** - 智能处理软件依赖关系
- **错误处理** - 全面的错误检查和日志记录

### 📋 卸载过程：
1. 显示将要卸载的软件列表
2. 要求用户确认操作
3. 按安全顺序卸载各个软件
4. 清理配置文件和环境变量
5. 清理 Homebrew 未使用的依赖
6. 显示最终状态报告

## 详细卸载说明

### Python 配置清理
- 移除 `~/.pip/pip.conf` 中国镜像配置
- 从 shell 配置文件中移除 Python 环境变量
- 保留 Homebrew Python（其他软件可能依赖）

### Java (OpenJDK) 完全卸载
```bash
# 将执行以下操作：
brew uninstall openjdk
sudo rm -f /Library/Java/JavaVirtualMachines/openjdk.jdk
# 移除 JAVA_HOME 环境变量
```

### Rust 完全卸载
```bash
# 将执行以下操作：
brew uninstall rust
rm -f ~/.cargo/config
# 移除空的 .cargo 目录
# 移除 CARGO_HOME 环境变量
```

### Node.js 完全卸载
```bash
# 将执行以下操作：
brew uninstall node
rm -rf ~/.npm-global
rm -rf ~/.npm
# 移除 NPM 环境变量
```

### sing-box 完全卸载
```bash
# 将执行以下操作：
brew uninstall sing-box
rm -rf ~/.config/sing-box
```

### VS Code 卸载选项
```bash
# 将执行以下操作：
rm -rf "/Applications/Visual Studio Code.app"
sudo rm -f /usr/local/bin/code

# 可选择是否删除：
# ~/Library/Application Support/Code
# ~/.vscode
```

## 恢复说明

### 配置文件备份
脚本会自动创建 shell 配置文件的备份：
```bash
~/.zshrc.backup.YYYYMMDD_HHMMSS
~/.bash_profile.backup.YYYYMMDD_HHMMSS
```

### 手动恢复
如果需要恢复配置：
```bash
# 恢复最新的备份
cp ~/.zshrc.backup.* ~/.zshrc
source ~/.zshrc
```

### 重新安装
如果需要重新安装某个软件：
```bash
# 重新运行安装脚本
./setup_mac.sh

# 或单独安装某个软件
brew install openjdk    # Java
brew install rust       # Rust  
brew install node       # Node.js
brew install sing-box   # sing-box
brew install --cask visual-studio-code  # VS Code
```

## 故障排除

### 常见问题

1. **权限错误**
   ```bash
   # 确保有管理员权限（部分操作需要 sudo）
   ```

2. **Homebrew 依赖警告**
   ```bash
   # 正常现象，脚本会自动处理依赖关系
   brew autoremove  # 清理未使用的依赖
   ```

3. **配置文件问题**
   ```bash
   # 检查备份文件
   ls -la ~/.zshrc.backup.*
   
   # 手动编辑配置文件
   nano ~/.zshrc
   ```

### 检查卸载状态
```bash
# 检查软件是否已卸载
which java rust node sing-box code

# 检查 Homebrew 包
brew list | grep -E "(openjdk|rust|node|sing-box)"

# 检查应用程序
ls /Applications/ | grep -i "visual studio code"
```

## 注意事项

⚠️ **重要提醒**：
- 卸载前请确保没有重要的项目依赖这些工具
- VS Code 扩展和设置可能会丢失（除非选择保留用户数据）
- 某些 Node.js 全局包可能需要重新安装
- Python 包将保留在 Homebrew Python 中

✅ **安全承诺**：
- 不会删除用户创建的文件和项目
- 不会影响系统关键组件
- 提供完整的操作日志
- 支持配置文件恢复

## 许可证

MIT 许可证 - 自由使用和修改。