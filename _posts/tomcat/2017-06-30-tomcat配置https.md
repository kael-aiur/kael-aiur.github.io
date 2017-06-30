---
layout: post
comments: true
categories: tomcat
title: tomcat配置https
tags: tomcat,ssl,https
grammar_cjkRuby: true
author: KAEL
---
    
* content
{:toc}

## 前言

一般来说，tomcat从官网下载后即可直接使用，但是默认只能使用http协议，如果需要使用https，需要少量配置。当然这个配置非常简单，本文只做记录备忘。

## 生成证书

一般使用jdk提供的`keytool`生成即可。

这个工具在`${JAVA_HOME}/bin/keytool`，使用命令行创建证书：

```text
$> "c:\Program Files\Java\jdk1.8.0_66\bin\keytool.exe" -genkey -alias tomcat -keyalg RSA -keystore d:\tomcat.keystore

输入密钥库口令: #输入密码，这里我输入的是tomcat
再次输入新口令: #再次输入密码tomcat

您的名字与姓氏是什么?
  [Unknown]:  localhost # 这里需要输入绑定的域名，如果不是使用域名访问，输入ip地址
您的组织单位名称是什么?
  [Unknown]:  bingo # 单位名称，即OU
您的组织名称是什么?
  [Unknown]:  bingo # 组织名称，即DC
您所在的城市或区域名称是什么?
  [Unknown]:  gz # 城市名称
您所在的省/市/自治区名称是什么?
  [Unknown]:  gd # 省份名称
该单位的双字母国家/地区代码是什么?
  [Unknown]:  cn # 国家代码
CN=localhost, OU=bingo, O=bingo, L=gz, ST=gd, C=cn是否正确? # 最后的确认信息
  [否]:  y

输入 <tomcat> 的密钥口令
        (如果和密钥库口令相同, 按回车): # 直接回车，使用和密钥库相同的口令
        
$> 
```

> **注意：** 这里建议使用管理员权限的命令提示符，以免用户没有权限在当前目录下生成证书，如果没有权限在指定目录生成证书库，会出现如下错误：
> ```
> keytool 错误: java.io.FileNotFoundException: C:\tomcat.keystore (拒绝访问。)
> ```

证书会在当前目录生成一个文件：

```text
tomcat.keystore
```

把这个文件拷贝到`${tomcat}/conf`目录下即可。

## 配置SSL证书

配置tomcat使用https，只要在`server.xml`中增加如下配置即可：

```xml
<Connector  port="8443" protocol="org.apache.coyote.http11.Http11NioProtocol"
            maxThreads="150" SSLEnabled="true" scheme="https" secure="true"
            clientAuth="false" sslProtocol="TLS"
            keystoreFile="conf\tomcat.keystore"  
            keystorePass="tomcat"/>
```

