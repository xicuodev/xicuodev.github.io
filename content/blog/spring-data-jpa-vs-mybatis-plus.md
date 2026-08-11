---
date: 2026-04-04T23:01:41+08:00
slug: spring-data-jpa-vs-mybatis-plus
tags:
- 对象关系映射
- 领域驱动设计
- 命令-查询职责分离
title: Spring Data JPA、MyBatis-Plus、DDD 和 CQRS 串讲
---
## Spring Data JPA 与 MyBatis-Plus 的区别

Spring Data JPA（下称 JPA）是以对象中心的（object-centric），它把 SQL 操作封装起来，你只管操作 Java 对象，它负责生成 SQL；MyBatis-Plus（下称 MP）是以 SQL 中心的（SQL-centric），它让你可以在 Java 代码中方便地构建复杂的查询逻辑，支持更细粒度的 SQL 控制。

- JPA 的优点：好做简单关联查询，事务管理可以做到强一致性，适合微服务和领域驱动设计，用它的大部分都是微服务和领域驱动设计的项目。JPA 的缺点：难做动态 SQL 等复杂的查询逻辑。
- MP 的优点：好做复杂关联查询、动态 SQL 和 SQL 调优。MP 的缺点：难以处理关联查询的 n+1 问题。

JPA 在国外很火，但在国内不温不火。国内基本上都是用 MP，可能做微服务比较成熟的厂用 JPA 要多一点。

## 领域驱动设计(DDD)的持久层基础设施的实现

领域驱动设计（DDD，domain-driven design）的持久层基础设施的一个实现方案是 CQRS 的持久层实现：命令用 JPA，查询用 MP。

CQRS（command query responsibility segregation，命令和查询职责分离）的核心是命令和查询的业务处理逻辑职责分离，这将应用层和持久层又纵向分为 Command 和 Query 两侧。对于持久层，建议 Command 侧用 JPA，Query 侧用 MP。把工具用在它最擅长的地方，各司其职。领域驱动设计的一个好处是可以减少跨聚合的关联查询，把数据库的联表压力转移到了应用层的两次查询或缓存，这点与 JPA 的特点刚好适配。对于不得不做的跨聚合关联查询，比如有此类需求的专门的查询侧接口，就适合用 MP 来做。

值得注意的是，Command 侧仍需要先读数据构建聚合根，才能开展下一步领域操作，此时 JPA 强大的关联查询能力就可派上用场。注意，Command 侧的查询只是为了从持久层读取并构建聚合根，其目的是为了完成写入操作。不应该因为是查询逻辑就跑去依赖 Query 侧的查询逻辑，这样会导致 CQ 两侧耦合，违背了 CQRS 命令查询职责分离的原则。因此，JPA 在 Command 侧仍需要发挥其查询能力。
