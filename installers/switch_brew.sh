#!/bin/bash

echo "🔍 开始测速候选 Homebrew 源..."

# 定义候选源
mirrors=(
    "Tencent|https://mirrors.tencent.com/homebrew/brew.git"
    "Aliyun|https://mirrors.aliyun.com/homebrew/brew.git"
    "USTC|https://mirrors.ustc.edu.cn/brew.git"
    "Official|https://github.com/Homebrew/brew.git"
)

best_mirror=""
best_time=999999

for item in "${mirrors[@]}"; do
    name="${item%%|*}"
    url="${item##*|}"
    
    time=$(curl -o /dev/null -s -w "%{time_total}\n" -m 3 "$url" || echo "999999")

    if [ "$time" != "999999" ]; then
        printf "✅ %-10s : 延迟 %.3f 秒\n" "$name" "$time"
        if (( $(echo "$time < $best_time" | bc -l) )); then
            best_time=$time
            best_mirror=$name
        fi
    else
        printf "❌ %-10s : 连接超时或失败\n" "$name"
    fi
done

if [ -z "$best_mirror" ]; then
    echo "⚠️ 所有源均不可用，请检查网络。"
    exit 1
fi

echo "-----------------------------------"
echo "🚀 测速完成！最快的源是: $best_mirror (延迟 $best_time 秒)"
echo "-----------------------------------"

case $best_mirror in
    "Tencent")
        BREW_GIT="https://mirrors.tencent.com/homebrew/brew.git"
        BOTTLE_DOMAIN="https://mirrors.tencent.com/homebrew-bottles"
        API_DOMAIN="https://mirrors.tencent.com/homebrew-bottles/api"
        ;;
    "Aliyun")
        BREW_GIT="https://mirrors.aliyun.com/homebrew/brew.git"
        BOTTLE_DOMAIN="https://mirrors.aliyun.com/homebrew/homebrew-bottles"
        API_DOMAIN="https://mirrors.aliyun.com/homebrew/homebrew-bottles/api"
        ;;
    "USTC")
        BREW_GIT="https://mirrors.ustc.edu.cn/brew.git"
        BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
        API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
        ;;
    "Official")
        BREW_GIT="https://github.com/Homebrew/brew.git"
        BOTTLE_DOMAIN="https://ghcr.io/v2/homebrew/core"
        API_DOMAIN="https://formulae.brew.sh/api"
        ;;
esac

echo "🔧 1/2 正在修改 brew 底层 git remote..."
git -C "$(brew --repo)" remote set-url origin "$BREW_GIT"

# 自动判断当前使用的 Shell 配置文件
if [[ "$SHELL" == */zsh ]]; then
    RC_FILE="$HOME/.zshrc"
elif [[ "$SHELL" == */bash ]]; then
    RC_FILE="$HOME/.bash_profile"
else
    RC_FILE="$HOME/.profile"
fi

# 确保文件存在
touch "$RC_FILE"

echo "📝 2/2 正在自动修改配置文件 ($RC_FILE)..."
# 使用兼容 macOS (BSD) 的 sed 语法删除旧配置，防止重复写入
sed -i '' '/^export HOMEBREW_BREW_GIT_REMOTE/d' "$RC_FILE"
sed -i '' '/^export HOMEBREW_BOTTLE_DOMAIN/d' "$RC_FILE"
sed -i '' '/^export HOMEBREW_API_DOMAIN/d' "$RC_FILE"
sed -i '' '/^# Homebrew 自动测速配置/d' "$RC_FILE"

# 追加新配置
echo "# Homebrew 自动测速配置" >> "$RC_FILE"
echo "export HOMEBREW_BREW_GIT_REMOTE=\"$BREW_GIT\"" >> "$RC_FILE"
echo "export HOMEBREW_BOTTLE_DOMAIN=\"$BOTTLE_DOMAIN\"" >> "$RC_FILE"
echo "export HOMEBREW_API_DOMAIN=\"$API_DOMAIN\"" >> "$RC_FILE"

echo "✅ 配置已成功写入 $RC_FILE！下次打开终端将自动生效。"
echo "-----------------------------------"

# 在当前脚本环境中临时导出变量，跳过 "source" 步骤，直接开干
export HOMEBREW_BREW_GIT_REMOTE="$BREW_GIT"
export HOMEBREW_BOTTLE_DOMAIN="$BOTTLE_DOMAIN"
export HOMEBREW_API_DOMAIN="$API_DOMAIN"
