---
layout: post
comments: true
categories: leap笔记
title: leap的单元测试中的instrument问题
tags: instrument,leap,单元测试
grammar_cjkRuby: true
---

* content
{:toc}

## 前言

今天用leap开发公司的一个api，由于我现在比较习惯使用测试驱动开发，所以经常是先完成一个单元测试，再基于单元测试做功能，今天在写单元测试的时候遇到了一个问题，属于leap的一个比较深层次的问题了，所以决定记录一下。

## 问题

因为leap本身提供了单元测试模块，可以非常方便的写leap单元测试和leap-web单元测试，我写单元测试用的也是leap的单元测试模块，所以严格来说这个问题是leap的单元测试模块的一个问题，我们先来看看单元测试的代码：

首先是`BaseModel`类，这个类继承了`Model`类：

```java
@NonEntity
public class BaseModel extends Model {
    @Id
    private String id;
    @Column
    private String name;

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
}
```

然后是`Model1`类，这个类继承了`BaseModel`类，并且指定了数据库表：

```java
@Table("model1")
public class Model1 extends BaseModel {
}
```

我们看到`Model1`类自身没有属性，所有的属性都是继承过来的，并且是一个数据库表的映射类，因此这个类是需要leap做字节码增强的。

接下来看我们单元测试的代码：

```java
public class InstrumentTest1 extends WebTestBase {

    @Test
    public void testInstrumentSubModel(){
        defineClassImmediately(new Model1());

        assertNotNull(Model1.dao());
    }
    protected void defineClassImmediately(BaseModel model) {
    }
}
```

这个时候当我们运行单元测试的时候，就会抛出如下异常：

```
java.lang.IllegalStateException: Failed to determine Model class name, are you sure models have been instrumented?

	at leap.orm.model.Model.getClassName(Model.java:479)
	at leap.orm.model.Model.context(Model.java:464)
	at leap.orm.model.Model.dao(Model.java:444)
	at tested.InstrumentTest1.testInstrumentSubModel(InstrumentTest1.java:31)
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.lang.reflect.Method.invoke(Method.java:497)
	at org.junit.runners.model.FrameworkMethod$1.runReflectiveCall(FrameworkMethod.java:47)
	at org.junit.internal.runners.model.ReflectiveCallable.run(ReflectiveCallable.java:12)
	at org.junit.runners.model.FrameworkMethod.invokeExplosively(FrameworkMethod.java:44)
	at org.junit.internal.runners.statements.InvokeMethod.evaluate(InvokeMethod.java:17)
	at org.junit.internal.runners.statements.RunBefores.evaluate(RunBefores.java:26)
	at org.junit.internal.runners.statements.RunAfters.evaluate(RunAfters.java:27)
	at org.junit.rules.TestWatcher$1.evaluate(TestWatcher.java:55)
	at org.junit.rules.RunRules.evaluate(RunRules.java:20)
	at org.junit.runners.ParentRunner.runLeaf(ParentRunner.java:271)
	at org.junit.runners.BlockJUnit4ClassRunner.runChild(BlockJUnit4ClassRunner.java:70)
	at leap.webunit.WebTestRunner.runChild(WebTestRunner.java:115)
	at leap.webunit.WebTestRunner.runChild(WebTestRunner.java:35)
	at org.junit.runners.ParentRunner$3.run(ParentRunner.java:238)
	at org.junit.runners.ParentRunner$1.schedule(ParentRunner.java:63)
	at org.junit.runners.ParentRunner.runChildren(ParentRunner.java:236)
	at org.junit.runners.ParentRunner.access$000(ParentRunner.java:53)
	at org.junit.runners.ParentRunner$2.evaluate(ParentRunner.java:229)
	at org.junit.runners.ParentRunner.run(ParentRunner.java:309)
	at org.junit.runner.JUnitCore.run(JUnitCore.java:160)
	at com.intellij.junit4.JUnit4IdeaTestRunner.startRunnerWithArgs(JUnit4IdeaTestRunner.java:117)
	at com.intellij.junit4.JUnit4IdeaTestRunner.startRunnerWithArgs(JUnit4IdeaTestRunner.java:42)
	at com.intellij.rt.execution.junit.JUnitStarter.prepareStreamsAndStart(JUnitStarter.java:262)
	at com.intellij.rt.execution.junit.JUnitStarter.main(JUnitStarter.java:84)
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.lang.reflect.Method.invoke(Method.java:497)
	at com.intellij.rt.execution.application.AppMain.main(AppMain.java:147)
```

为什么会抛出这个异常呢？实际上这里跟leap的实现有关，更深层次一点，和jvm的类加载机制有关。

## 异常原理解析

要知道这个异常产生的原因，我们需要先了解leap的实现机制。

leap框架中，很多功能都是通过字节码增强(instrument)实现的，简单的说，字节码增强就是通过修改类的字节码文件，增加类的功能，为了实现字节码增强，leap也实现了自己的类加载器，所有需要leap做字节码增强的类，都必须由leap的类加载器来加载，leap在启动的时候，会将启动线程的类加载器设置为leap的类加载器，因此可以保证leap启动之后，所有的类加载都经过leap的类加载器来加载和处理，所以上面说的问题一般情况下不会出现在真正运行的过程，而是出现在单元测试的过程。

> 注意：如果在运行的过程出现了这个错误，可以检查一下`config.xml`的配置，看下`<base-package>`是否有包含需要leap加载的类所在的包下，如果没有包含，leap也加载不到这个类。

那么为什么在单元测试的过程会出现这个异常呢？这是因为leap的单元测试框架是基于junit实现的，而各个ide和构建工具对junit的支持都不尽相同，这里就涉及到jvm的类加载机制了。

> jvm的类加载机制也是一个比较深入的话题，这里先不展开讲，下次有时间我会专门针对jvm的类加载机制写一篇博客，现在我只简单描述一下问题。

这里简单说一下jvm类加载机制跟这个问题有关的三个关键特性：

* jvm在加载类的时候，首先会分析类的依赖，如父类，祖父类，类中引入的其他类等，都是这个类的依赖类，加载这个类之前要先加载依赖的类所有依赖类都加载完之后，才真正加载这个类；
* jvm加载类的过程，会首先把类交给当前类加载器的父类加载器，看父加载器是否已经加载，如果所有父加载器都没有加载过，才会使用自己的类加载器加载；
* 如果一个类已经被加载过了，那么这个类既不能修改，也不能重新加载。

因此，当使用单元测试的时候，junit框架会首先启动并运行起来，在这个过程中，leap框架还没启动，这个过程junit会开始加载自己的单元测试类，然后在这个过程中，完全是由jvm的`AppClassLoader`来主导加载类的，由于类的依赖关系，这个过程会把一些需要leap加载处理的类先给加载到jvm中，然后leap再启动起来开始加载类，但是由于某些类已经被jvm加载过了，导致leap的类加载器无法重复加载这个类，所以也就没办法对类进行字节码增强了。

后续在运行的时候，leap会在某些需要的地方检查类是否经过字节码增强，如果是需要字节码增强，但是却没有经过字节码增强，这个时候就看会抛出前面看到的异常了。

我们可以使用jvm的参数`-verbose:class`来看一下类加载的过程，在单元测试运行的命令中添加jvm启动参数`-verbose:class`，可以看到日志中打印了类加载的过程：

```
// .... 省略无关的类加载记录

[Loaded leap.orm.model.Model from file:/F:/mavenRepository/org/leapframework/leap-orm/0.2.2b/leap-orm-0.2.2b.jar]
[Loaded test.model.BaseModel from file:/F:/idea-2016.1-workspace/instrument/target/classes/]
[Loaded test.model.Model1 from file:/F:/idea-2016.1-workspace/instrument/target/classes/]

// .... 省略无关的类加载记录

[Loaded leap.web.AppBootstrap$AppBeanProcessor from __JVM_DefineClass__]
[Loaded leap.web.AppBootstrap$AppBeanProcessor$LeapReflectAccessor from __JVM_DefineClass__]
[Loaded leap.web.AppInitializer from file:/F:/mavenRepository/org/leapframework/leap-web/0.2.2b/leap-web-0.2.2b.jar]
[Loaded leap.web.DefaultAppInitializer from __JVM_DefineClass__]
```

从这里我们可以看到，有一部分leap相关的类由于依赖关系被jvm先接下到并加载了，因此leap无法再加载并做字节码增强，可以在后续leap启动过程的日志中看到：

```
23:52:48.044 [main] WARN leap.core.AppClassLoader - Instrument failed, class 'test.model.BaseModel'
23:52:48.046 [main] WARN leap.core.AppClassLoader - Redefine failed class 'test.model.BaseModel' by class loader!
23:52:48.063 [main] WARN leap.core.AppClassLoader - Instrument failed, class 'test.model.Model1'
23:52:48.063 [main] WARN leap.core.AppClassLoader - Redefine failed class 'test.model.Model1' by class loader!
```

这里的警告已经告诉我们，`BaseModel`和`Model1`已经被加载过了，并且字节码增强失败。


## 解决问题

上面的问题产生之后，如何解决呢？有一段时间我跟我老大都以为这个问题无解，不过经过一段时间查资料和研究ide的类加载机制，并参考了jmx的实现机制，我们找到了一个解决方案，并在leap中提供了支持。

我们给leap增加了一个agent模块，实现的原理就是在main方法运行之前先把leap启动起来，这样无论ide或者构建工具(如maven)如何集成junit，都不会影响leap对类的字节码增强，使用的方式也很简单，在jvm启动参数中添加使用agent.jar即可，举例如下：

```
$ > java -jar Main.jar -javaagent:${mavenRepository}/org/leapframework/leap-agent/${leap.version}/leap-agent-${leap.version}.jar
```

把上述命令的`${mavenRepository}`替换成你的本地maven库地址，`${leap.version}`替换成依赖的版本号即可。

如果是web工程的单元测试的话，使用如下命令：

```
$ > java -jar Main.jar -javaagent:${mavenRepository}/org/leapframework/leap-agent/${leap.version}/leap-agent-${leap.version}.jar=webunit
```

当然，如果使用maven构建的工程的话，就更好解决了，可以通过maven的插件来配置自动添加指令：

```xml
<build>
  <plugins>
    <plugin>
      <groupId>org.apache.maven.plugins</groupId>
      <artifactId>maven-surefire-plugin</artifactId>
      <version>${plugins.surefire.version}</version>
      <configuration>
        <systemPropertyVariables>
          <file.encoding>UTF-8</file.encoding>
          <org.apache.jasper.compiler.disablejsr199>
          	true
          </org.apache.jasper.compiler.disablejsr199>
        </systemPropertyVariables>
        <argLine>
        	-javaagent:"${settings.localRepository}"/org/leapframework/leap-agent/${project.version}/leap-agent-${project.version}.jar
        </argLine>
      </configuration>
    </plugin>
  </plugins>
</build>
```

对应的web工程配置：

```xml
    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <version>${plugins.surefire.version}</version>
                <configuration>
                    <systemPropertyVariables>
                        <file.encoding>UTF-8</file.encoding>
                        <org.apache.jasper.compiler.disablejsr199>true</org.apache.jasper.compiler.disablejsr199>
                    </systemPropertyVariables>
                    <argLine>
                    	-javaagent:"${settings.localRepository}"/org/leapframework/leap-agent/${leap.version}/leap-agent-${leap.version}.jar=webunit
                    </argLine>
                </configuration>
            </plugin>
        </plugins>
    </build>
```

## 总结

一开始遇到这个问题的时候，我曾经一度以为是单元测试框架的问题，实际上可以把两个Model类的继承关系去掉来解决这个问题，不过这个却不是比较好的解决方案，经过深入的研究，也确实发现这个问题涉及的是leap本身实现上的限制和jvm的机制。

所以越是莫名其妙的问题，越是需要我们去研究的清楚的，因为一般越莫名其妙的问题，牵涉的问题可能就越底层。

这一点不得不佩服我的老大，对技术的理解非常深刻，哪些问题需要深究，哪些问题可以简单解决都有自己的一套方法，尤其记得他跟我说过，越是底层越需要通用，不能有任何特殊处理，越是上层越可以放宽要求，所以到了项目层面的时候，很多问题可能就可以做一些特殊的判断来满足业务需求，而在底层，必须保证通用和抛出的异常准确，上层使用的人才能理解和容易找到问题。
