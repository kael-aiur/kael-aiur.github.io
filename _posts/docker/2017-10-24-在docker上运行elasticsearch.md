---
layout: post
comments: true
categories: docker
title: 在docker上运行elasticsearch
tags: elasticsearch,docker,容器
grammar_cjkRuby: true
author: KAEL
---

* content
{:toc}

## 前言

elasticsearch的docker镜像已经不再由docker官方支持了，转由es官方支持，本文主要记录使用es官方docker镜像的过程。

参考[Install Elasticsearch with Docker](https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html)

## 安装镜像

安装镜像比较简单：

```bash
$> docker pull docker.elastic.co/elasticsearch/elasticsearch:5.6.3
```

等待下载完成即可，下载完成后，查看镜像：

```bash
$> docker images
REPOSITORY                                      TAG                 IMAGE ID            CREATED             SIZE
docker.elastic.co/elasticsearch/elasticsearch   5.6.3               865b21b970de        13 days ago         657 MB (1)
nginx                                           latest              1e5ab59102ce        2 weeks ago         108 MB
```

> **(1).** 这个就是我们刚刚下载的镜像

## 运行镜像

es官方的docker支持开发模式运行和产品模式运行，这里用于开发，所以使用开发模式运行即可。

```bash
$> docker run --name myes -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" docker.elastic.co/elasticsearch/elasticsearch:5.6.3
```

开发模式运行后，docker进程会占用当前终端，进行测试的话需要打开一个新的终端，输入：

```
$> curl -u elastic http://127.0.0.1:9200/_cat/health
Enter host password for user 'elastic':
1508837488 09:31:28 docker-cluster yellow 1 1 5 5 0 0 5 0 - 50.0%
```

> 这里需要输入密码，密码是changeme。

需要停止docker的话，在新的终端使用docker命令停止即可:

```bash
$> docker stop myes
```

> **注意：** 这里的myes是前面启动镜像的时候使用的名字。
> 不能直接在启动docker的终端通过ctrl-c停止docker，会导致docker不能正常退出，占用端口，目前还不知道是什么原因导致的。

## 安全

docker镜像中的es默认安装了X-Pack，并且内置了一个用户：

```bash
elastic:changeme
```

由于X-Pack是有license要求的，只有30天的试用时间，到期后我们可以考虑把X-Pack去掉。

首先运行docker容器：

```bash
$>  docker run --name myes -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" docker.elastic.co/elasticsearch/elasticsearch:5.6.3
```

然后进入docker容器内部查看配置：

```bash
$> docker exec -it myes bash
[elasticsearch@fd5593b673dc ~]$
```

查看es的配置：

```bash
$> cat /usr/share/elasticsearch/config/elasticssearch.yml
cluster.name: "docker-cluster"
network.host: 0.0.0.0

# minimum_master_nodes need to be explicitly set when bound on a public IP
# set to 1 to allow single node clusters
# Details: https://github.com/elastic/elasticsearch/pull/17288
discovery.zen.minimum_master_nodes: 1
```

把配置复制出来，在主机上保存一份用于修改。

```bash
$> vim /root/es.yaml
cluster.name: "docker-cluster"
network.host: 0.0.0.0

# minimum_master_nodes need to be explicitly set when bound on a public IP
# set to 1 to allow single node clusters
# Details: https://github.com/elastic/elasticsearch/pull/17288
discovery.zen.minimum_master_nodes: 1
xpack.security.enabled: false # 增加这个配置
```

保存退出。

现在删除已经运行的容器：

```bash
$> docker rm -f myes
```

运行新容器并指定配置覆盖：

```bash
$> docker run --name myes -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" -v /root/es.yaml:/usr/share/elasticsearch/config/elasticsearch.yml docker.elastic.co/elasticsearch/elasticsearch:5.6.3
```

这样启动的容器中就禁用掉X-Pack了。