---
layout: post
comments: true
categories: 黑科技
title: 使用hyper-v搭建nat内部网络
tags: hyper-v,nat网络,内部局域网
grammar_cjkRuby: true
author: kael
---

* content
{:toc}

## 前言

很多时候，我们开发应用的时候，需要搭一整套完整的开发环境，对于大型的应用，可能开发环境需要多台机器运行不同的服务。
为了能在自己的单台电脑上搭建整套开发环境，一般会选择使用虚拟机，直接安装多台虚拟机搭建。
使用虚拟机的时候，就带来了一个网络问题：

* 虚拟机和宿主机之间的网络通讯
* 虚拟机和虚拟机之间的网络通讯
* 虚拟机和互联网的网络通讯问题
* 所有虚拟机和物理机之间的相对IP必须固定

要解决这个问题，就必须搭建一套内部的局域网，为了保证各个机器之间的IP相对固定，一般使用NAT网络拓扑，使得所有机器对外统一使用物理机IP，
各个虚拟机之间有一套内部的局域网，并且IP是固定的。

如果使用VMWare的话，这个NAT网络几乎是完全自动搭建的，不用多说，因此本文主要介绍在hyper-v上如何搭建这套完整的基于NAT内部局域网。

本文参考：[设置NAT网络](https://docs.microsoft.com/zh-cn/virtualization/hyper-v-on-windows/user-guide/setup-nat-network)

> **注意：** 在windows 10升级到1709版本后，内置了一个`默认开关`的网络交换机，已经实现这种全自动的NAT网络搭建，不需要再按照本文进行搭建了。  
> 不过，如果是在升级之前已经搭建好的虚拟机，需要 __右键 -> 升级到新版配置__ 才能使用默认开关进行自动IP配置。但是`默认开关`网络交换机不保证
> IP地址不变。需要固定的地址还是需要配置。

## 网络拓扑结构

最终实现的网络拓扑结构如下：

![]({{site.image_repo1}}/hyper_v_nat/hyper_v_nat_1.png)

要实现这样的结果，需要按照如下步骤：

* 创建虚拟网络交换机
* 创建NAT虚拟网络
* 设置虚拟机连接NAT虚拟网络
* 设置虚拟机静态IP

## 开始前的检查

> 以下操作需要使用PowerShell操作。

* **目前windows的NAT虚拟网络只能支持一个，因此在开始创建NAT网络之前需要先检查是否已存在NAT网络**

```
PS> Get-NetNat

Name                             : NATOutsideName
ExternalIPInterfaceAddressPrefix :
InternalIPInterfaceAddressPrefix : 192.168.10.0/24
IcmpQueryTimeout                 : 30
TcpEstablishedConnectionTimeout  : 1800
TcpTransientConnectionTimeout    : 120
TcpFilteringBehavior             : AddressDependentFiltering
UdpFilteringBehavior             : AddressDependentFiltering
UdpIdleSessionTimeout            : 120
UdpInboundRefresh                : False
Store                            : Local
Active                           : True

```

如上情况说明已经存在NAT网络，需要先删除：

```
PS> Get-NetNat | Remove-NetNat
```

* **确保应用程序或功能（例如 Windows 容器）仅有一个“内部”vmSwitch。 记录 vSwitch 的名称**

```
PS> Get-VMSwitch

Name       SwitchType NetAdapterInterfaceDescription
----       ---------- ------------------------------
默认开关   Private
SwitchName Internal

```

> 我这里有两个虚拟交换机，其中`默认开关`是私有的（hyper-v自带），`SwitchName`是内部的，就是我自己创建的。

如果需要重新创建虚拟交换机，请先删除已有的内部虚拟交换机：

```
PS> Remove-VMSwitch -SwitchName "SwitchName"
确认
是否确实要删除虚拟交换机“SwitchName”?
[Y] 是(Y)  [A] 全是(A)  [N] 否(N)  [L] 全否(L)  [S] 暂停(S)  [?] 帮助 (默认值为“Y”): y
```

* **检查是否仍存在从旧 NAT 向适配器分配的专用 IP 地址（例如 NAT 默认网关 IP 地址 – 通常为 \*.1）**

```
PS> Get-NetIPAddress -InterfaceAlias "vEthernet (<name of vSwitch>)"

IPAddress         : fe80::a5fb:711b:2725:2b56%38
InterfaceIndex    : 38
InterfaceAlias    : vEthernet (SwitchName)
AddressFamily     : IPv6
Type              : Unicast
PrefixLength      : 64
PrefixOrigin      : WellKnown
SuffixOrigin      : Link
AddressState      : Preferred
ValidLifetime     : Infinite ([TimeSpan]::MaxValue)
PreferredLifetime : Infinite ([TimeSpan]::MaxValue)
SkipAsSource      : False
PolicyStore       : ActiveStore

IPAddress         : 192.168.10.1
InterfaceIndex    : 38
InterfaceAlias    : vEthernet (SwitchName)
AddressFamily     : IPv4
Type              : Unicast
PrefixLength      : 24
PrefixOrigin      : Manual
SuffixOrigin      : Manual
AddressState      : Preferred
ValidLifetime     : Infinite ([TimeSpan]::MaxValue)
PreferredLifetime : Infinite ([TimeSpan]::MaxValue)
SkipAsSource      : False
PolicyStore       : ActiveStore
```

如果仍存在需要删除：

```
PS> Remove-NetIPAddress -InterfaceAlias "vEthernet (<name of vSwitch>)" -IPAddress <IPAddress>
```

## 创建虚拟交换机并配置NAT网络

创建虚拟交换机，需要以管理员身份打开PowerShell，以下所有指令都在管理员权限下的PowerShell中执行。

### 创建虚拟交换机

```
PS> New-VMSwitch -SwitchName "SwitchName" -SwitchType Internal

Name       SwitchType NetAdapterInterfaceDescription
----       ---------- ------------------------------
SwitchName Internal
```

> 这里的`"SwitchName"`是交换机的名字，可以按自己需求修改，在这里我们就用这个名字。

### 查找并记录虚拟交换机的接口索引

```
PS> Get-NetAdapter

Name                      InterfaceDescription ifIndex Status       MacAddress   LinkSpeed
----                      -------------------- ------- ------------ ----------   ---------
vEthernet (SwitchName)    Hyper-V ...          38      Up           00-15-5D-... 10 Gbps
以太网                    Realtek ...          22      Disconnected 80-FA-5B-... 0 bps
WLAN                      Broadcom ...         2       Up           48-D2-24-... 130 Mbps
```

这里的`vEthernet (SwitchName)`就是我们刚刚创建的虚拟机，注意，这里的`ifIndex`就是**接口索引**，我这里的值是38。

### 配置NAT网关

```
PS> New-NetIPAddress -IPAddress <NAT Gateway IP> -PrefixLength <NAT Subnet Prefix Length> -InterfaceIndex <ifIndex>
```

> 参数含义：
>
> * **IPAddress** - NAT 网关 IP 指定要用作 NAT 网关 IP 的 IPv4 或 IPv6 地址。常规形式将为 a.b.c.1（例如 172.16.0.1）。 尽管最后一个位置不一定必须是.1，但通常是（基于前缀长度），通用网关 IP 为 192.168.0.1
> * **PrefixLength** - NAT 子网前缀长度定义的 NAT 本地子网大小（子网掩码）。子网前缀长度将为 0 到 32 之间的整数值。0 将映射整个 Internet，32 将只允许一个映射的 IP。常用值的范围为 24 到 12，具体取决于需要附加到 NAT 的 IP 数。常用 PrefixLength 为 24 -- 这是子网掩码 255.255.255.0
> * **InterfaceIndex** - ifIndex 是你在上一步中确定的虚拟交换机的接口索引。

运行如下命令即可创建NAT网关：

```
PS> New-NetIPAddress -IPAddress 192.168.10.1 -PrefixLength 24 -InterfaceIndex 38
```

### 配置 NAT 网络

配置NAT网络一般用如下命令：

```
PS> New-NetNat -Name <NATOutsideName> -InternalIPInterfaceAddressPrefix <NAT subnet prefix>
```

> 参数含义：
> 
> * **Name** - NATOutsideName 描述 NAT 网络的名称。 将使用此参数删除 NAT 网络。
> * **InternalIPInterfaceAddressPrefix** - NAT 子网前缀同时描述上述 NAT 网关 IP 前缀和上述 NAT 子网前缀长度。常规形式将为 a.b.c.0/NAT 子网前缀长度,综上所述，对于本示例，我们将使用 192.168.0.0/24

对于我们的示例，运行以下命令以设置 NAT 网络：

```
PS> New-NetNat -Name MyNATnetwork -InternalIPInterfaceAddressPrefix 192.168.10.0/24
```

到这里，一个可用的虚拟NAT网络已经配置完成。

## 设置虚拟交换机使用NAT网络

在hyper-v的管理器中，设置虚拟机，如下：

![]({{site.image_repo1}}/hyper_v_nat/hyper_v_nat_2.png)

在**网络适配器**选项中，选择我们刚刚创建的虚拟交换机：

![]({{site.image_repo1}}/hyper_v_nat/hyper_v_nat_3.png)

## 设置虚拟机静态IP

我们创建的虚拟交换机实际上不能作为dhcp服务器，因此不会自动给虚拟机分配IP，所以所有使用这个交换机的虚拟机都得在虚拟机内设置静态IP。

> 如果使用VMWare的话，这个ip是可以自动设置的，但是微软似乎是故意做成需要管理员手动设置IP的，我也不明白为什么这么做。

虚拟机内我们主要需要设置如下几项：

* 网关地址
* DNS地址
* IP地址
* 设置获取IP方式为静态

这里以centOS 7为例说明在linux下的设置，windows或其他操作系统请自行百度。

```
$> vim /etc/sysconfig/network-scripts/ifcfg-eth0
TYPE="Ethernet"
BOOTPROTO="static" # dhcp -> static
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
UUID="72a5c366-1b72-4ee9-b06d-3cb446b47588"
DEVICE="eth0"
ONBOOT="yes" # no -> yes 
IPADDR="192.168.10.2" # 指定IP地址
NETMASK="255.255.255.0" # 指定子关掩码
GATEWAY="192.168.10.1" # 指定网关地址
DNS1="8.8.8.8" # 指定DNS1服务器，如果不指定的话，无法解析域名，因为NAT网关不能作为DNS服务器
```

修改完成后保存退出，重启网卡：

```
$> service network restart
```

重启后即可和主机通讯：

```
$> ping 192.168.10.1
PING 192.168.10.1 (192.168.10.1) 56(84) bytes of data.
64 bytes from 192.168.10.1: icmp_seq=1 ttl=128 time=0.252 ms
64 bytes from 192.168.10.1: icmp_seq=2 ttl=128 time=0.236 ms
64 bytes from 192.168.10.1: icmp_seq=3 ttl=128 time=0.644 ms
64 bytes from 192.168.10.1: icmp_seq=4 ttl=128 time=0.172 ms
64 bytes from 192.168.10.1: icmp_seq=5 ttl=128 time=0.227 ms
```

同样的主机也可以和虚拟机通讯：

```
PS> ping 192.168.10.2
正在 Ping 192.168.10.2 具有 32 字节的数据:
来自 192.168.10.2 的回复: 字节=32 时间<1ms TTL=64
来自 192.168.10.2 的回复: 字节=32 时间<1ms TTL=64

192.168.10.2 的 Ping 统计信息:
    数据包: 已发送 = 2，已接收 = 2，丢失 = 0 (0% 丢失)，
往返行程的估计时间(以毫秒为单位):
    最短 = 0ms，最长 = 0ms，平均 = 0ms
```

### 解决ssh连接虚拟机慢的问题

配置好nat网络之后，物理机ping虚拟机已经通了，但是有可能ssh连接会很慢，这是因为虚拟机的ssh服务使用DNS回查导致的。可以在虚拟机中配置关闭ssh服务的DNS回查，并重启即可：

```
$> vim /etc/ssh/sshd_config
```

找到如下配置：

```
#ClientAliveInterval 0
#ClientAliveCountMax 3
#ShowPatchLevel no
#UseDNS yes
#PidFile /var/run/sshd.pid
#MaxStartups 10:30:100
#PermitTunnel no
```

修改为

```
#ClientAliveInterval 0
#ClientAliveCountMax 3
#ShowPatchLevel no
UseDNS no # yes -> no
#PidFile /var/run/sshd.pid
#MaxStartups 10:30:100
#PermitTunnel no
```

然后重启sshd服务：

```
$> service sshd restart
```

> 解释下UseDNS,当客户端试图登录SSH服务器时，服务器端先根据客户端的IP地址进行DNS PTR反向查询出客户端的主机名，然后根据查询出的客户端主机名进行DNS正向A记录查询，验证与其原始IP地址是否一致，这是防止客户端欺骗的一种措施，但大部分IP都没有配置PTR记录，如果没有特别的情况，一般建议关闭。

## 卸载虚拟交换机和NAT网络

安装完成之后，有时候需要完整卸载重新安装，可以按照如下方式：

### 卸载NAT网络

```
PS> Get-NetNat | Remove-NetNat
```

### 卸载NAT网络IP地址

```
PS> Remove-NetIPAddress -InterfaceAlias "vEthernet (<name of vSwitch>)" -IPAddress <IPAddress>
```

> * **vEthernet (\<name of vSwitch\>)** - 这个值可以通过`Get-VMSwitch`找到要卸载的虚拟交换机。
> * **\<IPAddress\>** - 这个值可能有多个，通过`Get-NetIPAddress -InterfaceAlias "vEthernet (<name of vSwitch>)"`找到全部后一个一个删除。

### 卸载虚拟交换机

```
PS> Remove-VMSwitch -SwitchName "SwitchName"
```

> **"SwitchName"** - 这个值通过`Get-VMSwitch`找到要卸载的虚拟交换机即可。

完成以上三步即可卸载干净。