---
title: 解决NSString stringWithFormat:参数nil时返回(null)
date: 2017-01-05 00:15:19
categories: 解决方案
tags: iOS
---

#### 前言

NSString 这个类，在 OC 中很常见，[NSString stringWithFormat:] 这个方法我们都很熟悉了。但是也有很常见的一个问题，那就是参数为空的时候会返回@"(null)"。

<b>举个例子</b><br>
```
label.text = [NSString stringWithFormat:@"所在医院 : %@", self.doctor.hospital];
```
当 doctor.hospital 为 nil 时，显示“所在医院 : (null)”，理所当然 (null) 这样的字眼不应该出现在界面上被用户看见。

<!--more-->

#### 解决 
- 使用宏，将传入的可变参数中的nil替换为空字符串@""

    1.定义一个宏，写到PCH文件中
    ```
    #define DKNonnullString(str) ((str && [str isKindOfClass:[NSString class]] && str.length) ? str : @"")
    ```
    2.可变参数每一个都包上这个宏
    ```
    label.text = [NSString stringWithFormat:@"所在医院 : %@", DKNonnullString(self.doctor.hospital)];
    ```

    原理 : 其实很简单，就是先判断参数是否为nil，如果是，就把它替换为空字符串，再进行format。

    虽然可以实现，但这样子每次调用stringWithFormat:的时候都要包一个宏，感觉很麻烦！程序猿是无法忍受这种重复累赘的，至少我是这样子的，那有没有更酷的办法呢？

- 使用分类，重写stringWithFormat方法

    跳到头文件 NSString.h 中，可以看到有与它相似的方法。
    ```
    + (instancetype)stringWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);
    - (instancetype)initWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);
    - (instancetype)initWithFormat:(NSString *)format arguments:(va_list)argList NS_FORMAT_FUNCTION(1,0);
    ```
    首先需要了解 initWithFormat: 和 stringWithFormat: 的区别
    - initWithFormat是实例方法，在MRC下需要手动release
    - stringWithFormat是类方法，在MRC下返回的结果是autoRelease，推荐使用。

  而现在的项目绝大部分都是ARC了，所以两者可以说是没有区别，从调用方式的角度来讲，我个人还是比较喜欢类方法。重点是两者之间可以互换！
  
  再来看看 arguments，可以看到参数类型是 va_list，这货一看就不像是OC的东西，应该是C语言的。网上一搜，果然跟猜想的一样。它的意思是参数列表，除了va_list，还有 va_start、va_arg、va_end、NS_FORMAT_FUNCTION，都是C语言提供的处理变长参数的方法。
  
  给NSString添加一个分类，重写系统的stringWithFormat:方法。
  ```
   // NSString+DKExtension.m
   
   /**
    * 重写系统方法，替换返回的字符串中的 (null) 为空字符串
    *  @"(null)" -> @""
    */
    + (instancetype)stringWithFormat:(NSString *)format, ...
    {
        va_list arglist; 
        va_start(arglist, format); 
        NSString *outStr = [[NSString alloc] initWithFormat:format arguments:arglist];
        va_end(arglist); 
    
        return [outStr stringByReplacingOccurrencesOfString:@"(null)" withString:@""];
    }
  ```
  - NS_FORMAT_FUNCTION(1, 2) : 告诉编译器，索引1处的参数是一个格式化字符串，而实际参数从索引2处开始
  - va_list : 定义一个指向个数可变的参数列表的指针，这个参数列表指针就是arglist
  - va_start : 使参数列表指针指向format，从format的下一个元素开始
  - va_end : 结束

  原理 : 重写系统的 stringWithFormat 方法，使用C语言提供的处理变长参数的方法获取参数列表，调用 initWithFormat:arguments: 方法，把返回的字符串在return前做过滤处理，把@"(null)"全部替换成@""。

  因为分类是load完毕就生效的，所以不需要#import导入分类文件，写好放着就行了。
  
#### 补充

如果是MRC下，再调用 autorelease 方法即可
```
NSString *outStr = [[[NSString alloc] initWithFormat:formatStr arguments:arglist] autorelease];
```
  
#### 后话

也许有人会说，重写了系统的方法，会不会带来其它地方的未知问题。我觉得还好吧，虽然重写了 stringWithFormat: 这个方法，把返回的字符串中的 @"(null)" 过滤掉了而已，但实际上还是调用系统的另一个方法 initWithFormat:arguments:，只不过在ARC下恰好没什么影响。

我们整理了开发中常用的分类 [DKExtension](https://github.com/bingozb/DKExtension)，里面已经包含了上面所说的内容，欢迎导入我们的分类库进行开发。
- 支持Cocoapods
  ```
  pod 'DKExtension.h'
  ```
- Download or Usage 请移步 GitHub
