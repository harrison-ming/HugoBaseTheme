#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 脚本说明
echo "${BLUE}=== Hugo Theme Factory 测试站点创建脚本 ===${NC}"
echo ""

# 检查参数
if [ "$#" -lt 1 ]; then
    echo "${RED}错误: 缺少站点名称参数${NC}"
    echo "用法: $0 <站点名称>"
    exit 1
fi

# 获取脚本所在的目录作为Base Theme目录
BASE_THEME_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# 设置sites目录与BASE_THEME_DIR并列
SITES_DIR="$( dirname "$BASE_THEME_DIR" )/sites"
SITE_NAME=$1
SITE_DIR="$SITES_DIR/$SITE_NAME"

# 检查Hugo和Go是否已安装
echo "${YELLOW}检查环境...${NC}"
if ! command -v hugo &> /dev/null; then
    echo "${RED}错误: Hugo 未安装${NC}"
    echo "请安装 Hugo: https://gohugo.io/getting-started/installing/"
    exit 1
fi

if ! command -v go &> /dev/null; then
    echo "${RED}错误: Go 未安装${NC}"
    echo "请安装 Go: https://golang.org/doc/install"
    echo "Hugo 模块功能需要 Go 环境支持"
    exit 1
fi

# 创建站点目录
echo "${YELLOW}创建站点目录: $SITE_DIR${NC}"
mkdir -p "$SITES_DIR"

# 检查站点目录是否已存在
if [ -d "$SITE_DIR" ]; then
    echo "${YELLOW}站点目录已存在，是否覆盖? [y/N]${NC}"
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "${RED}操作取消${NC}"
        exit 1
    fi
    rm -rf "$SITE_DIR"
fi

# 创建新的Hugo站点
echo "${YELLOW}创建新的Hugo站点...${NC}"
hugo new site "$SITE_DIR"

# 创建配置文件
echo "${YELLOW}创建站点配置文件...${NC}"
cat > "$SITE_DIR/config.toml" << EOF
# 基本站点设置
title = "测试站点 - $SITE_NAME"
baseURL = "http://example.com/"
languageCode = "zh-cn"

# 使用模块模式导入基础主题
[module]
  [[module.imports]]
    path = "github.com/harrison-ming/HugoBaseTheme"

# 参数设置
[params]
  siteName = "$SITE_NAME"
  siteDescription = "这是一个测试站点，用于验证基础主题功能"
  mainSections = ["posts"]
  contactEmail = "contact@example.com"
  
  # 社交媒体链接
  [params.social]
    twitter = "example"
    github = "harrison-ming"
  
  # 自定义设置
  [params.custom]
    showHeaderImage = true
EOF

# 创建测试内容
echo "${YELLOW}创建测试内容...${NC}"

# 创建示例文章
mkdir -p "$SITE_DIR/content/posts"
cat > "$SITE_DIR/content/posts/hello-world.md" << EOF
---
title: "Hello World - 测试文章"
date: $(date +%Y-%m-%dT%H:%M:%S%z)
draft: false
---

# 欢迎使用 Hugo Theme Factory

这是一篇测试文章，用于验证基础主题的功能。

## 标题二

这是正文内容。

- 列表项 1
- 列表项 2
- 列表项 3

### 标题三

更多正文内容...

> 这是一段引用文字，看看它在主题中的呈现效果如何。
EOF

# 创建关于页面
mkdir -p "$SITE_DIR/content/about"
cat > "$SITE_DIR/content/about/_index.md" << EOF
---
title: "关于我们"
date: $(date +%Y-%m-%dT%H:%M:%S%z)
draft: false
---

# 关于 $SITE_NAME

这是 $SITE_NAME 的关于页面，由 Hugo Theme Factory 自动生成。
EOF

# 复制法律页面
echo "${YELLOW}复制法律页面...${NC}"
mkdir -p "$SITE_DIR/content/legal"

# 修改复制法律页面的方式，对模板进行预处理
if [ -d "$BASE_THEME_DIR/content/legal" ]; then
  for file in "$BASE_THEME_DIR/content/legal"/*.md; do
    if [ -f "$file" ]; then
      filename=$(basename "$file")
      echo "${YELLOW}处理法律页面: $filename${NC}"
      
      # 创建目标文件
      target_file="$SITE_DIR/content/legal/$filename"
      
      # 从config.toml中获取contactEmail值（如果存在）
      CONTACT_EMAIL="contact@example.com"
      if grep -q "contactEmail" "$SITE_DIR/config.toml"; then
        CONTACT_EMAIL=$(grep "contactEmail" "$SITE_DIR/config.toml" | cut -d'=' -f2 | tr -d ' "')
      fi
      
      # 复制文件内容但替换常见模板变量
      cat "$file" | sed "s/{{ site.Title }}/$SITE_NAME/g" | \
                    sed "s/{{ now.Format \"2006年01月02日\" }}/$(date '+%Y年%m月%d日')/g" | \
                    sed "s/{{ site.Params.contactEmail }}/$CONTACT_EMAIL/g" > "$target_file"
    fi
  done
else
  echo "${YELLOW}警告: 基础主题中没有找到法律页面目录${NC}"
fi

# 复制首页和其他基础页面
echo "${YELLOW}复制基础主题页面...${NC}"

# 复制主页模板文件
if [ -d "$BASE_THEME_DIR/layouts" ]; then
  mkdir -p "$SITE_DIR/layouts"
  cp -r "$BASE_THEME_DIR/layouts/"* "$SITE_DIR/layouts/" 2>/dev/null || :
fi

# 复制首页内容
if [ -f "$BASE_THEME_DIR/content/_index.md" ]; then
  cp "$BASE_THEME_DIR/content/_index.md" "$SITE_DIR/content/" 2>/dev/null || :
fi

# 复制部分模板
if [ -d "$BASE_THEME_DIR/layouts/partials" ]; then
  mkdir -p "$SITE_DIR/layouts/partials"
  cp -r "$BASE_THEME_DIR/layouts/partials/"* "$SITE_DIR/layouts/partials/" 2>/dev/null || :
fi

# 复制静态文件
if [ -d "$BASE_THEME_DIR/static" ]; then
  mkdir -p "$SITE_DIR/static"
  cp -r "$BASE_THEME_DIR/static/"* "$SITE_DIR/static/" 2>/dev/null || :
fi

# 复制其他内容目录
for dir in "$BASE_THEME_DIR/content/"*/; do
  if [ -d "$dir" ]; then
    dirname=$(basename "$dir")
    # 跳过已经复制的目录
    if [[ "$dirname" != "legal" && "$dirname" != "posts" && "$dirname" != "about" ]]; then
      echo "${YELLOW}复制内容目录: $dirname${NC}"
      mkdir -p "$SITE_DIR/content/$dirname"
      
      # 对每个文件进行变量替换处理
      for file in "$dir"*.md; do
        if [ -f "$file" ]; then
          filename=$(basename "$file")
          target_file="$SITE_DIR/content/$dirname/$filename"
          
          # 复制文件内容但替换常见模板变量
          cat "$file" | sed "s/{{ site.Title }}/$SITE_NAME/g" | \
                        sed "s/{{ now.Format \"2006年01月02日\" }}/$(date '+%Y年%m月%d日')/g" > "$target_file"
        fi
      done
    fi
  fi
done

# 创建 go.mod 文件以支持模块模式
echo "${YELLOW}设置 Hugo 模块...${NC}"
cd "$SITE_DIR"

# 初始化 Go 模块
go mod init "$SITE_NAME"

# 使用hugo mod获取本地模块，注意使用-replacements标志
echo "module github.com/harrison-ming/HugoBaseTheme" > "$BASE_THEME_DIR/go.mod"
hugo mod get github.com/harrison-ming/HugoBaseTheme
hugo mod vendor

# 添加替换声明到go.mod文件
echo "replace github.com/harrison-ming/HugoBaseTheme => $BASE_THEME_DIR" >> go.mod

# 完成提示
echo ""
echo "${GREEN}✅ 测试站点 $SITE_NAME 创建完成!${NC}"
echo ""
echo "${BLUE}您可以通过以下命令开始测试:${NC}"
echo "cd $SITE_DIR"
echo "hugo server -D"
echo ""
echo "${YELLOW}访问 http://localhost:1313/ 查看站点${NC}"
