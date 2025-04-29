#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 脚本说明
echo "${BLUE}=== Hugo Theme Factory 站点构建脚本 ===${NC}"
echo ""

# 检查参数
if [ "$#" -lt 1 ]; then
    echo "${RED}错误: 缺少站点名称参数${NC}"
    echo "用法: $0 <站点名称> [输出目录]"
    exit 1
fi

# 设置变量
SITE_NAME=$1
OUTPUT_DIR=${2:-"public"}  # 默认输出到public目录

# 获取脚本所在的目录作为Base Theme目录
BASE_THEME_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# 设置sites目录与BASE_THEME_DIR并列
SITES_DIR="$( dirname "$BASE_THEME_DIR" )/sites"

# 配置路径
BASE_CONFIG="${BASE_THEME_DIR}/specs/base-config.toml"
SITE_DIR="${SITES_DIR}/${SITE_NAME}"
SITE_CONFIG="${SITE_DIR}/config.toml"

# 检查站点目录是否存在
if [ ! -d "$SITE_DIR" ]; then
    echo "${RED}错误: 站点目录 ${SITE_DIR} 不存在${NC}"
    echo "请先使用 newsite.sh 创建站点"
    exit 1
fi

# 检查配置文件是否存在
if [ ! -f "$SITE_CONFIG" ]; then
    echo "${RED}错误: 站点配置文件 ${SITE_CONFIG} 不存在${NC}"
    exit 1
fi

# 检查环境
echo "${YELLOW}检查环境...${NC}"
if ! command -v hugo &> /dev/null; then
    echo "${RED}错误: Hugo 未安装${NC}"
    echo "请安装 Hugo: https://gohugo.io/getting-started/installing/"
    exit 1
fi

# 确认构建模式
echo "${YELLOW}站点: ${SITE_NAME}${NC}"
if grep -q "\[\[module.imports\]\]" "$SITE_CONFIG"; then
    echo "检测到模块配置"
    BUILD_MODE="module"
    if grep -q "theme" "$SITE_CONFIG"; then
        echo "同时检测到主题配置 (theme = \"HugoBaseTheme\")"
        BUILD_MODE="hybrid"
    fi
else
    if grep -q "theme" "$SITE_CONFIG"; then
        echo "使用主题模式构建 (theme = \"HugoBaseTheme\")"
        BUILD_MODE="theme"
    else
        echo "${RED}错误: 配置文件中既没有模块导入也没有主题设置${NC}"
        exit 1
    fi
fi

# 选择构建方式
if [ "$BUILD_MODE" == "theme" ]; then
    # 主题模式构建 - 当没有Go环境时的备选方案
    echo "${YELLOW}开始构建 (主题模式)...${NC}"
    (cd "$SITE_DIR" && hugo --destination="$OUTPUT_DIR")
    BUILD_STATUS=$?
elif [ "$BUILD_MODE" == "module" ] || [ "$BUILD_MODE" == "hybrid" ]; then
    # 模块模式构建 - 先确保模块依赖更新
    echo "${YELLOW}开始构建 (模块模式)...${NC}"
    
    # 检查contactEmail参数是否存在
    if ! grep -q "contactEmail" "$SITE_CONFIG"; then
        echo "${YELLOW}添加contactEmail参数到配置文件...${NC}"
        sed -i '' '/\[params\]/a\\
  contactEmail = "contact@example.com"' "$SITE_CONFIG"
    fi
    
    # 检查Go环境，如果有则更新模块
    if command -v go &> /dev/null; then
        echo "${YELLOW}更新模块依赖...${NC}"
        
        # 确保基础主题的go.mod设置正确
        if [ ! -f "$BASE_THEME_DIR/go.mod" ] || ! grep -q "module github.com/harrison-ming/HugoBaseTheme" "$BASE_THEME_DIR/go.mod"; then
            echo "${YELLOW}更新基础主题模块定义...${NC}"
            echo "module github.com/harrison-ming/HugoBaseTheme" > "$BASE_THEME_DIR/go.mod"
            echo "go 1.18" >> "$BASE_THEME_DIR/go.mod"
        fi
        
        # 进入站点目录并更新模块依赖
        cd "$SITE_DIR"
        
        # 确保站点的go.mod包含正确的替换声明
        if ! grep -q "replace github.com/harrison-ming/HugoBaseTheme" "go.mod"; then
            echo "${YELLOW}添加模块替换声明...${NC}"
            echo "replace github.com/harrison-ming/HugoBaseTheme => $BASE_THEME_DIR" >> go.mod
        fi
        
        # 更新依赖
        echo "${YELLOW}获取最新模块依赖...${NC}"
        hugo mod get -u

        # 清理hugo配置
        if [ -f "hugo.toml" ]; then
            echo "${YELLOW}删除多余的hugo.toml配置...${NC}"
            rm -f hugo.toml
        fi
    else
        echo "${RED}错误: Go 未安装，无法使用模块模式${NC}"
        exit 1
    fi
    
    # 检查基础配置
    if [ ! -f "$BASE_CONFIG" ]; then
        echo "${YELLOW}警告: 基础配置文件 ${BASE_CONFIG} 不存在，将只使用站点配置${NC}"
        (cd "$SITE_DIR" && hugo --destination="$OUTPUT_DIR")
        BUILD_STATUS=$?
    else
        if [ "$BUILD_MODE" == "module" ] || [ "$BUILD_MODE" == "hybrid" ]; then
            # 模块模式下，不合并基础配置，直接使用站点配置
            echo "${YELLOW}使用站点配置: ${SITE_CONFIG}${NC}"
            (cd "$SITE_DIR" && hugo --destination="$OUTPUT_DIR")
            BUILD_STATUS=$?
        else
            # 主题模式下，合并配置
            echo "${YELLOW}合并配置: ${BASE_CONFIG} + ${SITE_CONFIG}${NC}"
            (cd "$SITE_DIR" && hugo --config="$BASE_CONFIG,$SITE_CONFIG" --destination="$OUTPUT_DIR")
            BUILD_STATUS=$?
        fi
    fi
fi

# 检查构建结果
if [ $BUILD_STATUS -eq 0 ]; then
    SITE_OUTPUT="${SITE_DIR}/${OUTPUT_DIR}"
    echo "${GREEN}✅ 构建成功!${NC}"
    echo "${YELLOW}输出目录: ${SITE_OUTPUT}${NC}"
    echo "${YELLOW}文件数量: $(find "$SITE_OUTPUT" -type f | wc -l)${NC}"
    echo "${YELLOW}输出大小: $(du -sh "$SITE_OUTPUT" | cut -f1)${NC}"
    
    # 显示预览链接
    echo ""
    echo "${BLUE}要预览站点，请运行:${NC}"
    echo "cd $SITE_DIR && hugo server"
    echo "${YELLOW}或访问生成的静态文件:${NC}"
    echo "file://${SITE_OUTPUT}/index.html"
else
    echo "${RED}❌ 构建失败，请检查错误信息${NC}"
    exit 1
fi