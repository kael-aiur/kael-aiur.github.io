# Kael's Personal Website

Kael 的个人技术博客，使用 [Jekyll](https://jekyllrb.com/) 构建，由 GitHub Pages 托管。

## 切换主题

只需修改 `_config.yml` 中的一个配置项：

```yaml
theme: chirpy
```

当前支持：

- `chirpy`：功能完整的技术博客主题，也是线上默认主题。
- `minima`：Jekyll 官方的轻量主题。

主题适配配置位于 `_themes/`。新增主题时需要注册对应的 Gem 和适配配置，已有主题之间切换不需要修改其他文件。

## 本地预览

需要 Ruby 3.1 或更高版本（推荐与发布流程一致的 Ruby 3.4）。

```bash
bundle install
bundle exec ruby scripts/site serve
```

访问 <http://127.0.0.1:4000>。

## 发布

推送到 `master` 后，GitHub Actions 会读取 `_config.yml` 中的主题，完成构建、HTML 检查和 GitHub Pages 发布。
