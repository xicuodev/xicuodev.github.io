---
date: 2025-08-26T15:11:00+08:00
slug: typing-disciplines-of-prog-langs
title: 编程语言的类型推断系统：动态类型与静态类型和强类型与弱类型
---

本文参考[这篇知乎回答](https://www.zhihu.com/question/19918532/answer/23217475)，讨论的是[编程语言理论](https://zh.wikipedia.org/wiki/程式語言理論)([PLT, programming language theory](https://en.wikipedia.org/wiki/Programming_language_theory))的[类型系统](https://zh.wikipedia.org/wiki/類型系統)([type system](https://en.wikipedia.org/wiki/Type_system))中的类型推断系统[^1](typing disciplines)或者更常说的[类型推论](https://zh.wikipedia.org/wiki/类型推论)([type inference](https://en.wikipedia.org/wiki/Type_inference))。

[^1]: 这个译名参考[这篇条目](https://www.wikidata.org/wiki/Property:P7078)。

---

说到动态类型与静态类型和强类型与弱类型的区别，简而言之：

- 动静：类型声明的严格程度
- 强弱：类型转换的严格程度

## 常见的不同类型推断系统的编程语言

使用方法：先看下面的具体解释，再看这张表，并结合所学编程语言知识对照理解。

|       |                       强类型                        |                      弱类型                      |
| :---: | :-------------------------------------------------: | :----------------------------------------------: |
| 动态  |                    Python, Ruby                     |            JavaScript, PHP, VBScript             |
| 静态  | Java, C++, C#, Rust, Go,<br/>Swift, Kotlin, Haskell | C/C++(底层指针,`void*`,<br />`union`), ASM(汇编) |

## 动态类型语言 Dynamically Typed Language

变量的类型是在运行时确定的，不需要显式声明。例如 ECMAScript (JavaScript)、Ruby、Python 和 PHP 就是典型的动态类型语言，脚本语言如 VBScript 也多少属于动态类型语言。

* 优点：方便阅读，不需要写非常多的类型相关的代码。
* 缺点：不方便调试，命名不规范时会造成读不懂，不利于理解等。

## 静态类型语言 Statically Typed Language

变量的类型在编译时（或声明时）确定，需要显式声明。C/C++ 是静态类型语言的典型代表，其他还有 C#、Java 等。

* 优点：结构非常规范，便于调试，方便类型安全。
* 缺点：为此需要写更多类型相关代码，不便于阅读、不清晰明了。

## 强类型定义语言 Explicit type conversion

变量是类型安全的，不允许任何隐式不安全转换。定义一个整型变量 a，若不显式转换，则不能将 a 当作字符串类型处理。例如 C/C++、C#、Java 等。

## 弱类型定义语言 Implicit type conversion

弱变量是类型不安全的，允许大量的隐式不安全转换。例如 PHP、ASP、Ruby、Python、Perl、ABAP、SQL、JavaScript、Unix Shell 等。

在 VBScript 中，可以将字符串 '12' 和整数 3 进行连接得到字符串 '123'，然后可以把它看成整数 123，而不需要显式转换。
