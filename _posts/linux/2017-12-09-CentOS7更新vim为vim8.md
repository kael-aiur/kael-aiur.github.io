---
layout: post
comments: true
categories: cate
title: CentOS7 更新vim为vim8
tags: Cent OS 7,vim8,update vim
grammar_cjkRuby: true
author: KAEL
---

* content
{:toc}

## 添加VIM最新仓库

```
# curl -L https://copr.fedorainfracloud.org/coprs/mcepl/vim8/repo/epel-7/mcepl-vim8-epel-7.repo -o /etc/yum.repos.d/mcepl-vim8-epel-7.repo
```

## 更新VIM

```
yum update vim*
```