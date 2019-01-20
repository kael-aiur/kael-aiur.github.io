---
layout: post
comments: true
categories: linux
title: centos7上安装xrdp支持windows远程桌面连接
tags: 标签1,标签2,标签3
grammar_cjkRuby: true
author: kael
---

* content
{:toc}

## 前言

本文基于最小版CentOS 7安装

## 安装桌面环境

> 如果只需要远程访问的话，也可以不安装桌面环境，只安装远程桌面环境

```
$> yum -y update # 更新包
$> yum -y groupinstall "GNOME Desktop" # 安装桌面环境
$> ln -sf /lib/systemd/system/runlevel5.target /etc/systemd/system/default.target # 配置系统启动时自动启动桌面服务
```

## 安装MATE

```
$> yum -y install epel-release # 安装epel-release源
$> yum -y update # 更新yum
$> yum clean all # 清理yum缓存
$> yum -y groupinstall "X Window system" # 安装窗口工具包
$> yum -y groupinstall "MATE Desktop" # 安装MATE
$> systemctl set-default graphical.target # 设置GUI或MATE desktop跟随系统启动
```

## 安装XFCE

```
$> yum -y groupinstall xfce # 安装XFCE
$> systemctl set-default graphical.target # 设置GUI或MATE desktop跟随系统启动
```

## 安装XRDP

```
$> yum -y install xrdp tigervnc-server
$> chcon --type=bin_t /usr/sbin/xrdp
$> chcon --type=bin_t /usr/sbin/xrdp-sesman
$> systemctl start xrdp # 启动xrdp服务
$> systemctl enable xrdp # 设置开机自启动
$> systemctl status xrdp # 查看XRDP启动状况
```

## XRDP无法启动

如果XRDP无法启动可以参考[CentOS 7 更新後xrdp.service無法啟動](https://yc999.wordpress.com/2015/04/04/centos-7-%E6%9B%B4%E6%96%B0%E5%BE%8Cxrdp-service%E7%84%A1%E6%B3%95%E5%95%9F%E5%8B%95/)

## 安装远程桌面环境

```
$> yum groupinstall "Server with GUI" //it's installed gnome and all staff include gnome-session
```

参考[xrdp on centos7 can't connect](https://stackoverflow.com/questions/43812257/xrdp-on-centos7-cant-connect)

## 参考博客

[Using a Desktop Environment on a CentOS 7 VPS](https://hostpresto.com/community/tutorials/using-a-desktop-environment-on-a-centos-7-vps/)
