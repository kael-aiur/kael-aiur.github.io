---
layout: post
comments: true
categories: 数据库
title: Linux上使用mysql的yum资源安装mysql
tags: mysql,yum,linux
grammar_cjkRuby: true
author: Kael
---

* content
{:toc}

## 前言

在Linux下安装mysql包含了许多依赖，一般都会使用yum或者apt-get来安装，但是很多Linux的发行版中并没有包含mysql的最新版本，因此我们如果想要安装mysql的最新版本，一般都没办法直接用Linux发行版的源中带的mysql。

所幸mysql官方提供了Linux的源，我们只需要将这个源添加到我们的系统源中即可使用yum来安装最新版本的mysql了。

本文会以yum安装为例说明如何使用mysql官方的yum源库。

## 安装mysql的yum源

mysql提供了安装源配置的rpm包，只要根据自己的操作系统对应的内核版本找到安装包下载并安装即可使用mysql的源，这里我使用的是CentOS7，安装mysql5.7版本。

* 查看内核版本

```
$> uname -a
Linux localhost.localdomain 3.10.0-327.el7.x86_64 #1 SMP Thu Nov 19 22:10:57 UTC 2015 x86_64 x86_64 x86_64 GNU/Linux
```

这里可以看到内核是el7的64位操作系统，到mysql官网查看对应的源安装包：

[mysql官网源安装包下载地址](https://dev.mysql.com/downloads/repo/yum/)

* 下载安装包

```
$> wget https://repo.mysql.com//mysql57-community-release-el7-9.noarch.rpm
```

* 安装源

```
$>  rpm -ivh mysql57-community-release-el7-9.noarch.rpm
```

* 测试mysql源

```
$> yum repolist all | grep mysql
mysql-connectors-community/x86_64 MySQL Connectors Community      enabled:    30
mysql-connectors-community-source MySQL Connectors Community - So disabled
mysql-tools-community/x86_64      MySQL Tools Community           enabled:    43
mysql-tools-community-source      MySQL Tools Community - Source  disabled
mysql-tools-preview/x86_64        MySQL Tools Preview             disabled
mysql-tools-preview-source        MySQL Tools Preview - Source    disabled
mysql55-community/x86_64          MySQL 5.5 Community Server      disabled
mysql55-community-source          MySQL 5.5 Community Server - So disabled
mysql56-community/x86_64          MySQL 5.6 Community Server      disabled
mysql56-community-source          MySQL 5.6 Community Server - So disabled
mysql57-community/x86_64          MySQL 5.7 Community Server      enabled:   166
mysql57-community-source          MySQL 5.7 Community Server - So disabled
mysql80-community/x86_64          MySQL 8.0 Community Server      disabled
mysql80-community-source          MySQL 8.0 Community Server - So disabled
```

能看到如上列表则说明源已经安装成功。

> 如果准备安装最新版本的mysql，则不用配置可以直接安装，如果想要指定安装旧版本的mysql，需要编辑`/etc/yum.repos.d/mysql-community.repo`这个文件。
> 默认情况下，配置的启用资源库是mysql最新版本的：
> 
>```
>[mysql57-community]
>name=MySQL 5.7 Community Server
>baseurl=http://repo.mysql.com/yum/mysql-5.7-community/el/6/$basearch/
>enabled=1
>gpgcheck=1
>gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql
>```
>
>只要把`enabled=1`改成`enabled=0`，同时将实际想要安装的版本对应的`enabled=0`改成`enabled=1`即可。

## 安装mysql

```
$> yum install mysql-community-server
```

安装的过程需要下载rpm包，时间视个人网速决定。

安装完成后启动mysql:

```
$>  systemctl start mysqld.service
```

启动完成，查看一下mysql的运行状态：

```
$> systemctl status mysqld.service
Redirecting to /bin/systemctl status  mysqld.service
● mysqld.service - MySQL Server
   Loaded: loaded (/usr/lib/systemd/system/mysqld.service; enabled; vendor preset: disabled)
   Active: active (running) since Tue 2017-03-21 00:18:19 CST; 10s ago
     Docs: man:mysqld(8)
           http://dev.mysql.com/doc/refman/en/using-systemd.html
  Process: 17953 ExecStart=/usr/sbin/mysqld --daemonize --pid-file=/var/run/mysqld/mysqld.pid $MYSQLD_OPTS (code=exited, status=0/SUCCESS)
  Process: 17880 ExecStartPre=/usr/bin/mysqld_pre_systemd (code=exited, status=0/SUCCESS)
 Main PID: 17956 (mysqld)
   CGroup: /system.slice/mysqld.service
           └─17956 /usr/sbin/mysqld --daemonize --pid-file=/var/run/mysqld/my...

Mar 21 00:18:13 localhost.localdomain systemd[1]: Starting MySQL Server...
Mar 21 00:18:19 localhost.localdomain systemd[1]: Started MySQL Server.
```

启动完成。

## 设置管理员账号密码

mysql5.6以后，root账号不再使用安装过程设置密码了，而是在安装的时候生成一个随机密码用于root账号第一次登录，登录完成后必须修改密码，先查看安装时生成的随机密码：

```
$> grep 'temporary password' /var/log/mysqld.log
2017-03-20T16:18:14.987087Z 1 [Note] A temporary password is generated for root@localhost: tHsV)(&&e5kH
```

这里我们可以看到密码是`tHsV)(&&e5kH`。

现在登录mysql：

```
$> mysql -uroot -p
Enter password:
```

输入密码，登录成功，使用如下sql修改密码：

```
$> ALTER USER 'root'@'localhost' IDENTIFIED BY 'MyNewPass4!';
Query OK, 0 rows affected (0.00 sec)
```

修改成功。

## 设置mysql允许远程连接

* 设置远程连接授权：

```
mysql> GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'MyNewPass4!' WITH GRANT OPTION;
Query OK, 0 rows affected, 1 warning (0.00 sec)
```

* 重载授权表

```
mysql> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.00 sec)
```

设置成功，现在可以使用root在其他机器远程连接了。