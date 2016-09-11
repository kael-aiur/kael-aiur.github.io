---
layout: post
comments: true
categories: java
title: jdk的线程池实现-ThreadPoolExecutor
tags: 并发,线程池,ThreadPoolExecutor,jdk8
grammar_cjkRuby: true
---

## 前言

一直以来对线程池的概念都挺模糊的，想不明白线程池要如何实现，今天难得周末，就开始查阅资料，研究了一下jdk中的线程池实现，终于解开了我长久依赖的疑惑，本文参考文章来自网络，原文连接如下：

[http://www.cnblogs.com/dolphin0520/p/3932921.html](http://www.cnblogs.com/dolphin0520/p/3932921.html)

参考连接针对jdk6，本文针对jdk8

## 疑惑

和线程池类似的有一个概念叫连接池，在数据库连接中使用的非常多，连接池比较好理解，一般来说就是一个连接建立完成之后不去关闭它，需要的时候就看获取这个连接的对象并给它的输入流写数据，并从输出流读取响应结果，但是在线程中，一旦某个线程的run方法运行结束之后，线程也就结束了，因此和连接池有很大的不同，这也给我留下了几个疑惑：

* 如何复用一个线程？
* 多个线程如何管理？
* 如何知道某个线程是目前正在运行还是在等待任务？

今天看过jdk中对线程池的实现，才真正明白，线程池和连接池是有很大不同的，使用上也完全不一样。

1. 连接池是每次需要时候的时候，从池里取出一个连接给我们，我们再使用这个连接来交换数据，而线程池并不是在使用的时候从池里取出一个线程对象给我们使用，而是将我们的任务交给线程池，由线程池自己调度任务决定什么时候执行这个任务。
2. 连接池的连接用完之后，会直接放到池内，等待下一个请求连接，而线程池的线程一旦运行完，线程也就结束了，因不存在放回池内的操作。
3. 一个连接池要持有一定数量的连接，只要保证持有这些未关闭的连接的对象即可，而线程池要持有一定数量的线程，必须保证持有的线程的run方法不会运行结束。

了解了线程池和连接池的区别之后，我们就可以知道，虽然名字很像，但是实际上这两者在原理和概念上是完全不一样的。

jdk1.5以后，新增了一个并发包`java.concurrent`，这个包里就包含了线程池的实现，最核心的实现类是`java.util.concurrent.ThreadPoolExecutor`。

> 实际上jdk从1.5到1.8，`java.util.concurrent.ThreadPoolExecutor`已经经过多次重构了，1.6和1.8在实现上已经有了很大的不同了，本文针对的是jdk8中的实现。

## jdk的线程池实现

我们来看一下jdk中的线程池是如何实现的。

首先要先了解一下类结构，如下图：

![enter description here][1]

### 类结构

最顶层的接口是`java.util.concurrent.Executor`:

```java
public interface Executor {
    void execute(Runnable command);
}
```

只有一个接口，传入一个Runnable对象，称为指令，线程池就会帮你执行这个指令。

它的一级子接口是`java.util.concurrent.ExecutorService`:

```java
public interface ExecutorService extends Executor {
    void shutdown();
    List<Runnable> shutdownNow();
    boolean isShutdown();
    boolean isTerminated();
    boolean awaitTermination(long timeout, TimeUnit unit) throws InterruptedException;
    <T> Future<T> submit(Callable<T> task);
    <T> Future<T> submit(Runnable task, T result);
    Future<?> submit(Runnable task);
    <T> List<Future<T>> invokeAll(Collection<? extends Callable<T>> tasks) throws InterruptedException;
    <T> List<Future<T>> invokeAll(Collection<? extends Callable<T>> tasks, long timeout, TimeUnit unit) throws InterruptedException;
    <T> T invokeAny(Collection<? extends Callable<T>> tasks) throws InterruptedException, ExecutionException;
    <T> T invokeAny(Collection<? extends Callable<T>> tasks, long timeout, TimeUnit unit)  
    		throws InterruptedException, ExecutionException, TimeoutException;
}
```

这个接口是执行器服务接口，声明了关于执行器的许多管理方法，如：

```java
void shutdown();
<T> Future<T> submit(Callable<T> task);
<T> List<Future<T>> invokeAll(Collection<? extends Callable<T>> tasks) throws InterruptedException;
```

这些方法都是用于对线程池内的任务管理的接口。

接下来我们看`java.util.concurrent.ExecutorService`的抽象实现类`java.util.concurrent.AbstractExecutorService`，这里就不贴源码了，这个抽象类实现了接口中的大部分方法，不过大部分的实现都依赖于`Executor`接口声明的`execute`方法，而这里并没有实现这个关键的方法，而是把这个方法的实现交给了子类，也就是`java.util.concurrent.ThreadPoolExecutor`来实现了。

接下来我们看一下最终的实现类`java.util.concurrent.ThreadPoolExecutor`，在类结构图中，我们还能看到`ThreadPoolExecutor`有如下几个内部类:

```java
public static class DiscardPolicy implements RejectedExecutionHandler
public static class CallerRunsPolicy implements RejectedExecutionHandler
private final class Worker extends AbstractQueuedSynchronizer implements Runnable
public static class AbortPolicy implements RejectedExecutionHandler
public static class DiscardOldestPolicy implements RejectedExecutionHandler
```

这几个类都是线程池实现需要的，这里最关键的类就是`Worker`，每一个Worker对象代表了一个线程，同时也是真正负责执行任务的对象。

### 线程池的实现原理

我们现在已经了解线程池的整体结构，现在让我们来看看具体的实现，我们按照下面的几个方面来阅读jdk的源码：

1. 线程池的状态
2. 线程任务执行
3. 线程池关闭
4. 线程容量动态调整

#### 线程池的状态

我们先看看跟线程池状态有关的几个属性：

```java
AtomicInteger ctl; // 状态计数器
int RUNNING; // 运行状态
int SHUTDOWN ;// 关闭状态
int STOP; // 停止状态
int TIDYING; // 整理状态
int TERMINATED; //结束状态
```

这里的状态计数器`ctl`是用来标识线程池当前状态和线程数的，这里要特别注意，这个属性把两个变量打包成一个变量了，通过这个属性可以计算得出目前的线程数和线程池当前的状态。

其他属性都是常量，用来定义状态的，从源码的定义看，线程池的状态是有大小关系的，分别是:

···
RUNNING < SHUTDOWN < STOP < TIDYING < TERMINATED
···

各个状态表示的含义如下：

* RUNNING

正在处理任务和接受队列中的任务。

* SHUTDOWN

不再接受新的任务，但是会继续处理完队列中的任务。

* STOP

不再接受新任务，也不继续处理队列中的任务，并且会中止正在处理的任务。

* TIDYING

所有任务都已经处理结束，目前worker数为0，当线程池进入这个状态的时候，会调用`terminated()`方法。

* TERMINATED

线程池已经全部结束，并且`terminated()`方法执行完成。

> **注意：**这里使用了`AtomicInteger`，因此也决定了线程池最大线程数不能超过(2^29)-1个线程，大约是500万个线程，多数情况下是能满足要求的，如果需要支持更高线程数的话，需要使用`AtomicLong`来标识。

这里还有几个跟状态有关的方法

```java
static int runStateOf(int c) ; // 计算线程池当前状态
static boolean runStateLessThan(int c, int s) ; // 计算当前状态是否小于某个状态
static boolean runStateAtLeast(int c, int s) ; // 计算当前状态是否大于或等于某个状态
static boolean isRunning(int c) ; // 计算当前状态是否RUNNING
```

#### 线程任务执行

在了解线程任务执行的实现之前，我们需要先了解一些等一下会涉及到的成员变量：

```java
private volatile int corePoolSize;
private final BlockingQueue<Runnable> workQueue;
private volatile int maximumPoolSize;
private final ReentrantLock mainLock = new ReentrantLock();
private volatile RejectedExecutionHandler handler;
private volatile long keepAliveTime;
```

* **corePoolSize**

这个属性称为核心线程数，实际上表示的是整个线程池中最少存活的线程数，实际上，线程池会在任务数比较多的情况下，创建一些新的临时线程出来执行任务，等到任务数降下来之后，临时线程就会逐渐减少，总的线程数会回落到核心线程数，需要注意的是，当线程池任务队列中没有任务的时候，所有线程都会处于等待状态，但是临时线程等待会超时，当超时之后，临时线程数就会结束，而核心线程是不允许等待超时的，因此核心线程不会减少，这也保证了线程池的线程数量不会少于核心线程数。

* **workQueue**

这个属性称为任务队列，这个队列用来存放任务，在任务量比较大，核心线程在执行任务的时候，会把新来的任务放到任务队列中，如果任务队列再满了的话，会尝试创建临时线程来处理任务，如果临时线程全部满了的话，就会启动拒绝策略。

这里任务队列的poll()允许返回null，线程池判断队列是否为空时不会根据这个判断，而是根据队列的`isEmpty()`方法判断的。

**maximumPoolSize**

最大线程数，我们已经知道，线程池默认会有一定数量的核心线程，当任务繁忙的时候，就会创建临时线程来处理任务，这个最大线程数表示的就是线程池最大的线程数量，也就是说，临时线程的数量最多不能超过最大线程数和核心线程数的差值。

**mainLock**

线程池主锁，这个对象用于线程池内部某些需要同步的操作，在对线程池本身的一些状态操作的时候，必须使用这个锁。

**handler**

任务拒绝策略处理器，这个拒绝处理策略是可以由外界传入的，具体的策略可以由使用者自己决定，当然，线程池默认使用的处理策略是`java.util.concurrent.ThreadPoolExecutor.AbortPolicy`，这个在前面我们已经看到了，就是`ThreadPoolExecutor`的内部类，这个默认策略是直接抛出`RejectedExecutionException`异常。

**keepAliveTime**

临时线程等待超时时间，这个属性表示创建的临时线程在空闲的时候最长的等待时间，如果超过这个时间，线程就会结束掉。

了解上面的成员变量之后，我们来看一下线程池是如何执行任务的，下面是`execute()`的源码:

```java
public void execute(Runnable command) {
        if (command == null)
            throw new NullPointerException();
        int c = ctl.get();
        if (workerCountOf(c) < corePoolSize) {
            if (addWorker(command, true))
                return;
            c = ctl.get();
        }
        if (isRunning(c) && workQueue.offer(command)) {
            int recheck = ctl.get();
            if (! isRunning(recheck) && remove(command))
                reject(command);
            else if (workerCountOf(recheck) == 0)
                addWorker(null, false);
        }
        else if (!addWorker(command, false))
            reject(command);
}
```

我们先观察这个逻辑，首先判断了传入的指令对象是否为空，为空就不用执行了，直接抛出异常。

如果指令对象不为空，那么就真正进入线程任务的逻辑，一共分为3步来处理：

1. 检查当前线程总数，如果低于核心线程数，则创建新的线程来执行这个任务

```java
int c = ctl.get();
if (workerCountOf(c) < corePoolSize) {
    if (addWorker(command, true))
    	return;
    c = ctl.get();
}
```

这里`workerCountOf(c) `可以从计数器(clt)的结果中计算出当前线程数。

`addWorker(command, true)`会检查线程池状态和总线程数，并确定是否创建新线程，如果创建了新线程执行这个任务，则返回true，如果没有创建新线程，则返回false，这个方法我们后边再细说。

2. 尝试把任务放入任务队列，并且重新检查线程池状态，如果线程池已经不接收新的任务，则移除这个任务，并转入拒绝策略。

```java
if (isRunning(c) && workQueue.offer(command)) {
	int recheck = ctl.get();
	if (! isRunning(recheck) && remove(command))
		reject(command);
	else if (workerCountOf(recheck) == 0)
	addWorker(null, false);
}
```

这里我们看到，第二步先检查了线程池当前是否运行状态，如果是运行状态的话，则执行`workQueue.offer(command)`把任务放入任务队列。

> 注意`&&`运算符的特性，如果线程池已经不在RUNNING状态了，`workQueue.offer(command)`是不会执行的。

任务放入队列之后，会复查线程池状态是否RUNNING，这里需要做复查的主要原因是在前面的检查中没有加锁，因此可能在添加任务队列的过程，其他线程修改了线程池的状态。

如果这个时候线程池状态被修改了，那么就会把这次添加的任务移除`remove(command)`，同时启动拒绝策略`reject(command)`，拒绝策略我们后边再细讲。

如果线程池状态没有被改变，则重新检查当前核心线程数，如果为0则调用`addWorker(null, false)`去队列中取任务并执行，如果不为0，则不做任何操作，等待线程执行完当前任务后自动去任务队列中获取新的任务并执行。

3. 如果任务队列已满，则尝试添加临时线程，并把当然任务交给临时线程处理，如果临时线程也满了，则启动拒绝策略

```java
else if (!addWorker(command, false))
            reject(command);
```

这里先通过`addWorker(command, false)`尝试添加临时线程，如果临时线程创建成功则由临时线程执行这个任务，如果临时线程创建失败，则会返回false，并转入拒绝策略`reject(command)`。

现在我们已经了解了，当我们把一个任务交给线程池的时候，线程池是如何处理这个任务的，接下来我们再来分析这个处理过程中涉及的两个重要函数：

`private boolean addWorker(Runnable firstTask, boolean core)`

这个方法主要用于添加线程和启动线程，源码如下：

```java
    private boolean addWorker(Runnable firstTask, boolean core) {
        retry:
        for (;;) {
            int c = ctl.get();
            int rs = runStateOf(c);

            // Check if queue empty only if necessary.
            if (rs >= SHUTDOWN &&
                ! (rs == SHUTDOWN &&
                   firstTask == null &&
                   ! workQueue.isEmpty()))
                return false;

            for (;;) {
                int wc = workerCountOf(c);
                if (wc >= CAPACITY ||
                    wc >= (core ? corePoolSize : maximumPoolSize))
                    return false;
                if (compareAndIncrementWorkerCount(c))
                    break retry;
                c = ctl.get();  // Re-read ctl
                if (runStateOf(c) != rs)
                    continue retry;
                // else CAS failed due to workerCount change; retry inner loop
            }
        }

        boolean workerStarted = false;
        boolean workerAdded = false;
        Worker w = null;
        try {
            w = new Worker(firstTask);
            final Thread t = w.thread;
            if (t != null) {
                final ReentrantLock mainLock = this.mainLock;
                mainLock.lock();
                try {
                    // Recheck while holding lock.
                    // Back out on ThreadFactory failure or if
                    // shut down before lock acquired.
                    int rs = runStateOf(ctl.get());

                    if (rs < SHUTDOWN ||
                        (rs == SHUTDOWN && firstTask == null)) {
                        if (t.isAlive()) // precheck that t is startable
                            throw new IllegalThreadStateException();
                        workers.add(w);
                        int s = workers.size();
                        if (s > largestPoolSize)
                            largestPoolSize = s;
                        workerAdded = true;
                    }
                } finally {
                    mainLock.unlock();
                }
                if (workerAdded) {
                    t.start();
                    workerStarted = true;
                }
            }
        } finally {
            if (! workerStarted)
                addWorkerFailed(w);
        }
        return workerStarted;
    }
```

这里有两个参数：

```java
Runnable firstTask; // 表示新建的线程的第一个任务
boolean core; // 是否以核心线程数为边界，如果传入true，表示以核心线程数为边界，当前线程超过核心线程数则不创建新线程，如果不使用核心线程数为边界，则会以最大线程数为边界
```

进入这个函数的时候，第一步就是检查线程池当前的状态:

```java
int c = ctl.get();
int rs = runStateOf(c);

// Check if queue empty only if necessary.
if (rs >= SHUTDOWN &&
	! (rs == SHUTDOWN &&
		firstTask == null &&
		! workQueue.isEmpty()))
			return false;
```

如果已经不允许接受新任务了，这里就直接返回了，如果允许接受新任务的话，会继续执行：

```java
for (;;) {
	int wc = workerCountOf(c);
	if (wc >= CAPACITY ||
		wc >= (core ? corePoolSize : maximumPoolSize))
			return false;
	if (compareAndIncrementWorkerCount(c))
		break retry;
	c = ctl.get();  // Re-read ctl
	if (runStateOf(c) != rs)
		continue retry;
}
```

这里需要好好理解一下，进入这个循环的时候，首先检查是否要求使用核心线程数为边界，如果不满足条件，则直接返回false:

```java
if (wc >= CAPACITY ||
		wc >= (core ? corePoolSize : maximumPoolSize))
			return false;
```

如果不要求核心线程，则会执行`compareAndIncrementWorkerCount(c)`给计数器加1，同时跳出循环，执行下一步，如果计数器添加失败，会再次计算线程池当前状态是否RUNNING，如果线程池还在RUNNING状态，则继续重试：

```java
if (runStateOf(c) != rs)
		continue retry;
```

如果在前面已经添加了线程数了，那么下一步就开始创建新线程了：

```java
w = new Worker(firstTask);
final Thread t = w.thread;
```

前面我们已经说了，一个`Worker`对象表示的是一个线程，这里我们看一下`Worker`的构造方法：

```java
Worker(Runnable firstTask) {
	setState(-1); // inhibit interrupts until runWorker
	this.firstTask = firstTask;
	this.thread = getThreadFactory().newThread(this);
}
```

可以看到，每创建一个`Worker`对象，就会创建一个新的线程，并以自己作为线程的运行对象(`Worker`自己也是`Runnable`的实现类)。

创建了`Worker`对象之后，需要对线程池做一系列的检查，并将这个对象加入到线程池中：

```java
final ReentrantLock mainLock = this.mainLock;
mainLock.lock();
try {
	int rs = runStateOf(ctl.get());
	if (rs < SHUTDOWN ||
	(rs == SHUTDOWN && firstTask == null)) {
		if (t.isAlive()) // precheck that t is startable
			throw new IllegalThreadStateException();
		workers.add(w);
		int s = workers.size();
		if (s > largestPoolSize)
			largestPoolSize = s;
		workerAdded = true;
	}
} finally {
	mainLock.unlock();
}
```

这里首先获取线程池的主锁，保证在添加线程的过程不受其他线程干扰。

```java
mainLock.lock();
```

然后检查线程池状态和线程状态，如果线程池各个状态都是正常的，可以把线程加入到线程池中，则会把线程池加入线程池，并将线程添加状态设置为true:

```java
workers.add(w);
// ... 省略若干代码
workerAdded = true;
```

最后释放锁：

```java
finally {
	mainLock.unlock();
}
```

这里要特别注意，锁一定要在`finally`代码块中释放，不然很容易造成死锁，想知道为什么的同学可以查一下`synchronized`关键字和`Lock`对象获取锁的区别。

最后，判断线程是否已经加入线程池中，如果已经加入线程池中，则启动线程：

```java
if (workerAdded) {
	t.start();
	workerStarted = true;
}
```

如果前面的过程抛出了没有捕获的异常，会在最后判断线程是否启动，如果线程没有启动，则会做回滚：

```java
finally {
	if (! workerStarted)
		addWorkerFailed(w);
}
```

`final void reject(Runnable command)`

这个方法是调用线程池的拒绝处理策略：

```java
final void reject(Runnable command) {
        handler.rejectedExecution(command, this);
}
```

当然这个策略可以通过我们自己传入的对象来处理，默认使用`AbortPolicy`处理，抛出异常。

-------

现在我们已经知道线程池整个执行的过程了，那么线程池如何保证线程的存活呢？这里就涉及到`Worker`的`run`方法实现了。

```java
public void run() {
	runWorker(this);
}
```

这里实际上是调用了`java.util.concurrent.ThreadPoolExecutor`的`runWorker(Worker w)`方法（jdk6中这个方法在`Worker`内部），我们来看下这个方法：

```java
final void runWorker(Worker w) {
        Thread wt = Thread.currentThread();
        Runnable task = w.firstTask;
        w.firstTask = null;
        w.unlock(); // allow interrupts
        boolean completedAbruptly = true;
        try {
            while (task != null || (task = getTask()) != null) {
                w.lock();
                if ((runStateAtLeast(ctl.get(), STOP) ||
                     (Thread.interrupted() &&
                      runStateAtLeast(ctl.get(), STOP))) &&
                    !wt.isInterrupted())
                    wt.interrupt();
                try {
                    beforeExecute(wt, task);
                    Throwable thrown = null;
                    try {
                        task.run();
                    } catch (RuntimeException x) {
                        thrown = x; throw x;
                    } catch (Error x) {
                        thrown = x; throw x;
                    } catch (Throwable x) {
                        thrown = x; throw new Error(x);
                    } finally {
                        afterExecute(task, thrown);
                    }
                } finally {
                    task = null;
                    w.completedTasks++;
                    w.unlock();
                }
            }
            completedAbruptly = false;
        } finally {
            processWorkerExit(w, completedAbruptly);
        }
}
```

这里首先调用`Worker`的`unlock()`方法，允许这个线程被中断，然后进入一个循环，这个循环内部做了几件事情：

1. 获取要执行的任务

```java
while (task != null || (task = getTask()) != null) 
```

这里判断是否有第一个任务，如果有第一个任务则使用第一个任务，如果没有第一个任务，则使用`getTask()`获得新任务，`getTask()`是一个重要的方法，如果获取不到任务的话，这个方法会阻塞并等待任务，后边我们再来详细看这个方法。

2. 获取当前线程的锁，检查当前线程是否允许运行

```java
w.lock();
if ((runStateAtLeast(ctl.get(), STOP) ||
                     (Thread.interrupted() &&
                      runStateAtLeast(ctl.get(), STOP))) &&
                    !wt.isInterrupted())
                    wt.interrupt();
```

3. 所有检查通过之后，确认当前任务可以执行了，就开始执行任务

```java
try {
	beforeExecute(wt, task);
	Throwable thrown = null;
	try {
		task.run();
	} catch (RuntimeException x) {
		thrown = x; throw x;
	} catch (Error x) {
		thrown = x; throw x;
	} catch (Throwable x) {
		thrown = x; throw new Error(x);
	} finally {
		afterExecute(task, thrown);
	}
} finally {
	task = null;	
	w.completedTasks++;
	w.unlock();
}
```

执行任务的过程，先调用了`beforeExecute(wt, task)`做执行前处理，任务执行完成后，调用`afterExecute(task, thrown)`做执行完成后处理，这里主要是留给开发者扩展用的，默认不做任何处理，如果我们需要做一些处理，比如计算任务执行时间一类的，可以通过继承`java.util.concurrent.ThreadPoolExecutor`并重写这两个方法来实现。

任务执行完成后，在finally中释放了锁并给完成任务计数器加1。

然后再回到循环的开头，继续取新的任务执行，如果没有新的任务，线程就会阻塞在`getTask()`方法内，现在我们可以来看看这个方法如何实现了：

```java
private Runnable getTask() {
        boolean timedOut = false; // Did the last poll() time out?

        for (;;) {
            int c = ctl.get();
            int rs = runStateOf(c);

            // Check if queue empty only if necessary.
            if (rs >= SHUTDOWN && (rs >= STOP || workQueue.isEmpty())) {
                decrementWorkerCount();
                return null;
            }

            int wc = workerCountOf(c);

            // Are workers subject to culling?
            boolean timed = allowCoreThreadTimeOut || wc > corePoolSize;

            if ((wc > maximumPoolSize || (timed && timedOut))
                && (wc > 1 || workQueue.isEmpty())) {
                if (compareAndDecrementWorkerCount(c))
                    return null;
                continue;
            }

            try {
                Runnable r = timed ?
                    workQueue.poll(keepAliveTime, TimeUnit.NANOSECONDS) :
                    workQueue.take();
                if (r != null)
                    return r;
                timedOut = true;
            } catch (InterruptedException retry) {
                timedOut = false;
            }
        }
}
```

这个方法已经很好理解了，这里就不再多做解释，简单而言就是检查线程池状态，只要线程池还没有终止，这里就就会无限循环知道抛出异常或者线程池终止，线程的阻塞是用`workQueue.poll(keepAliveTime, TimeUnit.NANOSECONDS)`或`workQueue.take()`实现的。

#### 线程池关闭

线程池的关闭就比较简单了，在`java.util.concurrent.ExecutorService`接口中提供了如下两个方法：

```java
void shutdown(); // 不会立即终止线程池，而是要等所有任务缓存队列中的任务都执行完后才终止，但再也不会接受新的任务
List<Runnable> shutdownNow(); // 立即终止线程池，并尝试打断正在执行的任务，并且清空任务缓存队列，返回尚未执行的任务
```

#### 线程池容量的动态调整

动态调整线程池容量，在执行过程我们已经知道了，只要改变核心线程数和最大线程数即可：

```java
void setCorePoolSize(int corePoolSize);// 调整核心线程数
void setMaximumPoolSize(int maximumPoolSize) ; // 调整动态线程数
```

## 线程池使用

jdk8中提供了一个线程池的工程类`java.util.concurrent.Executors`，我们一般使用这个工厂类来创建线程池，而不是直接new线程池对象，这个工程类提供了多个创建线程池对象的静态方法，其实使用的是线程池不同的构造器和传了不同的参数而已，有兴趣的童鞋请自行查阅API文档，下面给出一个例子：

```java
import java.util.concurrent.Executors;
import java.util.concurrent.ThreadPoolExecutor;

public class Main {

    public static void main(String[] args) {
        ThreadPoolExecutor executor = (ThreadPoolExecutor)Executors.newFixedThreadPool(15);

        for(int i=0;i<15;i++){
            final int index = i;
            executor.execute(new Runnable() {
                @Override
                public void run() {
                    System.out.println("正在执行task "+index);
                    try {
                        Thread.currentThread().sleep(4000);
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                    System.out.println("task "+index+"执行完毕");
                }
            });
            System.out.println("线程池中线程数目："+executor.getPoolSize()+"，队列中等待执行的任务数目："+
                    executor.getQueue().size()+"，已执行玩别的任务数目："+executor.getCompletedTaskCount());
        }
        executor.shutdown();
    }
}
```

执行结果如下：

```
正在执行task 0
线程池中线程数目：1，队列中等待执行的任务数目：0，已执行玩别的任务数目：0
线程池中线程数目：2，队列中等待执行的任务数目：0，已执行玩别的任务数目：0
正在执行task 1
线程池中线程数目：3，队列中等待执行的任务数目：0，已执行玩别的任务数目：0
线程池中线程数目：4，队列中等待执行的任务数目：0，已执行玩别的任务数目：0
线程池中线程数目：5，队列中等待执行的任务数目：0，已执行玩别的任务数目：0
线程池中线程数目：6，队列中等待执行的任务数目：0，已执行玩别的任务数目：0
线程池中线程数目：7，队列中等待执行的任务数目：0，已执行玩别的任务数目：0
线程池中线程数目：8，队列中等待执行的任务数目：0，已执行玩别的任务数目：0
线程池中线程数目：9，队列中等待执行的任务数目：0，已执行玩别的任务数目：0
正在执行task 2
线程池中线程数目：10，队列中等待执行的任务数目：0，已执行玩别的任务数目：0
正在执行task 3
线程池中线程数目：11，队列中等待执行的任务数目：0，已执行玩别的任务数目：0
正在执行task 4
线程池中线程数目：12，队列中等待执行的任务数目：0，已执行玩别的任务数目：0
线程池中线程数目：13，队列中等待执行的任务数目：0，已执行玩别的任务数目：0
正在执行task 5
线程池中线程数目：14，队列中等待执行的任务数目：0，已执行玩别的任务数目：0
正在执行task 6
线程池中线程数目：15，队列中等待执行的任务数目：0，已执行玩别的任务数目：0
正在执行task 7
正在执行task 8
正在执行task 9
正在执行task 10
正在执行task 11
正在执行task 12
正在执行task 13
正在执行task 14
task 0执行完毕
task 9执行完毕
task 7执行完毕
task 6执行完毕
task 5执行完毕
task 3执行完毕
task 2执行完毕
task 4执行完毕
task 1执行完毕
task 11执行完毕
task 10执行完毕
task 8执行完毕
task 13执行完毕
task 12执行完毕
task 14执行完毕
```

## 合理配置线程池

知道了线程池的作用和实现，那么我们要怎么合理配置线程池大小呢？一般有如下规则：

* 如果是CPU密集型任务，就需要尽量压榨CPU，参考值可以设为 NCPU+1
* 如果是IO密集型任务，参考值可以设置为2*NCPU

当然，这只是一个参考值，具体的设置还需要根据实际情况进行调整，比如可以先将线程池大小设置为参考值，再观察任务运行情况和系统负载、资源利用率来进行适当调整。

  [1]: /static/img/blog/java-thread-pool/images/class_struts.png "类结构图"