---
layout: post
comments: true
categories: 工具使用
title: CentOS源码安装git
tags: git,Linux,CentOS
author: Kael
grammar_cjkRuby: true
---

* content
{:toc}

## 前言

Centos 6.5默认安装的是git 1.7.X 版本，使用过程中会有一些奇怪的问题，对于用户名、密码支持不是很友好。
将Centos6.5上的git更新到2.0.5。

## 安装

* 安装编译git时需要的包

```
# yum install curl-devel expat-devel gettext-devel openssl-devel zlib-devel
# yum install  gcc perl-ExtUtils-MakeMaker
```

* 删除已有的git

```
# yum remove git
```


* 下载git源码

```
# cd /usr/src
# wget https://www.kernel.org/pub/software/scm/git/git-2.0.5.tar.gz
# tar xzf git-2.0.5.tar.gz
```

* 编译安装

```
# cd git-2.0.5
# make prefix=/usr/local/git all
# make prefix=/usr/local/git install
# echo "export PATH=$PATH:/usr/local/git/bin" >> /etc/bashrc
# source /etc/bashrc
```

* 检查一下版本号

```
# git --version
git version 2.0.5
```

## 转载连接

本文转载自：

[http://blog.sina.com.cn/s/blog_3fe961ae0102w9ui.html](http://blog.sina.com.cn/s/blog_3fe961ae0102w9ui.html)