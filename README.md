# Hugo Theme Factory

基础主题和构建系统，用于批量生成多个不同风格的 Hugo 静态网站。
# Hugo Documentation

## Introduction

Welcome to the documentation for your Hugo site. This document will help you understand the structure of your site and how to make the most out of it.

## Script Usage

### build.sh

The build script allows you to build, test, and deploy your Hugo site.

```bash
./build.sh [options]
```

Options:
- `build`: Build the site (default if no option provided)
- `clean`: Remove the public directory
- `server`: Start the Hugo server for local development
- `deploy`: Deploy the site to your hosting provider
- `new [post|draft] "title"`: Create a new post or draft with the specified title

Examples:
```bash
./build.sh             # Build the site
./build.sh clean       # Clean the public directory
./build.sh server      # Start the Hugo server
./build.sh deploy      # Deploy the site
./build.sh new post "My New Post"  # Create a new post
./build.sh new draft "My Draft"    # Create a new draft
```

### newsite.sh

The newsite script helps you create a new Hugo site with the baseline configuration.

```bash
./newsite.sh site_name
```

This script will:
1. Create a new Hugo site in the specified directory
2. Install the PaperMod theme
3. Copy necessary configuration files
4. Initialize Git repository
5. Create sample content

Example:
```bash
./newsite.sh my-new-blog
```

## 重新构建测试站点

如果您需要重新构建测试站点，可以使用以下步骤：

1. 使用 build.sh 脚本重新构建站点：

```bash
# 导航到 Hugo Base Theme 目录
cd /path/to/HugoBaseTheme

# 构建特定的测试站点
./build.sh test-site

# 或者如果需要自定义输出目录
./build.sh test-site custom-output
```

2. 如果需要完全重新创建测试站点：

```bash
# 删除现有站点
rm -rf ../sites/test-site

# 重新创建站点
./newsite.sh test-site

# 构建新创建的站点
./build.sh test-site
```

3. 要在本地预览站点：

```bash
cd ../sites/test-site
hugo server -D
```

然后在浏览器中访问 http://localhost:1313/ 查看站点。

## 模块加载错误的解决方案

如果您遇到类似 `module "base-theme" not found` 的错误，可以尝试以下解决方法：

1. 确保 base theme 文件夹中有 go.mod 文件：

```bash
# 导航到 Hugo Base Theme 目录
cd /Users/ming/Documents/HUGO/HUGOBASE/HugoBaseTheme

# 创建基本 go.mod 文件
echo "module github.com/harrison-hugo/base-theme" > go.mod
```

2. 在测试站点的 go.mod 文件中添加替换指令：

```bash
# 导航到测试站点目录
cd ../sites/test-site

# 编辑 go.mod 文件
echo "replace github.com/harrison-hugo/base-theme => /Users/ming/Documents/HUGO/HUGOBASE/HugoBaseTheme" >> go.mod

# 更新 Hugo 模块
hugo mod get -u
```

3. 使用主题模式作为备选方案：

```bash
# 创建主题目录并添加符号链接
mkdir -p themes
ln -sf /Users/ming/Documents/HUGO/HUGOBASE/HugoBaseTheme themes/HugoBaseTheme

# 编辑 config.toml 添加主题设置
echo 'theme = "HugoBaseTheme"' >> config.toml
```

完成上述步骤后，应该能够成功构建站点。