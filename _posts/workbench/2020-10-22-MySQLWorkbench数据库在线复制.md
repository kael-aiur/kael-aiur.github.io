---
layout: post
comments: true
categories: MySQLWorkbench
title: MySQLWorkbench数据库在线复制
tags: MySQLWorkbench,schema copy, 数据库复制
grammar_cjkRuby: true
---

* content
{:toc}

## 前言

在使用mysql的过程中，我们经常需要备份一个数据库用于各种测试，这时候就需要将一个正在使用的数据库复制一份用于变更测试，在MySQLWorkbench中这个功能使用起来远没有Navicat那么简单，这里提供一个简单的指引，用于复制数据库。

在workbench中，提供了一个migration的功能，这个功能可以用于对比两个schema的差异，并将两个数据库同步，我们将使用这个功能来实现复制一个数据库。

## 步骤

在顶部菜单中，找到`Database`菜单下的`Migration Wizard...`:

![][1]

点击后进入Migration向导。

![][2]

这里对界面做一个简单的介绍，左边栏是一个配置步骤，右边栏是配置区。

点击`Start Migration`开始配置。

第一步是`Source Selection`，选择数据源，这里需要配置数据来源的连接，按实际情况配置即可，也可以选择已经保存的连接。

![][3]

点击next进入下一步，这一步是选择目标数据，即将数据源的数据复制到哪里，配置方式和 源数据相似：

![][4]

继续点击next进入下一步，进入`Fetch schemas List`，这一步workbench会拉取数据源的Schema列表，以供下一步选择。

![][5]

继续点击next，选择源数据库，这里可以选一个或者多个：

![][6]

这里我们以iam为例，勾选后选择next，加载源的元数据：

![][7]

点击next进入下一步，选择需要复制的表和数据：

![][8]

点击next，开始分析源数据并生成创建脚本：

![][9]

继续点击next，进入人工配置环节，这里默认的视图的问题预览视图，一般情况下不会有error，如果有error的话则需要先解决，视图选框包含三个视图：

* Migration Prolems: 问题视图
* AllObjects: 对象视图
* Column Mappings: 字段映射

选择AllObjects: 

![][10]

这时我们看到完整的映射对象关系：

![][11]

由于我们要复制完整的数据库，所以只需单击`Target Object`下的数据库名（这里是iam）,就会变成编辑状态，然后修改数据库名为希望复制的目标数据库即可：

![][12]

继续点击next，进入目标数据库的复制选项：

![][13]

这里有三个选项：

* Create schema in target RDBMS: 在目标数据库创建Scheam，如果是已经存在的Scheam，则去掉这个选项
* Create a SQL script file: 保存执行的数据库脚本，不需要保存则不勾选
* Keep schemas if they already exist: 勾选此选项表示保存已存在的表和Scheam，建议不勾选，勾选的话会导致数据库两边的结构不能保持一致

继续点击next，开始创建目标数据库，此时如果目标数据库已经存在的话，会弹出目标数据库将被删除的提示，点击yes继续即可：

![][14]

执行后，可能会存在一些警告，点击next可以看到问题总览，在我这里，出现了一个错误，按照错误提示，我们知道由于创建了两个同名的索引导致数据库表无法创建：

![][15]

选择出现错误的表，修改其中一个索引的名称，点击Apply应用：

![][16]

点击左下角的`Recreate Objects`，回到创建目标数据库界面， 点击next，这次创建就全部通过了：

![][17]

继续点击next，问题总览中已经没有问题了，继续next开始配置数据传输：

![][18]

这里直接在线传输即可，按默认选项，点击next开始数据复制：

![][19]

到这里我们的数据库复制就完成了，继续点击next查看本次传输的报告：

![][20]

生成报告的过程可能会比较久，稍等即可，如果不需要查看报告，也可以直接退出向导，报告生成完成之后，点击finish即可退出向导。

  [1]: /static/img/blog/workbench/migration_1.png "菜单位置"
  [2]: /static/img/blog/workbench/migration_2.png "Migration向导"
  [3]: /static/img/blog/workbench/migration_3.png "数据源选择"
  [4]: /static/img/blog/workbench/migration_4.png "目标选择"
  [5]: /static/img/blog/workbench/migration_5.png "拉取源Schema"
  [6]: /static/img/blog/workbench/migration_6.png "选择源Schema"
  [7]: /static/img/blog/workbench/migration_7.png "加载源的元数据"
  [8]: /static/img/blog/workbench/migration_8.png "选择复制的表和数据"
  [9]: /static/img/blog/workbench/migration_9.png "分析所选数据库，生产脚本"
  [10]: /static/img/blog/workbench/migration_10.png "升级问题纵览"
  [11]: /static/img/blog/workbench/migration_11.png "切换对象视图"
  [12]: /static/img/blog/workbench/migration_12.png "修改目标Schema名"
  [13]: /static/img/blog/workbench/migration_13.png "目标数据库创建选项"
  [14]: /static/img/blog/workbench/migration_14.png "创建目标数据库"
  [15]: /static/img/blog/workbench/migration_15.png "创建目标数据库问题总览"
  [16]: /static/img/blog/workbench/migration_16.png "解决脚本问题"
  [17]: /static/img/blog/workbench/migration_17.png "目标数据库创建成功"
  [18]: /static/img/blog/workbench/migration_18.png "数据传输配置"
  [19]: /static/img/blog/workbench/migration_19.png "数据传输完成"
  [20]: /static/img/blog/workbench/migration_20.png "数据库复制结果报告"

