---
layout: post
comments: true
categories: linux
title: ubuntu上安装xrdp支持windows远程桌面连接
tags: 标签1,标签2,标签3
grammar_cjkRuby: true
author: kael
---

* content
{:toc}

## 命令

1. 安装xrdp

```
$> sudo apt-get install xrdp
```

2. 安装vnc4server

```
$> sudo apt-get install vnc4server
```

3. 安装xfce4

```
$> sudo apt-get install xubuntu-desktop
```

4. 终端输入

```
$> echo "xfce4-session" > ~/.xsession
$> sudo service xrdp restart
```

5. windows使用远程桌面(mstsc)连接
