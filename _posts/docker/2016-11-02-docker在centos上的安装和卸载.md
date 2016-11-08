---
layout: post
comments: true
categories: docker
title: docker在centos7上的安装和卸载
tags: 卸载,安装,docker,CentOS
grammar_cjkRuby: true
---

* content
{:toc}

## 前言

docker是最近比较火的一种虚拟化技术，很早之前在window上安装和体验过了，今天在linux上安装的时候才发现，CentOS官方的源上的docker安装后并不能使用，所以看一了一下docker的官网，按照官网的指引把docker安装好了，现在顺便把官网的安装教程翻译一下。

原文连接:[https://docs.docker.com/engine/installation/linux/centos/]()

## 翻译

Docker可以在CentOS 7.X上运行，在其他兼容EL7 的发行版(如：Scientific Linux)也可能可以，不过Docker官方并没有测试也没有明确支持其他的发行版。

建议使用Docker的安装指令和机制安装最新的Docker发布包，如果想要使用CentOS自己的安装包，可以查阅CentOs的官方文档。

### 准备

Docker要求安装在64位操作系统上，并且linux内核必须是3.10或以上版本。

安装之前想检查一下你的系统版本：

```
$ uname -r
3.10.0-229.el7.x86_64
```

另外，强烈建议把操作系统版本更新到最新的稳定版，保证所有已知的内部Bug都已经修复了。

### 安装Docker引擎

有两种方式安装Docker引擎。[使用yum命令安装](#yum_install)或者[使用脚本安装](#script_install)，其实使用脚本安装的方式也是用脚本运行了yum命令安装的。

#### **使用yum命令安装**{:#yum_install}

* 使用root账号登录或者可以使用sudo特权的账号登录。
* 确保所有的软件已经更新到最新版本

```
$ sudo yum update
```

* 添加yum的源

```
$ sudo tee /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF
```

* 安装docker的包

```
$ sudo yum install docker-engine
```

* 启用docker的服务

```
$ sudo systemctl enable docker.service
```

* 启动Docker的守护线程

```
$ sudo systemctl start docker
```

* 运行一下测试镜像验证docker是否安装完成

```
 $ sudo docker run --rm hello-world

 Unable to find image 'hello-world:latest' locally
 latest: Pulling from library/hello-world
 c04b14da8d14: Pull complete
 Digest: sha256:0256e8a36e2070f7bf2d0b0763dbabdd67798512411de4cdcf9431a1feb60fd9
 Status: Downloaded newer image for hello-world:latest

 Hello from Docker!
 This message shows that your installation appears to be working correctly.

 To generate this message, Docker took the following steps:
  1. The Docker client contacted the Docker daemon.
  2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
  3. The Docker daemon created a new container from that image which runs the
     executable that produces the output you are currently reading.
  4. The Docker daemon streamed that output to the Docker client, which sent it
     to your terminal.

 To try something more ambitious, you can run an Ubuntu container with:
  $ docker run -it ubuntu bash

 Share images, automate workflows, and more with a free Docker Hub account:
  https://hub.docker.com

 For more examples and ideas, visit:
  https://docs.docker.com/engine/userguide/
```

如果需要添加HTTP代理，设置不同的目录或分区，或者其他定制化，可以看一下[customize your Systemd Docker daemon options](https://docs.docker.com/engine/admin/systemd/)

#### **使用脚本安装**{:#script_install}

* 使用root账号登录或者可以使用sudo特权的账号登录
* 确保所有的软件已经更新到最新版本
    
```
$ sudo yum update
```

* 运行Docker的安装脚本

```
$ curl -fsSL https://get.docker.com/ | sh
```

* 启动守护进程

```
$ sudo systemctl start docker
```
    
* 验证是否安装完成

```
$ sudo docker run --rm hello-world
```
    
如果需要添加HTTP代理，设置不同的目录或分区，或者其他定制化，可以看一下[customize your Systemd Docker daemon options](https://docs.docker.com/engine/admin/systemd/)

#### 创建docker的用户组

由于docker是需要使用root权限的，因此如果非root的用户使用docker的指令，经常会需要加`sudo`命令，如果不想要使用sudo命令，可以给docker添加一个用户组，并把你的用户加入到这个用户组内。

> *警告：* docker用户组相当于root用户，如果太多用户拥有root权限的话，对系统的安全可能会有影响，了解更多可以看[Docker Daemon Attack Surface](https://docs.docker.com/engine/security/security/#docker-daemon-attack-surface)

* 使用root账号登录或者可以使用sudo特权的账号登录
* 创建docker用户组：

```
$ sudo groupadd docker
```

> 译者注：我自己实测的时候，好像安装完docker之后这个用户组就已经自动创建了，这一步是可以省略的。

* 把自己的用户加入到这个用户组中

```
$ sudo usermod -aG docker your_username
```
    
* 注销当前用户，重新登录即可。
* 验证是否已经不需要`sudo`命令

```
$ docker run --rm hello-world
```
    
#### 设置docker守护线程开机自启动

```
$ sudo systemctl enable docker
```

### 卸载docker

可以使用yum命令卸载docker。

* 查询已经安装的docker包:

```
$ yum list installed | grep docker

docker-engine.x86_64     1.7.1-0.1.el7@/docker-engine-1.7.1-0.1.el7.x86_64
```

* 删除包

```
$ sudo yum -y remove docker-engine.x86_64
```
    
这个命令会卸载docker，但是不会删除镜像，容器，卷或其他用户创建的配置文件。
    
* 删除所有镜像容器和卷

```
$ rm -rf /var/lib/docker
```

* 自行删除用户自己创建的配置文件。