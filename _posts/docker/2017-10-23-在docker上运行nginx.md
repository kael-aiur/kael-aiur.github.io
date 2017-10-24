---
layout: post
comments: true
categories: docker
title: 在docker上运行nginx
tags: nginx,docker,容器
grammar_cjkRuby: true
author: KAEL
---

* content
{:toc}

## 前言

出于测试目的，偶尔会突然需要使用nginx,但是测试完之后又不想让nginx一直运行，这时候就可以使用docker官方提供的nginx镜像，然后写几份配置保存下来即可。

我在自己的电脑装了虚拟机，在虚拟机中安装CentOS 7的操作系统，本文基于这样的环境，在虚拟机中运行nginx的docker镜像。

参考[Docker官方Nginx镜像](https://hub.docker.com/_/nginx/)

## 下载nginx镜像

官方镜像下载非常简单：

```bash
$> docker pull nginx
```

> **注意：** 如果没有启动docker的守护进程，需要先启动：`service docker start`。

经过一小段时间等待镜像下载完成即可。

下载完成后，可以通过如下命令查看docker镜像：

```bash
$> docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
nginx               latest              1e5ab59102ce        13 days ago         108 MB
```

## 运行docker镜像并获取默认配置

要获取默认配置，我们需要进入到容器的系统中去，这时需要先运行容器。

```bash
$> docker run --name default-nginx -d nginx
```

这样容器就运行起来了，接下来进入docker镜像：

```bash
$> docker exec -it default-nginx bash
root@b82b1228eae7:/#
```

进到docker容器后，就和普通的命令行操作一样了。

nginx镜像的默认配置文件位置在

```
$> cat /etc/nginx/nginx.conf
user  nginx;
worker_processes  1;
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;
events {
    worker_connections  1024;
}
http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    include /etc/nginx/conf.d/*.conf;
}
```

这个是根配置文件，我们使用这个配置直接重写是可以的，但是实际上为了减少我们的配置量，建议只从写代理部分的配置即可，从上面的配置文件可以看出，这里的配置`include`了`/etc/nginx/conf.d/`这个目录下的全部`.conf`配置。

实际上只有一个文件：

```bash
$> cat /etc/nginx/conf.d/default.conf
server {
    listen       80;
    server_name  localhost;

    #charset koi8-r;
    #access_log  /var/log/nginx/host.access.log  main;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    #error_page  404              /404.html;

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

    # proxy the PHP scripts to Apache listening on 127.0.0.1:80
    #
    #location ~ \.php$ {
    #    proxy_pass   http://127.0.0.1;
    #}

    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
    #
    #location ~ \.php$ {
    #    root           html;
    #    fastcgi_pass   127.0.0.1:9000;
    #    fastcgi_index  index.php;
    #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
    #    include        fastcgi_params;
    #}

    # deny access to .htaccess files, if Apache's document root
    # concurs with nginx's one
    #
    #location ~ /\.ht {
    #    deny  all;
    #}
}
```

这里我们可以把这个`default.conf`的内容全部复制出来。

现在退出容器：

```bash
$> exit
exit
[root@localhost ~]# 
```

在`/root`目录下创建一个`nginx.conf`文件，并将刚刚复制的`default.conf`配置粘贴进来。

```bash
$> ls
anaconda-ks.cfg  download  kaelkaelkael.pem  nginx.conf(1)
```

> **(1).** 我们刚刚创建的配置文件。

现在修改`nginx.conf`的配置，将

```bash
location / {
    root   /usr/share/nginx/html;
    index  index.html index.htm;
}
```

修改为：

```bash
location / {
    proxy_pass http://192.168.85.1:8099;
}
```

即所有根目录的请求全部转发到`http://192.168.85.1:8099`这个地址来。

这个地址是我本地物理机的IP，我写了一个简单的服务，返回请求的所有请求头。

现在我们启动docker容器，并指定使用`/root/nginx.conf`配置替换`/etc/nginx/conf.d/default.conf`配置,同时将虚拟机的8080端口映射到容器的80端口。

为了防止容器同名冲突，我们先删掉刚刚启动的默认镜像：

```bash
$> docker rm -f mynginx
```

启动容器：

```bash
$> docker run --name mynginx -p 8080:80 -v /root/nginx.conf:/etc/nginx/conf.d/default.conf -d nginx
```

查看容器启动状态：

```bash
$> docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                  NAMES
b82b1228eae7        nginx               "nginx -g 'daemon ..."   26 minutes ago      Up 26 minutes       0.0.0.0:8080->80/tcp   mynginx
```

> **注意：** 如果发现容器没有启动成功，有可能是配置出错了，这个时候可以通过docker的启动日志检查原因：
>
> ```bash
> $> docker logs -f mynginx
> 192.168.85.1 - - [23/Oct/2017:23:14:20 +0000] "GET /header_print HTTP/1.1" 200 467 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.100 Safari/537.36" "-"
> 192.168.85.1 - - [23/Oct/2017:23:14:21 +0000] "GET /favicon.ico HTTP/1.1" 404 0 "http://192.168.85.132:8080/header_print" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.100 Safari/537.36" "-"
> ```
>
> 这个命令有点类似`tail -f`

容器启动成功，测试配置是否有效：

```bash
$> curl 127.0.0.1:8080/header_print
{"content-length":"0","Accept":"*/*","Connection":"close","User-Agent":"curl/7.29.0","Host":"192.168.85.1:8099"}
```

得到请求头的json，说明转发成功。

## 总结

通过这种方式，可以预先配置好多个不同的配置文件，然后准备好不同的脚本，每次需要测试的时候，直接启动脚本即可。