---
layout: post
comments: true
categories: nginx
title: nginx配置https
tags: nginx,https
grammar_cjkRuby: true
---

* content
{:toc}

## 前言

本文主要记录如何将nginx配置为https反向代理

## 自签名证书

在配置https之前，我们需要先准备好证书文件，nginx需要两个证书文件：pem和key。

如果你已经有申请好的根证书，则忽略本步骤，如果没有证书，需要自签名，则按照本步骤生成自己的证书。

> 这里生成证书使用的是openssl和jdk中的keytool，如果没有请先自行安装这两个工具。

### 生成证书库

```
$> keytool -genkey -alias nginx -keyalg RSA -keystore nginx.jks
输入密钥库口令:  
再次输入新口令: 
您的名字与姓氏是什么?
  [Unknown]:  127.0.0.1
您的组织单位名称是什么?
  [Unknown]:  bingo 
您的组织名称是什么?
  [Unknown]:  bingo
您所在的城市或区域名称是什么?
  [Unknown]:  gz
您所在的省/市/自治区名称是什么?
  [Unknown]:  gd
该单位的双字母国家/地区代码是什么?
  [Unknown]:  cn
CN=127.0.0.1, OU=bingo, O=bingo, L=gz, ST=gd, C=cn是否正确?
  [否]:  y

输入 <nginx> 的密钥口令
	(如果和密钥库口令相同, 按回车):  
再次输入新口令: 

Warning:
JKS 密钥库使用专用格式。建议使用 "keytool -importkeystore -srckeystore nginx.jks -destkeystore nginx.jks -deststoretype pkcs12" 迁移到行业标准格式 PKCS12。
```

> 说明： 这里所有输入密钥的地方，全部以`changeit`为例。
> 需要注意的是，由于证书和域名是绑定的，因此`您的名字与姓氏是什么?`这里，需要输入nginx的访问域名或者ip地址，其他值随意。

上面的步骤执行完成之后，在当前目录会生成一个证书库文件`nginx.jks`，接下来从这个证书库中提取证书文件：

首先转换证书格式为p12: 

```
$> keytool -importkeystore -srckeystore nginx.jks -destkeystore nginx.p12 -srcalias nginx -srcstoretype jks -deststoretype pkcs12
正在将密钥库 nginx.jks 导入到 nginx.p12...
输入目标密钥库口令:  
再次输入新口令: 
输入源密钥库口令:  
```

> 三次口令全部输入`changeit`。

得到p12证书文件。

将p12证书文件转换为pem文件：

```
$> openssl pkcs12 -in nginx.p12 -out nginx.pem
Enter Import Password:
MAC verified OK
Enter PEM pass phrase:
Verifying - Enter PEM pass phrase:
```

> 三次口令全部输入`changeit`。

从pem文件提取key文件：

```
$> openssl rsa -in nginx.pem -out nginx.key
Enter pass phrase for nginx.pem:
writing RSA key
```

> 口令输入`changeit`。

到这里我们就得到`nginx.pem`和`nginx.key`文件了。

## 配置证书

这里以nginx 1.14为例。

在`/etc/nginx/nginx.conf`中，包含如下配置：

```
http {
    ## ...
	include /etc/nginx/conf.d/*.conf;
	include /etc/nginx/sites-enabled/*;
}
```

这里表示加载`/etc/nginx/conf.d`目录和`/etc/nginx/sites-enabled/`目录的配置，在`/etc/nginx/sites-enabled/`目录下，`default`配置了默认的80端口服务，如果不需要，建议删除`default`配置文件。

在`/etc/nginx/conf.d`增加配置文件`server.conf`:

```
server {
	listen 8443 ssl;
	ssl_certificate /etc/nginx/conf.d/cert/nginx.pem; # pem证书文件位置
	ssl_certificate_key /etc/nginx/conf.d/cert/nginx.key; # key证书文件位置

	server_name 127.0.0.1; # 服务名，注意和证书申请的`您的名字与姓氏是什么?`保持一致
	location /iamsso {
		proxy_pass http://127.0.0.1:8089/iamsso;
	}
	location /iamapi {
		proxy_pass http://127.0.0.1:8087/iamapi;
	}
}
```

如上配置，即可实现如下转发：

```
https://127.0.0.1:8443/iamsso -> http://127.0.0.1:8089/iamsso
https://127.0.0.1:8443/iamapi -> http://127.0.0.1:8087/iamapi
```