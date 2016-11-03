---
layout: post
comments: true
categories: nodejs
title: CentOS上安装nodejs
tags: nodejs,npm,Linux
grammar_cjkRuby: true
---

## 前言

nodejs已经火了挺长一段时间了，[官网](https://nodejs.org/en/)上现在有很多安装方式，window上的安装比较简单，mac的安装也比较简单，linux的安装在官网上没有找到安装教程，所以就记录一下。

linux上安装nodejs有两种方式，一种是直接用发布包，配置环境变量安装，这个个人感觉反而比较麻烦，所以采用源码安装。

本文使用6.9.1的版本，源码下载地址[https://nodejs.org/dist/v6.9.1/node-v6.9.1.tar.gz]()

在进行源码安装之前，先保证开发者环境已经安装好了，可以看我另一篇博客[centos下安装开发者工具](/linux/centos下安装开发者工具.html)。

## 安装nodejs

下载源码包

```
[kael@localhost Download]$ wget https://nodejs.org/dist/v6.9.1/node-v6.9.1.tar.gz
```

下载完成后解压

```
[kael@localhost Download]$ tar -xvf node-v6.9.1.tar.gz
```

进入nodejs源码根目录：

```
[kael@localhost Download]$ cd node-v6.9.1
```

执行配置脚本

```
[kael@localhost node-v6.9.1]$ ./configure 
```

输出如下：

```
creating  ./icu_config.gypi
* Using ICU in deps/icu-small
creating  ./icu_config.gypi
{ 'target_defaults': { 'cflags': [],
                       'default_configuration': 'Release',
                       'defines': [],
                       'include_dirs': [],
                       'libraries': []},
  'variables': { 'asan': 0,
                 'debug_devtools': 'node',
                 'force_dynamic_crt': 0,
                 'gas_version': '2.23',
                 'host_arch': 'x64',
                 'icu_data_file': 'icudt57l.dat',
                 'icu_data_in': '../../deps/icu-small/source/data/in/icudt57l.dat',
                 'icu_endianness': 'l',
                 'icu_gyp_path': 'tools/icu/icu-generic.gyp',
                 'icu_locales': 'en,root',
                 'icu_path': 'deps/icu-small',
                 'icu_small': 'true',
                 'icu_ver_major': '57',
                 'node_byteorder': 'little',
                 'node_enable_d8': 'false',
                 'node_enable_v8_vtunejit': 'false',
                 'node_install_npm': 'true',
                 'node_module_version': 48,
                 'node_no_browser_globals': 'false',
                 'node_prefix': '/usr/local',
                 'node_release_urlbase': '',
                 'node_shared': 'false',
                 'node_shared_cares': 'false',
                 'node_shared_http_parser': 'false',
                 'node_shared_libuv': 'false',
                 'node_shared_openssl': 'false',
                 'node_shared_zlib': 'false',
                 'node_tag': '',
                 'node_use_bundled_v8': 'true',
                 'node_use_dtrace': 'false',
                 'node_use_etw': 'false',
                 'node_use_lttng': 'false',
                 'node_use_openssl': 'true',
                 'node_use_perfctr': 'false',
                 'node_use_v8_platform': 'true',
                 'openssl_fips': '',
                 'openssl_no_asm': 0,
                 'shlib_suffix': 'so.48',
                 'target_arch': 'x64',
                 'uv_parent_path': '/deps/uv/',
                 'uv_use_dtrace': 'false',
                 'v8_enable_gdbjit': 0,
                 'v8_enable_i18n_support': 1,
                 'v8_inspector': 'true',
                 'v8_no_strict_aliasing': 1,
                 'v8_optimized_debug': 0,
                 'v8_random_seed': 0,
                 'v8_use_snapshot': 'true',
                 'want_separate_host_toolset': 0}}
creating  ./config.gypi
creating  ./config.mk
```

> 注意：如果没有安装开发者环境，这里的配置脚本会出现警告或者错误，要想安装开发者环境

编译代码

```
[kael@localhost node-v6.9.1]$ make
```

编译是个比较久的过程，慢慢等吧。

编译完成之后，安装到本地

```
[kael@localhost node-v6.9.1]$ make install
```

安装完成，接下来验证一下

```
[kael@localhost node-v6.9.1]$ node --version
v6.9.1
```

说明nodejs安装完成了。

需要说明一下，nodejs是用npm来做包管理的，以前安装nodejs之后是需要再安装npm的，不过现在新的版本已经把npm内置在nodejs的安装包里了，所以我们不用再安装npm了，现在顺便验证一下npm：

```
[kael@localhost node-v6.9.1]$ npm -version
3.10.8
```

安装完成。