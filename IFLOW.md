# 项目上下文文件 (IFLOW.md)

## 项目概述

这是一个基于 Jekyll 构建的个人技术博客网站，由 GitHub Pages 托管。网站名为"九千万代码的梦想"，作者是 Kael (kael.peng@gmail.com)。该网站使用了 [Gaohaoyang](https://github.com/Gaohaoyang/gaohaoyang.github.io) 的 Jekyll 主题。

项目内容涵盖了多种技术领域，包括 AI 编程工具、Linux、Docker、数据库、Java、前端开发等技术文章，以及一些键盘和硬件相关的说明文档。

## 项目结构

```
kael-aiur.github.io/
├── _config.yml          # Jekyll 配置文件
├── _includes/           # 可重用的 HTML 片段
├── _layouts/            # 页面布局模板
├── _posts/              # 博客文章目录（按类别组织）
├── _sass/               # SCSS 样式文件
├── index.md             # 首页内容
├── README.md            # 项目说明
├── CNAME                # 自定义域名配置
├── static/              # 静态资源（CSS、JS、图片）
└── ...
```

## 主要功能特点

- 响应式设计，支持移动设备访问
- 文章分类浏览功能
- 支持代码高亮显示
- 包含 Mermaid 图表支持
- 评论系统（配置了 Disqus、多说或友言等选项）
- 导航菜单和页脚信息

## 技术栈

- **静态网站生成器**: Jekyll
- **前端框架**: Bootstrap 3
- **样式**: SCSS, 自定义 CSS
- **代码高亮**: Highlight.js
- **托管平台**: GitHub Pages

## 主要配置

- **Markdown 解析器**: kramdown
- **主题**: 基于 Gaohaoyang 的 Jekyll 主题
- **永久链接格式**: `/:categories/:title.html`
- **图片资源库**: 配置了 image_repo1 用于存储图片

## 开发约定

- 博客文章使用 Markdown 格式编写
- 文章文件名格式为 `YYYY-MM-DD-title.md`
- 文章头部包含分类、标签、标题等元数据
- 使用 Liquid 模板语法进行动态内容渲染

## 构建和运行

由于该项目部署在 GitHub Pages 上，通常不需要本地构建，但本地开发时可以使用以下命令：

```bash
# 安装依赖
gem install jekyll bundler

# 本地运行预览
bundle exec jekyll serve

# 构建静态文件
bundle exec jekyll build
```

## 文件说明

- `_config.yml`: 站点配置，包括标题、描述、社交链接等
- `_layouts/`: 定义了页面模板（default, frontpage, page, post）
- `_includes/`: 包含可重用组件（header, footer, comments 等）
- `_posts/`: 存放博客文章，按类别组织在子目录中
- `static/`: 静态资源，如 CSS、JavaScript 和图片文件