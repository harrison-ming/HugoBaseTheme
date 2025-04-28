#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 要检查的仓库名称
REPO_NAME="HugoBaseTheme"
GH_USERNAME="harrison-ming"

echo "${BLUE}=== Hugo Theme Factory 初始化脚本 ===${NC}"
echo "${BLUE}检查环境与初始化基础主题仓库${NC}"
echo ""

# 检查是否安装了GitHub CLI
if ! command -v gh &> /dev/null; then
    echo "${RED}错误: GitHub CLI (gh) 未安装${NC}"
    echo "请安装 GitHub CLI: https://cli.github.com/"
    exit 1
fi

# 检查GitHub是否已登录
echo "${YELLOW}检查 GitHub 登录状态...${NC}"
if ! gh auth status &> /dev/null; then
    echo "${RED}您尚未登录 GitHub CLI${NC}"
    echo "请运行 'gh auth login' 进行登录"
    exit 1
fi

# 检查登录的用户是否为harrison-ming
CURRENT_USER=$(gh api user | grep -o '"login": *"[^"]*"' | cut -d'"' -f4)

if [ "$CURRENT_USER" != "$GH_USERNAME" ]; then
    echo "${RED}警告: 您当前登录的GitHub账户 ($CURRENT_USER) 不是预期的账户 ($GH_USERNAME)${NC}"
    read -p "是否继续使用当前账户? (y/n): " CONTINUE
    if [ "$CONTINUE" != "y" ]; then
        echo "请使用正确的账户重新登录"
        exit 1
    fi
else
    echo "${GREEN}已确认登录用户: $GH_USERNAME${NC}"
fi

# 创建文件夹结构
echo "${YELLOW}创建项目文件夹结构...${NC}"
mkdir -p specs

# 移动规范文件到specs文件夹
if [ -f "Specification.md" ]; then
    mv Specification.md specs/
    echo "${GREEN}已移动 Specification.md 到 specs 文件夹${NC}"
fi

if [ -f "base-config.toml" ]; then
    mv base-config.toml specs/
    echo "${GREEN}已移动 base-config.toml 到 specs 文件夹${NC}"
fi

if [ -f "site-config-spec.toml" ]; then
    mv site-config-spec.toml specs/
    echo "${GREEN}已移动 site-config-spec.toml 到 specs 文件夹${NC}"
fi

# 检查本地是否已初始化Git仓库
if [ ! -d ".git" ]; then
    echo "${YELLOW}初始化本地Git仓库...${NC}"
    git init
    echo "${GREEN}本地Git仓库初始化完成${NC}"
fi

# 检查仓库是否已存在于GitHub上
echo "${YELLOW}检查 $REPO_NAME 仓库是否存在...${NC}"
if gh repo view "$GH_USERNAME/$REPO_NAME" &> /dev/null; then
    echo "${GREEN}远程仓库 $GH_USERNAME/$REPO_NAME 已存在${NC}"
    
    # 检查是否已添加远程仓库
    if ! git remote get-url origin &> /dev/null; then
        echo "${YELLOW}添加远程仓库...${NC}"
        git remote add origin "https://github.com/$GH_USERNAME/$REPO_NAME.git"
        echo "${GREEN}已添加远程仓库${NC}"
    else
        echo "${GREEN}远程仓库已配置${NC}"
    fi
else
    echo "${YELLOW}远程仓库 $GH_USERNAME/$REPO_NAME 不存在，正在创建...${NC}"
    
    # 创建新仓库
    if gh repo create "$GH_USERNAME/$REPO_NAME" --public --description "Hugo Theme Factory 基础主题"; then
        echo "${GREEN}成功创建仓库 $GH_USERNAME/$REPO_NAME${NC}"
        
        # 添加远程仓库
        git remote add origin "https://github.com/$GH_USERNAME/$REPO_NAME.git"
        echo "${GREEN}已添加远程仓库${NC}"
        
        # 初始化README文件
        if [ ! -f "README.md" ]; then
            echo "# Hugo Theme Factory" > README.md
            echo "" >> README.md
            echo "基础主题和构建系统，用于批量生成多个不同风格的 Hugo 静态网站。" >> README.md
            git add README.md
        fi
    else
        echo "${RED}创建仓库失败${NC}"
        exit 1
    fi
fi

# 检查文件并提交
if [ -n "$(git status --porcelain)" ]; then
    echo "${YELLOW}添加文件到Git...${NC}"
    git add .
    echo "${YELLOW}提交更改...${NC}"
    git commit -m "初始化 Hugo Theme Factory 基础主题"
    echo "${YELLOW}推送到远程仓库...${NC}"
    git push -u origin HEAD
    echo "${GREEN}已提交初始文件并推送到远程仓库${NC}"
else
    echo "${YELLOW}没有新文件可提交${NC}"
fi

echo ""
echo "${GREEN}✅ 仓库检查与初始化完成${NC}"
echo "${BLUE}现在可以继续开发 Hugo Theme Factory 了${NC}"
