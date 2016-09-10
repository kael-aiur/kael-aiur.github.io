---
layout: post
comments: true
categories: tomcat源码解读
title: 1、使用maven搭建tomcat开发工程
tags: tomcat,maven,源码
grammar_cjkRuby: true
---

## 前言

其实很早前就想读一下tomcat的源码了，无奈的是tomcat的工程一直是使用ant构建的，ant是比较早前的构建工具了，甚至可以说是古老的构建工具，我并没有用过，也不熟悉，所以一直都没办法构建一个开发环境来读tomcat的源码。

后来在网上查了一些资料，现在确实有人使用maven来构建tomcat的开发环境，不过基本上都是把整份源码拷贝过来，再配合tomcat的发布包来运行起来的，对于我这种重度强迫症患者，这种构建方式显然无法接受，所以决定自己来构建一个标准的maven工程开发环境，简单的说，就是手动把tomcat从ant的结构转换成maven结构。

在开始搭建工程环境之前，我们先要确定一下本文目标：

* 基于解读源码的目的搭建工程，只要能吧tomcat源码完整拷贝过来并运行起来即可，不需要考虑打包的问题
* 解读tomcat源码，可以暂时忽略tomcat的单元测试，所以本文不迁移tomcat的单元测试

最终的成果：

一个可以直接在开发环境运行的maven工程。

另外给自己留个坑：再补一篇博客，记录如何把tomcat的单元测试也迁移过来。

## 成果

开始之前，先看看最后搭建的环境吧：

![enter description here][1]

考虑到tomcat本身有一些模块依赖，如：jdbc、lite等，在这次迁移中我们不考虑迁移这些模块，但是要考虑未来迁移，所以采用聚合模块的方式，这个创建的工程作为母工程，tomcat的源码工程作为core的子工程。

这个环境基于TOMCAT_8_0_37，使用Intellij idea构建，源码已经上传到github，不想自己手动搭建的同学可以直接clone我的工程，工程地址[https://github.com/kael-aiur/tomcat80-maven/](https://github.com/kael-aiur/tomcat80-maven/)，也可以直接使用下面的git仓库地址clone:

git协议：

```
git@github.com:kael-aiur/tomcat80-maven.git
```

https协议：

```
https://github.com/kael-aiur/tomcat80-maven.git
```

## 工程搭建

### 创建简单的maven工程

搭建环境之前，我们需要创建一个简单的maven工程，可以通过maven指令创建，也可以通过IDE提供的插件创建，只要一个简单的工程结构即可，不需要使用模板，pom.xml的内容如下：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>kael.tomcat</groupId>
    <artifactId>tomcat-parent</artifactId>
    <version>1.0-SNAPSHOT</version>
    <modules>
        <module>core</module>
    </modules>
    <packaging>pom</packaging>

</project>
```

这里我们指定母工程的`packaging`为`pom`，表示这个工程只用来构建依赖。

接下来我们给母工程创建一个子模块，模块的根目录就在母工程根目录的core文件夹下，模块的`pom.xml`源码如下：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <parent>
        <artifactId>tomcat-parent</artifactId>
        <groupId>kael.tomcat</groupId>
        <version>1.0-SNAPSHOT</version>
    </parent>
    <modelVersion>4.0.0</modelVersion>

    <artifactId>tomcat-core</artifactId>
    <build>
        <finalName>Tomcat8.0</finalName>
        <resources>
            <resource>
                <directory>src/main/java</directory>
                <includes>
                    <include>**/*.xml</include>
                    <include>**/*.dtd</include>
                    <include>**/*.properties</include>
                </includes>
            </resource>
        </resources>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>2.3</version>

                <configuration>
                    <encoding>UTF-8</encoding>
                    <source>1.8</source>
                    <target>1.8</target>
                </configuration>
            </plugin>
        </plugins>
    </build>

    <dependencies>
        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>4.12</version>
            <scope>test</scope>
        </dependency>
        <!-- https://mvnrepository.com/artifact/org.easymock/easymock -->
        <dependency>
            <groupId>org.easymock</groupId>
            <artifactId>easymock</artifactId>
            <version>3.4</version>
            <scope>test</scope>
        </dependency>

        <dependency>
            <groupId>ant</groupId>
            <artifactId>ant</artifactId>
            <version>1.7.0</version>
        </dependency>
        <dependency>
            <groupId>wsdl4j</groupId>
            <artifactId>wsdl4j</artifactId>
            <version>1.6.2</version>
        </dependency>
        <dependency>
            <groupId>javax.xml</groupId>
            <artifactId>jaxrpc</artifactId>
            <version>1.1</version>
        </dependency>
        <dependency>
            <groupId>org.eclipse.jdt.core.compiler</groupId>
            <artifactId>ecj</artifactId>
            <version>4.5.1</version>
        </dependency>
        <dependency>
            <groupId>javax.servlet</groupId>
            <artifactId>javax.servlet-api</artifactId>
            <version>3.1.0</version>
        </dependency>
    </dependencies>

</project>
```

这里我们需要注意，我们添加了`<build>`元素下的`<resources>`元素，并且指定资源包含了`*.xml`、`*.dtd`、`*.properties`三种后缀的文件，这个是因为tomcat的源码包中确实有这些文件，并且在启动过程需要读这些文件，因此必须包含进来，实际上，tomcat的源码包里还包含了某些`html`文件，但是目前我并没有发现这些文件的用途，所以先不指定打包进来，等到遇到问题了，我们就能真正发现这些文件的用途，那个时候再指定打包进来会更有利于我们理解。

同时，我们还给tomcat的源码工程添加了很多依赖，这些依赖都是tomcat需要使用的，直接依赖进来即可，不多做解释了。

OK，现在基本的工程环境已经搭建完成了，接下来准备迁移tomcat的源码。

### 源码迁移

我们需要先下载tomcat的源码，可以通过git下载，svn下载，或者直接在tomcat的官网下载，下载之后解压，可以看到tomcat的源码工程目录如下：

![enter description here][2]

这个工程目录有很多东西是我们开发阶段并不需要的，我们只关注开发过程需要的目录。

```
java //这个是tomcat源码目录

test // 这个是tomcat单元测试目录，需要关注，但本次迁移先不迁移测试代码

conf // tomcat的默认配置，要启动tomcat需要大量的配置，所以这部分默认配置也需要迁移

modules // 这个是tomcat的一些模块目录，这个模块目录下的工程都是用maven构建的，本次搭建不迁移，但是未来需要迁移也很好做

webapps //这个目录是tomcat的样例web应用，我们在读tomcat源码的时候，需要一些web工程来辅助，就直接用这里的web工程就好了
```

现在我们已经知道哪些目录是需要迁移的，那么迁移对应的是maven中的哪个目录呢，接着往下走吧。

* 迁移源码

首先是源码，在java目录下有两个目录，`javax`和`org`，把这两个文件夹直接拷贝到maven工程的`src/main/java`目录下，源码就迁移完成了。

* 迁移配置

接下来迁移配置，我们把conf文件夹整个拷贝到`src/main/resources`目录下，配置迁移就完成了。

* 迁移web工程

把webapps整个目录也拷贝到`src/main/resources`下即可，值得注意的是，这里其实并不需要一定拷贝到这个目录下，也可以拷贝到其他目录，在运行tomcat的时候，指定`appBase`的路径即可，当然为了我们之后方便代码迁移什么的，还是直接放到这个目录下最简单。

到这里之后，tomcat其实已经可以运行了，但是访问web应用的时候还是会抛出异常，因为没有办法解析jsp。

* 添加jsp解析器的web片段

所以我们还需要手动添加一些内容，tomcat8支持了servlet3.0的标准，因此可以使用web片段来增强web应用的能力，实际上tomcat8也是采用这种方式来扩展对jsp的支持的，我们在`src/main/resources`下创建`META-INF`目录，并在`META-INF`目录下创建一个web片段的配置文件`web-fragment.xml`，配置内容如下：

```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<web-fragment xmlns="http://xmlns.jcp.org/xml/ns/javaee"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee
                      http://xmlns.jcp.org/xml/ns/javaee/web-fragment_3_1.xsd"
              version="3.1"
              metadata-complete="true">
    <name>org_apache_jasper</name>
    <distributable/>
</web-fragment>
```

创建完成之后，我们需要让这个片段生效，有两种方式，一种是直接在这个片段里配置启动类，这个是servlet3.0的标准支持的，不清楚怎么配置的可以自行谷歌，这里我们采用tomcat打包的时候使用的配置方式，添加service类配置。

在`META-INF`目录下创建`services`目录，在`services`目录下创建一个文件，文件名为`javax.servlet.ServletContainerInitializer`，并且指定文件内容为：

```
org.apache.jasper.servlet.JasperInitializer
```

这种方式是jdk7以后提供的类加载器标准，在这样指定的目录下配置之后，会使用`ServiceLoader`加载文件名指定的接口，并且实例化文件内容指定的类，要求实例化的类必须实现文件名指定的类。

现在我们本次迁移的目标已经全部迁移完成。

### 运行tomcat

迁移完成之后，现在我们需要开始运行tomcat了。

tomcat的启动类是`org.apache.catalina.startup.Bootstrap`，我们需要从这个类启动，但是启动的时候tomcat需要一些启动参数，不同的ide有不同的配置方式，这里我用idea的配置如下：

![enter description here][3]

这里特别需要注意的是VM options这项，配置的是启动参数，参数内容如下：

```
-Dcatalina.home=target/classes/ 
-Dcatalina.base=target/classes/ -Djava.endorsed.dirs=${catalina.base}endorsed 
-Djava.io.tmpdir=${catalina.base}temp -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager 
-Djava.util.logging.config.file=${catalina.base}conf/logging.properties
```

这里参数的`catalina.home`和`catalina.base`我指定了`target/classes/ `，这个目录是maven编译的默认输入目录，我们之前配置的源码和资源最终都会输出到这里，所以需要指定这个目录才能读到这些配置。

OK！到了这里，我们已经可以开始启动tomcat了，运行你配置好的main函数，在浏览器中输入`http://localhost:8080`看看吧：

![enter description here][4]

当你看到这个结果的时候，说明环境已经搭建完成了。

## 总结

不知道为什么，tomcat官方的开发团队一直都不愿意把tomcat从ant迁移到maven上来。

在这次搭建过程中，其实我遇到了很多问题，调试代码，检查配置，对照tomcat的源码工程和发布包一步一步调试出来的，现在做完之后重新总结一次，这个迁移并不困难，后续的博客我再补充单元测试迁移和打包迁移吧。

  [1]: /static/img/blog/tomcat-maven-project/images/tomcat_maven_project.png "搭建完成后的工程目录"
  [2]: /static/img/blog/tomcat-maven-project/images/tomcat_source_project.png "tomcat源码工程目录"
  [3]: /static/img/blog/tomcat-maven-project/images/idea_running_config.png "运行配置"
  [4]: /static/img/blog/tomcat-maven-project/images/tomcat_portal.png "tomcat首页"