---
layout: post
comments: true
categories: java
title: Redis中的keys pattern实现
tags: redis,java,keys pattern
grammar_cjkRuby: true
author: kael
---

* content
{:toc}

## 前言

近期在做技术研究的时候，发现涉及到redis的应用，写自动化单元测试相当麻烦，需要连接Redis才能完成测试，这就要求跑单元测试代码的时候，必须安装运行Redis，无法做到开箱即用。

目前在GitHub上可以找到几个用于单元测试的内嵌Redis:

* [kstyrc/embedded-redis](https://github.com/kstyrc/embedded-redis)
* [zxl0714/redis-mock](https://github.com/zxl0714/redis-mock)
* [wilkenstein/redis-mock-java](https://github.com/wilkenstein/redis-mock-java)

可惜三个项目的活跃度都比较一般，已经很长时间没维护了。

经过对比，我最终选用了[zxl0714/redis-mock](https://github.com/zxl0714/redis-mock)作为单元测试的内嵌redis，主要是考虑它纯Java实现，并且可以自己使用代码控制redis服务。

尚未实现的命令，我准备基于这个代码，在测试需要的话就继续完善这个仓库。

OK，闲话不多说，我第一个遇到的命令是keys，本文主要也是记录我用java按照redis的规则实现的思路和最终的代码，方便参考。

## 实现思路

将匹配过程分为两步：

* 1.解析模板，生成模板语法树（可以避免重复解析模板）
* 2.用语法树匹配目标字符串

### 解析模板

由于Redis的keys匹配字符串的规则比较简单：

* `*`表示匹配任意长度的字符串
* `?`表示匹配任意单个字符
* `[]`表示匹配`[]`内部出现的任意单个字符，以`^`开头则表示`[]`内部未出现的任意字符
* `\`表示转义字符，对特殊字符可以转义使其变成普通字符

在这四个规则下，key的模板一共可以分成四种类型：

* 标识匹配：即普通字符组成的类型
* 任意匹配：即`*`号表示的任意长度的字符串
* 单字符匹配：即`?`号表示的单个字符
* 枚举匹配：即由`[]`包围的单个字符所有可能性的枚举表达式

因此模板可以解析成最终由这四种类型的Token组成的语法树。

### 匹配目标字符串

语法树解析完成之后，就可以用来匹配字符串了。

目标字符串匹配思路如下：

* 1.从第一个Token开始，按照懒惰模式（即尽量短的匹配）从左往右匹配字符串
* 2.每一个Token匹配到自己的字符串之后，即将剩下的字串交给下一个Token进行匹配
* 3.当Token无法在剩余的字符串中找到自己匹配的内容时，返回上一个Token，并让上一个Token扩大自己匹配的子串，然后从上一个Token新匹配后剩余的子串重新匹配
* 4.当第一个Token无法找到匹配的子串时，返回无法匹配（由于所有Token匹配失败都会返回上一个，因此只有第一个Token最终能确定匹配失败）
* 5.当最后一个Token匹配完成后，目标字符串仍然有剩余时，自动扩大最后一个的Token的匹配范围
* 6.当最后一个Token无法匹配到字符串的最后一位时，回到第3步
* 7.当最后一个Token能匹配到目标字符串的最后剩余子串时，返回匹配成功

> 由于博客的样式问题，这里就不用`mermaid`画流程图了，毕竟思路也比较清晰和简单。

顺便说明一下，实际上也可以考虑递归的方式来解决，思路和代码可能会更加清晰，但是由于递归的性能有问题，并且线程的递归栈深度有限制，所以最终还是放弃的递归的思路。

## 实现代码

最终实现代码可以参考[KeyPattern.java](https://github.com/kael-aiur/redis-mock/blob/dev/src/main/java/com/github/zxl0714/redismock/pattern/KeyPattern.java)