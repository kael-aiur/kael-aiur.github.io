---
layout: post
comments: true
categories: java
title: java中volatile关键字 
tags: volatile,java,并发,多线程
grammar_cjkRuby: true
---

## 前言

昨天在读jdk的线程池实现的时候，发现线程池中使用了一个关键字`volatile`，这个关键字其实知道很久了，一直都不太理解，因为很多专家和书都强烈推荐不要使用这个关键字，所以一直都很迷惑这个关键字的用途，也不知道为什么要设计这个关键字，今天难得有点时间，决定把这个迷惑彻底解开。

## `volatile`到底有什么用

在java的定义中，`volatile`关键字是用来保证变量的改动在并发环境下的修改可见性的，官方文档给的解释是保证变量被读取时读到的时候变量最后一次被线程修改的值。

这里很容易让人误解，以为这个关键字能保证变量的线程安全性，这里我们用一段代码来测试一下:

```java
public class Main1 {
    public static volatile int count = 0;

    public static void main(String[] args) {

        for (int i = 0; i < 10000; i++) {
            new Thread(() -> {
                count++;
                
            }).start();
        }
        System.out.println(count);
    }
}
```

运行结果如下：

```
9972
```

是不是发现不太对？没错，这里实际上在并发环境下，即使用了`volatile`也并不是现成安全的，这是为什么呢？在百度上很多文章都是各种转载，很多转发的人可能并没有真正理解过文章说的内容，这点确实坑了不少人，包括我。

实际上，`volatile`关键字确实是在并发环境下使用的，但是它并不保证线程安全，它保证的是每次线程要读取他的值的时候，都是最后一次被修改的值，这个值可能是被其他线程修改的，也可以是被自己修改的。

要理解这句话是什么意思，我们需要先了解jvm的内存模型。

## jvm内存模型

![enter description here][1]

从内存模型中我们可以看到，java将内存划分为两大块，一块是线程共享区，也就是主内存，包含java堆和方法区，另一块是线程私有区，有虚拟机栈，本地方法栈和程序计数器。

线程共享区用来存放java运行时的数据，线程私有区是在每个线程私有的，在编译的时候已经决定了大小，java会在线程运行的时候，将一些变量复制到线程私有区中使用。

关于虚拟机内存模型不是本文的重点，我们只了解到这里即可。

## `volatile`的真正作用

现在我们已经知道了，在并发环境下，每个线程都会从主内存读取自己需要的信息并拷贝一份到自己的线程私有区，因此，在上面的测试程序中，如果我们没有加上`volatile`关键字，每个线程处理的其实是自己线程私有区内的变量，处理完成之后再把结果写回主内存，也就是线程共享区，在这个过程里，`count`变量的变化其实对其他线程是不可见的，因此会导致并发问题。

但是即使我们加上了`volatile`关键字，从前面的实验上看，依然会有并发的问题，这是为什么呢?

实际上，`volatile`的真正作用是，告诉虚拟机，在使用这个变量的时候，不要拷贝一份到线程私有区，使用引用的方式来使用这个变量，也就是说，需要读这个变量的时候，直接从主内存的地址读，而不是拷贝一份到自己的私有区，再读私有区的内容，要修改这个变量的时候，也直接修改主内存的变量，而不是修改本地拷贝，再写回主内存。

理解了`volatile`的真正作用，现在我们来看看为什么上面的程序依然存在并发问题。

假设我们有两个线程，分别叫线程1和线程2，由于CPU是随机执行线程的，并且每个线程只有特定的时间片，因此可能会出现如下的执行顺序：

1. 线程1读取count的值，此时count的值为0
2. 线程2读取count的值，此时count的值为0
3. 线程1修改count的值为count+1=0+1=1，这个值会直接写到主内存，此时count的值为1
4. 线程2修改count的值为count+1=0+1，这个值再次写到主内存，count的值为1

这个时候是不是发现，这个就是并发问题？没错，确实是这样，虽然线程不再写自己的私有区变量，而是直接写到主内存，仍然不能保证在count下一次被读取前先把值写回去，所以并发的问题依然存在。

因此，`volatile`不能用来解决并发操作的问题。

## 什么时候使用`volatile`

从上面我们可以知道，`volatile`关键字并不能保证线程安全，那么这个关键字的真正作用到底在哪呢？

其实它真正的作用在于大并发读和少量并发写的时候使用，因为实际上没有加锁，所以`volatile`关键字修饰的属性比使用锁来保证变量在并发环境下的多线程可见性具有更高的性能，我们来看一下下面的代码：

```java
public class Main {

    static int count = 0;

    public static void main(String[] args) {
        // 线程1
        new Thread(()->{
            do{}while (count<1);
            System.out.println("exit when count = "+count);
        }).start();
        // 线程2
        new Thread(()->{
            try {
                Thread.sleep(1000);
                count = 10;
                System.out.println("change value of count to "+count);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }).start();
    }
}
```

这里解释一下这个程序，在main函数中，启动了两个线程，第一个线程读取变量`count`之后，做了空循环，当循环结束的时候，会打印`count`的值，第二个线程启动之后，休眠了1秒，并把count的值改成10。

我们先来看看，按照正常的理解，程序的执行应该是这样的：

1. 线程1启动，读取count的值为0，进入无限循环
2. 线程2启动，读取count的值为0，休眠1秒
3. 线程2休眠结束，修改count的值为10
4. 线程1的循环条件发现count=10>1，结束循环，打印出count的值
5. 程序结束

但是实际的情况是这样吗？并不是，我们执行起来会发现，一秒后，程序打印了如下内容：

```
change value of count to 10
```

之后程序就无限循环了，线程1并没有结束。

为什么会这样？这里其实就是我们前面提到的，线程1读取到`count=0`之后，把这个结果存到线程私有内存了，之后每次使用`count`都从私有内存读取，所以虽然线程2修改了`count`的值，但是这个结果线程1并不知道，所以线程1就无限循环了。

那么，如果我们把`count`的声明修改成这样:

```java
static volatile int count = 0;
```

再次运行程序，这个时候会发现，执行的结果如我们预料的那样，1秒后线程2修改了count的值，线程1读到了这个变化并退出了循环：

```
change value of count to 10
exit when count = 10
```

实际上，这里也突出了`volatile`关键字的一个用途，这个例子中使用`synchronized`也是无法满足要求的，因为一旦进入线程1的循环，线程2就无法改变线程1的私有内存值了。

无论给线程1和线程2单独加锁，`count`的变化线程1都是无法探测到的，如下:

```java
public static void main(String[] args) {
    new Thread(()->{
        synchronized (count){
            do{}while (count<1);
        }
        System.out.println("exit when count = "+count);
    }).start();
    new Thread(()->{
        try {
            Thread.sleep(1000);
                count = 10;
            System.out.println("change value of count to "+count);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }).start();
}
```

或

```java
public static void main(String[] args) {
    new Thread(()->{
        do{}while (count<1);
        System.out.println("exit when count = "+count);
    }).start();
    new Thread(()->{
        try {
            Thread.sleep(1000);
            synchronized (count){
                count = 10;
            }
            System.out.println("change value of count to "+count);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }).start();
}
```

运行结果都和不加锁一样，如果同时给线程1和线程2加锁，由于线程1持有锁之后不在释放，线程2根本无法改变`count`的值。

为什么加上`volatile`关键字之后就能解决问题呢？

前面我们已经提到，线程在运行的时候，会把变量拷贝到线程私有内存中，`volatile`关键字实际上告诉JVM，`count`变量不允许拷贝到私有内存，需要用的时候只能从主内存读取，因此线程1每一次判断`count`是否大于1时，都会从主内存读`count`来判断，而1秒后，线程2修改了主内存的值，因此这个变化就能被线程1探测到了，从而可以退出程序。

## 如何正确使用`volatile`

接下来我们来讨论一下如何正确使用`volatile`关键字，实际上，这个关键字是一个“程度较轻的 synchronize”，运行的开销远比`synchronize`要小。

想要正确使用`volatile`，我们需要遵循如下两个原则：

* 对变量的写操作不依赖于当前值
* 该变量没有包含在具有其他变量的不变式中

第一个原则的理解就是，当你需要改变这个变量时，要保证你要改变的值跟这个变量原先的值没有任何关系，比如：

```java
count = 10;
```

这里我们无论`count`的值是什么都直接赋值了10，这个变化跟它原先的值没有任何关系，如果是如下的方式:

```java
count++;
```

这里`count`的结果是依赖于它原来的值加1得到的，所以这种场景不适合使用`volatile`关键字。

第二个原则的理解，我们举如下例子：

```java
public class NumberRange {
    private volatile int lower, upper;

    public int getLower() { return lower; }
    public int getUpper() { return upper; }

    public void setLower(int value) { 
        if (value > upper) 
            throw new IllegalArgumentException(...);
        lower = value;
    }

    public void setUpper(int value) { 
        if (value < lower) 
            throw new IllegalArgumentException(...);
        upper = value;
    }
}
```

这里我们看到，`setLower`和`setUpper`两个方法中，使用了大小的边界检查，保证了`lower`总是小于`upper`，在单线程环境下没有问题，但是如果有另外两个线程并发的调用`setLower`和`setUpper`，比如，初始状态是``(0, 5)`，某个时刻线程A调用 `setLower(4)`的同时线程B调用`setUpper(3)`，这个时候两个调用都可以通过边界检查，最后得到`(4, 3)`，这个边界结果显然是没有意义的，但是`volatile`在这里并不能起作用，这种情况应该使用锁来保证边界结果的有效性。

一般情况下，在并发环境下需要同时满足上面的两个原则会比较难，这也决定了`volatile`的使用场景非常有限。现在我们介绍一下正确的几个使用场景：

### 场景一：作为状态标识

这个场景很好理解，一般来说状态值的改变都是完全独立于上一个状态的，同时也基本不会用来和其他变量组成不变式，比如在jdk8的线程池实现中，状态值就用了这个关键字，在我们前面无限循环的例子中，循环条件`(count < 1)`也可以认为是一个状态值，注意，这里`count`是和常量组成不变式，而不是和变量组成不变式，这是满足第二个原则的。

### 场景二：多线程初始化对象

在某些复合对象中，有时候复合对象含有某个复合对象的属性，我们知道，这个属性实际上存储的是这个对应的复合对象的地址，在并发环境下，这个地址可能由某个指定的线程来赋值，而其他的线程只需要使用即可，但是使用前需要检查确保这个属性可用，举例如下：

```java
public class Main {
    public static void main(String[] args) {
        ComplexObject obj = new ComplexObject();
        // 线程1
        new Thread(()->{
            do{
                if(obj.field != null){
                    break;
                }
            }while (true);
            System.out.println("exit when obj.field is not null ");
        }).start();
        // 线程2
        new Thread(()->{
            try {
                Thread.sleep(1000);
                System.out.println("init obj");
                obj.init();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }).start();
    }

    static class ComplexObject{
        public volatile ComplexObject field = null;

        public void init(){
            field = new ComplexObject();
        }

    }
}
```

这里我们可以看到，线程1会不停的检测复合对象的`field`属性是否为空，只有当不为空的时候才会结束循环，而线程2会在启动1秒后才给`obj`进行初始化，也就是说，`obj`对象真正出于发布可用的状态是在线程2中初始化之后，因此这里需要对`field`属性使用`volatile`，否则线程2对`obj`的初始化将对线程1永远不可见，线程1也就不会结束了。

### 场景三：定期修改的对象

还是参考场景二的例子，如果在线程2中会跟随时间变化给`field`设置不同的值，并且在线程1中会根据不同的值做不同的处理，那么就是线程1使用一个定期修改的对象，这种情况下为了保证线程1能每次看到的都是最新的`field`，需要使用`volatile`来修饰。

### 场景四：不稳定对象

我们现在经常使用spring容器，或者leap框架提供的IOC容器，这里的bean对象一般来说是单例的，在多线程环境下使用的是同一个bean，这种场景下，如果这个bean对象的属性是可变的，并且某个线程可能会改变这个属性，而其他线程会使用这个属性，这个时候我们就需要使用`volatile`修饰所有属性来保证某个线程对这个bean的修改对其他线程是可见的，比如，在web应用中，我们登录后会吧用户的对象放在`Session`中，用户对象的类如下：

```java
public class Person {
    private volatile String firstName;
    private volatile String lastName;
    private volatile int age;

    public String getFirstName() { return firstName; }
    public String getLastName() { return lastName; }
    public int getAge() { return age; }

    public void setFirstName(String firstName) { 
        this.firstName = firstName;
    }

    public void setLastName(String lastName) { 
        this.lastName = lastName;
    }

    public void setAge(int age) { 
        this.age = age;
    }
}
```

当某个线程对`Person`的属性进行修改时，要保证其他线程都能探测到这个修改，因此这里的属性需要使用`volatile`来修饰。

#### 场景五：高性能读-写锁策略

这个场景属于`volatile`比较高级的应用，我们可以通过`volatile`来保证读的可见性，使用锁来保证赋值操作的原子性，最简单的例子就是做一个高性能的计数器：

```java
public class Counter {
    private volatile int value;

    public int getValue() { return value; }

    public synchronized int increment() {
        return value++;
    }
}
```

我们可以看到，由于这里读取当前计数结果`getValue()`没有加锁，因此这个读取的性能非常高，而对计数自增时`increment()`，采用了锁`synchronized`，可以保证在高并发环境下计数结果不会出错。

当然，这里的例子非常简单，在比较复杂的业务逻辑下，这种高级应用需要特别小心，如果对读的性能要求并没有特别高的话，可以考虑完全使用锁来处理，否则就要特别小心地使用，不然很容易在高并发下出现并发问题导致大量业务失败，那就得不偿失了。

## 总结

`volatile`的使用需要对jvm本身的一些机制特别理解才能正确使用，当然，既然涉及到jvm本身的机制，那么`volatile`的特性跟jvm的实现就有关系了，本文所有的代码和结论都是在jdk8下，使用`HotSpot`虚拟机得出的结果，不同的虚拟机可能会有不一样的实现结果，当然，只要符合按照jvm标准实现的虚拟机，上述的结论都是成立的。

  [1]: https://raw.githubusercontent.com/kael-aiur/image-repo1/master/java_volatile/java_vm_mem.png "java_vm_mem.png"
