---
layout: post
comments: true
categories: 黑科技
title: 利用hyper-v在window上开发Linux程序 
tags: Linux,hyper-v,nfs
author: Kael
grammar_cjkRuby: true
---

* content
{:toc}

## 前言

先说明一下最终的成果，可能并没有标题那么高大上。

本文最终想要实现的目标是，在idea中导入一个java工程并开发，然后开发完成之后代码自动推送到Linux系统上，并且可以使用ssh远程到Linux系统上做git相关的操作和打包等操作。

为什么要在Linux上做，是因为Linux的指令比window好用很多而已，实际上属于比较折腾的做法，并没有什么实际的好处，只是我个人比较喜欢Linux的指令操作，又贪图window的方便才研究的做法。

## 实现思路

实现的思路是这样的：


首先利用hyper-v在本地操作系统跑一个虚拟机的Linux系统，理论上这个Linux操作系统可以在任何网络能联通的地方，放在本地操作系统是为了保证网络稳定性。

然后利用nfs(网络文件系统)把Linux上的某个文件夹共享出来，挂载到物理机的磁盘上，这样就可以实现在物理机上改代码，能够实时保存到虚拟机上。

最后利用ssh远程到虚拟机终端，这样就可以使用Linux的指令做需要的操作了。

思路非常简单，具体操作的过程要解决几个问题：

1. 虚拟机相对物理机的ip必须固定，这样才能每次开机自动挂载虚拟机的文件夹，同时需要保证物理机和虚拟机都能上网，这个是必须解决的问题。
2. 物理机挂载Linux的nfs，必须解决权限问题，要允许物理机对nfs做任何操作，因为IDE会做很多文件操作都需要比较高的权限
3. ssh打开的方式必须能够配置成默认状态，不然每次打开终端都要输入ip，用户和密码都是非常麻烦的事情。

## 开始搭建

现在思路和需要解决的问题我们都清楚了，开始我们的尝试吧。

### 安装Hyper-V

首先是安装hyper-v，这个比较简单：

控制面板 >>> 程序和功能 >>> 启用或关闭window功能 >>> 勾选Hyper-V即可。

> 注意：Hyper-V管理工具和Hyper-V平台都得勾选。

![enter description here][1]

安装完成之后可以在开始任务栏中找到hyper-v管理工具，按下`ctrl+q`并输入`hyper-v`即可看到。

![enter description here][2]

### 配置网络

安装了hyper-v之后，想要hyper-v中的虚拟机能够使用网络，我们就得创建虚拟网卡给hyper-v使用，需要注意的是，一旦创建虚拟网卡，hyper-v就会接管我们整个物理机的网络，物理机的网卡会变成虚拟网卡的交换机，也就是说对我们的物理机使用的网络也是虚拟网卡提供的网络，而虚拟网卡的网络是通过绑定物理网卡获得的。

现在我们先点击右侧的新建虚拟交换管理器：

![enter description here][3]

看到如下对话框：

![enter description here][4]

这里有三种网络：

* 外部
* 内部
* 专用

外部网络指的是可以连接外网的网络，表现形式就是虚拟出几个网卡，也就是每一台虚拟机对应一个虚拟的MAC地址，对外来说相当于一台物理机。

内部网络指的是内部局域网，虚拟机没有对外的ip，只能跟其他虚拟机和当前物理机通讯，相当于一个没有连接网络的路由器，对于外部网络来说，所有的虚拟机都是同一台物理机，虚拟机的ip是由物理机分配的。

专用网络就是一个虚拟机之间的网络，虚拟机只能在虚拟机内部通讯，不能跟物理机通讯，也就是说，对于外部网络，所有的虚拟机都是不存在的，物理机也不知道虚拟机的存在。

从上面的介绍我们就知道了，要解决前面提到的问题1,保证虚拟机相对物理机有固定的ip，那么需要使用内部网络，虚拟机的ip由物理机分配才行，如果使用外部网络，虚拟机的ip是由网关（路由或外层交换机）分配的，这种情况就比较难固定了。

所以这里我们先创建一个内部网络。

创建过程就不详细说了，比较简单。

内部网络创建完成之后，虚拟机就有一个局域网了，只要虚拟机使用这个网络，并且设置固定MAC地址，虚拟机的ip相对物理机就是固定的了。

控制面板 >>> 网络和共享中心 >>> 更改适配器设置

这里至少能看到两个连接：

* vEthernet(内部网络)
* 物理网络连接

内部网络就是我们刚刚创建的网络，物理网络连接就是我们这个时候真正用来连接网络的网卡了。

> 如果是双网卡的电脑，一般会有两个物理网络连接，但是只会有一个连接是已连接的状态。

这个时候我们右键选择物理网络连接(双网卡的情况要选那个已经连接的网络)，选属性。

打开属性对话框，选择共享标签，勾选**允许其他网络用户通过此计算机的Internet连接来连接**

并选择网络连接**vEthernet (内部网络)**表示允许这个连接通过我们的物理网络连接来上网。

![enter description here][5]

确定之后就可以了。

这个设置，其实相当于我们把物理网卡开放一个热点给虚拟网卡的内部网络连接，所有使用内部网络连接的虚拟机都会通过这个物理网络来上网，也就是公网ip都是这个物理网络连接的ip。

这个时候可以真正把我们的物理网络连接理解为虚拟机局域网的路由器了。

到这里我们的网络配置已经完成了。

> 这里我们不设置外部网络，因为一旦设置外部网络，hyper-v会自动使用桥接方式，把物理网卡的网络和虚拟机的外部网络通过网桥连接起来，虽然我们可以使用外部网络共享给内部网络来实现虚拟机内部网络上网，但是这会导致每次重启都得手动重新共享网络，目前还不清楚原因，猜测是这里的共享存在bug导致的，有可能是外部网络连接先初始化完成，导致共享对象找不到，无法共享给内部网络导致的。

#### 配置静态ip

> 经过我的实际测试，使用网络共享的方式非常容易在物理机重启之后无法访问网络，因此还是建议配置静态ip，可以保证在任何时候都能连接，但是虚拟机不能上网，如果需要上网，可以先手动取消网络共享，再重新启动网络共享即可。

在CentOS7下，使用vim编辑网卡配置：

```
$> vim /etc/sysconfig/network-scripts/ifcfg-eth0 
```

修改为如下配置

```
TYPE="Ethernet"
BOOTPROTO="static" # 把原本的DCPH改成static
DEFROUTE="yes"
PEERDNS="yes"
PEERROUTES="yes"
IPV4_FAILURE_FATAL="no"
IPV6INIT="yes"
IPV6_AUTOCONF="yes"
IPV6_DEFROUTE="yes"
IPV6_PEERDNS="yes"
IPV6_PEERROUTES="yes"
IPV6_FAILURE_FATAL="no"
NAME="eth0"
UUID="352339ce-4e5a-4fc6-97ad-db2f89905613"
DEVICE="eth0"
ONBOOT="yes"
DNS1=192.168.137.1 # 添加DNS配置
IPADDR=192.168.137.10 # 指定静态ip
NETMASK=255.255.255.0 # 指定子关掩码
GATEWAY=192.168.137.1 # 指定默认网关
```

在上面的配置中，除了ip地址可以按照需要配置之外，其他的都是hyper的默认配置，建议不要修改。

### 安装Linux虚拟机并配置nfs服务

现在我们可以在hyper-v中创建一个虚拟机并安装Linux系统了，这里我安装的是CentOS7的操作系统。

安装的过程比较简单，不细说了。

安装完成之后，使用root账号登录。

> 由于虚拟机是在本机，并且使用了内部网络，因此是比较安全的，为了方便使用nfs，避免各种权限问题，**强烈建议所有操作使用root用户**，包括后边我们使用window的nfs客户端，也会改成使用root的权限来挂载网络磁盘。

现在我们需要先安装nfs服务：

```
$> yum install -y nfs-utils rpcbind
```

安装完成之后，需要配置共享目录和允许的客户端ip。

```
$> vim /etc/exports
```

加入如下内容：

```
#共享目录   允许连接的客户端(可读写,同步磁盘和内存,不压缩root用户)
/root       192.168.137.1(rw,sync,no_root_squash)
```

这里关于nfs的配置不过更深入的讨论，我们只使用root账户连接，并且只支持物理机的ip。

这里注意，物理机的ip一般是固定的`192.168.137.1`，如果不确定，自己用ipconfig命令查看。

修改完成之后，执行如下命令让修改生效：

```
$> exportfs -rv
```

然后使用如下命令查看最终结果：

```
$> exportfs -v
/root  192.168.137.1(rw,wdelay,no_root_squash,no_subtree_check,sec=sys,rw,no_root_squash,no_all_squash)
```

启动服务：

```
$> service nfs restart
Redirecting to /bin/systemctl restart  nfs.service
```

服务端配置完成，现在我们配置客户端，就是物理机：

控制面板 >>> 程序和功能 >>> 启用或关闭window功能 >>> 勾选NFS服务。

![enter description here][6]

然后打开命令行：

```
C:\> mount ${虚拟机ip}:/root X:
X: 现已成功连接到 192.168.137.10:/root

命令已成功完成。

```

连接成功，现在可以在我的电脑里看到X盘符：

不过此时由于权限问题无法访问，我们先取消挂载：

```
C:\> umount X:
正在断开连接            X:      \\192.168.137.10\root
命令已成功完成。

```

现在打开注册表：

win+r >> regedit

找到HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ClientForNFS\CurrentVersion\Default，给其中增加两个QWORD64位值：

```
AnonymousUid
AnonymousGid
```

这两个值默认是0，不用改。

![enter description here][7]

> 0,是root用户的id，理论上可以改成任意你想要的用户id值,在Linux系统上用指定的用户登录，然后使用`id`指令即可看到用户id：
>
> ```
> $> id
> uid=0(root) gid=0(root) groups=0(root)  context=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
> ```

客户端身份修改完成。重启电脑使得注册表生效。

重启之后虚拟机的网络会出现问题，目前还不太清楚原因：

但是我们会发现虚拟机没有ip了，所有无法连接，这个时候只要打开网络共享中心，会看到至少如下四个连接：

* vEthernet(内部网络)
* 物理网络连接

并且这里物理网络是共享的，只要取消物理网络共享，然后重新开启物理网络共享即可：


现在重新挂载网络地址，为了保证每次开机自动挂载，直接打开我的电脑，右键我的电脑，选择**映射网络驱动器...**

![enter description here][8]

输入挂载信息，并勾选登陆时重新连接即可：

![enter description here][9]

现在发现可以打开X盘了，右键X盘，选择属性，并打开NFS装载选项，可以看到：

![enter description here][10]

UID和主GID都是0,表示的是root账号，如果没有修改注册表的话，默认是-2，即匿名用户。

到这里我们已经可以在window任意修改Linux共享的文件夹了。

### 用idea做应用开发

到这里已经很好理解了，现在X盘相当于我们的工作空间，在X盘的文件修改都会同步映射到虚拟机上，所以我们可以在这里创建一个普通的maven工程：

![enter description here][11]

创建完这个工程之后，开发的过程和在本地开发完全一致，不过idea相当智能，由于通过网络读写文件，硬盘读写性能瓶颈比较突出，因此idea会给出警告：

![enter description here][12]

不过这不影响我们使用。

现在该使用idea提供的远程连接工具了SSH了。

打开 Setting > Tools > SSH Terminal

![enter description here][13]

点击Configure Server:

![enter description here][14]

添加一个远程SFTP服务器，配置相关的ssh连接：

![enter description here][15]

保存，然后回到Setting > Tools > SSH Terminal：

选择deployment server为我们刚刚保存的部署服务器，并且修改默认编码为UTF-8

![enter description here][16]

保存。

现在我们再修改一下快捷键，打开 Setting > keymap，

在搜索栏输入ssh，找到ssh终端的选项，右键选择已安家快捷键：

![enter description here][17]

输入你习惯的快捷键，我使用的是`Ctrl+H`。

![enter description here][18]

OK，一切设置妥当，这个时候我们回到编辑区，按下`Ctrl+H`:

![enter description here][19]

这个时候发现已经打开Linux终端了，现在我们可以使用Linux指令对这个工程的文件进行操作了。

接下来就是按照你的开发需要，在Linux虚拟机上安装相应的指令，然后就可以开始愉快得假装在Linux上做开发咯。


  [1]: {{{{site.image_repo1}}/hyper_v_linux/images/1.png "1.png"
  [2]: {{{{site.image_repo1}}/hyper_v_linux/images/2.png "2.png"
  [3]: {{{{site.image_repo1}}/hyper_v_linux/images/1483106967942.jpg "1483106967942.jpg"
  [4]: {{{{site.image_repo1}}/hyper_v_linux/images/1483107041298.jpg "1483107041298.jpg"
  [5]: {{{{site.image_repo1}}/hyper_v_linux/images/1483113364942.jpg "1483113364942.jpg"
  [6]: {{{{site.image_repo1}}/hyper_v_linux/images/1483114773713.jpg "1483114773713.jpg"
  [7]: {{{{site.image_repo1}}/hyper_v_linux/images/1483115362207.jpg "1483115362207.jpg"
  [8]: {{{{site.image_repo1}}/hyper_v_linux/images/1483159413859.jpg "1483159413859.jpg"
  [9]: {{{{site.image_repo1}}/hyper_v_linux/images/1483159461623.jpg "1483159461623.jpg"
  [10]: {{{{site.image_repo1}}/hyper_v_linux/images/1483116622451.jpg "1483116622451.jpg"
  [11]: {{{{site.image_repo1}}/hyper_v_linux/images/1483155110579.jpg "1483155110579.jpg"
  [12]: {{{{site.image_repo1}}/hyper_v_linux/images/1483155306022.jpg "1483155306022.jpg"
  [13]: {{{{site.image_repo1}}/hyper_v_linux/images/1483155379234.jpg "1483155379234.jpg"
  [14]: {{{{site.image_repo1}}/hyper_v_linux/images/1483155428965.jpg "1483155428965.jpg"
  [15]: {{{{site.image_repo1}}/hyper_v_linux/images/1483155500924.jpg "1483155500924.jpg"
  [16]: {{{{site.image_repo1}}/hyper_v_linux/images/1483155537687.jpg "1483155537687.jpg"
  [17]: {{{{site.image_repo1}}/hyper_v_linux/images/1483155661002.jpg "1483155661002.jpg"
  [18]: {{{{site.image_repo1}}/hyper_v_linux/images/1483155694731.jpg "1483155694731.jpg"
  [19]: {{{{site.image_repo1}}/hyper_v_linux/images/1483155830927.jpg "1483155830927.jpg"