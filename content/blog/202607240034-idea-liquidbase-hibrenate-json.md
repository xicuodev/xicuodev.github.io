---
date: 2026-07-24T10:34:00+08:00
slug: idea-liquidbase-hibrenate-json
title: 让Spring Data JPA和Liquibase能够处理JSON类型的Hibernate ORM映射的JPA注解（含JDK8和11两种方案）
---
[Jakarta Persistence](https://jakarta.ee/learn/docs/jakartaee-tutorial/current/persist/persistence-intro/persistence-intro.html)（原名Java Persistence，简称JPA）是Java持久化规范，它定义了一套Java持久化的标准接口、注解（如`@Entity`、`@Table`、`@Column`）和查询语言（JPQL）。JPA是一套抽象的API规范，不是具体的代码实现。[Hibernate](https://hibernate.org/)是Java的一个具体的ORM框架，早在JPA规范诞生之前就已经存在并广泛应用。JPA规范的拟定大量借鉴了Hibernate的设计思想，而Hibernate也对JPA规范做了完整的实现，同时Hibernate还包含更多自己特有的高级特性。因此，Hibernate是JPA的超集。

[Liquibase](https://www.liquibase.com/)是Java生态中的一个数据库迁移脚本（Liquibase称之为“更新日志”，changelog）的生成和管理工具，它本身也是Java写的。Liquibase更新日志支持XML、YAML、JSON和SQL四种格式，它的生成有两种方式，一种是手动编写，另一种是比对最新更新日志和当前数据库架构，根据二者之间的差异生成新的更新日志（过程和Git的diff差异算法是一个道理）。IntelliJ IDEA捆绑集成的[Liquibase插件](https://www.jetbrains.com/help/idea/liquibase.html)可以读取Java实体类中的JPA注解，将其与当前数据库架构比对差异，据此生成Liquibase更新日志并执行它（也就是将更新日志中的更改实际作用于数据库），用于管理数据库架构（schema）的版本。

下面介绍如何通过JPA注解让Spring Data JPA和IDEA的Liquibase插件都能够处理Java复杂类型字段与MySQL JSON类型列之间的相互映射，在“把一个Java复杂类型字段转换为JSON字符串存到数据库中，并能够从数据库中读取JSON字符串并据此重建出原始字段”方面达成共识。其中，IDEA的Liquibase插件负责管理数据库架构，Spring Data JPA负责读写数据库，它们都依赖于JPA规范。

MySQL从`5.7.8`版本开始正式引入并支持原生的`JSON`数据类型。在此之前，开发者通常只能使用`VARCHAR`或`TEXT`等字符类型来存储JSON格式的字符串。下面都采用`5.7.8`及以上版本的MySQL，使用MySQL的原生`JSON`类型。

首先，在一开始这里简要给出jdk8持久化JSON类型的实用方案。欲知详情，请见[jdk8的方案-原生jpa方案](#jdk8-jpa)。

```java
@Convert(converter = JpaMapJsonConverter.class)
@Column(columnDefinition = "json")
private Map<String, String> spec;
```

```sql
-- liquibase插件根据上面的代码生成的SQL更新日志
ALTER TABLE item ADD spec JSON NULL;
```

## 1. jdk11的方案

对于jdk11及以上的开发环境，使用`@JdbcTypeCode`一行注解即可实现JSON类型的ORM映射，支持Map和List，分别对应JSON对象和JSON数组。但是idea的liquibase插件往往不认，此时真得控制控制它了，需要加一行`@Column(columnDefinition = "json")`让它强行认识。

```java
@JdbcTypeCode(SqlTypes.JSON)
@Column(columnDefinition = "json")
private Map<String, String> spec;
```

liquibase插件生成的SQL更新日志：

```sql
ALTER TABLE item ADD spec JSON NULL;
```

## 2. jdk8的方案

对于jdk8来说，实现JSON类型的ORM映射有两种方式，一种是通常更为推荐的原生jpa方案，另一种是

### 2.1. 原生jpa方案 (适合mysql) {#jdk8-jpa}

实现 jpa 提供的 `AttributeConverter` 接口，手动调用 jackson 方法实现 map 与 string 的互转。mysql 的 jdbc 驱动天然支持将 json 字符串存入 mysql 的 `JSON` 类型列。

```java
@Converter
public class JpaMapJsonConverter implements AttributeConverter<Map<String, String>, String> {
  private static final ObjectMapper objectMapper = new ObjectMapper();

  @Override
  public String convertToDatabaseColumn(Map<String, String> attribute) {
    if (attribute == null) {
      return null;
    }
    try {
      return objectMapper.writeValueAsString(attribute);
    } catch (JsonProcessingException e) {
      throw new RuntimeException("JSON 序列化失败: " + e.getMessage(), e);
    }
  }

  @Override
  public Map<String, String> convertToEntityAttribute(String dbData) {
    if (dbData == null || dbData.trim().isEmpty()) {
      return null;
    }
    try {
      return objectMapper.readValue(dbData, new TypeReference<Map<String, String>>() {});
    } catch (JsonProcessingException e) {
      throw new RuntimeException("JSON 反序列化失败: " + e.getMessage(), e);
    }
  }
}
```

调用`objectMapper.readValue()`时，必须传入`TypeReference`，否则反序列化出来会丢失`Map`的泛型类型。

```java
@Convert(converter = JpaMapJsonConverter.class)
@Column(columnDefinition = "json")
private Map<String, String> spec;
```

### 2.2. hibernate-types方案 (适合postgresql)

`@JdbcTypeCode`需要hibernate orm 6，但是后者[最低支持jdk11](https://hibernate.org/community/integrations/#java)，jdk8用不了。但也不是没有替代方案：hibernate 5.x + [hibernate-types库](https://github.com/vladmihalcea/hypersistence-utils) + 手动注明 `@Column(columnDefinition = "json")`。

```xml
<dependency>
    <groupId>org.hibernate</groupId>
    <artifactId>hibernate-core</artifactId>
    <version>5.6.15.Final</version>
</dependency>

<dependency>
    <groupId>com.vladmihalcea</groupId>
    <artifactId>hibernate-types-55</artifactId>
    <version>2.21.1</version>
</dependency>
```

```java
import com.vladmihalcea.hibernate.type.json.JsonType;
import org.hibernate.annotations.Type;
import org.hibernate.annotations.TypeDef;

@Entity
@TypeDef(name = "json", typeClass = JsonType.class)
public class Item {
    @Type(type = "json")
    @Column(columnDefinition = "json")
    private Map<String, String> spec;
}
```

- `@Type(type = "json")`告诉基于hibernate的spring data jpa使用`JsonType`处理该字段。
- `@Column(columnDefinition = "json")`告诉idea的liquibase插件生成`JSON`类型的数据库列。

## 3. 更多参考

- [hibernate 5 hypersistence-utils库](https://www.baeldung-cn.com/hibernate-persist-json-object#5-使用-hypersistence-utils-库)
- [io.hypersistence/hypersistence-utils-hibernate-55](https://mvnrepository.com/artifact/io.hypersistence/hypersistence-utils-hibernate-55)
- [com.vladmihalcea/hibernate-types-55](https://mvnrepository.com/artifact/com.vladmihalcea/hibernate-types-55)
- [hibernate 6 @JdbcTypeCode JDBC类型代码注解](https://www.baeldung-cn.com/hibernate-persist-json-object#6-使用-jdbctypecode-注解（hibernate-6）)
- [hibernate 6 @Embeddable 嵌入实体类注解](https://www.baeldung-cn.com/hibernate-persist-json-object#7-将-json-映射到-embeddable-类（hibernate-6）)
- [hutool-bean-to-map](https://doc.hutool.cn/pages/BeanUtil/#bean转为map)
- [hutool-bean-to-bean](https://doc.hutool.cn/pages/BeanUtil/#bean转bean)
- [mp-type-handler-json](https://baomidou.com/guides/type-handler/#json-字段类型处理器)
