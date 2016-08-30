---
layout: post
comments: true
categories: 前端技术
title: 关于angularjs中$http服务的参数序列化
tags: 新建,模板,小书匠
grammar_cjkRuby: true
---

## 前言

早前就用过angular，不过一直都不太喜欢它的$http服务，以前对angular的理解特别浅，所以一直都不明白为什么$http服务用如下的方式发请求:

```javascript
$http({
        method:'POST',
        url:contextPath+"/",
        data :{"id":id}
}).then(function successCallback(response) {
	console.log(response);
}, function errorCallback(response) {
});
```

这里发出去的请求，在后端用`request.getParameter("id")`得到的结果是null，一直觉得angular这个行为很奇怪，后来也查过资料，发现参数并不是没有传到后端，而是没有经过urlencode序列化，所以tomcat无法解析得到参数，需要自己读请求的输入流解析请求体来获取参数，当时就觉得这个做法好麻烦，果断放弃$http，重新写了一个基于jquery.ajax的http服务。

最近在新的项目中重新接触到angular，再次使用$http，依然还是不明白为什么$http要这么做，但是心想angular这么火的一个框架，开发团队不可能没想到这点，所以决定深入研究一下，于是就有了这篇博客。

## HTTP请求的Content-Type

要解释清楚$http的事情，我们至少得先了解HTTP请求的Content-Type的基础。实际上在前面那个请求中，发出去的http请求如下：

```http
RequestURL:http://localhost:8080/test/
Request Method:POST  
Status Code:200 OK  
   
Request Headers  
Host: localhost:8080
Connection: keep-alive
Content-Length: 54
Pragma: no-cache
Cache-Control: no-cache
Accept: application/json, text/plain, */*
Origin: http://localhost:8080
User-Agent: Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36
Content-Type: application/json;charset=UTF-8
Referer: http://localhost:8080/console/monitor?id=ebd93c3d-8e9c-4d91-ab6e-e55a7d29d73b
Accept-Encoding: gzip, deflate
Accept-Language: zh-CN,zh;q=0.8,en;q=0.6,zh-TW;q=0.4
Cookie: JSESSIONID=BCA9A2CC450B2019C0E89E944EFD9C47; auth_token_console=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYW1lIjoiYWRtaW4yIiwiZXhwIjoxNDcyNTEyMzA4NTI3fQ.B71FUEpRq2NKRLZw7cfX_5TgJRYDvPaDXjr0DaiXIOI; nde-textsize=16px; SUV=1510302329032011; JSESSIONID=95fcy5eqlp9p11od0wwslna88; auth_token_root=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYW1lIjoiYWRtaW4yIiwiZXhwIjoxNDcyNTA4MzQzODc2fQ.dIMWG0CclpJ_2Uor-XYlweJMWFAu5kVNVgN5a4DK4Tc

Request Payload  
{"equipmentId":"ebd93c3d-8e9c-4d91-ab6e-e55a7d29d73b"}
```

这里并不是标准的HTTP请求，已经转换为可读模式了。

我们注意啊到，这里请求头的`Content-Type`的值是`application/json;charset=UTF-8`，这个请求头表示请求体是一个json，之后我们可以看到请求体:

```
{"equipmentId":"ebd93c3d-8e9c-4d91-ab6e-e55a7d29d73b"}
```

这个就是我们写的`data`参数转化出来的json字符串，这种请求后端的web容器(我用的是tomcat)默认是不解析的，因为在http协议中，并没有规定请求体是怎么样的，请求体的格式是由请求头的`Content-Type`决定的，tomcat实际上只对`Content-Type`值为`application/x-www-form-urlencoded`和`multipart/form-data`的请求做了特殊处理，这是因为这两种类型的请求，请求体是有固定标准的：

`application/x-www-form-urlencoded`请求体必须是`key=value`的键值对，如果有多个键值对用`&`符号连接；
`multipart/form-data`是文件上传，请求体是文件的二进制流。

这两种情况都是能解析的，因此一般后端的容器都会做解析，其他的`Content-Type`并没有对格式做规定，因此后端容器无法知道请求体的格式如何解析，所以一般就不解析了，这也是为什么无法从request中得到这个参数，因为这种情况需要我们自己解析请求体。

如果没有显示设置`Content-Type`，那么默认的`Content-Type`为`text/plain`，这种情况下tomcat自然就不会解析请求体了。

> 值得注意的是，jquery的ajax其实是内置设置了`Content-Type`为`application/x-www-form-urlencoded`并帮我们自动把data的对象转换成键值对了，所以jquery的请求一般后端都能解析。

## $http的处理

现在我们已经知道为什么$http发出去的请求tomcat没有解析出参数了，实际上就是因为$http并没有设置请求头的`Content-Type`，而且也并没有自动把data参数序列化成键值对。

$http实际上在发请求前，会有默认的参数序列化器`$http.defaults.transformRequest`，这个参数序列化器并没有做太多事情，所以这里发出去的请求体实际上就是我们设置的data。

知道了这里的逻辑，那么我们就知道如何处理post的时候让后端能解析到这个参数了，一般有两种思路：

* 在设置data之前先把要传递的参数序列化成键值对字符串，然后再传给data，同时设置`Content-Type`为`application/x-www-form-urlencoded`即可，还是上面的例子，我们把data参数的值改一下，并添加请求头，如下：

```javascript
$http({
        method:'POST',
        url:contextPath+"/",
        data :"id="+id,
        headers:{
        	"Content-Type":"application/x-www-form-urlencoded"
        }
}).then(function successCallback(response) {
	console.log(response);
}, function errorCallback(response) {
});
```

这个时候我们就可以看到后端能正常解析请求参数了。

* 设置请求头，并重写$http的默认参数序列化器，如下：

```javascript
$http({
        method:'POST',
        url:contextPath+"/",
        data :{id:id},
        headers:{
        	"Content-Type":"application/x-www-form-urlencoded"
        },
        transformRequest:function (data, headersGetter) {
        	return "id="+data.id;
        }
}).then(function successCallback(response) {
	console.log(response);
}, function errorCallback(response) {
});
```

这里我们传入`transformRequest`这个参数重写了默认的序列化器，最终的效果我前面的方式是一样的。

> 这里实际上只对单次请求重写了序列化器，angular也支持我们直接修改默认的序列化器，这里就不进一步讨论了，有兴趣的朋友可以看看angular的官网。

这里我示例的序列化器对参数的依赖比较大，就是序列化只支持`{id:id}`这样的json对象，实际使用的时候，我们一般跟jquery结合：

```javascript
$http({
        method:'POST',
        url:contextPath+"/",
        data :{id:id},
        headers:{
        	"Content-Type":"application/x-www-form-urlencoded"
        },
        transformRequest:function (data, headersGetter) {
        	return $.param(data);
        }
}).then(function successCallback(response) {
	console.log(response);
}, function errorCallback(response) {
});
```

使用jquery的`$.param(data)`帮我们序列化data对象即可。

## 总结

原本以为是angular的$http的问题，细究之后才发现原来这里设计http的基本协议和web容器的实现，看来在编程技术这方面，很多错误并不能只看表面，以后还是要多多注意。