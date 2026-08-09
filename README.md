# Kael's Personal Website

Kael 的个人技术博客，使用 [Jekyll](https://jekyllrb.com/) 和
[Chirpy](https://github.com/cotes2020/jekyll-theme-chirpy) 构建，由 GitHub Pages 托管。

## 本地预览

需要 Ruby 3.1 或更高版本（推荐与发布流程一致的 Ruby 3.4）。

```bash
bundle install
bundle exec jekyll serve
```

访问 <http://127.0.0.1:4000>。

## 发布

推送到 `master` 后，GitHub Actions 会完成构建、HTML检查和GitHub Pages发布。
