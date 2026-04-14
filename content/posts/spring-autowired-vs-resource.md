---
date: 2026-03-06T22:56:43+08:00
categories:
- Spring
tags:
- 依赖注入
slug: spring-autowired-vs-resource
title: Spring @Autowired 和 @Resource 的区别
---

`@Autowired` 和 `@Resource` 都是用来依赖注入的注解，但不同的是，它们：

## 来源不同

`@Autowired` 是 Spring 提供的，`@Resource` 是 **Java 标准**（JSR-250 规范）提供的。

`@Autowired` 的全限定名是：

```
org.springframework.beans.factory.annotation.Autowired
```

`@Resource` 的全限定名是 `javax.annotation.Resource`（在 Jakarta EE 中为 `jakarta.annotation.Resource`）。

## 行为不同

`@Autowired` 是按类型匹配（byType），`@Resource` 是按名称匹配（byName），如果匹配不到再按类型匹配。


`@Autowired` 会首先在 Spring 容器中查找与所需类型匹配的 Bean，如果容器中恰好有一个该类型的 Bean，直接注入；如果容器中有多个该类型的 Bean，或一个接口有多个实现类，则会抛出异常（`NoUniqueBeanDefinitionException`），此时需要配合 `@Qualifier` 指定名称来注入。`@Resource` 会首先根据字段名（或 setter 名）去查找 Bean，如果找不到名称匹配的，才会回退到按类型查找。

## 消歧义方式不同

`@Autowired` 必须配合 `@Qualifier` 来指定 Bean 的唯一名称。`@Resource` 自带属性，可以通过 `name` 属性直接指定，更加简洁。

```java
@Autowired
@Qualifier("aliyunSmsService")
private SmsService smsService;
```

```java
@Resource(name = "aliyunSmsService")
private SmsService smsService;
```

或者直接把字段名写全了，对默认匹配名称的 `@Resource` 来说就不会有歧义了：

```java
@Resource
private SmsService aliyunSmsService;
```

## 用的地方不同

`@Autowired` 支持在构造器上使用，Spring 官方推荐的方式，尤其适用于生成不可变对象（`final` 字段）。`@Resource` 不支持在构造器上使用，主要用于字段和 setter 方法。

## 总结：依赖注入时该用哪个注解？

如果你明确需要按类型注入，且项目是标准的 Spring 项目，用 `@Autowired` 比较方便。如果你需要按名称注入，或者希望代码尽可能减少对 Spring 的依赖（比如将来可能迁移到其他 IoC 容器），或者单纯觉得 `@Resource` 写起来比 `@Autowired` + `@Qualifier` 简洁，可以用 `@Resource`（而且它不会报“**不建议使用字段注入**”的黄色波浪线）。
