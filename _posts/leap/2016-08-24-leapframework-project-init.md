---
layout: post
comments: false
categories: leap笔记
title: "leap的开发环境搭建"
---

## leap介绍

leap是一个java web应用开发框架，全称是Light Enterprise Application Platform。主要定位是企业应用和互联网应用开发框架。

简单一点说，就是类似目前流行的Spring + Struts + Hibernate或者Spring + Struts + Mybatis的框架。

不过leap比上面的两个组合框架有几点好处:

* 更轻量
* 内置各模块深度整合
* 更统一的编码风格
* 环境搭建更简单

关于leap的更多介绍和详细信息，可以在[官网](http://leapframework.org/)看到。

## leap的环境搭建

为了让大家更了解leap的文档结构，我先从搭建完成后的leap开发工程的目录结构说起吧，如下：

```
leap
  ┣━ src
  ┃   ┣━ main
  ┃   ┃    ┣━ java
  ┃   ┃    ┃    ┗━ app
  ┃   ┃    ┃        ┗━ test
  ┃   ┃    ┃            ┣━ Global.java
  ┃   ┃    ┃            ┗━ controller
  ┃   ┃    ┃                   ┗━ HomeController.java
  ┃   ┃    ┣━ resources
  ┃   ┃    ┃     ┗━ conf
  ┃   ┃    ┃         ┣━ beans.xml
  ┃   ┃    ┃         ┗━ config.xml
  ┃   ┃    ┗━ webapp
  ┃   ┃         ┗━ WEB-INF
  ┃   ┃              ┣━ views
  ┃   ┃              ┃    ┗━ index.html
  ┃   ┃              ┗━ web.xml
  ┃   ┗━ test
  ┃        ┣━ java
  ┃        ┗━ resources
  ┃        
  ┗━ pom.xml
```

可以看到这是一个标准的maven工程目录结构。

接下来我们一步一步来新建这样的工程目录。

### 新建pom.xml文件

在准备开发的目录新建一个文件夹，名称可以随意定，建议是工程名，这里我们假设创建的工程目录名为leap。

在leap目录下创建pom.xml，内容如下:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>leap.test</groupId>
    <artifactId>leap-test-0.2.0b</artifactId>
    <version>0.2.0b</version>
    <packaging>war</packaging>
    <repositories>
        <!-- leap快照资源库 -->
        <repository>
            <id>leap-snapshots</id>
            <url>https://raw.githubusercontent.com/leapframework/repo/master/snapshots</url>
            <snapshots>
                <enabled>true</enabled>
                <updatePolicy>always</updatePolicy>
                <checksumPolicy>warn</checksumPolicy>
            </snapshots>
        </repository>

        <repository>
            <id>leap-releases</id>
            <url>https://raw.githubusercontent.com/leapframework/repo/master/releases</url>
            <releases>
                <enabled>true</enabled>
                <updatePolicy>never</updatePolicy>
                <checksumPolicy>warn</checksumPolicy>
            </releases>
        </repository>
    </repositories>
    <dependencies>
        <dependency>
            <groupId>org.leapframework</groupId>
            <artifactId>leap</artifactId>
            <version>0.2.0b</version>
            <type>pom</type>
        </dependency>
        <dependency>
            <groupId>com.h2database</groupId>
            <artifactId>h2</artifactId>
            <version>1.3.172</version>
        </dependency>
    </dependencies>

</project>
```

这里我们依赖leap的0.2.0b的版本，需要注意的是，leap目前还没有发布到maven的中心库，使用的是自己搭建的maven库，因此需要配置maven的leap资源库。

### 初始化maven目录结构

接下来我们按照maven工程的目录结构创建相应的文件夹:

* src/main/java
* src/main/resource
* src/main/webapp
* src/test/java
* src/test/resource

创建完成以上几个目录后，maven的目录结构已经创建好了。

### 新建配置文件

leap有非常强的扩展性，同时必须配置的配置项也非常少，本文只介绍必须的配置项，更多配置项可以从[官方文档](http://leapframework.org/doc/index.html)里看。

我们在`src/main/resource`下创建`conf`目录，这个目录是leap约定的配置目录，不能改变。
在conf下创建两个配置文件`beans.xml`和`config.xml`，内容如下：

config.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<config xmlns="http://www.leapframework.org/schema/config">
    <base-package>app.test</base-package>
    <properties>
        <property name="jdbc.driverClassName">org.h2.Driver</property>
        <property name="jdbc.url">jdbc:h2:./target/test;DB_CLOSE_ON_EXIT=FALSE</property>
        <property name="jdbc.username">sa</property>
    </properties>
</config>
```

beans.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.leapframework.org/schema/beans">
    <bean type="javax.sql.DataSource" class="leap.db.cp.PooledDataSource">
        <property name="driverClassName" value="${jdbc.driverClassName}" />
        <property name="jdbcUrl"         value="${jdbc.url}" />
        <property name="username"        value="${jdbc.username}" />
        <property name="password"        value="${jdbc.password}" />
    </bean>
</beans>
```

这里我配置了一些基本的属性，最核心的配置其实只有一项`<base-package>app.test</base-package>`，这一项配置是必须的，表示的是leap扫描包的根目录，其他的配置在不需要数据库的时候可以省略。

这里config.xml一般用于配置一些经常变化的属性，beans.xml用于配置leap ioc容器中的bean。

### 创建对应的类

我们先在`src/main/java`下创建包`app.test`和`app.test.controller`。

然后在包`app.test`下创建`Global.java`，内容如下：

```java
package app.test;

import leap.web.App;

public class Global extends App {
}

```

这里`leap.web.App`是leap提供的类，一般我们会在自己的工程的`base-package`下创建`Global`类并继承这个类来做应用的初始化，应用初始化通过重写`App`类的`init()`方法来实现，当然这不是必须的。

接下来我们在包`app.test.controller`下创建`HomeController.java`类，内容如下：

```java
package leap.test.controller;
import leap.web.action.ControllerBase;
import leap.web.view.ViewData;

/**
 * Created by kael on 2016/7/8.
 */
public class HomeController extends ControllerBase {


    public void index(ViewData vd){
        
    }
}

```

这个类是leap的控制器，实际上，leap会把所有类名后缀为`Controller`的类当成控制器，并把控制器下所有的公共方法当成http url接口。默认控制器的根就是`index()`方法。

### 创建`web.xml`和`index.html`

我们知道，web.xml是web应用中必须的描述文件(在servlet 3.0以后不再是必须的)。leap的入口也是在web.xml中配置的。
我们在`src/webapp`下创建`WEB-INF`目录，并在`WEB-INF`目录下创建`web.xml`，内容如下:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xmlns="http://java.sun.com/xml/ns/javaee"
         xsi:schemaLocation="http://java.sun.com/xml/ns/javaee http://java.sun.com/xml/ns/javaee/web-app_3_0.xsd"
         version="3.0">
    <filter>
        <filter-name>app-filter</filter-name>
        <filter-class>leap.web.AppFilter</filter-class>
    </filter>
    <filter-mapping>
        <filter-name>app-filter</filter-name>
        <url-pattern>/*</url-pattern>
    </filter-mapping>
</web-app>
```

这里需要指定用leap的拦截器接管所有请求。

然后我们再创建第一个视图文件，在`WEB-INF`下创建`views`目录，并在`views`下创建`index.html`文件，内容如下:

```html
<html>
<head>
    <title>test</title>
</head>
<body>
Hello leap!
</body>
</html>
```

到这里我们整个工程目录已经创建成功，只要把工程导入到ide内即可开始leap开发。当然，如果你熟悉的话，也可以直接在ide内搭建这个开发环境。

