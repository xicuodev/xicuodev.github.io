---
date: 2026-04-12T11:59:03+08:00
tags:
- 软件开发
- 领域驱动设计
slug: data-objects-in-software-development
title: 软件开发中的数据载体：VO、DTO、DO 和 PO
---
## 简单 Java 对象 POJO, Plain Old Java Object

POJO 是所有数据载体的基础原型，指不继承特定类、不实现特定接口、不依赖特定框架、仅包含私有属性 getter/setter 方法、无业务逻辑的轻量 Java 类。

POJO 是泛化概念，而非特指某一种业务对象，DO、DTO、VO 等数据载体均是特殊的 POJO。[^1]

## 各架构层级下的行为主体和数据载体一览表

| 架构层级            | 行为主体                                                                        | 数据载体                                         |
| ------------------- | ------------------------------------------------------------------------------- | ------------------------------------------------ |
| 表现层 Presentation | Controller (控制器), ViewResolver (视图解析器)                                  | **VO**, Response                                 |
| 应用层 Application  | ApplicationService (应用服务), **QueryHandler & CommandHandler** (CQRS)         | **DTO**, BO, TO, **Query & Command** (CQRS)      |
| 领域层 Domain       | DomainEntity (领域实体), ValueObject (值对象), 聚合根, DomainService (领域服务) | **领域实体**, **值对象**, 领域DO                 |
| 持久层 Persistence  | Repository 仓储接口, Mapper 映射器                                              | **PO**, DatabaseEntity (数据库实体), DAO, 数据DO |

## DTO “克制”的设计原则

DTO 应该是扁平的、无行为的、仅包含必要字段的简单数据容器。

- 字段数量：超过 10-15 个字段就需要审视——是否把多个职责揉在一起了？
- 嵌套层级：避免 DTO 嵌套 DTO 超过 2 层。深层嵌套往往意味着视图与领域模型过度耦合。
- 不包含逻辑：DTO 里不能有任何业务方法、验证逻辑（格式校验除外）、计算属性。验证应该由应用服务使用领域对象或专门的验证器完成。

DTO 从创建到转换为领域对象（或序列化为响应）即结束，不在内存中长期持有。

- 输入 DTO：在应用服务方法内部完成转换后，不再被引用。
- 输出 DTO：从领域对象转换后立即返回给调用方，不做二次修改。

## 领域驱动设计中的 DO

在 DDD 的领域层（Domain Layer），原有的 DO（Domain Object）会被更精确的**领域实体（Entity）和值对象（Value Object）** 所替代。领域实体和值对象必须做到：

- 不包含任何数据库、JSON 等外部框架的注解或标签。
- 不依赖任何基础设施，如仓储的具体实现、网络通信等。
- 仅封装核心业务逻辑与验证规则，成为一个**纯粹表达业务知识**的模型。

[^1]: https://developer.aliyun.com/article/1720695
