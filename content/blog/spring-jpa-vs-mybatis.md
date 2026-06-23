---
date: 2026-04-04T23:01:41+08:00
slug: spring-jpa-vs-mybatis
title: Spring JPA、MyBatis、DDD 和 CQRS 串讲
tags:
- 对象关系映射
- 领域驱动设计
- 命令-查询职责分离
---
## Spring Data JPA 与 MyBatis 的区别

JPA 是对象优先（object-centric），它把 SQL 操作封装起来，你只管操作 Java 对象，它负责生成 SQL；MyBatis 是 SQL 优先（SQL-centric），让你在 Java 代码中写 SQL，支持更细粒度的 SQL 控制。

- JPA 的优点：适合关联复杂的数据架构，事务管理可以做到强一致性，适合微服务和领域驱动设计，用它的大部分都是微服务和领域驱动设计的项目。领域驱动设计的一个好处是可以减少关联查询，多表关联是性能很差的操作，应当淘汰。
- JPA 的缺点：JPA 做动态 SQL 很难，也就是说它难做复杂的查询逻辑。

- MyBatis 的优点：好做动态 SQL，SQL 调优。
- MyBatis 的缺点：难以处理关联查询的 n+1 问题。

Spring JPA 在国外很火，但在国内不温不热，国内基本上都是用 MyBatis，可能做微服务比较成熟的厂用 JPA 要多一点。

## 领域驱动设计的持久层基础设施的实现

领域驱动设计（DDD，domain-driven design）的持久层基础设施的一个实现方案是 CQRS：业务用 JPA，查询用 MyBatis。

CQRS（command query responsibility segregation，命令和查询职责分离）的核心是读写分离，写数据的时候用 JPA，读数据的时候用 MyBatis。把工具用在它最擅长的地方，各司其职。
