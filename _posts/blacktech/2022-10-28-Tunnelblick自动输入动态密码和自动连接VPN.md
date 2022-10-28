---
layout: post
comments: true
categories: 黑科技
title: Tunnelblick自动输入动态密码和自动连接
tags: VPN,动态密码
author: Kael
grammar_cjkRuby: true
---

* content
{:toc}

## 前言

很多公司为了保证安全，一般内网服务都不允许直接公网访问，员工使用内网服务通常都需要使用VPN接入公司内网，目前企业内网的VPN方便常见的有微软自带的VPN功能，或者开元的OpenVPN协议，或者其他的easy connect等等。

本文主要讨论基于OpenVPN方案的工具。

基于OpenVPN方案的客户端比较常见的有[OpenVPN Connect](https://openvpn.net/)和[Tunnelblick](https://tunnelblick.net/)，这两个都是非常优秀的客户端软件，（Ubuntu系统自带了OpenVPN连接，可以不使用这两个软件）。

出于工作需要，每次打开电脑都要连接VPN，如果使用固定密码的话，可以通过软件的记住密码功能实现不用每次都输入密码，但是有些公司的服务器为了安全，不会使用固定密码，而是使用类似谷歌验证的方式，使用动态密码，这个时候就非常麻烦了，每次连接必须先获取谷歌动态密码，然后再输入到密码框中，一天连接一次可能还好，连接多次的时候，确实是非常烦人的操作。

目前经过笔者研究，OpenVPN Connect还不支持使用脚本动态输入密码，但是Tunnelblick从`3.8.3beta02`以后的版本就支持通过脚本动态替换密码的能力了，官网文档[Using Scripts](https://tunnelblick.net/cUsingScripts.html)。

本文主要介绍在Mac OS系统下如何基于Tunnelblick的脚本功能实现动态输入密码自动连接VPN。


## 前期准备

在开始实现动态输入密码的脚本前，我们要先通过正常的安装和配置，确保们的VPN已经可以正常使用，参考官网安装并导入配置即可。

* [安装文档](https://tunnelblick.net/cInstall.html)
* [导入VPN配置](https://tunnelblick.net/cConfigT.html)

安装配置完成后，可以看到如下vpn详情中有如下配置：

![](/static/img/blog/tunnelblick/tunnelblick_1.png)

现在我们先配置自动登录：

![](/static/img/blog/tunnelblick/tunnelblick_2.png)

> 这里的密码随便输入，后面我们会用脚本自动替换，在这里随便输入密码只是为了自动触发登录的操作。

ok，到这里我们的前期准备已经完成。

## 编写脚本

根据官网的文档：

```
password-replace.user.sh is executed to get a string to replace a password before it is passed to OpenVPN.
```

我们可以使用脚本**password-replace.user.sh**在登陆前对输入的密码进行替换，替换成我们自动计算的动态密码即可，需要实现如下两部：

* 生成谷歌验证码
* 使用password-replace.user.sh脚本将谷歌验证码返回给tunnelblick替换前面记住的密码
* 重新加载配置，使脚本生效

### 生成谷歌验证码

首选我们需要一个自动生成谷歌验证码的脚本，目前最简单的方式就是使用python脚本，这里给出一个实际可用的例子：

```python
import hmac, base64, struct, hashlib, time
import platform

def get_hotp_token(secret, intervals_no):
    key = base64.b32decode(secret, True)
    msg = struct.pack(">Q", intervals_no)
    h = hmac.new(key, msg, hashlib.sha1).digest()
    o = ord(chr(h[19])) & 15
    h = (struct.unpack(">I", h[o:o+4])[0] & 0x7fffffff) % 1000000
    return h

def get_totp_token(secret, bias):
    return get_hotp_token(secret, intervals_no=int(time.time()+bias)//30)

def get_google_code():
    secret="$SECRET" # 谷歌验证密钥，用于生成谷歌验证码，需要注意的是，验证码的长度需是16的整数倍，比如16，32，64等，如果长度不足，则通过=号补齐长度
    googlecode=get_totp_token(secret, 0)
    return '%06d' % googlecode

print(get_google_code(),end="")
```

完成上述脚本之后，可以执行一下验证是否成功：

```
$> python3 tunnelblick.py
303158%
```

说明脚本已经ok。

> 注意最后的`%`，这个是自动添加的，可以不理会，tunnelblick在使用密码的时候会自动将这个结尾去掉，官网原文：
> 
> ```
> If the output from the "password…" scripts ends in an ASCII LF character (0x0A), it will be removed before the string is used to replace or modify the password.
> ```

### 替换输入密码

**password-replace.user.sh**脚本要放在对应的VPN设置目录下，默认是:

```
/Library/Application Support/Tunnelblick/Users/{user}/{config_name}.tblk/Contents/Resources
```

这个目录必须使用root权限创建和修改脚本，参考官网[File Locations](https://tunnelblick.net/cFileLocations.html)。

脚本内容如下：

```bash
#! /bin/bash
PASSWORD=$(python3 tunnelblick.py)
echo "$PASSWORD"
```

> 这里第一行的`#! /bin/bash`不能少，否则tunnelblick不会执行这个脚本。

`echo`输出的结果tunnelblick会作为返回值，替换原来记住的密码，可以根据需要处理即可。

### 重新加载配置

增加这个脚本后，相当于修改了当前vpn连接的配置，Tunnelblick会扫描并发现配置变更了，此时连接会出现警告：

![](/static/img/blog/tunnelblick/tunnelblick_3.png)

这里有三个选项：

* **Secure the Configuration**: 回滚配置，使用最后一次正确的配置
* **Revert to the Last Secured Copy**: 应用配置，保存本次变更为最后一次正确配置
* **Cancel**: 取消，暂时不处理，也不连接VPN

这里我们选择**Revert to the Last Secured Copy**保存配置即可。

现在已经可以自动填写动态密码并连接VPN了。

## 设置启动连接【可选】

最后，我们可以在配置中选择启动tunnelblick即自动连接VPN，这样就可以达到重启后也自动连接的目的，最大限度减少我们关注VPN是否连接的问题：

![](/static/img/blog/tunnelblick/tunnelblick_4.png)