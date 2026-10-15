---
date: 2026-10-15T12:34:15+08:00
slug: 3-ant-style-path-parsers
title: 3种Ant风格路径的解析器：Spring AntPathMatcher、Spring PathPatternParser和Hutool AntPathMatcher
tags: []
---

Ant风格路径（Ant-Style Path）是一种用于匹配文件路径或URL的通配符语法规范。它最早起源于Apache Ant构建工具（用于指定需要编译、打包的文件集合），后来因为简洁直观，被Spring Framework、Gradle、Jenkins、Nginx等无数Java生态及DevOps工具采纳，成为了事实上的路径匹配行业标准。

| 通配符 | 含义             | 匹配范围                     | 示例                                                            |
| :----- | :--------------- | :--------------------------- | :-------------------------------------------------------------- |
| `?`    | 匹配单个字符     | 不包含路径分隔符 `/`         | `/user/?` 匹配 `/user/a`，不匹配 `/user/ab`                     |
| `*`    | 匹配任意数量字符 | 不包含路径分隔符 `/`         | `/api/*.json` 匹配 `/api/data.json`，不匹配 `/api/v1/data.json` |
| `**`   | 匹配任意层级目录 | 包含路径分隔符 `/`，可跨多级 | `/api/**` 匹配 `/api/v1/user/list`                              |

Spring Core (Legacy) AntPathMatcher、Spring WebFlux PathPatternParser和Hutool AntPathMatcher都是Ant风格路径解析器，三者的区别在于：Spring AntPathMatcher背负着多年的历史包袱，追求“绝对兼容”；Spring PathPattern为了极致性能，选择了“极致性能”的严格规范；而 Hutool AntPathMatcher则追求“够用就好”的轻量级实现。

## 三者支持路径风格的区别点

1. 多段路径匹配符`**`的支持程度

- Spring AntPathMatcher：随心所欲（最宽松），支持`**`出现在路径的任何位置。正例：`/**/api/**`、`/api/**/user`。
- Spring PathPattern：严格限制（最严格），明确禁止`**`出现在路径中间。`**`只能出现在路径的末尾，或者作为整个路径。正例：`/api/**`、`**`；反例：`/api/**/user`。
- Hutool AntPathMatcher：跟随传统Ant规范，支持`**`出现在中间，行为与Spring AntPathMatcher一致。

2. 路径变量与正则约束

- Spring AntPathMatcher：支持内联正则（最强大），支持在路径变量中直接嵌入正则表达式进行约束：`{varName:regex}`。正例：`/user/{id:\d+}` (只匹配纯数字的 id，如放行 `/user/123`，拒绝 `/user/abc`)、`/user/{name:[a-zA-Z]+}`。不仅能判断是否匹配，还能将`id`或`name`提取为Map返回。
- Spring PathPattern：砍掉正则，追求纯粹（最克制），完全不支持内联正则。反例：`/user/{id:\d+}`；正例：`/user/{id}`、`/files/{*path}` (PathPattern独有语法，捕获包含`/`的多段路径，等同于`**`的变量提取版)。Spring团队认为在路由层做正则匹配太重，且难以预编译优化。推荐的做法是：先用`{id}`匹配所有字符串，然后在Controller或Handler内部使用`@Valid`或手动校验类型。
- Hutool AntPathMatcher：只做匹配，不支持提取（最简陋）， Hutool的AntPathMatcher仅仅是一个布尔判断工具，不支持任何形式的`{var}`变量提取。反例：`/user/{id}` (Hutool 会把`{id}`当作普通字符串去匹配字面量`{id}`，而不是通配符)。

3. 尾部斜杠 (`/`) 的隐式匹配：当客户端请求`/api/user/`时，能否匹配到`/api/user`？

- Spring AntPathMatcher：默认匹配，可通过 `setUseTrailingSlashMatch(false)` 关闭。
- Spring PathPattern：默认不匹配，Spring Boot 3 中已废弃尾部斜杠匹配配置，强制要求精确匹配。如需匹配，必须显式定义两个 Pattern 或使用 Filter 移除尾部斜杠。
- Hutool AntPathMatcher：默认不匹配，纯字符串匹配逻辑，`/api/user` 和 `/api/user/` 被视为不同路径。

## 三者的性能差异

Spring AntPathMatcher性能差 (运行时解析)，Spring PathPattern性能极优 (预编译)，Hutool AntPathMatcher性能中等 (运行时解析)。
