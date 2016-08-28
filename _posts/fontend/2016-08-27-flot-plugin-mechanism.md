---
layout: post
comments: true
categories: 前端技术
title: "flot的插件机制"
---

## 简介

本文针对flot 0.8.3版本

最近遇到一个项目，需要在前端话图表，其实现在前端有很多js控件可以画图了，我对比过几个控件之后，最终选择了flot这个控件，flot是一个开源项目，项目主页[http://www.flotcharts.org/]()，有以下几点优势:

* 支持多种图表：柱状图，曲线图，饼图等；
* 支持多种配置：可以配置颜色，样式，还有坐标轴最大最小值等等；
* 支持插件扩展：flot有自己的插件机制支持扩展我们自己的插件，扩展方式也比较简单。

## 插件机制

flot是基于jquery的控件，本质上也是jquery的插件，并且在这个基础上，提供了一个类似jquery插件机制的插件机制。

### 插件对象

flot在初始化完成之后，会生成一个plot对象并存储在jquery的$对象中，我们可以通过$.plot访问这个对象，这个对象维护了整个flot插件需要的对象和属性，包括插件列表，因此我们扩展插件的时候只需要在plot对象的插件列表中加入我们的插件对象即可:

```javascript
$.plot.plugins.push(plugin);
```

flot的插件列表里存放的是插件对象，插件对象有以下几个属性：

```javascript
plugin:{
	init: init, // 初始化函数
    options: options, // 插件配置对象
    name: "pluginName", // 插件名
    version: "0.1" // 插件版本号
}
```

这里插件的配置对象是可以由我们自己来定义的，flot最终会把配置对象相应的参数合并到全局配置中去。

### 初始化函数

在插件对象中，init属性是一个初始化函数，接受plot对象作为参数，如下：

```javascript
function init(plot) {
    plot.coolstring = "Hello!";
};
```

这个初始化函数在插件加载的时候会调用，并且只调用一次，因此我们需要在初始化的时候这个插件的全部任务，包含数据解析，事件绑定等等。

### 初始化过程

flot的插件生效的过程是通过钩子(hook)来实现的，类似事件机制。flot在绘制图表的过程，开放了各个环节的钩子，因此我们可以在插件初始化的时候在各个钩子中加入我们的钩子函数来实现对各个环节的干预，举例如下:

```javascript
function init(plot) {
        var debugLevel = 1;

        function checkDebugEnabled(plot, options) {
            if (options.debug) {
                debugLevel = options.debug;
                plot.hooks.processDatapoints.push(alertSeries);
            }
        }

        function alertSeries(plot, series, datapoints) {
            var msg = "series " + series.label;
            if (debugLevel > 1) {
                msg += " with " + series.data.length + " points";
                alert(msg);
            }
        }

        plot.hooks.processOptions.push(checkDebugEnabled);
 }
```

上面的示例是flot官网的例子，这里我们在初始化的时候将`checkDebugEnabled`这个行数加入到`processOptions`的钩子中去了，因此在flot加载参数之后，就会触发这个钩子并执行我们的代码，当然我们要先把这个插件加入到plot对象的插件列表中去，完整的示例如下:

```javascript
(function ($) {
    function init(plot) {
        var debugLevel = 1;

        function checkDebugEnabled(plot, options) {
            if (options.debug) {
                debugLevel = options.debug;
                plot.hooks.processDatapoints.push(alertSeries);
            }
        }

        function alertSeries(plot, series, datapoints) {
            var msg = "series " + series.label;
            if (debugLevel > 1) {
                msg += " with " + series.data.length + " points";
                alert(msg);
            }
        }

        plot.hooks.processOptions.push(checkDebugEnabled);
    }

    var options = { debug: 0 };

    $.plot.plugins.push({
        init: init,
        options: options,
        name: "simpledebug",
        version: "0.1"
    });
})(jQuery);
```

这个例子示例了如何开发一个简单的插件，并没有做什么特别的事情，只是在处理完配置对象之后弹出了一个alert信息而已。

### flot的生命周期

flot的绘制过程一共分8个阶段：

* 插件初始化阶段：负责插件初始化和配置参数解析合并

* 构造canvases阶段：在html页面中构造一个canvase标签用于绘制图表，注意，这里决定了flot只能是在支持html5的浏览器上运行

* 数据解析阶段：解析原始数据规范，计算图表颜色，复制原始数据到内部并序列化为坐标轴，计算坐标轴最大最小值等等

* 网格设置阶段：计算网格，图例等信息

* 画图阶段：绘制网格，画出图表

* 事件绑定阶段：给图表中的对象绑定事件响应

* 触发事件阶段：触发图表上已经绑定的相应事件

* 结束阶段：摧毁当前图表的阶段，一般发生在plot对象被重写的时候

一个完整的flot执行过程就是上面的8个阶段，在这8个阶段中，flot提供了许多钩子来让我们在相应的阶段定制自己的内容。

#### 钩子

flot并不是在每个阶段提供一个钩子，有的阶段是没有钩子的，有的阶段有多个钩子，我们现在来看一下flot目前已经提供的钩子：

* processOptions[插件初始化阶段]

```javascript
function(plot, options)
```

这个钩子是在插件初始化的时候调用的，这个时候flot还没有解析和合并参数，我们可以在这里设置一些参数的默认值。

* processRawData[数据解析阶段]

```javascript
function(plot, series, data, datapoints)
```

这个钩子在配置项处理完成之后，原始数据复制到内部并序列化之前触发，我们可以在这个过程自己做数据序列化，并给`datapoints.pointsize`设置一个值，那么flot内部就不再做序列化了，而使用我们提供的序列化结果。

* processDatapoints [数据解析阶段]

```javascript
function(plot, series, datapoints)
```

这个钩子在数据序列化完成之后触发，这里可以对序列化后的结果做一些修改。

* processOffset[网格设置阶段]

```javascript
function(plot, offset)
```

这个阶段是flot开始绘制网格的过程，这里我们可以通过调整offset的参数来改变绘制的网格

* drawBackground[画图阶段]

```javascript
function(plot, canvascontext)
```

这个钩子在网格绘制完成后触发，其他的绘制开始之前，可以用来修改绘制图表的背景。

* drawSeries [画图阶段]

```javascript
function(plot, canvascontext, series)
```

这个钩子在开始画我们的数据之前触发，在这里还能最终修改需要绘制的数据。

* draw [画图阶段]

这个钩子在数据绘制完成之后触发，这个时候已经不能再修改需要绘制的数据了，但是可以再画别的信息。

* bindEvents [事件绑定阶段]

```javascript
function(plot, eventHolder)
```

这个钩子在事件绑定阶段触发，可以用来绑定图表中的事件。

* drawOverlay [触发事件阶段]

```javascript
function (plot, canvascontext)
```

这个钩子在事件触发阶段触发，可以在这里再做一些图表绘制任务。

* shutdown [结束阶段]

```javascript
function (plot, eventHolder)
```

这个钩子在plot被摧毁时触发，一般用来解除事件绑定等。

flot目前只提供了这几个钩子，并没有提供绘制过程每个数据点绘制的钩子，因此对于同一个数据只能用相同的样式，不然就自己修改flot的源码吧。

