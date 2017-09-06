---
layout: post
comments: true
categories: tomcat
title: 使用jmx监控tomcat
tags: jvisualvm,tomcat,jmx
grammar_cjkRuby: true
author: KAEL
---
    
* content
{:toc}

## 前言

在运行java应用的过程中，有时候会出现各种各样的服务器问题，或者因为我们的应用出现内存泄露等等，在开发环境中非常难重现，因此我们经常需要监控服务器的状态，
在Java中，提供了一种远程监控jvm进程的协议，叫JMX，官网介绍连接:[Monitoring and Management Using JMX](http://docs.oracle.com/javase/6/docs/technotes/guides/management/agent.html)

实际上每一个JVM进程都可以打开JMX监听功能，只需要在JAVA的启动参数中增加几个参数即可。

当远程应用打开JMX监听功能之后，我们就可以在本地使用JConsole或者jvisualvm连接上这个应用并且查看应用的运行情况了。

JConsole和jvisualvm在JDK中都已经自带了，两者关系是jvisualvm可以认为是JConsole的升级版，功能更加强大，优先使用。

## Tomcat对JMX的支持

想要使用JMX远程监控tomcat，只需要在tomcat的启动参数中添加jxm监听的参数即可。

### 免验证监控

使用免验证监控，可以通过匿名的方式远程连接tomcat进行监控，此时需要添加的监控参数如下：

```bash
-Dcom.sun.management.jmxremote
-Dcom.sun.management.jmxremote.port=%my.jmx.port%
-Dcom.sun.management.jmxremote.ssl=false
-Dcom.sun.management.jmxremote.authenticate=false
```

建议在`${tomcat}/bin`目录下添加`setenv.sh`(windows系统则添加`setenv.bat`)：

**setenv.bat**

```bash
set CATALINA_OPTS= %CATALINA_OPTS% -Dcom.sun.management.jmxremote
set CATALINA_OPTS= %CATALINA_OPTS% -Dcom.sun.management.jmxremote.port=10001
set CATALINA_OPTS= %CATALINA_OPTS% -Dcom.sun.management.jmxremote.ssl=false
set CATALINA_OPTS= %CATALINA_OPTS% -Dcom.sun.management.jmxremote.authenticate=false
```

**setenv.sh**

```bash
CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote"
CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.port=10001"
CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.ssl=false"
CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.authenticate=false"
# Linux下需要特殊指定的参数，window下会自动计算
CATALINA_OPTS="$CATALINA_OPTS -Djava.rmi.server.hostname=${ip}"
```

> **注意:** 在linux下的服务，还需要增加`-Djava.rmi.server.hostname`这个参数。
> 因为在jconsole/jvisualvm连接远程服务的时候，如果没有指定这个参数，会通过linux的`hostname -i`命令获取到远程服务的名称或地址，
> 然后进行连接，一般情况下这个命令会返回127.0.0.1，此时jconsole/jvisualvm会连接到本地，解决会被拒绝，设置了这个参数后，服务端会
> 返回这个地址，所以会直接连接到这台服务器。


重启tomcat即可。

然后在JConsole/jvisualvm里输入远程连接地址：

```bash
%IP%:10001
```

即可连接。

### 验证用户身份监控

有些时候我们需要长期打开JMX监控，为了安全起见，必须是经过验证的用户才允许连接，这个时候配置稍微麻烦点。

将`setenv.sh|.bat`修改为如下：

**setenv.bat**

```bash
set CATALINA_OPTS= %CATALINA_OPTS% -Dcom.sun.management.jmxremote
set CATALINA_OPTS= %CATALINA_OPTS% -Dcom.sun.management.jmxremote.port=10001
set CATALINA_OPTS= %CATALINA_OPTS% -Dcom.sun.management.jmxremote.ssl=false
set CATALINA_OPTS= %CATALINA_OPTS% -Dcom.sun.management.jmxremote.authenticate=true
set CATALINA_OPTS= %CATALINA_OPTS% -Dcom.sun.management.jmxremote.password.file=../conf/jmxremote.password
set CATALINA_OPTS= %CATALINA_OPTS% -Dcom.sun.management.jmxremote.access.file=../conf/jmxremote.access
```

**setenv.sh**

```bash
CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote"
CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.port=10001"
CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.ssl=false"
CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.authenticate=true"
CATALINA_OPTS="$CATALINA_OPTS -Djava.rmi.server.hostname=${ip}"
CATALINA_OPTS= %CATALINA_OPTS% -Dcom.sun.management.jmxremote.password.file=../conf/jmxremote.password
CATALINA_OPTS= %CATALINA_OPTS% -Dcom.sun.management.jmxremote.access.file=../conf/jmxremote.access
```

然后在`%{tomcat}/conf`目录下添加两个文件：

`jmxremote.access`

```bash
# 用户名 用户权限
monitorRole readonly
controlRole readwrite
```

`jmxremote.access`

```bash
# 用户名 用户密码
monitorRole tomcat
controlRole tomcat
```

> **注意：** `jmxremote.access`文件对于启动tomcat的用户来说必须只有只读权限。

然后重新启动，此时需要输入用户名和密码：

```text
controlRole/tomcat
controlRole/tomcat
```

才可以连接。



