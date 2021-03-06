---
layout: post
comments: true
categories: 入门指引
title: "使用github+jekyll搭建个人博客"
---

* content
{:toc}

## 前言

最近看了一些老程序员的回忆录，突然想开始写自己的博客，也为了10年后的自己留下一点东西吧，正好这两天工作不是特别忙，所以就开始准备这个东西了，以后会争取按时更新自己的博客吧，废话少说，先来看看我怎么搭建这个博客。

## 前期基础准备

想要通过github搭建自己的个人博客，你至少得先了解下面这几个东西：

* git
* github pages
* jekyll
* markdown

### git

git 不用多说了，一个分布式的版本管理工具，作用类似svn，不过好用很多，github整个站点的核心功能也是git，没了解过的可以去git的[官网](https://git-scm.com/)看看

### github pages

github pages的官网是[https://pages.github.com/](https://pages.github.com/)，可以用来展示一些静态页面，github最初做这个功能，目的应该是用于给人展示个人主页和项目主页，并不是用来做博客的，由于是静态页面，所以并不能记录一些动态数据如点击量一类的功能，使用教程可以在[这里](https://help.github.com/categories/github-pages-basics/)看到。

### jekyll

jekyll其实是一个静态网页生成工具，类似的还有[gitbook](https://www.gitbook.com/)，不过比gitbook强大很多，你可以在[官网](https://jekyllrb.com/)学习相关的知识。

前面已经说了，githug pages可以帮助我们托管一个静态代码的网站，jekyll可以帮我们生成一个静态网站，这两者搭配起来就天衣无缝了，实际上，github pages推荐的也是使用jekyll来写静态网站的，并且支持自动编译，只要按照jekyll的目录结构存放文件就可以了。

> 大部分官网都是英文，作为一个程序员英文阅读能力非常重要，如果你懒得读英文的话，可以在百度上找中文的文档教程(^_^)，不过我个人还是推荐读英文。

## 开始

* 首先你需要先申请一个github账号，在[github官网](https://github.com/)上，如下图：

![sign_up_in_github.png][1]

注册完成之后，创建一个新的工程，工程名必须是`{username}.github.io`，然后这个工程就可以通过域名`https://{username}.github.io`访问了，默认访问根目录的`index.html`文件。

* 创建jekyll的工程文件

将上面创建的项目clone到本地目录，按照官方文档指引安装jekyll，jekyll依赖ruby，因此需要先安装ruby平台。另外，github官方推荐使用bundler管理jekyll的工程，因此可以使用ruby安装bundler。

bundler安装完成之后就可以直接使用命令生成jekyll的项目文件了,这个过程github官方的指引已经做得非常好了，可以看下[指引](https://help.github.com/articles/setting-up-your-github-pages-site-locally-with-jekyll/)。

生成目录结构之后，把这部分代码push到github就可以访问了，关于jekyll的目录结构和使用方法看看官网就行了。

* 写博客

网站已经搭建好了，但是未来我们会不断在网站上更新博客，jekyll支持使用md来写博客，因此我也是使用md来写博客的，jekyll会自动帮我编译成html。


好吧实际上这篇博客并没有介绍太多详细的信息，因为每一部分官网都写的非常详细了，所以只是把基本的概念和搭建的思路解释一下而已，先这样吧，希望以后能按时更新博客。

  [1]: /static/img/blog/setup-my-blog/sign_up_in_github.png "sign_up_in_github.png"
