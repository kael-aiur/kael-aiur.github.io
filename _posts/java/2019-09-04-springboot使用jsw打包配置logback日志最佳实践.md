---
layout: post
comments: true
categories: java
title: springboot使用jsw打包配置logback日志最佳实践
tags: springboot,logback,jsw,日志
grammar_cjkRuby: true
author: kael
---

* content
{:toc}

## 前言

使用springboot开发的应用，可以打包成一个可运行的jar包发布，但在实际生产环境中我们很少这么做，主要是考虑运维和监控相关的工作，一个单独的jar包不方便。

因此更多的作为真正生产发布我们一般打包成一个jsw包([Java Service Wrapper](https://wrapper.tanukisoftware.com/doc/english/download.jsp))发布。

jsw包有自己的日志规范，虽然实际上是在原有的日志框架上套了一个马甲，但是和原应用的日志的规范是冲突的，也就是会出现logback配置的日志文件和jsw配置的日志文件双写的情况，浪费磁盘I/O和存储空间。

为了能使用jsw来发布应用程序，就要想办法解决原应用和wrapper的冲突，使两个日志规范能更好的协作。

笔者自己的实际使用的过程中，主要是用springboot依赖的logback日志框架，因此本文会重点讨论如何在springboot中配置logback和jsw来解决日志的问题。

## 日志需求

在开发过程中，日志配置经常会根据需要进行调整，运维过程中，也要能够按照实际的生产需求配置日志，因此日志框架整合需要满足下面的需求:

* 支持仅在控制台中输出（开发过程常用）
* 支持禁用控制台输出，只输出到文件（生产环境常用）
* 支持日志文件按日期和大小切割
* 支持日志文件现在总大小
* 支持发布后调节日志级别

## 日志框架对比

jsw的日志框架分割日志文件的功能不是很强大，常用如下两种方式滚动：

* 按日期滚动
* 按文件大小滚动

> 截至本文发布时，jsw尚不支持同时按日期和文件大小滚动，对于一天会产生大量日志的应用不适用。

logback的功能非常强大，可以支持按多种方式滚动和分割日志文件，并且可以自己扩展和定制格式化日志，因此我们选择使用logback的规范来配置日志文件记录，禁用jsw的日志输出。

## JSW的wrapper.conf配置

明确使用的日志规范之后就要考虑如何满足日志的配置需求了，首先需要禁用jsw的日志文件输出，但是为了保证使用

```
$> app console
```

命令启动时能在控制台看到输出的日志，需要保留jsw的控制台日志输出，并且为了使得jsw输出的日志格式和logback中配置的完全相同，还需要配置jsw日志只输出日志内容，不做格式化。

最终`wrapper.conf`配置中的日志部分如下：

```
wrapper.console.format=M # 控制台只输出日志内容
wrapper.console.loglevel=INFO # 控制台输出日志级别，这个级别是jsw自己的日志的级别，无论logback输出的级别是什么，都不受这个配置影响
wrapper.logfile.loglevel=NONE # 禁用jsw日志，这里配置之后，下面的几个配置都无效了

wrapper.logfile=logs/wrapper.log
wrapper.logfile.format=M 
wrapper.logfile.maxsize=1m
wrapper.logfile.maxfiles=1
wrapper.syslog.loglevel=NONE
```

主要注意的是，jsw配置的日志级别是jsw自己的日志级别，跟logback的日志级别没有关系，只要logback会输出到控制台的日志，都会输出到jsw的console中，因此logback的日志级别可以独立配置，这里一般建议使用info级别，用于启动是出现异常时检查异常原因。

### maven插件配置

上面的配置可以通过maven插件配置好，直接打包出来的结果就是按要求配置好的。

```xml
<plugin>
    <groupId>org.codehaus.mojo</groupId>
    <artifactId>appassembler-maven-plugin</artifactId>
    <version>2.0.0</version>
    <configuration>
        <target>${project.build.directory}</target>
        <repositoryLayout>flat</repositoryLayout>
        <logsDirectory>logs</logsDirectory>
        <useWildcardClassPath>true</useWildcardClassPath>
        <configurationSourceDirectory>jsw/conf</configurationSourceDirectory>
        <configurationDirectory>conf</configurationDirectory>
        <copyConfigurationDirectory>true</copyConfigurationDirectory>
        <daemons>
            <daemon>
                <id>${daemon-name}</id>
                <mainClass>${daemon-mainClass}</mainClass>
                <jvmSettings>
                    <initialMemorySize>${daemon-JAVA_Xms}</initialMemorySize>
                    <maxMemorySize>${daemon-JAVA_Xmx}</maxMemorySize>
                    <extraArguments>
                        <!-- 
                        Note : if the value is empty the plugin will throw NullPointerException
                        -->
                        <extraArgument>-Djava.wrapper=1 ${daemon-JAVA_OPS}</extraArgument>
                    </extraArguments>
                </jvmSettings>
                <platforms>
                    <platform>jsw</platform>
                </platforms>
                <generatorConfigurations>
                    <generatorConfiguration>
                        <generator>jsw</generator>
                        <includes>
                            <include>linux-x86-32</include>
                            <include>linux-x86-64</include>
                            <include>macosx-universal-32</include>
                            <include>macosx-universal-64</include>
                            <include>windows-x86-32</include>
                            <include>windows-x86-64</include>
                        </includes>
                        <configuration>
                            <property>
                                <name>configuration.directory.in.classpath.first</name>
                                <value>conf</value>
                            </property>
                            <property>
                                <name>set.default.REPO_DIR</name>
                                <value>lib</value>
                            </property>
                            <property>
                                <name>wrapper.console.loglevel</name>
                                <value>INFO</value>
                            </property>
                            <property>
                                <name>wrapper.console.format</name>
                                <value>M</value>
                            </property>
                            <property>
                                <name>wrapper.logfile</name>
                                <value>logs/wrapper.log</value>
                            </property>
                            <property>
                                <name>wrapper.logfile.format</name>
                                <value>M</value>
                            </property>
                            <property>
                                <name>wrapper.logfile.maxsize</name>
                                <value>100m</value>
                            </property>
                            <property>
                                <name>wrapper.logfile.loglevel</name>
                                <value>NONE</value>
                            </property>
                            <property>
                                <name>wrapper.startup.timeout</name>
                                <value>1800</value>
                            </property>
                            <property>
                                <name>wrapper.ping.timeout</name>
                                <value>1800</value>
                            </property>
                            <property>
                                <name>wrapper.ntservice.name</name>
                                <value>${daemon-name}</value>
                            </property>
                            <property>
                                <name>wrapper.ntservice.displayname</name>
                                <value>${daemon-ntservice-displayname}</value>
                            </property>
                            <property>
                                <name>wrapper.ntservice.description</name>
                                <value>${daemon-ntservice-description}</value>
                            </property>
                            <property>
                                <name>wrapper.console.title</name>
                                <value>${daemon-ntservice-displayname}</value>
                            </property>
                            <property>
                                <name>wrapper.java.additional.2</name>
                                <value>-Dfile.encoding=UTF-8</value>
                            </property>
                            <property>
                                <name>wrapper.java.additional.3</name>
                                <value>-XX:+UnlockExperimentalVMOptions</value>
                            </property>
                            <property>
                                <name>wrapper.java.additional.4</name>
                                <value>-XX:+UseCGroupMemoryLimitForHeap</value>
                            </property>
                            <property>
                                <name>wrapper.java.additional.5</name>
                                <value>-Djava.security.egd=file:/dev/./urandom</value>
                            </property>
                            <property>
                                <name>wrapper.java.additional.6</name>
                                <value>-Dlogging.filename=${project.build.finalName}</value>
                            </property>
                        </configuration>
                    </generatorConfiguration>
                </generatorConfigurations>
            </daemon>
        </daemons>
    </configuration>
    <executions>
        <execution>
            <id>generate-jsw-scripts</id>
            <phase>package</phase>
            <goals>
                <goal>generate-daemons</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

插件中的变量属性如下：

```xml
<properties>
    <java.version>1.8</java.version>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>    
    <!--jsw daemon -->
    <daemon-name>${project.artifactId}</daemon-name>
    <daemon-ntservice-displayname>${daemon-name}</daemon-ntservice-displayname>
    <daemon-ntservice-description>${daemon-name}</daemon-ntservice-description>
    <daemon-mainClass>app.Application</daemon-mainClass><!-- 根据实际的类名配置 -->
    <daemon-JAVA_Xms/>
    <daemon-JAVA_Xmx/>
    <daemon-JAVA_OPS/>
</properties>
```

注意到插件配置了一个启动参数：

```xml
<property>
    <name>wrapper.java.additional.6</name>
    <value>-Dlogging.filename=${project.build.finalName}</value>
</property>
```

这里是一个启动参数属性，在后文会使用这个属性，主要是配合springboot用于指定日志文件名称的。

到这里日志整合中jsw的配置就完成了。

## logback的配置

参考[logback配置](https://logback.qos.ch/manual/index.html)我们可以很方便配置出满足需求的日志方案，但是为了打包发布后在jsw包中修改配置的话，还需要配合springboot的属性来实现。

也就是我们需要能通过spring的`application.yml`来改动logback日志配置，由于`logback.xml`的配置加载在spring启动之前，所以无法使用spring的配置，但是springboot提供了另一种方式加载日志配置文件。

可以在classpath目录下创建`logback-spring.xml`文件，这个文件logback不会加载，会由springboot进行加载，spring加载的过程会对配置文件进行配置增强，扩展支持了几个属性：

```xml
<configuration>
    <springProperty scope="context" name="CONSOLE_APPENDER" 
        source="logging.appender.console" defaultValue="true"/>
    <springProperty name="test,prod">
        <appender-ref ref="ERROR_FILE"/>
    </springProperty>
</configuration>
```

这里`<springProperty>`标签可以使用spring的`application.yml`中配置的属性，source即属性的key，并且可以指定`defaultVale`默认值。  
`<springProperty>`标签类似if判断，只有当对应的profile被激活是配置才生效。

在实际使用中，spring扩展的这两个标签依然不够，如果要写一个通用的配置文件给其他的配置引用，还需要支持更多的判断逻辑，可以增加如下maven依赖：

```xml
<dependency>
    <groupId>org.codehaus.janino</groupId>
    <artifactId>janino</artifactId>
    <version>2.7.8</version>
</dependency>
```

即可使用if判断逻辑：

```xml
<if condition="property(&quot;ROLLING_FILE_APPENDER&quot;).equals(&quot;true&quot;)">
    <then>
        <appender-ref ref="ROLLING_FILE"/>
    </then>
    <else></else>
</if>
```

更多内容参考[Janino](http://janino-compiler.github.io/janino/)。

这样我们就可以使用spring的`application.yml`来修改logback中的配置了，可以将日志的大部分配置简化为spring的几个属性来控制。

### 基础配置

在classpath目录下，创建一个基础配置文件，可以给多个配置引用，这里给出一个示例：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<included>
    <contextName>Logback Base For IAM</contextName>
	
	<springProperty scope="context" name="CONSOLE_APPENDER" source="logging.appender.console" defaultValue="true"/>
	<springProperty scope="context" name="ROLLING_FILE_APPENDER" source="logging.appender.rollingfile" defaultValue="true"/>
	<springProperty scope="context" name="ERROR_FILE_APPENDER" source="logging.appender.errorfile" defaultValue="false"/>
	
	<springProperty scope="context" name="LOG_HOME" source="logging.path" defaultValue="./logs"/>
	<springProperty scope="context" name="LOG_FILE_NAME" source="logging.filename" defaultValue="app"/>
	
	<springProperty scope="context" name="ROOT_LEVEL" source="logging.level.root" defaultValue="INFO"/>
	
	<springProperty scope="context" name="MAX_HISTORY" source="logging.rolling.maxHistory" defaultValue="10"/>
	<springProperty scope="context" name="MAX_FILE_SIZE" source="logging.rolling.maxFileSize" defaultValue="1GB"/>
	<springProperty scope="context" name="TOTAL_SIZE_CAP" source="logging.rolling.totalSizeCap" defaultValue="0"/>
	
    <!-- 设置log日志存放地址 -->
    <property name="LOG_HOME" value="${LOG_HOME:-./logs}"/>
    <property name="LOG_FILE_NAME" value="${LOG_FILE_NAME:-app}"/>
    <property name="MAX_HISTORY" value="${MAX_HISTORY:-10}"/>
    <property name="MAX_FILE_SIZE" value="${MAX_FILE_SIZE:-1GB}"/>
	<property name="TOTAL_SIZE_CAP" value="${TOTAL_SIZE_CAP:-0}"/>
    <property name="ROOT_LEVEL" value="${ROOT_LEVEL:-INFO}"/>
	<property name="CONSOLE_APPENDER" value="${CONSOLE_APPENDER:-false}"/>
	<property name="ROLLING_FILE_APPENDER" value="${ROLLING_FILE_APPENDER:-false}"/>
	<property name="ERROR_FILE_APPENDER" value="${ERROR_FILE_APPENDER:-false}"/>
    
    <!-- 控制台输出 -->
    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <encoder class="ch.qos.logback.classic.encoder.PatternLayoutEncoder">
            <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%15.15t] - %-5level %logger{5} -%msg%n</pattern>
        </encoder>
    </appender>
	<if condition="property(&quot;ROLLING_FILE_APPENDER&quot;).equals(&quot;true&quot;)">
		<then>
			<!-- 按照每天生成日志文件 -->
			<appender name="ROLLING_FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
				<rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
                    <fileNamePattern>${LOG_HOME}/${LOG_FILE_NAME}.%d{yyyy-MM-dd}.%i.log</fileNamePattern>
                    <!--日志文件保留天数 -->
                    <maxHistory>${MAX_HISTORY}</maxHistory>
                    <maxFileSize>${MAX_FILE_SIZE}</maxFileSize>
                    <totalSizeCap>${TOTAL_SIZE_CAP}</totalSizeCap>
				</rollingPolicy>
				<encoder class="ch.qos.logback.classic.encoder.PatternLayoutEncoder">
					<pattern>%d{dd HH:mm:ss.SSS} [%15.15t] %-5level %logger{20} -%msg%n</pattern>
				</encoder>
			</appender>
		</then>
		<else></else>
	</if>
	<if condition="property(&quot;ERROR_FILE_APPENDER&quot;).equals(&quot;true&quot;)">
		<then>
			<appender name="ERROR_FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
				<rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
					<fileNamePattern>${LOG_HOME}/error.${LOG_FILE_NAME}.%d{yyyy-MM-dd}.%i.log</fileNamePattern>
					<maxHistory>${MAX_HISTORY}</maxHistory>
					<maxFileSize>${MAX_FILE_SIZE}</maxFileSize>
					<totalSizeCap>${TOTAL_SIZE_CAP}</totalSizeCap>
				</rollingPolicy>
				<filter class="ch.qos.logback.classic.filter.ThresholdFilter">
					<level>ERROR</level>
				</filter>
				<encoder>
					<pattern>%d{dd HH:mm:ss.SSS} %-4relative [%thread] %-5level %logger{20} - %msg%n</pattern>
				</encoder>
			</appender>
		</then>
		<else></else>
	</if>
    <root level="${ROOT_LEVEL}">
		<if condition="property(&quot;CONSOLE_APPENDER&quot;).equals(&quot;true&quot;)">
			<then>
				<appender-ref ref="STDOUT"/>
			</then>
			<else></else>
		</if>
		<if condition="property(&quot;ROLLING_FILE_APPENDER&quot;).equals(&quot;true&quot;)">
			<then>
				<appender-ref ref="ROLLING_FILE"/>
			</then>
			<else></else>
		</if>
		<if condition="property(&quot;ERROR_FILE_APPENDER&quot;).equals(&quot;true&quot;)">
			<then>
				<appender-ref ref="ERROR_FILE"/>
			</then>
			<else></else>
		</if>
    </root>
</included>
```

这个基础配置几乎是完全通用的，假设我们将这个基础配置放在`resources/logging/logback/base.xml`中，那么使用如下简单配置即可复用基础配置的功能：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>	
	<include resource="logging/logback/base.xml" />
</configuration>
```

这个配置文件即`resources/logback-spring.xml`

### springboot的配置

按照上一步的配置，现在我们可以在`application.yml`使用如下属性来简单控制日志的配置：

```yaml
logging:
  path: ./logs # 日志存放的目录
  rolling:
    maxHistory: 10 # 日志最长保留天数
    maxFileSize: 1GB # 日志分割的文件最大值（默认达到1G时分割文件）
    totalSizeCap: 0 # 日志文件最大容量，为0表示不限制
  level:
    root: INFO # 默认日志级别
  appender:
    console: true # 启用控制台日志输出
    rollingfile: true # 启用文件日志输出
    errorfile: false # 启用ERROR级别日志单独输出日志文件（文件名为rollingfile的文件名加error.前缀）
```

特别说明：

一般情况下不建议对日志最大容量进行限制，以防出现问题时无法找到日志，如果在某些磁盘空间比较小的测试环境，日志不是特别重要，可以设置日志容量限制。
注意日志容量限制需要同时配置`logging.rolling.maxFileSize`和`logging.rolling.totalSizeCap`两个属性，`totalSizeCap`的值不能小于`maxFileSize`。

这样的配置即可达到[日志需求](#日志需求)中要求的全部需求。