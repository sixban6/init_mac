#!/bin/bash

# WezTerm installation and configuration
# This script installs WezTerm and applies an expert baseline config

# Load shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

install_wezterm() {
    log "Checking WezTerm installation..."

    if ! command_exists brew; then
        log_error "Homebrew is required to install WezTerm. Please run installers/homebrew.sh first."
        return 1
    fi

    if brew list --cask wezterm &>/dev/null; then
        log_success "WezTerm already installed"
        return 0
    fi

    log "Installing WezTerm via Homebrew cask..."
    retry_command "WezTerm installation" brew install --cask wezterm
    log_success "WezTerm installed successfully"
}

configure_wezterm() {
    local config_dir="$HOME/.config/wezterm"
    local config_file="$config_dir/wezterm.lua"

    log "Creating WezTerm config directory..."
    mkdir -p "$config_dir"

    if [[ -f "$config_file" && -s "$config_file" ]]; then
        cp "$config_file" "${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
        log "Existing wezterm.lua backed up"
    fi

    touch "$config_file"

    cat > "$config_file" << 'WEZTERM_EOF'
local wezterm = require 'wezterm'
local config = {}

-- 1. 基础外观设置
config.color_scheme = 'Catppuccin Macchiato' -- 柔和的高级感配色
config.font = wezterm.font('JetBrains Mono', { weight = 'Regular' }) -- 程序员首选字体
config.font_size = 14.5

-- 2. 窗口美化
config.window_background_opacity = 0.92      -- 微微透明，看代码更深邃
config.macos_window_background_blur = 30     -- 开启毛玻璃效果
config.window_decorations = "RESIZE"         -- 隐藏标题栏，极简主义
config.window_padding = { left = 15, right = 15, top = 15, bottom = 15 }

-- 3. 快捷键设置 (模仿 iTerm2/Tmux 习惯)
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }
config.keys = {
  -- 水平分屏 (Ctrl+A, 然后 \)
  { key = '\\', mods = 'LEADER', action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  -- 垂直分屏 (Ctrl+A, 然后 -)
  { key = '-', mods = 'LEADER', action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' } },
  -- 快速切换标签 (Cmd+1, 2, 3...)
  { key = '1', mods = 'CMD', action = wezterm.action.ActivateTab(0) },
  { key = '2', mods = 'CMD', action = wezterm.action.ActivateTab(1) },
  --  给重命名标签页绑定快捷键：Cmd + Shift + E (Edit)
    {
      key = 'E',
      mods = 'CMD|SHIFT',
      action = wezterm.action.PromptInputLine {
        description = '请输入新的标签名称:',
        action = wezterm.action_callback(function(window, pane, line)
          -- 如果用户输入了内容并按回车，就设置标题
          if line then
            window:active_tab():set_title(line)
          end
        end),
      },
    },
    -- 关闭当前标签页 (保持和 Mac 一致)
    { key = 'w', mods = 'CMD', action = wezterm.action.CloseCurrentTab { confirm = true } },
}


-- 5. 交互优化
config.scrollback_lines = 75025               -- 增加回滚行数，方便看长日志
config.enable_tab_bar = true                 -- 显示标签栏
config.use_fancy_tab_bar = false             -- 使用更节省空间的标签栏样式

return config
WEZTERM_EOF

    log_success "WezTerm configuration written to $config_file"
    log "WezTerm hot-reload: 每次保存 $config_file 后会自动检测并立即应用，无需重启。"
}

main() {
    check_macos
    check_not_root

    install_wezterm
    configure_wezterm
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
