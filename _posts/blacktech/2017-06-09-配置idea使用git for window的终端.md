---
layout: post
comments: true
categories: 黑科技
title: 配置idea使用git for window的终端
tags: 标签1,标签2,标签3
grammar_cjkRuby: true
author: kael
---

* content
{:toc}

## 前言

在window下，使用git的时候，可以安装[git for windows](https://git-scm.com/downloads)，安装后里边自带的git-bash终端可以使用linux的指令，
并且包含了很多linux下常用的工具如：curl,ssh等，真的非常好用。

但是在使用idea做应用开发的时候，有时候打开需要打开终端做操作，使用git-bash的话，体验不是很好，因为会单独打开一个窗口。而我们更希望是在终端内置的命令行。

## 使用bash

实际上，git-bash只是一层包装而已，真正使用的是${git for windows}/bin/bash.exe这个工具，git-bash是在bin/bash.exe之前执行了一些脚本，
设置了一些环境变量而已，因此我们可以把idea的终端设置为bin/base.exe这个工具，这个时候会发现，不会单独打开一个窗口了，而是内置集成了。但是由于缺少
git-bash执行的一些脚本，所以我们需要手动添加设置这部分脚本。

## 配置bash

在`${user}`这目录下创建两个文件：

* `.bash_profile`
* `.bashrc`

文件内容如下：

**.bash_profile**

```bash
if [ -f ~/.bashrc ]; then . ~/.bashrc; fi
```

**.bashrc**

```bash
alias ls='ls -F --color=auto --show-control-chars' # 使用ls命令的时候加上颜色
export LC_ALL=zh_CN.UTF-8 # 设置终端打开的编码

# 以下是maven命令简化
alias mct="mvn clean test"
alias mvn_test="mvn clean test"
alias mis="mvn clean install -Dmaven.test.skip=true -Dmaven.javadoc.skip=true"
alias mvn_install_skip="mvn clean install -Dmaven.test.skip=true -Dmaven.javadoc.skip=true"
alias mcd="mvn clean deploy -Dmaven.test.skip=true -Dmaven.javadoc.skip=true"
alias mvn_package_prod="mvn clean package -Pprod -Dmaven.test.skip=true -Dmaven.javadoc.skip=true"
alias mvn_package_dev="mvn clean package -Pdev -Dmaven.test.skip=true -Dmaven.javadoc.skip=true"
alias mvn_package_local="mvn clean package -Plocal -Dmaven.test.skip=true -Dmaven.javadoc.skip=true"
alias mvn_dependency_tree="mvn dependency:tree"
alias mvn_dependency_sources="mvn dependency:sources"
# 以下是两个发布命令，需要按实际情况修改变量
alias mvn_deploy_${profile}_snapshot="mvn clean deploy -DaltDeploymentRepository=bingo-maven-repository-snapshots::default::${snapshot_url} -Dmaven.test.skip=true -Dmaven.javadoc.skip=true"
alias mvn_deploy_${profile}_release="mvn clean deploy -DaltDeploymentRepository=bingo-maven-repository-releases::default::${release_url} -Dmaven.test.skip=true -Dmaven.javadoc.skip=true"
```

这样配置之后就可以在命令行终端使用别名了。