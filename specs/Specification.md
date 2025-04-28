# Hugo Theme Factory 规格说明书

## 1. 项目概述

### 1.1 项目目标
构建一个 **Hugo Theme Factory** 系统，通过维护一套通用基础主题（base-theme）+ 子站点局部覆盖，实现 **低冗余、高效率** 地批量生成多个不同风格的 Hugo 静态网站。

### 1.2 核心需求
- 统一维护一套 **基础主题 (Base Theme)**。
- 每个站点只需要：
  - 独立的 `config.toml` 配置文件（继承+扩展 base-config）
  - 少量局部覆盖的 `layouts/`（如首页 `index.html`）
- 使用 **Hugo Modules** 管理基础主题依赖。
- 支持通过 Hugo 的 `--config` 参数 **合并多个 config 文件**（实现继承扩展）。
- 用脚本（sh脚本）自动化快速生成站点、构建站点。

### 1.3 关键特性总结

| 特性 | 描述 |
|:----|:----|
| 单一维护 | 所有通用代码集中管理，统一升级 |
| 低冗余 | 子站只需要小量覆盖 |
| 快速扩展 | 复制一份子站 config 即可快速上线新站 |
| Hugo Modules | 用最现代化的 Hugo 项目依赖管理 |
| 自动化 | 用脚本一键新建、构建、发布子站 |

## 2. 系统架构

### 2.1 基础主题 (Base Theme)
#### 2.1.1 文件结构
- 包括：
  - `archetypes/` - 内容模板，便于创建新内容
  - `assets/` - SCSS/CSS/JS资源文件
  - `content/`
    - `legal/` - 法律页面模板目录：
      - `privacy-policy.md` - 隐私政策
      - `disclaimer.md` - 免责声明
      - `terms-of-service.md` - 服务条款
      - `cookie-policy.md` - Cookie政策
  - `data/` - 通用数据文件，如社交媒体链接、菜单结构等
  - `i18n/` - 国际化支持文件
  - `layouts/`
    - `_default/`
      - `baseof.html` - 基础页面模板
      - `list.html` - 列表页面模板
      - `single.html` - 单页面模板
    - `partials/` - 页面部分组件
      - `analytics.html` - Google Analytics统计代码
      - `pagination.html` - 分页控件
      - `seo/` - SEO优化组件，包含Open Graph、Twitter Card等
    - `shortcodes/` - 常用简码，如图片画廊、视频嵌入等
    - `404.html` - 统一的404页面
  - `theme.toml` - 主题描述文件
  - `go.mod` - Hugo模块定义文件

#### 2.1.2 主题管理
- **通过 Hugo Modules 管理**，便于统一升级。

#### 2.1.3 功能模块
- **Google Analytics配置**：
  - 在基础主题中包含统一的分析代码模板
  - 在 `base-config.toml` 中设置默认跟踪 ID
  - 允许各子站在自己的配置中覆盖跟踪 ID
  - 支持 Google Analytics 4 (GA4) 和旧版通用分析
- **性能优化**：
  - 内置延迟加载图片的支持
  - CSS/JS资源的选择性加载机制
  - 图片处理管道（使用Hugo的图像处理功能）
- **安全特性**：
  - CSP (Content Security Policy) 配置模板
  - 自动添加安全相关的HTTP头部

#### 2.1.4 法律页面模板
- **自动生成法律页面**：
  - 基础主题提供四个标准法律页面的模板内容
  - 页面中使用占位符标记站点名称、联系方式等变量
  - 通过配置文件中的参数自动替换占位符
  - 子站点无需重新编写法律页面，只需填写相关配置参数
  - 支持多语言版本的法律页面模板
  - 所有法律页面默认包含最后更新日期

### 2.2 子站点 (Site Projects)

#### 2.2.1 站点组成
- 独立的 `config.toml` 或 `site-config.toml`
- 可选的局部覆盖模板 (`layouts/index.html`)。
- 站点静态资源（如 logo、特殊样式）。
- 存储 `content/` 和 `posts/` 等动态文章内容

#### 2.2.2 配置参数
- **必须包含的基本参数**：
  - `SITE_NAME`：站点名称（用于文件夹和仓库名）
  - `SITE_TITLE`：站点显示标题
  - `SITE_DESCRIPTION`：站点描述
  - `SITE_LANGUAGE`：站点语言代码（如 zh-cn, en-us）
- **GitHub仓库配置**：
  - `GITHUB_PRIVATE`：是否为私有仓库（true/false）
  - `GITHUB_BRANCH`：主分支名称（main 或 master）

#### 2.2.3 构建方式
```bash
hugo --config ../config/base-config.toml,site-config.toml
```
合并基础配置与个性化配置，生成最终站点。

#### 2.2.4 文件夹规范
- 站点文件夹与 Hugo Base Theme 文件夹同级
- 站点文件夹名称使用各站点 `config.toml` 中定义的站点名称
- 通过 sh 脚本自动创建该文件夹
- 站点文件夹支持独立运行所有 Hugo 有效的命令行操作

#### 2.2.5 版本控制
- 为每个站点单独初始化一个 Git 仓库
- 在初始化脚本中调用 GitHub CLI 创建对应的远程仓库
- GitHub 账户名使用 `harrison-ming`
- 仓库名称使用站点域名的主体部分（例如，对于 bbc.com，仓库名为 bbc）
- 自动设置初始提交并推送到远程仓库

## 3. 自动化工具

### 3.1 构建脚本 (build.sh)
- 指定站点名，自动组合配置文件并构建。

### 3.2 站点创建脚本 (newsite.sh)
- 快速创建新子站目录结构，并初始化必要文件。
- **环境检查功能**：
  - 验证 Hugo 是否已安装
  - 检查 GitHub CLI 是否已登录
  - 验证文件夹名称是否可用
- **内容初始化**：
  - 为每个站点创建统一的示例文章（hello-world.md）
  - 创建站点关于页面（about/_index.md）
  - 生成项目 README.md
  - 创建 .gitignore 文件
  - **法律页面处理**：
    - 自动从基础主题复制法律页面模板（Privacy Policy等四个页面）
    - 读取站点配置中的法律信息参数（站点名称、联系方式等）
    - 使用sed或其他工具替换法律页面中的占位符
    - 更新法律页面的最后修改日期为当前日期
    - 确保法律页面正确链接到站点菜单中
- **完成提示**：
  - 显示站点创建成功信息
  - 提供后续操作指南（预览站点、添加内容、构建发布等）

## 4. 目录结构示例

```plaintext
/base-theme/
  layouts/
  assets/
  theme.toml
  go.mod

/sites/
  site1/
    config.toml
    layouts/index.html
    static/
    content/

  site2/
    config.toml
    layouts/index.html
    static/
    content/

/build.sh
/base-config.toml
```

## 5. 技术要求与最佳实践

### 5.1 系统要求
- 需要 Hugo 版本 0.111+ 或兼容新版。
- 基础 Theme 必须是 Hugo Module 格式。
- 每个子站至少需要一份独立的 `config.toml`。
- 基础配置 (`base-config.toml`) 与子配置（`site-config.toml`）组合生成最终配置。
- 构建指令需指定 `--config` 参数明确多文件合并。

### 5.2 SEO优化要求
- 每个页面必须有唯一的标题和元描述
- 自动生成规范的 URL（canonical URL）
- 每个网站必须包含 sitemap.xml 文件
- 图片必须包含 alt 属性
- 主题必须支持结构化数据（Schema.org）
- 页面加载速度优化（合并CSS/JS，延迟加载）
- 基础配置需默认启用 robots.txt
- 内容创建时提供 SEO 最佳实践提示
- 自动优化内部链接结构

### 5.3 配置文件规范

本项目包含多种配置文件规范，以确保一致性和兼容性：

- [基础配置文件规范 (base-config.toml)](/Users/ming/Documents/HUGO/HugoBaseTheme/base-config.toml) - 所有子站点共享的基础设置
- [子站点配置文件规范 (site-config.toml)](/Users/ming/Documents/HUGO/HugoBaseTheme/site-config-spec.toml) - 子站点个性化配置模板

> 注意：详细规范请参考项目根目录下的相应文件

## 6. 最终目标

通过 Hugo Theme Factory 实现：

- 快速批量建站
- 低成本维护
- 高度可扩展
- 高质量输出
