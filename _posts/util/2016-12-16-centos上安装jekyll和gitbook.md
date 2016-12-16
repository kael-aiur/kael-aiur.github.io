---
layout: post
comments: true
categories: 工具使用
title: centos上安装jekyll和gitbook
tags: linux,jekyll,gitbook
author: Kael
grammar_cjkRuby: true
---

* content
{:toc}

## 前言

使用jekyll和gitbook有一段时间了，最近用来更新leap框架的官网，发现有一点使用上比较麻烦， 那就是gitbook和github都是墙外，访问速度略慢略慢，于是就想利用jekyll和gitbook编译得到的静态网页组合在公司内部搭建一个官网，但是这样做相当麻烦每次修改完都得重新build然后覆盖旧的编译结果，所以就自己做了一个自动编译服务，先上github地址：

[https://github.com/kael-aiur/jekyll-gitbook-builder](https://github.com/kael-aiur/jekyll-gitbook-builder)

这个自动编译服务依赖的软件如下：

* git服务(github或gitlab)
* git
* jdk
* jekyll
* gitbook

整个自动编译的原理比较简单：

1. 将gitbook和jekyll的源码push到github上
2. 利用github的webhooks推送通知到自动编译服务
3. 自动编译服务调用git指令更新到最新的代码
4. 自动编译服务调用jekyll和gitbook的指令编译出静态文件
5. 自动编译服务将静态文件拷贝到指定目录
6. 利用web容器将静态文件的目录以网站的方式运行

整个原理比较简单，技术也没什么难度，但是比较麻烦的是安装整个依赖环境，本文就是为了记录这个依赖环境的安装过程写的。

本文使用的操作系统是centos7

## 安装依赖

首先，git服务直接用已有的就行了，github或者公司内部安装的gitlab都行，就不需要安装了。

> **注意：** 以下的安装为了避免出现问题，强烈建议使用root用户进行安装。

### 安装git

安装git之前先看看是否已经安装了：

```
$> git --version
-bash: git: command not found
```

说明还没有安装，如果出现版本号：

```
$> git --version
git version 2.8.4.windows.1
```

则说明已经安装了。

git的安装比较简单，一个指令搞定：

```
$> yum install git
```

等待依赖解析完成输入y确认安装即可。

安装完之后我们再确认一下：

```
$> git --version
git version 1.8.3.1
```

ok，安装成功。

### 安装jdk

安装jdk的方式也比较简单，先检查一下是否已经安装：

```
$> java -version
-bash: java: command not found
```

这里安装jdk有两种，一种是Oracle官方的jdk，另一种是linux平台的open jdk，装哪种都行，不过要求jdk8或以上的版本，这里为了简单起见，我们安装open jdk就好了。

```
$> yum install java-1.8.0-openjdk
```

等待解析依赖，输入y确认安装即可。

安装完成后我们确认一下：

```
$> java -version
openjdk version "1.8.0_111"
OpenJDK Runtime Environment (build 1.8.0_111-b15)
OpenJDK 64-Bit Server VM (build 25.111-b15, mixed mode)
```

安装成功！

### 安装jekyll

从这里开始，安装起来会比较麻烦，jekyll本身依赖的内容也很多：

* Ruby(对j需要包含开发包，对jekyll 2需要v1.9.3以上版本，对jekyll 3需要v2以上版本)
* RubyGems
* 只能在Linux，Unix或macOS操作系统上（注意，这里经过我实验，其实在window上安装了git的shell之后也能在git的shell中使用）
* NodeJs
* Python 2.7

每一个依赖都得安装。

#### 安装ruby

先检查一下ruby是否已经安装：

```
$> ruby -v
-bash: ruby: command not found
```

没安装，使用如下指令安装：

```
$> yum install ruby-devel
```

> **注意：** 这里必须安装`ruby-devel`，如果使用`yum install ruby`也能安装但是不是开发包，会缺少jekyll需要的组件。

安装完成之后再检查一下：

```
$> ruby -v
ruby 2.0.0p648 (2015-12-16) [x86_64-linux]
```

安装成功！

另外说明一下，`ruby-devel`安装完成之后，RubyGems也自动安装了。所以我们不用单独安装RubyGems，

```
$> gem -v
2.0.14.1
```

如果没有安装的话，可以看下[官网的安装教程](https://rubygems.org/pages/download)

#### 安装nodejs

先检查有没有安装：

```
node --version
-bash: node: command not found
```

linux上安装nodejs感觉挺麻烦的，不明白为什么nodejs这么火不做成源，可以参考另一篇博客[CentOS安装nodejs](/nodejs/CentOS安装nodejs.html)

#### 安装Python

其实在安装git的时候，由于git依赖Python，因此我们的Python已经安装好了，直接检查一下：

```
$> python --version
Python 2.7.5
```

#### 安装jekyll

终于把jekyll的依赖全部安装好了，开始安装我们的正主jekyll。

当然，安装前按惯例检查一下：

```
$> jekyll -v
-bash: jekyll: command not found
```

没有安装，那么我们安装一下，jekyll的安装其实很简单：

```
$> gem install jekyll
```

由于墙的问题，这个安装过程也会等很久，耐心等待吧。

安装完成之后，检查一下：

```
$> jekyll -v
jekyll 3.1.6
```

安装成功。


但是现在还不能直接使用jekyll的功能，需要构建网站还需要jekyll的两个插件：

```
$> gem install jekyll-sitemap
$> gem install jekyll-feed
```

这两个插件的安装也需要等比较长的时间，安装完成之后jekyll就可以使用了。


### 安装gitbook

先检查一下gitbook是否已经安装：

```
$> gitbook --version
-bash: gitbook: command not found
```

前面已经安装好jekyll之后，gitbook相关的依赖其实也全部安装好了，现在我们只需要一个命令即可安装gitbook:

```
$> npm install gitbook-cli -g
```

> 这里同样强烈建议使用root用户进行安装。

同样的，墙的问题，需要比较漫长的等待。

完成之后再检查一下：

```
$> gitbook --version
CLI version: 2.3.0
GitBook version: 3.2.2
```

安装成功。


### 安装自动部署服务

到这里gitbook和jekyll都已经安装完成，在这里我们顺便把自动部署服务也安装了吧。

#### 安装maven

由于自动部署服务需要maven编译打包，所以我们先安装maven吧。

首先检查是否已经安装：

```
$> mvn -v
-bash: mvn: command not found
```

没有安装，那么安装一下：

```
$> yum install maven
```

安装完成之后在检查一下：

```
[root@localhost node-v6.9.1]# mvn -v            
Apache Maven 3.0.5 (Red Hat 3.0.5-17)
Maven home: /usr/share/maven
Java version: 1.8.0_111, vendor: Oracle Corporation
Java home: /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.111-2.b15.el7_3.x86_64/jre
Default locale: en_US, platform encoding: UTF-8
OS name: "linux", version: "3.10.0-327.el7.x86_64", arch: "amd64", family: "unix"
```

安装成功。

#### 编译部署服务

首先使用git命令把服务的源码下载到本地。

```
$> git clone https://github.com/kael-aiur/jekyll-gitbook-builder.git
```

进入源码目录并用maven打包服务：

```
$> cd jekyll-gitbook-builder
$> mvn clean package
```

打包完成之后，将编译的结果拷贝到/opt目录下：

```
$> mv target/jsw/jekyll-gitbook /opt/
```

现在我们先用git把jekyll的工程和gitbook的工程从git服务上拉到本地，并且切换到我们需要用来构建网站的分支上。

```
$> git clone ${jekyll_repo}
$> git clone ${gitbook_repo}
```

工程复制完成之后，把本地的两个目录都切换到我们准备用来构建网站的分支。

```
$> git checkout ${branch}
```

然后根据自动编译服务的源码中的`README.md`说明修改自动编译服务的配置即可。

最后，在git服务上给工程添加webhook，使得我们push代码到git服务上之后自动构建服务可以收到git服务的推送消息即可。