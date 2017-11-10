---
layout: post
comments: true
categories: AsciiDoc
title: asciidoc最佳实践-maven插件
tags: asciidoc,maven,最佳实践
grammar_cjkRuby: true
author: kael
---

* content
{:toc}

## 前言

AsciiDoc是一种轻量型的标记语言，语法简单易用，兼容Markdown的同时，提供了更丰富的标记功能，非常适用于写电子文档，使用AsciiDoc
的时候，为了编写和维护方便，经常需要按照一定的规范组织目录结构，而发布的目录结构不一定和编写过程一致，因此本文主要是讨论我自己
在尝试使用AsciiDoc编写文档时的最佳实践。

目前只讨论使用maven插件搭建目录结构和发布的方式。

## 目录结构

```
- root
    -src
        - main
            - asciidoc
                - ask
                    ask.adoc
                - index.adoc
            - resources
                - images
                    - ask
                        - ask_1.png
    - target
        - book
    - pom.xml
```

* 根目录是`root`;
* 使用`src/main/asciidoc`作为源码目录，即`asciidoctor-maven-plugin`插件的默认源码目录;
* 将所有的资源文件放到`src/main/resources`目录下，如：图片的目录在`src/main/resources/images`目录下;
* `target`目录是默认输出目录，并配置将asciidoc编译的结果输出到`target/book`目录下;

## pom.xml配置

如下配置即可完全按照上面的目录结构生成最终的电子书。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>kael.demo</groupId>
    <artifactId>asciidoc</artifactId>
    <version>1.0-SNAPSHOT</version>

    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
        <maven.compiler.encoding>UTF-8</maven.compiler.encoding>
        
        <asciidoctorj.version>1.5.6</asciidoctorj.version>
        <asciidoctorj.diagram.version>1.5.4.1</asciidoctorj.diagram.version>
        <jruby.version>1.7.26</jruby.version>
    </properties>
    <build>
        <!-- 默认命令，配置后可以直接使用mvn编译 -->
        <defaultGoal>process-resources</defaultGoal>
        <plugins>
            <plugin>
                <groupId>org.asciidoctor</groupId>
                <artifactId>asciidoctor-maven-plugin</artifactId>
                <version>1.5.5</version>
                <executions>
                    <execution>
                        <id>output-html</id>
                        <phase>generate-resources</phase>
                        <goals>
                            <goal>process-asciidoc</goal>
                        </goals>
                    </execution>
                </executions>
                <dependencies>
                    <!-- Comment this section to use the default jruby artifact provided by the plugin -->
                    <dependency>
                        <groupId>org.jruby</groupId>
                        <artifactId>jruby-complete</artifactId>
                        <version>${jruby.version}</version>
                    </dependency>
                    <!-- Comment this section to use the default AsciidoctorJ artifact provided by the plugin -->
                    <dependency>
                        <groupId>org.asciidoctor</groupId>
                        <artifactId>asciidoctorj</artifactId>
                        <version>${asciidoctorj.version}</version>
                    </dependency>
                    <dependency>
                        <groupId>org.asciidoctor</groupId>
                        <artifactId>asciidoctorj-diagram</artifactId>
                        <version>${asciidoctorj.diagram.version}</version>
                    </dependency>
                </dependencies>
                <configuration>
                    <outputDirectory>${project.build.directory}/book</outputDirectory>
                    <sourceDocumentName>index.adoc</sourceDocumentName>
                    <sourceHighlighter>prettify</sourceHighlighter>
                    <backend>html</backend>
                    <preserveDirectories>false</preserveDirectories>
                    <requires>
                        <require>asciidoctor-diagram</require>
                    </requires>
                </configuration>
            </plugin>
        </plugins>
    </build>

</project>
```

## 编写规范

编写AsciiDoc文本推荐使用idea/WebStorm，安装AsciiDoc插件即可实施预览：

![]({{site.image_repo1}}/asciidoc_maven/AsciiDoc_1.png)

在编写时，所有的源码文档使用`.adoc`作为扩展名。

在文档中引用图片时，遵循如下规范：

* 在个源码文件的顶部定义图片根目录相对当前目录的相对路径
* 每个目录的图片在图片根目录下创建一个同名目录
* 每个源码文件引用的图片命名按照{源码文件名}_{序号递增}.png|...

如上面提到的目录结构，在`src/main/asciidoc/index.adoc`顶部定义图片根目录：

```
ifndef::imagesdir[:imagesdir: ../resources/images]
```

在`src/main/asciidoc/ask/index.adoc`顶部定义图片根目录：

```
ifndef::imagesdir[:imagesdir: ../../resources/images]
```

那么在引用图片的时候，可以按照如下方式：

```
image::ask/ask_1.png
```

> 在`src/main/asciidoc/index.adoc`中尽量不直接写内容，使用`include`指令组合各个章节即可。
> 这样定义的好处有几点：
> 
> * 无论是AsciiDoc的预览工具，还是最终编译发布的电子书，都可以完美看到图片，不会出现为了保证发布时图片不缺失，而放弃预览时看到图片的情况。
> * 各个目录的图片文件路径清晰，一旦需要做比较大的调整的时候，可以准确的找到所有文件对应的图片路径

## 预览

编写的过程，经常需要预览整个文档，这种情况推荐使用一个简单的静态http服务器，如`http-server`。

指定监听`target/book`目录即可，

```
$> http-server target/book -p 4001 -e html
```

每次修改完需要查看的时候，只需要使用`mvn clean process-resources`编译一次，就可以直接在浏览器预览整体效果了。

