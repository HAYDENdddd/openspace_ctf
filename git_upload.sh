#!/bin/bash

set -e  # 出错时退出脚本

echo "📁 当前路径: $(pwd)"

# ========== 初始化 Git ==========
if [ ! -d .git ]; then
    echo "🧱 当前目录不是 Git 仓库。是否初始化？(y/n)"
    read init_ans
    if [ "$init_ans" = "y" ]; then
        git init || { echo "❌ Git 初始化失败"; exit 1; }
        echo "✅ Git 初始化完成"
    else
        echo "🚫 用户取消，退出脚本"
        exit 0
    fi
fi

# ========== 自动识别当前分支 ==========
current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
echo "🌿 当前分支：$current_branch"

# ========== 添加子模块（支持多次添加） ==========
echo "📦 是否添加 Git 子模块？(y/n)"
read add_submodule
while [ "$add_submodule" = "y" ]; do
    echo "📥 输入子模块仓库 URL："
    read submodule_url
    echo "📁 子模块路径（如 lib/forge-std）："
    read submodule_path

    if [ -d "$submodule_path/.git" ]; then
        echo "⚠️ 子模块路径已存在并可能是嵌套仓库，跳过。"
    else
        git submodule add "$submodule_url" "$submodule_path" || {
            echo "❌ 添加子模块失败，检查 URL 或路径是否正确"; exit 1;
        }
        echo "✅ 子模块添加成功：$submodule_path"
    fi

    echo "📦 继续添加子模块？(y/n)"
    read add_submodule
done

# ========== 添加所有文件 ==========
git add .

# ========== 检查是否有变更 ==========
if git diff --cached --quiet; then
    echo "⚠️ 没有待提交的更改，已跳过提交"
else
    # 提交
    echo "📝 输入提交信息："
    read commit_msg
    if [ -z "$commit_msg" ]; then
        echo "❌ 提交信息不能为空，退出"
        exit 1
    fi
    git commit -m "$commit_msg" || { echo "❌ 提交失败"; exit 1; }
fi

# ========== 远程仓库设置 ==========
if ! git remote get-url origin > /dev/null 2>&1; then
    echo "🌐 未设置远程仓库。请输入 GitHub 地址（如 https://github.com/yourname/repo.git）："
    read remote_url
    git remote add origin "$remote_url" || { echo "❌ 添加远程仓库失败"; exit 1; }
    echo "✅ 远程仓库已添加"
else
    echo "🌍 已配置远程仓库：$(git remote get-url origin)"
fi

# ========== 推送到远程 ==========
echo "📤 正在推送到 origin/$current_branch ..."
git push -u origin "$current_branch" || { echo "❌ 推送失败，请检查网络或权限"; exit 1; }

# ========== 子模块初始化 ==========
echo "🔁 更新子模块状态 ..."
git submodule update --init --recursive

echo "🎉 所有操作完成，项目已成功上传至 GitHub 🚀"
