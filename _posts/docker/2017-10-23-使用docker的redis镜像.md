---
layout: post
comments: true
categories: docker
title: 使用docker的redis镜像
tags: docker,redis,镜像
grammar_cjkRuby: true
author: kael
---

* content
{:toc}

## 前言

docker的官方镜像提供了redis的镜像，为了方便自己随时随地需要的使用，就学习一下，顺便记录下来。

参考[Docker官方Redis镜像](https://hub.docker.com/_/redis/)

## 准备工作

* 一台linux机器（我用windows10自带的hyper-v装了个虚拟机）
* 安装docker

## 获取redis镜像

一行命令搞定：

```
$> docker pull redis
```

> **说明：** docker的官方镜像都可以在[Docker Hub](https://hub.docker.com/)上找到，这里会自动从[Docker Hub](https://hub.docker.com/)
> 上找到对应的镜像并下载。

下载完成之后，可以使用如下命令查看镜像：

```
$> docker images

REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
redis               latest              1fb7b6c8c0d0        6 days ago          107MB (1)
oraclelinux         latest              6c33a25f4a29        2 weeks ago         229MB
elasticsearch       latest              d1ac13423d3c        5 weeks ago         580MB
hello-world         latest              1815c82652c0        4 months ago        1.84kB
```

> **(1).** 这个就是我们刚刚获取的镜像。

## 运行redis镜像

```
$> docker run --name my-redis -d redis
7dabbc56e3514e9ba1705d6c6ec180e603ceff7e6011f7915ef3b0f1f5b05b35
```

启动后可以查看redis运行的信息：

```
$> docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
7dabbc56e351        redis               "docker-entrypoint..."   35 minutes ago      Up 35 minutes       6379/tcp            my-redis
```

## 连接redis

在虚拟机中，没有ui工具可以连接redis，要测试redis是否正常服务，需要安装redis的命令行客户端工具(redis-cli)。

### 安装redis-cli

```
$> wget http://download.redis.io/releases/redis-2.8.17.tar.gz
$> tar xzf redis-2.8.17.tar.gz
$> cd redis-2.8.17
$> make
```

> **注意:** 这里是下载redis源码进行编译，编译后在`src`目录下就会有`redis-cli`工具。
> 源码编译过程需要使用gcc，如果没有安装的话请先用yum或者apt-get安装gcc。
> 如：`yum install gcc`或`apt-get install gcc`。

编译完成后：

```
$> cd src
$> ./redis-cli
Could not connect to Redis at 127.0.0.1:6379: Connection refused
not connected> 
```

说明已经编译完成，可以使用了。

由于没有参数的情况下，默认是连接`127.0.0.1:6379`，这里连接失败了，先退出cli：

```
not connected> exit
```

## 连接docker-redis

现在我们需要知道docker中的redis的IP地址：

{% raw %} 
```
$> docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${容器id}
```
{% endraw %}

> 容器id我们前面已经用`docker ps`看到了，拷贝过来替换掉`${容器id}`。

{% raw %} 
```
$> docker inspect --format '{{ .NetworkSettings.IPAddress }}' 7dabbc56e351
172.17.0.2
```
{% endraw %}

连接：

```
$> ./redis-cli -h 172.17.0.2
172.17.0.2:6379> 
```

> 不需要指定端口，使用默认端口6379即可。

正常连接上了，现在测试一下：

```
172.17.0.2:6379> set first:key "hello redis"
OK
172.17.0.2:6379> get first:key
"hello redis"
172.17.0.2:6379> 
```

成功！

## 允许物理机连接

上面成功连接之后，说明我们已经可以正常使用redis了，但是实际上这不是我们想要的效果，因为只能在虚拟机内连接，我们希望可以在物理机上连接，这样才可以进行开发。

现在让我们先停掉虚拟机里的dcoker:

```
$> docker stop ${容器id}
```

现在重新启动docker的redis镜像，同时指定主机端口映射容器端口：

```
$> docker run -p 6379:6379 --name port-map-redis -d redis
```

现在使用redis-cli直接连接本地：

```
$> ./redis-cli
127.0.0.1:6379>
```

说明连接本地成功。