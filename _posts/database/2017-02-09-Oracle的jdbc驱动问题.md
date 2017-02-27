---
layout: post
comments: true
categories: 数据库
title: Oracle的jdbc驱动问题
tags: Oracle,JDBC,maven
author: Kael
grammar_cjkRuby: true
---

* content
{:toc}

## 前言

最近为了测试leap在Oracle的使用情况，特意安装了Oracle来测试，不过由于比较喜欢maven管理工程，但是Oracle的驱动包居然不能在maven中心库找到，也是累，因为Oracle使用的授权协议，Maven的中央库不被允许托管其artifacts，所以我们只能把驱动包安装到本地了。

## 安装

在Oracle的安装目录中下，找到所有驱动包：

```
{ORACLE_HOME}\product\11.2.0\dbhome_1\jdbc\lib
```

这个包下有如下几个包：

```
ojdbc5.jar
ojdbc5_g.jar
ojdbc5dms.jar
ojdbc5dms_g.jar
ojdbc6.jar
ojdbc6_g.jar
ojdbc6dms.jar
ojdbc6dms_g.jar
simplefan.jar
```

各个包的作用可以看官网：[http://www.oracle.com/technetwork/database/enterprise-edition/jdbc-112010-090769.html](http://www.oracle.com/technetwork/database/enterprise-edition/jdbc-112010-090769.html)

一般来说，jdk5和以下的版本我们使用`ojdbc5`的驱动，jdk6和以上的版本我们使用`ojdbc6`的驱动，这里我们使用`ojdbc6`的驱动，使用如下指令安装：

```
mvn install:install-file -Dfile={Path/to/your/ojdbc.jar} -DgroupId=com.oracle.jdbc -DartifactId=ojdbc6 -Dversion=${your jdbc version} -Dpackaging=jar
```

上面的Maven命令会把jar文件安装到本地的Maven仓库，DgroupId和DartifactId参数分别指定安装时的groupId和artifactId，可以随便指定，但肯定最好是和jar包的版本尽量一致的，避免以后混淆。

安装完成之后，在`pom.xml`中添加如下依赖即可：

```xml
<dependency>
    <groupId>com.oracle.jdbc</groupId>
    <artifactId>ojdbc6</artifactId>
    <version>${your jdbc version}</version>
</dependency>
```